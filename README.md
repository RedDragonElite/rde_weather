# 🌍 RDE Weather & Time — Persistent Weather & Time Sync System
![dl_1771628943063](https://github.com/user-attachments/assets/0a96714d-948b-4a54-825a-fef358c4ab19)

<div align="center">

![Version](https://img.shields.io/badge/version-1.0.1-red?style=for-the-badge&logo=github)
![License](https://img.shields.io/badge/license-RDE%20Black%20Flag%20v6.66-black?style=for-the-badge)
![FiveM](https://img.shields.io/badge/FiveM-Compatible-orange?style=for-the-badge)
![ox_core](https://img.shields.io/badge/ox__core-Required-blue?style=for-the-badge)
![Free](https://img.shields.io/badge/price-FREE%20FOREVER-brightgreen?style=for-the-badge)

**True persistence across restarts, instant global sync, smooth transitions, full admin control, and zero performance overhead.**
Built on ox_core · Lightweight · No bloat

*Built by [Red Dragon Elite](https://rd-elite.com) | SerpentsByte*

</div>

---

## 📖 Table of Contents

- [Overview](#-overview)
- [Features](#-features)
- [Dependencies](#-dependencies)
- [Installation](#-installation)
- [Configuration](#%EF%B8%8F-configuration)
- [Admin Commands](#-admin-commands)
- [Nostr Integration](#-nostr-integration)
- [Performance](#-performance)
- [Troubleshooting](#-troubleshooting)
- [Changelog](#-changelog)
- [License](#-license)

---

## 🎯 Overview

**RDE Weather & Time** solves the one thing every other weather script gets wrong — persistence. Server restarts, crashes, resource reloads — the world stays exactly how you left it. Storm stays storm. Night stays night. No more players logging back in to sudden sunshine after a restart.

Every player sees the exact same weather and time the instant they join. No desync, no drift, no vanilla randomness.

### Why RDE Weather & Time?

| Feature | Vanilla / Generic Scripts | RDE Weather & Time |
|---|---|---|
| Persists across restarts | ❌ | ✅ Saved to disk |
| Instant global sync on join | ❌ | ✅ |
| Smooth weather transitions | ❌ | ✅ Configurable fade |
| Blackout mode | ❌ | ✅ |
| Freeze time | ❌ | ✅ |
| Admin weather/time control | Limited | ✅ Full command set |
| Performance overhead | Variable | ✅ Near zero |
| Nostr logging support | ❌ | ✅ via rde_nostr_log |

---

## ✨ Features

### 🌦️ Weather System
- Full GTA V weather type support: `CLEAR`, `RAIN`, `THUNDER`, `SNOW`, `FOG`, `EXTRASUNNY`, and more
- Smooth transitions between weather states — configurable fade duration
- Weather state saved to disk — survives restarts and crashes
- Admin-forced weather changes broadcast instantly to all players

### 🕐 Time System
- Real-time clock with configurable cycle speed (default: 1 real second = 1 game minute)
- Time state persisted to disk — server restarts from exactly where it left off
- Freeze time toggle — lock the clock for events, screenshots, RP scenarios
- Quick preset commands for common times of day

### ⚡ Blackout Mode
- Toggle city power outage globally with a single command
- All players affected instantly — full immersion for events and RP

### 🔄 Synchronization
- Every joining player receives the current weather and time state immediately
- All state changes broadcast to all connected clients in real time
- No polling, no drift — event-driven architecture

---

## 📦 Dependencies

| Resource | Required | Notes |
|---|---|---|
| [ox_core](https://github.com/communityox/ox_core) | ✅ Required | Player/character framework |
| [rde_nostr_log](https://github.com/RedDragonElite/rde_nostr_log) | ⚠️ Optional | Decentralized weather change logging |

> **That's it.** No ox_lib, no oxmysql, no ox_target required. Pure and lightweight.

---

## 🚀 Installation

### 1. Clone the repository

```bash
cd resources
git clone https://github.com/RedDragonElite/rde_weather.git
```

### 2. Add to `server.cfg`

```cfg
ensure ox_core
ensure rde_nostr_log   # optional
ensure rde_weather
```

### 3. Configure (Optional)

Edit `config.lua` to set your starting weather, cycle speed, and transition time.

### 4. Restart

```
restart rde_weather
```

The world syncs instantly on start. Check server console for confirmation.

---

## ⚙️ Configuration

```lua
Config = {}

Config.DefaultWeather        = 'CLEAR'   -- starting weather on first boot
Config.WeatherTransitionTime = 30.0      -- seconds for smooth weather fade
Config.TimeCycleSpeed        = 1.0       -- 1 real second = 1 game minute
                                         -- increase for faster day/night cycles
Config.FreezeTime            = false     -- start with time frozen?
Config.Blackout              = false     -- start with city power off?
```

### Weather Types

Valid values for `Config.DefaultWeather` and the `/weather` command:

```
CLEAR · EXTRASUNNY · CLOUDS · OVERCAST · RAIN · CLEARING
THUNDER · SMOG · FOGGY · XMAS · SNOWLIGHT · BLIZZARD · SNOW · NEUTRAL
```

---

## 📋 Admin Commands

All commands require the `rde.weather.admin` ACE permission or an admin ox_core group.

| Command | Usage | Description |
|---|---|---|
| `/weather` | `/weather [type]` | Force a specific weather type instantly |
| `/time` | `/time [hour] [minute]` | Set exact server time |
| `/freezetime` | `/freezetime` | Toggle time freeze on/off |
| `/morning` | `/morning` | Set time to 06:00 |
| `/noon` | `/noon` | Set time to 12:00 |
| `/evening` | `/evening` | Set time to 19:00 |
| `/night` | `/night` | Set time to 00:00 |
| `/blackout` | `/blackout` | Toggle city power outage |

### ACE Setup (server.cfg)

```cfg
add_ace group.admin rde.weather.admin allow
add_principal identifier.steam:110000xxxxxxxx group.admin
```

---

## 📡 Nostr Integration

If `rde_nostr_log` is running, weather and time changes are automatically logged to the Nostr network — decentralized, permanent, uncensorable server logs.

Watch weather changes from this system live on Nostr:
[Live Bot Feed](https://nostr.band/npub17he2teg8mxdjhlmnqtnw8s53068lc87dtcrrrm8yqaf6k425z07qkqw00z)

See [rde_nostr_log](https://github.com/RedDragonElite/rde_nostr_log) for setup.

---

## ⚡ Performance

- Event-driven — no per-tick polling
- State sync fires only on change, not on a loop
- No database dependency — state written to lightweight disk file
- Zero measurable overhead on large servers

---

## 🐛 Troubleshooting

**Weather not persisting after restart?**
Check that the resource has write permission to its own directory. The state file is written locally — some hosting panels restrict this. Check server console for file write errors on shutdown.

**Players joining with wrong weather/time?**
Ensure `rde_weather` starts **after** `ox_core` in `server.cfg`. The sync event fires on `ox:playerLoaded` — if ox_core isn't ready, the event is missed.

**Weather command not working?**
Verify your ACE permission setup. Run `test_ace [identifier] rde.weather.admin` in the server console to confirm the permission is granted.

**Blackout not affecting all players?**
Confirm no other weather/time resource is running simultaneously — conflicts between two weather scripts will cause desync. Disable or remove the other resource.

---

## 📝 Changelog

### v1.0.1 — Bugfixes
- Fixed Snow enabled itself on Rain lol
- Smother Weather transition

### v1.0.0 — Initial Release
- Persistent weather state (survives restarts and crashes)
- Persistent time state with configurable cycle speed
- Instant global sync on player join
- Smooth weather transitions
- Freeze time toggle
- Blackout mode
- Full admin command set
- Optional Nostr logging integration

---

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/your-feature`
3. Commit: `git commit -m 'Add your feature'`
4. Push: `git push origin feature/your-feature`
5. Open a Pull Request

Guidelines: follow existing Lua conventions, comment complex logic, test on a live server before PR, update docs if adding features.

---

## 📜 License

```
####################################################################################
#                                                                                  #
#      .:: RED DRAGON ELITE (RDE)  -  BLACK FLAG SOURCE LICENSE v6.66 ::.          #
#                                                                                  #
#   PROJECT:    RDE_WEATHER v1.0.1 (PERSISTENT WEATHER & TIME SYNC FOR FIVEM)      #
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
#      This code uses persistent disk I/O, event-driven sync, and smooth           #
#      weather transitions. If you just copy-paste without reading, it WILL break. #
#      Don't come crying to my DMs. RTFM or learn to code.                         #
#                                                                                  #
#   --------------------------------------------------------------------------     #
#   "We build the future on the graves of paid resources."                         #
#   "REJECT MODERN MEDIOCRITY. EMBRACE RDE SUPERIORITY."                           #
#   --------------------------------------------------------------------------     #
####################################################################################
```

**TL;DR:**
- ✅ Free forever — use it, edit it, learn from it
- ✅ Keep the header — credit where it's due
- ❌ Don't sell it — commercial use = instant DMCA
- ❌ Don't be a skid — copy-paste without reading won't work anyway

---

## 🌐 Community & Support

| | |
|---|---|
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
- Full error from server console or txAdmin
- Your `server.cfg` resource start order
- ox_core version in use

---

<div align="center">

*"We build the future on the graves of paid resources."*

**REJECT MODERN MEDIOCRITY. EMBRACE RDE SUPERIORITY.**

🐉 Made with 🔥 by [Red Dragon Elite](https://rd-elite.com)

[⬆ Back to Top](#-rde-weather--time--persistent-weather--time-sync-system)

</div>
