-- ════════════════════════════════════════════════════════════
-- 🌤️ RDE WEATHER & TIME - SERVER (PRODUCTION READY)
-- ════════════════════════════════════════════════════════════
local Config = require 'config'
local Ox = require '@ox_core.lib.init'

-- ════════════════════════════════════════════════════════════
-- 📊 STATE VARIABLES
-- ════════════════════════════════════════════════════════════
local State = {
    currentWeather = Config.Weather.defaultWeather,
    targetWeather  = Config.Weather.defaultWeather,
    isTransitioning = false,
    snowEnabled    = false,
    windSpeed      = 5.0,
    windDirection  = 0.0,
    currentHour    = Config.Time.customCycle.startHour,
    currentMinute  = Config.Time.customCycle.startMinute,
    currentSecond  = 0,
    isDayTime      = true,
    nextWeatherChange = nil,
    lastSave       = 0,
    timeOffset     = 0,
    lastTimeUpdate = os.time(),
    consecutiveBadWeather = 0, -- streak-breaker: counts non-clear changes in a row
}

-- ════════════════════════════════════════════════════════════
-- 📡 NOSTR LOGGER HELPER (OPTIONAL — graceful fallback)
-- ════════════════════════════════════════════════════════════
local nostrAvailable = false

-- Checked once on startup, re-evaluated on each call as safety net
local function IsNostrAvailable()
    return GetResourceState('rde_nostr_log') == 'started'
end

local function NostrLog(message, tags)
    if not IsNostrAvailable() then return end
    local ok, err = pcall(function()
        exports['rde_nostr_log']:postLog(message, tags or {})
    end)
    if not ok and Config.Debug then
        lib.print.warn('[NOSTR] Log failed: ' .. tostring(err))
    end
end

