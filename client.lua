-- ════════════════════════════════════════════════════════════
-- 🌤️ RDE WEATHER & TIME - CLIENT (PRODUCTION READY)
-- ════════════════════════════════════════════════════════════
local Config = require 'config'
local State = {
    weather = {
        current      = Config.Weather.defaultWeather,
        target       = Config.Weather.defaultWeather,
        transitioning = false,
        windSpeed    = 5.0,
        windDirection = 0.0,
        snowEnabled  = false,
    },
    time = {
        hour       = 12,
        minute     = 0,
        second     = 0,
        isDayTime  = true,
        frozen     = false,
        lastUpdate = 0,
    },
    transition = {
        active    = false,
        startTime = 0,
        progress  = 0.0,
    },
    initialized    = false,
    syncInProgress = false,
}

-- ════════════════════════════════════════════════════════════
-- 🚫 PREVENT TIMECYCLE BLACKOUT & FREEZE CLOCK
-- ════════════════════════════════════════════════════════════
CreateThread(function()
    while true do
        Wait(0)
        SetBlackout(false)
        PauseClock(true)
    end
end)

-- ════════════════════════════════════════════════════════════
-- 🌍 INSTANT SYNC ON SPAWN
-- ════════════════════════════════════════════════════════════
local function InitializeWeatherTime()
    if State.syncInProgress then return end
    State.syncInProgress = true

    local data = lib.callback.await('rde:getWeatherTimeData', false)
    if not data then
        State.syncInProgress = false
        return
    end

    -- Weather
    State.weather.current      = data.weather.current
    State.weather.target       = data.weather.target
    State.weather.windSpeed    = data.weather.windSpeed
    State.weather.windDirection = data.weather.windDirection
    State.weather.snowEnabled  = data.weather.snowEnabled
    State.weather.transitioning = data.weather.transitioning

    -- Time
    State.time.hour      = data.time.hour
    State.time.minute    = data.time.minute
    State.time.second    = data.time.second or 0
    State.time.isDayTime = data.time.isDayTime
    State.time.frozen    = data.time.frozen
    State.time.lastUpdate = GetGameTimer()

    -- FIX: honour transitioning flag from server so we don't double-start
    State.transition.active = data.weather.transitioning

    -- Apply weather with a short fade-in (5 s) instead of a hard instant cut.
    -- This prevents the jarring snap from GTA's default weather on fresh joins.
    ClearOverrideWeather()
    ClearWeatherTypePersist()
    SetWeatherTypeOvertimePersist(State.weather.current, 5.0)

    -- Apply wind instantly
    SetWindSpeed(State.weather.windSpeed)
    SetWindDirection(State.weather.windDirection)

    -- Apply time instantly
    NetworkOverrideClockTime(State.time.hour, State.time.minute, State.time.second)

    -- Apply snow (wrapped in thread — has an internal Wait loop)
    CreateThread(function()
        ApplySnowState()
    end)

    State.initialized    = true
    State.syncInProgress = false

    if Config.Debug then
        lib.print.info(('[SYNC] Weather: %s | Time: %02d:%02d:%02d | Wind: %.1f m/s | Snow: %s'):format(
            State.weather.current,
            State.time.hour, State.time.minute, State.time.second,
            State.weather.windSpeed,
            State.weather.snowEnabled and 'ON' or 'OFF'
        ))
    end
end

-- Init immediately — no delay
CreateThread(function()
    InitializeWeatherTime()
end)

-- Fallback for late spawns
AddEventHandler('playerSpawned', function()
    if not State.initialized then
        InitializeWeatherTime()
    end
end)

-- ════════════════════════════════════════════════════════════
-- 🌍 STATEBAG HANDLERS
-- ════════════════════════════════════════════════════════════
AddStateBagChangeHandler('rdeWeather', 'global', function(bagName, key, value)
    if not value then return end

    State.weather.target       = value.current
    State.weather.windSpeed    = value.windSpeed    or 5.0
    State.weather.windDirection = value.windDirection or 0.0
    State.weather.snowEnabled  = value.snowEnabled  or false
    State.weather.transitioning = value.transitioning or false

    if Config.Debug then
        lib.print.info(('[STATEBAG] Weather: %s → %s | Wind: %.1f m/s'):format(
            State.weather.current, State.weather.target, State.weather.windSpeed
        ))
    end

    -- Apply wind instantly
    SetWindSpeed(State.weather.windSpeed)
    SetWindDirection(State.weather.windDirection)

    -- FIX: snow runs in its own thread — avoids blocking the StateBag handler
    CreateThread(function()
        ApplySnowState()
    end)

    -- Start transition only when needed and not already running
    if State.initialized
    and State.weather.current ~= State.weather.target
    and not State.transition.active then
        StartWeatherTransition()
    end
end)

