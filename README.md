# 🌍 RDE Weather & Time — Dynamic Seasonal Weather, Persistent & Synced
![dl_1771628943063](https://github.com/user-attachments/assets/0a96714d-948b-4a54-825a-fef358c4ab19)

<div align="center">

![Version](https://img.shields.io/badge/version-2.2.1-red?style=for-the-badge&logo=github)
![License](https://img.shields.io/badge/license-RDE%20Black%20Flag%20v6.66-black?style=for-the-badge)
![FiveM](https://img.shields.io/badge/FiveM-Compatible-orange?style=for-the-badge)
![ox_core](https://img.shields.io/badge/ox__core-Required-blue?style=for-the-badge)
![Free](https://img.shields.io/badge/price-FREE%20FOREVER-brightgreen?style=for-the-badge)

**Real seasonal weather simulation, database persistence across restarts, instant global sync, ultra-smooth eased transitions, synchronized wind lerping, full admin menu, and a bad-weather streak breaker so it doesn't rain for three hours straight.**
Built on ox_core · ox_lib · oxmysql

*Built by [Red Dragon Elite](https://rd-elite.com) | SerpentsByte*

</div>

---

## 📖 Table of Contents

- [Overview](#-overview)
- [Features](#-features)
- [Dependencies](#-dependencies)
- [Installation](#-installation)
- [Configuration](#️-configuration)
- [Admin Menu](#-admin-menu)
- [How the Weather Engine Works](#️-how-the-weather-engine-works)
- [Nostr Integration](#-nostr-integration)
- [Performance](#-performance)
- [Troubleshooting](#-troubleshooting)
- [Changelog](#-changelog)
- [License](#-license)

---

## 🎯 Overview

**RDE Weather & Time** is a full seasonal weather simulation, not a random weather-of-the-day picker. Weather moves through a realistic state graph (storms clear via overcast → clearing → sun, not straight to EXTRASUNNY), is weighted per real-world season, and persists through restarts via MySQL — not a flat file. Every joining player is synced to the exact current weather, time, wind, and snow state the instant they load in.

### Why RDE Weather & Time?

| Feature | Vanilla / Generic Scripts | RDE Weather & Time |
|---|---|---|
| Persists across restarts | ❌ | ✅ MySQL-backed |
| Instant global sync on join | ❌ | ✅ Single callback, zero delay |
| Smooth weather transitions | ❌ / opaque native | ✅ Manually stepped blend with Sine-Easing |
| Synced Wind Interpolation | ❌ Snaps instantly | ✅ Smooth Lerp (Speed & Direction math) |
| Realistic state graph | ❌ Random pick | ✅ Markov-style transitions per weather type |
| Seasonal weighting | ❌ | ✅ 4 seasons, real calendar months |
| Bad-weather streak protection | ❌ | ✅ Configurable hard cap |
| Dynamic wind | ❌ | ✅ Per-weather base + periodic variation |
| Snow system | ❌ | ✅ Auto-enable, vehicle trails, footstep tracks |
| Admin control | Limited | ✅ Full ox_lib context menu |
| Nostr logging support | ❌ | ✅ via rde_nostr_log (optional) |

---

## ✨ Features

### 🌦️ Weather Engine
- 15 weather types out of the box: `EXTRASUNNY`, `CLEAR`, `NEUTRAL`, `SMOG`, `FOGGY`, `OVERCAST`, `CLOUDS`, `CLEARING`, `RAIN`, `THUNDER`, `BLIZZARD`, `SNOW`, `SNOWLIGHT`, `XMAS`, `HALLOWEEN`
- **Realistic transition graph** — each weather type can only move to specific neighbours (e.g. `THUNDER` clears via `OVERCAST`/`CLEARING`, never jumps straight to `EXTRASUNNY`)
- **4 real seasons** (winter/spring/summer/autumn, mapped to actual calendar months) each with their own weight table — winter favours snow, summer favours sun, etc.
- **Ultra-Smooth Eased Transitions** — no reliance on opaque single-call natives. The blend is manually stepped every ~100ms (`transitionSteps`, default 450) across `transitionDuration` seconds (default 45s) via `SetWeatherTypeTransition`. Built-in **Sine-Easing** replaces raw linear crossfades for a natural atmospheric onset/decay.
- **Bad-weather streak breaker** — after `badWeatherStreakLimit` (default 3) consecutive non-clear changes, the next change is guaranteed to move toward `CLEARING`/`CLEAR` instead of rolling the dice again
- State saved to MySQL — survives restarts, crashes, resource reloads

### 🕐 Time System
- **Real-time sync mode** (default) — server clock mirrors actual wall-clock time
- **Custom cycle mode** — configurable in-game-seconds-per-real-second multiplier if you want a faster/slower day cycle instead
- Smooth client-side second interpolation between server syncs — no choppy minute jumps
- Freeze time toggle for events/screenshots
- Persisted to MySQL alongside weather

### 💨 Wind System
- Each weather type has its own base wind speed (light breeze in `CLEAR`, gale-force in `BLIZZARD`)
- **Synchronized Wind Lerping** — Wind speed and direction drift dynamically alongside the sky transition instead of snapping instantly. Uses shortest-path angle math so a rotation from `350° → 10°` drifts a smooth +20° instead of spinning -340° the wrong way around.
- Periodic randomized variation on top of the base, safely paused during transitions to prevent data overrides.

### ❄️ Snow System
- Auto-enables ground snow + vehicle trails + footstep tracks for snow-type weather
- Optional auto-enable by calendar month regardless of current weather
- Toggleable independently via the admin menu

### 🔄 Synchronization
- Instant sync on join via `lib.callback` — no waiting on the next tick
- StateBag-based propagation (`GlobalState.rdeWeather` / `GlobalState.rdeTime`) — throttled to only broadcast on actual change (time: minute rollover; weather/wind/snow: forced on change), not a fixed-rate flood

---

## 📦 Dependencies

| Resource | Required | Notes |
|---|---|---|
| [ox_core](https://github.com/communityox/ox_core) | ✅ Required | Player/character framework, permission groups |
| [ox_lib](https://github.com/communityox/ox_lib) | ✅ Required | Context menus, callbacks, notifications |
| [oxmysql](https://github.com/communityox/oxmysql) | ✅ Required | Weather/time state persistence |
| [rde_nostr_log](https://github.com/RedDragonElite/rde_nostr_log) | ⚠️ Optional | Decentralized weather/time/admin-action logging |

---

## 🚀 Installation

### 1. Clone the repository

```bash
cd resources
git clone https://github.com/RedDragonElite/rde_weather.git
```

### 2. Add to `server.cfg`

```cfg
ensure oxmysql
ensure ox_lib
ensure ox_core
ensure rde_nostr_log   # optional
ensure rde_weather
```

> **Order matters.** `rde_weather` must start after `oxmysql`, `ox_lib`, and `ox_core`.

### 3. Set up permissions

```cfg
add_ace group.admin rde.admin allow
add_principal identifier.steam:110000xxxxxxxx group.admin
```

Or rely on your ox_core group grades — see [Configuration](#️-configuration).

### 4. Restart

```
ensure rde_weather
```

The database table auto-creates on first start. Check console for confirmation.

---

## ⚙️ Configuration

Edit `config.lua` — fully commented. Key sections:

### Permissions

```lua
Permissions = {
    useOxAcl = true,
    acePermission = 'rde.admin',
    groups = {
        { name = 'admin',      minGrade = 1 },
        { name = 'moderator',  minGrade = 3 },
        { name = 'management', minGrade = 2 },
    },
}
```

### Weather & Transitions

```lua
Weather = {
    enabled = true,
    defaultWeather = 'CLEAR',
    transitionDuration = 45,        -- seconds for the full smooth blend
    transitionSteps    = 450,       -- ultra-fine tick interval (~100ms steps)
    transitionEasing   = 'sine',    -- eased blend curve ('sine' or 'linear')
    windTransition     = true,      -- dynamic wind interpolation enabled
    types = { ... },                -- 15 types, each with temp range + base wind
}
```

### Dynamic Weather, Seasons & the Streak Breaker

```lua
DynamicWeather = {
    enabled = true,
    changeInterval = {15, 45}, -- minutes, randomized between auto-changes

    badWeatherStreakLimit = 3, -- force a clearing exit after this many bad changes in a row
    goodWeatherTypes = { CLEAR = true, EXTRASUNNY = true },

    weights = { ... },          -- fallback weights (rarely hit — seasonal always wins)
    seasons = {
        winter = {12, 1, 2}, spring = {3, 4, 5},
        summer = {6, 7, 8},  autumn = {9, 10, 11},
    },
    seasonalWeights = { winter = {...}, spring = {...}, summer = {...}, autumn = {...} },
    transitions = { ... }, -- the state graph: which weather can follow which
}
```

### Time

```lua
Time = {
    enabled = true,
    syncWithRealTime = true,     -- true = mirrors server wall-clock
    realTimeMultiplier = 60.0,   -- only used when syncWithRealTime = false
    freezeTime = false,
    dayStart = 6, nightStart = 20,
}
```

### Wind & Snow

```lua
Wind = {
    enabled = true, dynamic = true,
    min = 0.0, max = 15.0,
    variation = { enabled = true, interval = 10000, maxChange = 2.0 },
}

Snow = {
    enabled = true,
    requireSnowWeather = true, -- auto on for SNOW/BLIZZARD/XMAS
    autoMonths = {12, 1, 2},
    vehicleTrails = true, footstepTracks = true,
}
```

### Database

```lua
Database = {
    tableName = 'rde_weather_time',
    autoCreate = true,
    saveInterval = 60, -- seconds between auto-saves
}
```

---

## 🎛️ Admin Menu

Unlike command-driven weather scripts, RDE Weather & Time uses a single entry point that opens a full **ox_lib context menu**:

| Command | Permission | Description |
| --- | --- | --- |
| `/weather` | `rde.admin` ACE or admin/moderator/management ox_core group | Opens the full control panel |

**Inside the menu:**

| Section | Options |
| --- | --- |
| 🌦️ Weather | Pick any of the 15 weather types — sets instantly server-side, blends smoothly on every client |
| 🕐 Time | Morning (06:00) / Noon (12:00) / Evening (18:00) / Night (00:00) / Custom (hour + minute input) |
| 💨 Wind | Manual speed/direction sliders, or randomize |
| ❄️ Snow | Toggle ON/OFF, or one-click "Christmas Mode" (sets `XMAS` + enables snow) |
| 📊 Status | Read-only dialog: current weather, time, wind, snow, transition state |

All actions are server-validated against `HasPermission()` regardless of what the client sends — the menu is a convenience layer, not the security boundary.

---

## ⚙️ How the Weather Engine Works

1. **Season lookup** — `GetCurrentSeason()` checks the real calendar month against `DynamicWeather.seasons`.
2. **Candidate selection** — `GetNextWeather()` looks up `Config.DynamicWeather.transitions[currentWeather]` for the list of weather types this one is allowed to move to (the realism constraint), then does a weighted random pick among only those candidates using the current season's weight table.
3. **Streak check** — before rolling, if `State.consecutiveBadWeather >= badWeatherStreakLimit`, the pick is skipped entirely and the system forces `CLEARING` (or `CLEAR` if directly reachable) instead.
4. **Broadcast** — the new weather is written to `GlobalState.rdeWeather` immediately (server-authoritative "what weather is active" state).
5. **Client blend** — each client's StateBag handler kicks off a manual stepped `StartWeatherTransition()`. Instead of a linear blend, it maps progress across 450 precision ticks using a sine curve, while simultaneously interpolating live wind speeds and directions (using shortest-path radians math) to make sure everything drifts seamlessly into the new state.

---

## 📡 Nostr Integration

If `rde_nostr_log` is running, the following are logged automatically: automatic weather changes (with season + wind context), admin-forced weather/wind/time changes, and snow toggles. Graceful no-op fallback if the resource isn't installed — no errors, no dependency lock-in.

See [rde_nostr_log](https://github.com/RedDragonElite/rde_nostr_log) for setup.

---

## ⚡ Performance

| Thread | Interval | Notes |
| --- | --- | --- |
| Server time progression | 100ms | Drives the clock; StateBag sync is throttled internally to fire only on minute rollover, not every tick |
| Server wind variation | `Wind.variation.interval` (10s default) | Skipped entirely while a weather transition is active to prevent overriding active lerps |
| Server auto-save | `Database.saveInterval` (60s default) | Single `INSERT ... ON DUPLICATE KEY UPDATE`, not a full table rewrite |
| Client blackout/clock-pause guard | Every frame | `SetBlackout(false)` + `PauseClock(true)` — both are "this-frame" natives that must be reasserted every frame, can't be throttled |
| Client time interpolation | Every frame | Smooths the visible clock between server syncs; only does work once 100ms of real interpolation has accumulated |
| Client weather blend | Active only during a transition | High-fidelity 450-step loop running at ~100ms intervals during crossfades; fully idle otherwise |

No `GetGamePool` scans, no per-tick weather polling — propagation is StateBag/event-driven throughout.

---

## 🐛 Troubleshooting

**Weather not persisting after restart?**
Check that `oxmysql` started successfully and the `rde_weather_time` table exists. Console will log `[RDE Weather & Time] Database initialized` on first boot.

**Players joining with wrong weather/time?**
Ensure `rde_weather` starts **after** `oxmysql`, `ox_lib`, and `ox_core` in `server.cfg`. Sync happens via a `lib.callback` fired on resource init, not an `ox:playerLoaded` event — if it's still wrong, check F8 console for callback timeout errors.

**`/weather` command not working / "Access Denied"?**
Verify your ACE setup (`add_ace group.admin rde.admin allow`) or that your ox_core group grade meets the `minGrade` threshold in `Config.Permissions.groups`.

**Weather transitions still look choppy?**
Confirm no other weather resource is running alongside this one — a second script calling `SetWeatherTypeNow`/`SetWeatherTypePersist` will fight this one's manual blend every frame. Disable or remove it.

**Stuck in bad weather for a long time?**
Check `Config.DynamicWeather.badWeatherStreakLimit` — lower it if you want the streak breaker to kick in sooner, or check `Config.Debug = true` console output to see the actual weighted rolls happening.

---

## 📝 Changelog

### v2.2.1 — "Smooth Transitions" Patch

**🐛 Fix — "instant/knopfdruck" snaps on weather change:**

* **The Issues:** Even with manual steps in v2.2.0, 90 steps over 45s updated only once every 500ms, causing noticeable stair-stepping in GTA's cloud system. Additionally, the wind speed and direction snapped instantly when the StateBag arrived, breaking the immersion completely (e.g., a sudden 2 m/s to 12 m/s blast during a clear sky fade).
* **The Fixes (`client.lua`):** Increased steps to **450** (~100ms intervals) and implemented **Sine-Easing** for atmospheric crossfades. Fully synchronized wind transitions into the main loop using shortest-path angle interpolation (`350° → 10°` drifts +20° instead of spinning -340°).
* **The Fixes (`server.lua`):** Added a +2s network latency safety buffer to the `isTransitioning` lock timer to guarantee clients finish local blending before persistence/refresh loops re-engage. Background wind-refresh loops are now safely paused during active transitions.

### v2.2.0 — Smooth Transitions Base & Bad-Weather Streak Breaker

* Replaced opaque native `SetWeatherTypeOvertimePersist` loops with deterministic manually-stepped `SetWeatherTypeTransition` crossfades.
* Introduced the Markov-chain streak breaker (`badWeatherStreakLimit = 3`) to prevent infinite sequences of rainy/gloomy variance.

### v1.0.1 — Bugfixes

* Fixed Snow enabling itself on Rain
* Smoother weather transition (early pass)

### v1.0.0 — Initial Release

* Persistent weather and time state via MySQL.
* Framework group integrations, full ox_lib context control panel, and optional Nostr logging.

---

## 📜 License

```
####################################################################################
#                                                                                  #
#       .:: RED DRAGON ELITE (RDE)  -  BLACK FLAG SOURCE LICENSE v6.66 ::.         #
#                                                                                  #
#   PROJECT:    RDE_WEATHER v2.2.1 (DYNAMIC SEASONAL WEATHER & TIME SYNC)          #
#   ARCHITECT:  .:: RDE ⧌ Shin [△ ᛋᛅᚱᛒᛅᚾᛏᛋ ᛒᛁᛏᛅ ▽] ::. | https://rd-elite.com      #
#   ORIGIN:     https://github.com/RedDragonElite                                  #
#                                                                                  #
#   WARNING: THIS CODE IS PROTECTED BY DIGITAL VOODOO AND PURE HATRED FOR LEAKERS  #
#                                                                                  #
#   [ THE RULES OF THE GAME ]                                                      #
#                                                                                  #
#   1. // THE "FUCK GREED" PROTOCOL (FREE USE)                                     #
#      You are free to use, edit, and abuse this code on your server.              #
#      Learn from it. Break it. Fix it. That is the hacker way.                    #
#      Cost: 0.00€. If you paid for this, you got scammed by a rat.                #
#                                                                                  #
#   2. // THE TEBEX KILL SWITCH (COMMERCIAL SUICIDE)                               #
#      Listen closely, you parasites:                                              #
#      If I find this script on Tebex, Patreon, or in a paid "Premium Pack":       #
#      > I will DMCA your store into oblivion.                                     #
#      > I will publicly shame your community.                                     #
#      > I hope your server lag spikes to 9999ms every time you blink.             #
#      SELLING FREE WORK IS THEFT. AND I AM THE JUDGE.                             #
#                                                                                  #
#   3. // THE CREDIT OATH                                                          #
#      Keep this header. If you remove my name, you admit you have no skill.       #
#      You can add "Edited by [YourName]", but never erase the original creator.   #
#      Don't be a skid. Respect the architecture.                                  #
#                                                                                  #
#   4. // THE CURSE OF THE COPY-PASTE                                              #
#      This code uses MySQL persistence, manually-driven weather blends, and       #
#      seasonal weighted state machines. If you just copy-paste without reading,   #
#      it WILL break. Don't come crying to my DMs. RTFM or learn to code.          #
#                                                                                  #
#   --------------------------------------------------------------------------     #
#   "We build the future on the graves of paid resources."                         #
#   "REJECT MODERN MEDIOCRITY. EMBRACE RDE SUPERIORITY."                           #
#   --------------------------------------------------------------------------     #
####################################################################################
```

**TL;DR:**

* ✅ Free forever — use it, edit it, learn from it
* ✅ Keep the header — credit where it's due
* ❌ Don't sell it — commercial use = instant DMCA
* ❌ Don't be a skid — copy-paste without reading won't work anyway

---

## 🌐 Community & Support

|  |  |
| --- | --- |
| 🐙 GitHub | [RedDragonElite](https://github.com/RedDragonElite) |
| 🌍 Website | [rd-elite.com](https://rd-elite.com) |
| 🔵 Nostr (RDE) | [RedDragonElite](https://primal.net/p/nprofile1qqsv8km2w8yr0sp7mtk3t44qfw7wmvh8caqpnrd7z6ll6mn9ts03teg9ha4rl) |
| 🔵 Nostr (Shin) | [SerpentsByte](https://primal.net/p/nprofile1qqs8p6u423fappfqrrmxful5kt95hs7d04yr25x88apv7k4vszf4gcqynchct) |
| 🚪 RDE Doors | [rde_doors](https://github.com/RedDragonElite/rde_doors) |
| 🚗 RDE Car Service | [rde_carservice](https://github.com/RedDragonElite/rde_carservice) |
| 🎯 RDE Skills | [rde_skills](https://github.com/RedDragonElite/rde_skills) |
| 🎮 RDE Props | [rde_props](https://github.com/RedDragonElite/rde_props) |
| 🌱 RDE Wild Plants | [rde_wildplants](https://github.com/RedDragonElite/rde_wildplant) |
| 📡 RDE Nostr Log | [rde_nostr_log](https://github.com/RedDragonElite/rde_nostr_log) |

**When asking for help, always include:**

* Full error from server console or txAdmin
* Your `server.cfg` resource start order
* ox_core / ox_lib versions in use

---

*"We build the future on the graves of paid resources."*

**REJECT MODERN MEDIOCRITY. EMBRACE RDE SUPERIORITY.**

🐉 Made with 🔥 by [Red Dragon Elite](https://rd-elite.com)

[⬆ Back to Top](#-rde-weather--time--dynamic-seasonal-weather-persistent--synced)