-- ════════════════════════════════════════════════════════════
-- 🗄️ DATABASE
-- ════════════════════════════════════════════════════════════
local function SaveToDatabase()
    MySQL.insert.await([[
        INSERT INTO ]] .. Config.Database.tableName .. [[ (
            id, weather_type, wind_speed, wind_direction, snow_enabled,
            current_hour, current_minute, current_second, time_offset
        ) VALUES (1, ?, ?, ?, ?, ?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE
            weather_type  = VALUES(weather_type),
            wind_speed    = VALUES(wind_speed),
            wind_direction = VALUES(wind_direction),
            snow_enabled  = VALUES(snow_enabled),
            current_hour  = VALUES(current_hour),
            current_minute = VALUES(current_minute),
            current_second = VALUES(current_second),
            time_offset   = VALUES(time_offset)
    ]], {
        State.currentWeather,
        State.windSpeed,
        State.windDirection,
        State.snowEnabled and 1 or 0,
        State.currentHour,
        State.currentMinute,
        State.currentSecond,
        State.timeOffset,
    })
end

local function InitDatabase()
    if not Config.Database.autoCreate then return end
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `]] .. Config.Database.tableName .. [[` (
            `id`           INT AUTO_INCREMENT PRIMARY KEY,
            `weather_type` VARCHAR(50) NOT NULL,
            `wind_speed`   FLOAT DEFAULT 5.0,
            `wind_direction` FLOAT DEFAULT 0.0,
            `snow_enabled` TINYINT(1) DEFAULT 0,
            `current_hour` INT DEFAULT 12,
            `current_minute` INT DEFAULT 0,
            `current_second` INT DEFAULT 0,
            `time_offset`  BIGINT DEFAULT 0,
            `last_updated` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            UNIQUE KEY `single_row` (`id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]])
    lib.print.info('[RDE Weather & Time] Database initialized')
end

local function LoadFromDatabase()
    local result = MySQL.query.await('SELECT * FROM ' .. Config.Database.tableName .. ' WHERE id = 1 LIMIT 1')
    if result and result[1] then
        local data = result[1]
        State.currentWeather  = data.weather_type or Config.Weather.defaultWeather
        State.targetWeather   = State.currentWeather
        State.windSpeed       = data.wind_speed or 5.0
        State.windDirection   = data.wind_direction or 0.0
        State.snowEnabled     = data.snow_enabled == 1
        State.currentHour     = data.current_hour or Config.Time.customCycle.startHour
        State.currentMinute   = data.current_minute or Config.Time.customCycle.startMinute
        State.currentSecond   = data.current_second or 0
        State.timeOffset      = data.time_offset or 0
        lib.print.info(('[RDE Weather & Time] Loaded: %s | %02d:%02d:%02d | Snow: %s'):format(
            State.currentWeather,
            State.currentHour, State.currentMinute, State.currentSecond,
            State.snowEnabled and 'ON' or 'OFF'
        ))
    else
        SaveToDatabase()
        lib.print.info('[RDE Weather & Time] Created new database entry')
    end
end

-- ════════════════════════════════════════════════════════════
-- 🌍 STATEBAG SYNC
-- FIX: Only broadcast when something actually changed to reduce
--      unnecessary network traffic on large servers.
-- ════════════════════════════════════════════════════════════
local lastSyncedMinute = -1

local function SyncState(force)
    -- Time: only sync when the minute changes (or forced by weather/wind/snow events)
    if not force and State.currentMinute == lastSyncedMinute then return end
    lastSyncedMinute = State.currentMinute

    GlobalState.rdeWeather = {
        current      = State.currentWeather,
        target       = State.targetWeather,
        transitioning = State.isTransitioning,
        windSpeed    = State.windSpeed,
        windDirection = State.windDirection,
        snowEnabled  = State.snowEnabled,
        timestamp    = os.time(),
    }
    GlobalState.rdeTime = {
        hour      = State.currentHour,
        minute    = State.currentMinute,
        second    = State.currentSecond,
        isDayTime = State.isDayTime,
        frozen    = Config.Time.freezeTime,
        timestamp = os.time(),
    }

    if Config.Debug then
        lib.print.info(('[SYNC] %s | %02d:%02d:%02d | Wind: %.1f m/s @ %.0f°'):format(
            State.currentWeather,
            State.currentHour, State.currentMinute, State.currentSecond,
            State.windSpeed, State.windDirection
        ))
    end
end

-- Convenience wrapper — weather/wind/snow changes always force a sync
local function ForceSyncState()
    lastSyncedMinute = -1
    SyncState(true)
end

-- ════════════════════════════════════════════════════════════
-- 🔐 PERMISSION SYSTEM
-- ════════════════════════════════════════════════════════════
local function HasPermission(source)
    if Config.Permissions.useOxAcl then
        if IsPlayerAceAllowed(source, Config.Permissions.acePermission) then
            return true
        end
    end
    local player = Ox.GetPlayer(source)
    if not player then return false end
    for _, groupConfig in ipairs(Config.Permissions.groups) do
        local grade = player.getGroup(groupConfig.name)
        if grade and grade >= groupConfig.minGrade then
            return true
        end
    end
    return false
end

-- ════════════════════════════════════════════════════════════
-- 🌦️ WEATHER LOGIC
-- ════════════════════════════════════════════════════════════
local function GetCurrentSeason()
    local month = os.date('*t').month
    for season, months in pairs(Config.DynamicWeather.seasons) do
        for _, m in ipairs(months) do
            if m == month then return season end
        end
    end
    return 'summer'
end

local function GetWeatherWeights()
    local season = GetCurrentSeason()
    return Config.DynamicWeather.seasonalWeights[season] or Config.DynamicWeather.weights
end

local function GetNextWeather()
    local transitions = Config.DynamicWeather.transitions[State.currentWeather]
    local weights = GetWeatherWeights()

    -- 🌈 STREAK BREAKER — see config.lua DynamicWeather.badWeatherStreakLimit.
    -- Don't roll the dice again if we've already had a run of bad weather —
    -- force the natural exit path (CLEARING, or CLEAR directly if reachable)
    -- instead. Falls through to the normal weighted pick if the current
    -- weather has neither in its transition list.
    if State.consecutiveBadWeather >= Config.DynamicWeather.badWeatherStreakLimit and transitions then
        for _, w in ipairs(transitions) do
            if w == 'CLEARING' then return 'CLEARING' end
        end
        for _, w in ipairs(transitions) do
            if w == 'CLEAR' then return 'CLEAR' end
        end
    end

    if not transitions or #transitions == 0 then
        local totalWeight = 0
        local options = {}
        for weather, weight in pairs(weights) do
            totalWeight = totalWeight + weight
            table.insert(options, { weather = weather, weight = weight })
        end
        local rand = math.random() * totalWeight
        local sum = 0
        for _, opt in ipairs(options) do
            sum = sum + opt.weight
            if rand <= sum then return opt.weather end
        end
        return Config.Weather.defaultWeather
    else
        local totalWeight = 0
        local options = {}
        for _, weather in ipairs(transitions) do
            local weight = weights[weather] or 10
            totalWeight = totalWeight + weight
            table.insert(options, { weather = weather, weight = weight })
        end
        local rand = math.random() * totalWeight
        local sum = 0
        for _, opt in ipairs(options) do
            sum = sum + opt.weight
            if rand <= sum then return opt.weather end
        end
        return transitions[1]
    end
end

local function GetWeatherLabel(weatherValue)
    for _, w in ipairs(Config.Weather.types) do
        if w.value == weatherValue then return w.label end
    end
    return weatherValue
end

local function UpdateWind(weatherType)
    if not Config.Wind.dynamic then return end
    local windBase = 5.0
    for _, w in ipairs(Config.Weather.types) do
        if w.value == weatherType then
            windBase = w.windBase or 5.0
            break
        end
    end
    local variation = math.random(-100, 100) / 100 * 2
    State.windSpeed     = math.max(Config.Wind.min, math.min(Config.Wind.max, windBase + variation))
    State.windDirection = math.random(0, 359) * 1.0
end

local function ChangeWeather(newWeather, isAuto, adminName)
    if State.currentWeather == newWeather then return end

    local oldWeather = State.currentWeather
    State.currentWeather  = newWeather
    State.targetWeather   = newWeather
    State.isTransitioning = true

    -- 🌈 STREAK TRACKING — feeds the GetNextWeather() streak-breaker above.
    -- Lives here (not in the auto-loop) so admin-forced changes via /weather
    -- also reset/advance the streak correctly.
    if Config.DynamicWeather.goodWeatherTypes[newWeather] then
        State.consecutiveBadWeather = 0
    else
        State.consecutiveBadWeather = State.consecutiveBadWeather + 1
    end

    if Config.Snow.requireSnowWeather then
        -- BUG FIX: find() returns a number (position) or nil — must convert to boolean
        -- before OR-chaining, otherwise `false ~= nil` (= true) would enable snow for
        -- every non-snow weather type.
        local isSnowWeather = (newWeather:find('SNOW') ~= nil)
                           or (newWeather:find('BLIZZARD') ~= nil)
                           or (newWeather == 'XMAS')
        State.snowEnabled = isSnowWeather
    end

    UpdateWind(newWeather)
    ForceSyncState()
    SaveToDatabase()

    lib.print.info(('[%s] %s → %s | Wind: %.1f m/s @ %.0f°'):format(
        isAuto and 'AUTO' or 'MANUAL', oldWeather, newWeather,
        State.windSpeed, State.windDirection
    ))

    -- ════ NOSTR LOG (optional) ════
    if isAuto then
        NostrLog(
            ('🌤️ [AUTO WEATHER] %s → %s | Wind: %.1fm/s @ %.0f° | Season: %s'):format(
                GetWeatherLabel(oldWeather),
                GetWeatherLabel(newWeather),
                State.windSpeed,
                State.windDirection,
                GetCurrentSeason()
            ),
            {
                { 'event_type',  'weather_auto_change' },
                { 'weather_old', oldWeather },
                { 'weather_new', newWeather },
                { 'wind_speed',  tostring(math.floor(State.windSpeed * 10) / 10) },
                { 'wind_dir',    tostring(math.floor(State.windDirection)) },
                { 'season',      GetCurrentSeason() },
                { 'snow',        State.snowEnabled and 'true' or 'false' },
            }
        )
    else
        NostrLog(
            ('🌤️ [ADMIN WEATHER] %s set weather: %s → %s | Wind: %.1fm/s @ %.0f°'):format(
                adminName or 'Unknown Admin',
                GetWeatherLabel(oldWeather),
                GetWeatherLabel(newWeather),
                State.windSpeed,
                State.windDirection
            ),
            {
                { 'event_type',  'weather_admin_change' },
                { 'admin',       adminName or 'unknown' },
                { 'weather_old', oldWeather },
                { 'weather_new', newWeather },
                { 'wind_speed',  tostring(math.floor(State.windSpeed * 10) / 10) },
                { 'wind_dir',    tostring(math.floor(State.windDirection)) },
                { 'snow',        State.snowEnabled and 'true' or 'false' },
            }
        )
    end
    -- ═════════════════════════════

    if Config.UI.notifications.enabled and Config.UI.notifications.showWeatherChange then
        local label = GetWeatherLabel(newWeather)
        TriggerClientEvent('ox_lib:notify', -1, {
            title       = '🌤️ Weather Update',
            description = ('Weather changing to %s'):format(label),
            type        = 'info',
            duration    = Config.UI.notifications.duration,
            position    = Config.UI.notifications.position,
        })
    end

    -- FIX v2.2.1: small safety buffer (2s) on top of transitionDuration.
    -- Clients only start their local blend once the StateBag change reaches
    -- them, which is a network round-trip after this event fires server-side.
    -- Without a buffer, ForceSyncState() here could close the transition
    -- window (isTransitioning = false) a moment before a laggier client has
    -- actually finished blending, letting the 60s persistence/refresh loops
    -- stomp on a still-running local transition.
    SetTimeout((Config.Weather.transitionDuration + 2) * 1000, function()
        State.isTransitioning = false
        ForceSyncState()
    end)
end

local function ScheduleNextWeatherChange()
    local min      = Config.DynamicWeather.changeInterval[1] * 60000
    local max      = Config.DynamicWeather.changeInterval[2] * 60000
    local interval = math.random(min, max)
    State.nextWeatherChange = os.time() * 1000 + interval

    if Config.Debug then
        lib.print.info(('[SCHEDULE] Next weather change in %.1f min'):format(interval / 60000))
    end
end

-- ════════════════════════════════════════════════════════════
-- 🕐 TIME PROGRESSION
-- ════════════════════════════════════════════════════════════
local function UpdateTime()
    if Config.Time.freezeTime then
        State.currentHour   = Config.Time.frozenHour
        State.currentMinute = Config.Time.frozenMinute
        State.currentSecond = 0
        return
    end

    if Config.Time.syncWithRealTime then
        local time = os.date('*t')
        State.currentHour   = time.hour
        State.currentMinute = time.min
        State.currentSecond = time.sec
    else
        local currentTime = os.time()
        local deltaTime   = currentTime - State.lastTimeUpdate

        if deltaTime > 0 then
            local secondsToAdd = deltaTime * Config.Time.realTimeMultiplier
            State.currentSecond = State.currentSecond + secondsToAdd

            while State.currentSecond >= 60 do
                State.currentSecond = State.currentSecond - 60
                State.currentMinute = State.currentMinute + 1

                if State.currentMinute >= 60 then
                    State.currentMinute = 0
                    State.currentHour   = (State.currentHour + 1) % 24
                end
            end

            State.lastTimeUpdate = currentTime
        end
    end

    local wasDay    = State.isDayTime
    State.isDayTime = State.currentHour >= Config.Time.dayStart
                   and State.currentHour < Config.Time.nightStart

    if wasDay ~= State.isDayTime and Config.Debug then
        lib.print.info(('[TIME] Now %s'):format(State.isDayTime and 'DAY' or 'NIGHT'))
    end
end

-- ════════════════════════════════════════════════════════════
-- ⚙️ MAIN LOOPS
-- ════════════════════════════════════════════════════════════
CreateThread(function()
    InitDatabase()
    LoadFromDatabase()
    UpdateTime()
    ForceSyncState()

    if Config.DynamicWeather.enabled then
        ScheduleNextWeatherChange()
    end

    -- Log startup to Nostr (optional)
    SetTimeout(3000, function()
        NostrLog(
            ('🌤️ [SERVER START] Weather & Time system online | Weather: %s | Time: %02d:%02d | Snow: %s'):format(
                State.currentWeather,
                State.currentHour,
                State.currentMinute,
                State.snowEnabled and 'ON' or 'OFF'
            ),
            {
                { 'event_type', 'system_start' },
                { 'weather',    State.currentWeather },
                { 'snow',       State.snowEnabled and 'true' or 'false' },
            }
        )
    end)

    -- Main loop — 100ms for smooth time progression
    while true do
        Wait(100)

        if Config.Time.enabled then
            UpdateTime()
            SyncState() -- throttled internally — only fires on minute change
        end

        if Config.DynamicWeather.enabled and State.nextWeatherChange then
            if os.time() * 1000 >= State.nextWeatherChange and not State.isTransitioning then
                local newWeather = GetNextWeather()
                ChangeWeather(newWeather, true)
                ScheduleNextWeatherChange()
            end
        end
    end
end)

-- Auto-save
CreateThread(function()
    while true do
        Wait(Config.Database.saveInterval * 1000)
        SaveToDatabase()
        if Config.Debug then
            lib.print.info('[DATABASE] Auto-saved state')
        end
    end
end)

-- Wind variation
if Config.Wind.variation.enabled then
    CreateThread(function()
        while Config.Wind.enabled do
            Wait(Config.Wind.variation.interval)
            if not State.isTransitioning then
                local change = math.random(-100, 100) / 100 * Config.Wind.variation.maxChange
                State.windSpeed = math.max(Config.Wind.min, math.min(Config.Wind.max, State.windSpeed + change))
                ForceSyncState()
            end
        end
    end)
end

-- ════════════════════════════════════════════════════════════
-- 📡 CALLBACKS & EVENTS
-- ════════════════════════════════════════════════════════════
lib.callback.register('rde:getWeatherTimeData', function(source)
    return {
        weather = {
            current       = State.currentWeather,
            target        = State.targetWeather,
            transitioning = State.isTransitioning,
            windSpeed     = State.windSpeed,
            windDirection = State.windDirection,
            snowEnabled   = State.snowEnabled,
        },
        time = {
            hour      = State.currentHour,
            minute    = State.currentMinute,
            second    = State.currentSecond,
            isDayTime = State.isDayTime,
            frozen    = Config.Time.freezeTime,
        },
    }
end)

RegisterNetEvent('rde:setWeather', function(weatherType)
    local src = source
    if not HasPermission(src) then
        lib.notify(src, {
            title       = '❌ Access Denied',
            description = 'No permission to change weather',
            type        = 'error',
        })
        return
    end
    local adminName = GetPlayerName(src) or ('Player #' .. src)
    ChangeWeather(weatherType, false, adminName)
    lib.notify(src, {
        title       = '✅ Weather Changed',
        description = ('Set to %s'):format(weatherType),
        type        = 'success',
    })
end)

RegisterNetEvent('rde:toggleSnow', function(enabled)
    local src = source
    if not HasPermission(src) then
        lib.notify(src, {
            title       = '❌ Access Denied',
            description = 'No permission',
            type        = 'error',
        })
        return
    end
    State.snowEnabled = enabled
    ForceSyncState()
    SaveToDatabase()

    -- ════ NOSTR LOG (optional) ════
    local adminName = GetPlayerName(src) or ('Player #' .. src)
    NostrLog(
        ('❄️ [ADMIN SNOW] %s %s snow effects'):format(
            adminName,
            enabled and 'ENABLED' or 'DISABLED'
        ),
        {
            { 'event_type', 'snow_toggle' },
            { 'admin',      adminName },
            { 'snow',       enabled and 'true' or 'false' },
        }
    )
    -- ═════════════════════════════

    lib.notify(src, {
        title       = enabled and '✅ Snow Enabled' or '❌ Snow Disabled',
        description = enabled and 'Ground snow active' or 'Snow disabled',
        type        = 'success',
    })
end)

RegisterNetEvent('rde:setWind', function(speed, direction)
    local src = source
    if not HasPermission(src) then return end
    State.windSpeed     = math.max(Config.Wind.min, math.min(Config.Wind.max, speed))
    State.windDirection = direction % 360
    ForceSyncState()
    SaveToDatabase()

    -- ════ NOSTR LOG (optional) ════
    local adminName = GetPlayerName(src) or ('Player #' .. src)
    NostrLog(
        ('💨 [ADMIN WIND] %s set wind: %.1fm/s @ %.0f°'):format(
            adminName, State.windSpeed, State.windDirection
        ),
        {
            { 'event_type', 'wind_admin_change' },
            { 'admin',      adminName },
            { 'wind_speed', tostring(math.floor(State.windSpeed * 10) / 10) },
            { 'wind_dir',   tostring(math.floor(State.windDirection)) },
        }
    )
    -- ═════════════════════════════

    lib.notify(src, {
        title       = '💨 Wind Updated',
        description = ('%.1f m/s @ %.0f°'):format(State.windSpeed, State.windDirection),
        type        = 'success',
    })
end)

RegisterNetEvent('rde:setTime', function(hour, minute)
    local src = source
    if not HasPermission(src) then return end
    local oldTime = ('%02d:%02d'):format(State.currentHour, State.currentMinute)
    State.currentHour   = hour % 24
    State.currentMinute = minute % 60
    State.currentSecond = 0
    State.lastTimeUpdate = os.time()
    ForceSyncState()
    SaveToDatabase()

    -- ════ NOSTR LOG (optional) ════
    local adminName = GetPlayerName(src) or ('Player #' .. src)
    NostrLog(
        ('🕐 [ADMIN TIME] %s set time: %s → %02d:%02d'):format(
            adminName, oldTime, State.currentHour, State.currentMinute
        ),
        {
            { 'event_type', 'time_admin_change' },
            { 'admin',      adminName },
            { 'time_old',   oldTime },
            { 'time_new',   ('%02d:%02d'):format(State.currentHour, State.currentMinute) },
        }
    )
    -- ═════════════════════════════

    lib.notify(src, {
        title       = '🕐 Time Set',
        description = ('%02d:%02d'):format(State.currentHour, State.currentMinute),
        type        = 'success',
    })
end)

lib.callback.register('rde:hasPermission', function(source)
    return HasPermission(source)
end)

-- ════════════════════════════════════════════════════════════
-- 💬 COMMANDS
-- ════════════════════════════════════════════════════════════
lib.addCommand('weather', {
    help = 'Open weather & time control panel',
    restricted = false,
}, function(source)
    if not HasPermission(source) then
        lib.notify(source, {
            title       = '❌ Access Denied',
            description = 'No permission for weather admin',
            type        = 'error',
        })
        return
    end
    TriggerClientEvent('rde:openMenu', source)
end)

-- ════════════════════════════════════════════════════════════
-- 🚀 STARTUP LOG
-- ════════════════════════════════════════════════════════════
AddEventHandler('onResourceStart', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    local nostrState = IsNostrAvailable() and '^2ACTIVE^7' or '^3NOT INSTALLED (optional)^7'
    lib.print.info(('\n' ..
        '^2╔════════════════════════════════════════════════════════════╗\n' ..
        '^2║  🌤️  RDE Weather & Time - Production Ready                 ║\n' ..
        '^2║                                                            ║\n' ..
        '^2║  ✓ Instant Sync on Player Join                             ║\n' ..
        '^2║  ✓ Smooth Time Progression (Seconds)                       ║\n' ..
        '^2║  ✓ 100ms Update Loop for Real-time Feel                    ║\n' ..
        '^2║  ✓ StateBag Sync (throttled, min-change only)              ║\n' ..
        '^2║  ✓ Database Persistence                                    ║\n' ..
        '^2║  🐉 Nostr Logger: %s\n' ..
        '^2║                                                            ║\n' ..
        '^2║  Framework: ox_core | Status: ^2READY                    ^2║\n' ..
        '^2╚════════════════════════════════════════════════════════════╝^7'
    ):format(nostrState .. ((' '):rep(math.max(0, 28 - #nostrState))) .. '║'))
end)