AddStateBagChangeHandler('rdeTime', 'global', function(bagName, key, value)
    if not value then return end

    State.time.hour      = value.hour    or 12
    State.time.minute    = value.minute  or 0
    State.time.second    = value.second  or 0
    State.time.isDayTime = value.isDayTime ~= false -- default true
    State.time.frozen    = value.frozen  or false
    State.time.lastUpdate = GetGameTimer()

    NetworkOverrideClockTime(State.time.hour, State.time.minute, State.time.second)

    if Config.Debug then
        lib.print.info(('[STATEBAG] Time: %02d:%02d:%02d'):format(
            State.time.hour, State.time.minute, State.time.second
        ))
    end
end)

-- ════════════════════════════════════════════════════════════
-- 🌦️ SMOOTH WEATHER TRANSITION
-- ════════════════════════════════════════════════════════════
function StartWeatherTransition()
    if State.transition.active then return end

    State.transition.active    = true
    State.transition.startTime = GetGameTimer()
    State.transition.progress  = 0.0

    -- NOTE: server.lua already fires an ox_lib:notify broadcast to all clients
    -- on every weather change (when Config.UI.notifications.showWeatherChange is true).
    -- A second local notify here would give every player two popups. Removed.

    CreateThread(function()
        local duration = Config.Weather.transitionDuration * 1000
        local blendTarget = State.weather.target  -- capture target at transition start

        ClearOverrideWeather()
        ClearWeatherTypePersist()
        SetWeatherTypeOvertimePersist(blendTarget, Config.Weather.transitionDuration)

        Wait(duration)

        -- Finalise the weather we actually blended to
        State.weather.current     = blendTarget
        State.transition.active   = false
        State.transition.progress = 1.0

        SetWeatherTypePersist(blendTarget)
        SetWeatherTypeNow(blendTarget)
        SetWeatherTypeNowPersist(blendTarget)

        -- BUG FIX: if the server pushed a new target while we were transitioning,
        -- the statebag handler was blocked by active=true and couldn't start a
        -- new transition. Kick one off now so the new weather isn't silently lost.
        if State.weather.current ~= State.weather.target then
            StartWeatherTransition()
        end

        if Config.Debug then
            lib.print.info('[TRANSITION] Complete: ' .. State.weather.current)
        end
    end)
end

-- ════════════════════════════════════════════════════════════
-- ❄️ SNOW MANAGEMENT
-- NOTE: Must always be called inside a CreateThread() because
--       HasNamedPtfxAssetLoaded can loop with Wait() internally.
-- ════════════════════════════════════════════════════════════
function ApplySnowState()
    if State.weather.snowEnabled then
        if Config.Snow.vehicleTrails then
            SetForceVehicleTrails(true)
        end
        if Config.Snow.footstepTracks then
            SetForcePedFootstepsTracks(true)
        end
        RequestScriptAudioBank('ICE_FOOTSTEPS', false)
        RequestScriptAudioBank('SNOW_FOOTSTEPS', false)
        RequestNamedPtfxAsset('core_snow')
        while not HasNamedPtfxAssetLoaded('core_snow') do
            Wait(10)
        end
        UseParticleFxAssetNextCall('core_snow')

        if Config.Debug then
            lib.print.info('[SNOW] Effects enabled')
        end
    else
        SetForceVehicleTrails(false)
        SetForcePedFootstepsTracks(false)
        RemoveNamedPtfxAsset('core_snow')

        if Config.Debug then
            lib.print.info('[SNOW] Effects disabled')
        end
    end
end

