fx_version 'cerulean'
game 'gta5'
lua54 'yes'
name 'RDE | Weather & Time'
author 'RDE | SerpentsByte'
version '2.1.0'
description 'Production-Ready Weather & Time System | Instant Sync | Smooth Progression | ox_core | Nostr Logging (optional)'

-- ════════════════════════════════════════════════════════════
-- 📦 HARD DEPENDENCIES
-- ════════════════════════════════════════════════════════════
dependencies {
    'ox_core',
    'ox_lib',
    'oxmysql',
}

-- ════════════════════════════════════════════════════════════
-- 📦 OPTIONAL DEPENDENCY
-- rde_nostr_log — decentralized event logging via Nostr protocol
-- If not installed the resource runs normally without logging.
-- Install: https://github.com/RedDragonElite/rde_nostr_log
-- ════════════════════════════════════════════════════════════
optional_dependencies {
     'rde_nostr_log',
}

-- ════════════════════════════════════════════════════════════
-- 📂 FILES
-- ════════════════════════════════════════════════════════════
shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
}
server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server.lua',
}
client_scripts {
    'client.lua',
}

-- ════════════════════════════════════════════════════════════
-- 🎮 CONVAR CONFIGURATION
-- ════════════════════════════════════════════════════════════
-- Add these to your server.cfg for runtime configuration:
--
-- # Debug Mode
-- setr rde:debug false
--
-- # Weather change notifications
-- setr rde:weather_notifications true
--
-- # Dynamic Weather System
-- setr rde:dynamic_weather true
--
-- # Time Sync Mode (true = real-time, false = custom cycle)
-- setr rde:time_sync_realtime false
--
-- # Time Multiplier (in-game seconds per real second)
-- setr rde:time_multiplier 60.0
--
-- ════════════════════════════════════════════════════════════
-- ✨ FEATURES v2.1.0
-- ════════════════════════════════════════════════════════════
-- ✓ Instant sync on player spawn (0ms delay)
-- ✓ Smooth time progression with seconds
-- ✓ 100ms server update loop for real-time feel
-- ✓ StateBag sync — throttled, only fires on minute change
-- ✓ Database persistence with auto-save
-- ✓ Realistic time multiplier system
-- ✓ Dynamic weather with seasonal patterns
-- ✓ Smooth weather transitions (45 seconds)
-- ✓ Advanced wind system with variations
-- ✓ Full snow system with tracks
-- ✓ Admin menu with ox_lib context
-- ✓ Permission system (ox_core + ACE)
-- ✓ Optional Nostr logging (rde_nostr_log) — graceful fallback
-- ✓ Production-ready error handling
-- ════════════════════════════════════════════════════════════