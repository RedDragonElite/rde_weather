return {
    -- ════════════════════════════════════════════════════════════
    -- 🔐 ADMIN PERMISSIONS (ox_core)
    -- ════════════════════════════════════════════════════════════
    Permissions = {
        useOxAcl = true,
        acePermission = 'rde.admin',
        groups = {
            { name = 'admin', minGrade = 1 },
            { name = 'moderator', minGrade = 3 },
            { name = 'management', minGrade = 2 },
        },
    },

    -- ════════════════════════════════════════════════════════════
    -- 🌤️ WEATHER SYSTEM
    -- ════════════════════════════════════════════════════════════
    Weather = {
        enabled = true,
        defaultWeather = 'CLEAR',
        transitionDuration = 45, -- Smooth 45-second transitions
        transitionSteps = 90,
        types = {
            { value = 'EXTRASUNNY',  label = '☀️ Extra Sunny',     temp = {25, 35}, windBase = 1.5 },
            { value = 'CLEAR',       label = '🌤️ Clear',          temp = {20, 30}, windBase = 2.0 },
            { value = 'NEUTRAL',     label = '⛅ Neutral',        temp = {18, 25}, windBase = 2.5 },
            { value = 'SMOG',        label = '🌫️ Smog',           temp = {15, 25}, windBase = 1.0 },
            { value = 'FOGGY',       label = '🌁 Foggy',          temp = {10, 20}, windBase = 0.5 },
            { value = 'OVERCAST',    label = '☁️ Overcast',       temp = {12, 22}, windBase = 3.0 },
            { value = 'CLOUDS',      label = '⛅ Clouds',         temp = {15, 23}, windBase = 2.5 },
            { value = 'CLEARING',    label = '🌤️ Clearing',       temp = {16, 24}, windBase = 2.0 },
            { value = 'RAIN',        label = '🌧️ Rain',           temp = {8, 18},  windBase = 5.0 },
            { value = 'THUNDER',     label = '⛈️ Thunder',        temp = {10, 20}, windBase = 8.0 },
            { value = 'BLIZZARD',    label = '🌨️ Blizzard',       temp = {-10, 5}, windBase = 12.0 },
            { value = 'SNOW',        label = '❄️ Snow',           temp = {-5, 5},  windBase = 4.0 },
            { value = 'SNOWLIGHT',   label = '🌨️ Light Snow',    temp = {0, 8},   windBase = 3.0 },
            { value = 'XMAS',        label = '🎄 Christmas',      temp = {-5, 5},  windBase = 2.5 },
            { value = 'HALLOWEEN',   label = '🎃 Halloween',      temp = {10, 18}, windBase = 4.0 },
        },
    },

    -- ════════════════════════════════════════════════════════════
    -- 🔄 DYNAMIC WEATHER
    -- ════════════════════════════════════════════════════════════
    DynamicWeather = {
        enabled = true,
        changeInterval = {15, 45}, -- Random between 15-45 minutes (was 60-120, too long — caused rain to lock for hours)
        weights = {
            EXTRASUNNY = 15, CLEAR = 20, NEUTRAL = 15,
            SMOG = 5, FOGGY = 5, OVERCAST = 10,
            CLOUDS = 12, CLEARING = 8, RAIN = 8,
            THUNDER = 3, BLIZZARD = 1, SNOW = 2,
            SNOWLIGHT = 3, XMAS = 1, HALLOWEEN = 1,
        },
        seasons = {
            winter = {12, 1, 2},
            spring = {3, 4, 5},
            summer = {6, 7, 8},
            autumn = {9, 10, 11},
        },
        seasonalWeights = {
            winter = {
                -- Snow-dominant but not exclusively — some clear winter days
                SNOW = 20, SNOWLIGHT = 18, BLIZZARD = 8,
                XMAS = 10, OVERCAST = 18, CLEAR = 15, EXTRASUNNY = 5, FOGGY = 6,
            },
            spring = {
                -- Balanced spring: rain exists but sunny/clearing weather is equally likely
                -- Reduced RAIN (20→10) and raised CLEAR+CLEARING to prevent rain-lock loops
                CLEAR = 25, CLEARING = 20, NEUTRAL = 15,
                CLOUDS = 12, OVERCAST = 10, RAIN = 10, FOGGY = 8,
            },
            summer = {
                -- Hot and mostly sunny with occasional cloud bursts
                EXTRASUNNY = 35, CLEAR = 30, NEUTRAL = 18,
                SMOG = 8, CLOUDS = 6, OVERCAST = 3,
            },
            autumn = {
                -- Moody autumn — overcast & fog dominant, some rain, but clears regularly
                FOGGY = 14, OVERCAST = 18, RAIN = 14,
                CLOUDS = 16, CLEARING = 15, HALLOWEEN = 8, CLEAR = 15,
            },
        },
        transitions = {
            EXTRASUNNY = { 'CLEAR', 'NEUTRAL', 'CLOUDS' },
            CLEAR = { 'EXTRASUNNY', 'NEUTRAL', 'CLOUDS', 'CLEARING' },
            NEUTRAL = { 'CLEAR', 'CLOUDS', 'OVERCAST', 'CLEARING' },
            SMOG = { 'FOGGY', 'OVERCAST', 'CLEAR' },
            FOGGY = { 'SMOG', 'OVERCAST', 'CLOUDS', 'CLEARING' },
            OVERCAST = { 'CLOUDS', 'RAIN', 'CLEARING', 'FOGGY' },
            CLOUDS = { 'OVERCAST', 'RAIN', 'CLEARING', 'NEUTRAL' },
            CLEARING = { 'CLEAR', 'NEUTRAL', 'CLOUDS', 'OVERCAST' },
            -- BUG FIX: added CLEARING exit to THUNDER and broadened RAIN exits
            -- so rain can break out of the RAIN↔OVERCAST↔CLOUDS loop naturally.
            RAIN    = { 'THUNDER', 'OVERCAST', 'CLEARING', 'CLOUDS', 'NEUTRAL' },
            THUNDER = { 'RAIN', 'OVERCAST', 'CLEARING', 'CLOUDS' },
            BLIZZARD = { 'SNOW', 'SNOWLIGHT', 'OVERCAST' },
            SNOW = { 'SNOWLIGHT', 'BLIZZARD', 'OVERCAST', 'XMAS' },
            SNOWLIGHT = { 'SNOW', 'OVERCAST', 'FOGGY' },
            XMAS = { 'SNOW', 'SNOWLIGHT', 'BLIZZARD' },
            HALLOWEEN = { 'FOGGY', 'OVERCAST', 'CLOUDS' },
        },
    },

    -- ════════════════════════════════════════════════════════════
    -- 🕐 TIME SYSTEM (PRODUCTION READY - SMOOTH & REALISTIC)
    -- ════════════════════════════════════════════════════════════
    Time = {
        enabled = true,
        
        -- ⏰ REALTIME SYNC (Recommended for Realism)
        -- If true: Time syncs with server's real time
        -- If false: Uses custom time cycle with multiplier
        syncWithRealTime = true,
        
        -- 🔄 CUSTOM TIME CYCLE (Only used if syncWithRealTime = false)
        customCycle = {
            dayDuration = 90,    -- Not used with new system
            nightDuration = 60,  -- Not used with new system
            startHour = 12,
            startMinute = 0,
        },
        
        -- ⚡ REALISTIC TIME MULTIPLIER
        -- How many in-game seconds pass per real second
        -- Examples:
        --   1.0  = Real-time (1 real second = 1 game second)
        --   60.0 = 1 real minute = 1 game hour (realistic feel)
        --   120.0 = 1 real minute = 2 game hours (faster cycle)
        realTimeMultiplier = 60.0, -- Default: 1 real min = 1 game hour
        
        -- 🔒 FREEZE TIME
        freezeTime = false,
        frozenHour = 12,
        frozenMinute = 0,
        
        -- 🌅 DAY/NIGHT CYCLE
        dayStart = 6,   -- 06:00 = Day starts
        nightStart = 20, -- 20:00 = Night starts
    },

    -- ════════════════════════════════════════════════════════════
    -- 💨 WIND SYSTEM
    -- ════════════════════════════════════════════════════════════
    Wind = {
        enabled = true,
        dynamic = true,
        min = 0.0,
        max = 15.0,
        variation = {
            enabled = true,
            interval = 10000, -- Check every 10 seconds
            maxChange = 2.0,  -- Max wind speed change per interval
        },
    },

    -- ════════════════════════════════════════════════════════════
    -- ❄️ SNOW SYSTEM
    -- ════════════════════════════════════════════════════════════
    Snow = {
        enabled = true,
        requireSnowWeather = true, -- Auto-enable with SNOW/BLIZZARD/XMAS
        autoMonths = {12, 1, 2},   -- Auto-enable in winter months
        vehicleTrails = true,
        footstepTracks = true,
        disableXmasProps = true,
    },

    -- ════════════════════════════════════════════════════════════
    -- 📊 DATABASE
    -- ════════════════════════════════════════════════════════════
    Database = {
        tableName = 'rde_weather_time',
        autoCreate = true,
        saveInterval = 60, -- Auto-save every 60 seconds
    },

    -- ════════════════════════════════════════════════════════════
    -- 🎨 UI & NOTIFICATIONS
    -- ════════════════════════════════════════════════════════════
    UI = {
        notifications = {
            enabled = true,
            showWeatherChange = true,
            showTimeInfo = false,
            position = 'top-right',
            duration = 5000,
        },
        showWeatherHud = false,
        showTimeHud = false,
    },

    -- ════════════════════════════════════════════════════════════
    -- 🐛 DEBUG
    -- ════════════════════════════════════════════════════════════
    Debug = false,
}