-- ════════════════════════════════════════════════════════════
-- 🕐 SMOOTH CLIENT-SIDE TIME INTERPOLATION
-- FIX: realTimeMultiplier is only relevant when syncWithRealTime
--      is FALSE. In real-time mode the server already sends
--      actual clock seconds — just interpolate 1:1.
-- ════════════════════════════════════════════════════════════
CreateThread(function()
    while Config.Time.enabled do
        Wait(0) -- every frame for smooth seconds

        if State.initialized and not State.time.frozen then
            local currentTime = GetGameTimer()
            local deltaTime   = currentTime - State.time.lastUpdate

            if deltaTime >= 100 then
                -- In real-time sync mode the server provides actual wall-clock
                -- seconds, so 1 real ms = 1 game ms (multiplier = 1.0).
                -- In custom cycle mode we apply the configured multiplier.
                local multiplier = Config.Time.syncWithRealTime
                    and 1.0
                    or  Config.Time.realTimeMultiplier

                State.time.second = State.time.second + (deltaTime / 1000) * multiplier

                if State.time.second >= 60 then
                    State.time.second = State.time.second - 60
                    -- Full minute rollover handled by the next StateBag update
                    -- from the server; don't increment minute client-side to
                    -- avoid drift.
                end

                State.time.lastUpdate = currentTime

                NetworkOverrideClockTime(
                    State.time.hour,
                    State.time.minute,
                    math.floor(State.time.second)
                )
            end
        end
    end
end)

-- ════════════════════════════════════════════════════════════
-- 🎮 WEATHER PERSISTENCE (EVERY MINUTE)
-- ════════════════════════════════════════════════════════════
CreateThread(function()
    Wait(5000)
    while Config.Weather.enabled do
        Wait(60000)
        if State.initialized and not State.transition.active then
            SetWeatherTypePersist(State.weather.current)

            if Config.Debug then
                lib.print.info('[PERSISTENCE] Weather refresh: ' .. State.weather.current)
            end
        end
    end
end)

-- ════════════════════════════════════════════════════════════
-- 💨 WIND REFRESH (EVERY 10 SECONDS)
-- ════════════════════════════════════════════════════════════
CreateThread(function()
    Wait(6000)
    while Config.Wind.enabled do
        Wait(10000)
        if State.initialized then
            SetWindSpeed(State.weather.windSpeed)
            SetWindDirection(State.weather.windDirection)
        end
    end
end)

-- ════════════════════════════════════════════════════════════
-- 🎨 ADMIN MENU
-- ════════════════════════════════════════════════════════════
function OpenAdminMenu()
    local weatherOptions = {}
    for _, weather in ipairs(Config.Weather.types) do
        table.insert(weatherOptions, {
            title = weather.label,
            description = ('Temp: %d°C - %d°C | Wind: %.1f m/s'):format(
                weather.temp[1], weather.temp[2], weather.windBase
            ),
            icon     = 'cloud',
            onSelect = function()
                TriggerServerEvent('rde:setWeather', weather.value)
            end,
        })
    end

    lib.registerContext({
        id      = 'rde_weather_menu',
        title   = '🌤️ Weather Selection',
        menu    = 'rde_main_menu',
        options = weatherOptions,
    })

    lib.registerContext({
        id      = 'rde_time_menu',
        title   = '🕐 Time Control',
        menu    = 'rde_main_menu',
        options = {
            {
                title    = '🌅 Morning (06:00)',
                icon     = 'sunrise',
                onSelect = function() TriggerServerEvent('rde:setTime', 6, 0) end,
            },
            {
                title    = '☀️ Noon (12:00)',
                icon     = 'sun',
                onSelect = function() TriggerServerEvent('rde:setTime', 12, 0) end,
            },
            {
                title    = '🌆 Evening (18:00)',
                icon     = 'sunset',
                onSelect = function() TriggerServerEvent('rde:setTime', 18, 0) end,
            },
            {
                title    = '🌙 Night (00:00)',
                icon     = 'moon',
                onSelect = function() TriggerServerEvent('rde:setTime', 0, 0) end,
            },
            {
                title    = '🕐 Custom Time',
                icon     = 'clock',
                onSelect = function()
                    local input = lib.inputDialog('Set Time', {
                        { type = 'number', label = 'Hour (0-23)',   required = true, min = 0, max = 23 },
                        { type = 'number', label = 'Minute (0-59)', required = true, min = 0, max = 59 },
                    })
                    if input then
                        TriggerServerEvent('rde:setTime', input[1], input[2])
                    end
                end,
            },
        },
    })

    lib.registerContext({
        id      = 'rde_wind_menu',
        title   = '💨 Wind Control',
        menu    = 'rde_main_menu',
        options = {
            {
                title = '💨 Set Wind',
                description = ('Current: %.1f m/s @ %.0f°'):format(
                    State.weather.windSpeed    or 5.0,
                    State.weather.windDirection or 0.0
                ),
                icon     = 'wind',
                onSelect = function()
                    local input = lib.inputDialog('Wind Settings', {
                        { type = 'slider', label = 'Speed (m/s)',    default = State.weather.windSpeed    or 5.0, min = 0, max = 15,  step = 0.5 },
                        { type = 'slider', label = 'Direction (°)',  default = State.weather.windDirection or 0.0, min = 0, max = 360, step = 15 },
                    })
                    if input then
                        TriggerServerEvent('rde:setWind', input[1], input[2])
                    end
                end,
            },
            {
                title    = '🌪️ Random Wind',
                icon     = 'shuffle',
                onSelect = function()
                    TriggerServerEvent('rde:setWind', math.random(0, 150) / 10, math.random(0, 360))
                end,
            },
        },
    })

    lib.registerContext({
        id      = 'rde_snow_menu',
        title   = '❄️ Snow Control',
        menu    = 'rde_main_menu',
        options = {
            {
                title       = (State.weather.snowEnabled and '✅ Snow: ON' or '❌ Snow: OFF'),
                description = 'Toggle ground snow',
                icon        = 'snowflake',
                onSelect    = function()
                    TriggerServerEvent('rde:toggleSnow', not (State.weather.snowEnabled or false))
                end,
            },
            {
                title       = '🎄 Christmas Mode',
                description = 'XMAS weather + snow',
                icon        = 'tree-pine',
                onSelect    = function()
                    TriggerServerEvent('rde:setWeather', 'XMAS')
                    TriggerServerEvent('rde:toggleSnow', true)
                end,
            },
        },
    })

    lib.registerContext({
        id      = 'rde_main_menu',
        title   = '🌤️ RDE Weather & Time',
        options = {
            {
                title       = '🌦️ Weather',
                description = ('Current: %s'):format(State.weather.current or 'CLEAR'),
                icon        = 'cloud-sun',
                menu        = 'rde_weather_menu',
            },
            {
                title = '🕐 Time',
                description = ('%02d:%02d:%02d | %s'):format(
                    State.time.hour   or 12,
                    State.time.minute or 0,
                    math.floor(State.time.second or 0),
                    State.time.isDayTime and 'Day' or 'Night'
                ),
                icon = 'clock',
                menu = 'rde_time_menu',
            },
            {
                title = '💨 Wind',
                description = ('%.1f m/s @ %.0f°'):format(
                    State.weather.windSpeed    or 5.0,
                    State.weather.windDirection or 0.0
                ),
                icon = 'wind',
                menu = 'rde_wind_menu',
            },
            {
                title       = '❄️ Snow',
                description = (State.weather.snowEnabled and 'Enabled' or 'Disabled'),
                icon        = 'snowflake',
                menu        = 'rde_snow_menu',
            },
            {
                title       = '📊 Status',
                description = 'View system status',
                icon        = 'info',
                onSelect    = function()
                    lib.alertDialog({
                        header  = '📊 System Status',
                        content = ('**Weather:** %s\n**Time:** %02d:%02d:%02d (%s)\n**Wind:** %.1f m/s @ %.0f°\n**Snow:** %s\n**Transitioning:** %s'):format(
                            State.weather.current or 'CLEAR',
                            State.time.hour   or 12,
                            State.time.minute or 0,
                            math.floor(State.time.second or 0),
                            State.time.isDayTime and 'Day' or 'Night',
                            State.weather.windSpeed    or 5.0,
                            State.weather.windDirection or 0.0,
                            State.weather.snowEnabled  and 'Yes' or 'No',
                            State.transition.active    and 'Yes' or 'No'
                        ),
                        centered = true,
                        cancel   = true,
                    })
                end,
            },
        },
    })

    lib.showContext('rde_main_menu')
end

RegisterNetEvent('rde:openMenu', OpenAdminMenu)

-- ════════════════════════════════════════════════════════════
-- 🎯 EXPORTS
-- ════════════════════════════════════════════════════════════
exports('GetWeather',     function() return State.weather.current end)
exports('GetTime',        function() return { hour = State.time.hour, minute = State.time.minute, second = State.time.second } end)
exports('GetWind',        function() return { speed = State.weather.windSpeed, direction = State.weather.windDirection } end)
exports('IsSnowEnabled',  function() return State.weather.snowEnabled end)
exports('IsDayTime',      function() return State.time.isDayTime end)

-- ════════════════════════════════════════════════════════════
-- 🚀 CLIENT INIT
-- ════════════════════════════════════════════════════════════
lib.print.info('[RDE Weather & Time] Client initialized ✓')