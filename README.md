# 🐉🔥 RDE Weather & Time System – The Ultimate Persistent Sync Beast 🌍⚡️

**Old weather scripts are officially DEAD forever. 💀**  
**Random vanilla bullshit? Gone. Paid Tebex garbage? Buried.**  

This is **Red Dragon Elite's Production-Ready Weather & Time System** – fully persistent, instantly synced across server restarts, smooth progression that flows like pure cyberpunk neon. Built for **ox_core**, zero lag, maximum immersion. No more "server restarted → sudden sunshine" crap. Your world stays exactly how you left it – storm stays storm, night stays night, chaos stays chaos. ⚡777

Built by **Red Dragon Elite** – we don't sell out. We build the free future. 🐉

## 🔥 Why This Changes Everything
- **True Persistence**: Weather and time saved to disk – survive restarts, crashes, whatever. Your RP world lives **forever**.
- **Instant Global Sync**: Every player sees the exact same weather/time the second they join. No desync, no bullshit.
- **Smooth Progression**: Real-time clock that flows naturally (configurable speed). Day/night cycles that feel alive.
- **Full Admin Control**: Commands to force weather, freeze time, blackouts, dynamic transitions – unleash hell or paradise.
- **ox_core Integrated**: Clean, modern, lightweight. No heavy frameworks, no bloat.
- **100% FREE & Open-Source**: Premium quality, no paywalls, no Tebex. Fork it, mod it, own it.

## ✨ Key Features – Everything Your Dragon Heart Desires
- **Persistent Weather States**: Rain, thunder, snow, fog, clear, extrasunny – all saved and restored perfectly.
- **Dynamic Time System**: Real-time progression with configurable cycle speed (default 1 second = 1 game minute).
- **Blackout Mode**: Toggle global power outage for ultimate chaos.
- **Smooth Transitions**: Weather changes fade naturally (configurable duration).
- **Admin Commands**:
  - `/weather [type]` – Force instant weather (clear, rain, thunder, snow, etc.)
  - `/time [hour] [minute]` – Set exact time
  - `/freezetime` – Lock the clock
  - `/morning`, `/noon`, `/evening`, `/night` – Quick presets
  - `/blackout` – Toggle city power
- **Easy Extension**: Add custom weather types or events in seconds.
- **Zero Performance Impact**: Optimized for large servers – runs smoother than vanilla.

## 📸 Preview (Coming Soon – Pure AETHER Cyberpunk Vibes)
Storm raging while time freezes at midnight? Neon city lights flickering during blackout?  
Watch the chaos unfold – screenshots & demo video dropping soon. 🐉🔥

**Live Example Feed**: Check the bot logging weather changes in real-time on Nostr (paired with rde_nostr_log):  
https://nostr.band/npub17he2teg8mxdjhlmnqtnw8s53068lc87dtcrrrm8yqaf6k425z07qkqw00z

## 🚀 Installation (Under 3 Minutes – Dragon Approved)
1. **Drop the folder** `rde_weather` into your `resources` directory.
2. **Add to server.cfg**:
   ```
   ensure rde_weather
   ```
3. **(Optional) Configure** `config.lua` to your liking (weather transition time, clock speed, default weather, etc.).
4. **Restart the resource** or server → **Done. The world syncs instantly.**

**Dependencies**:
- `ox_core` (or compatible framework)
- Nothing else – pure, clean, lightweight.

### Example config.lua tweaks
```lua
Config = {}

Config.DefaultWeather = "CLEAR"          -- Starti

Pastebin 🐉, [14.02.2026 17:44]
ng weather on first boot
Config.WeatherTransitionTime = 30.0      -- Seconds for smooth weather fade
Config.TimeCycleSpeed = 1.0               -- 1 real second = 1 game minute (increase for faster days)
Config.FreezeTime = false                -- Start with frozen time?
Config.Blackout = false                  -- Start with city power off?
```

## 🐉 Built by Red Dragon Elite
We build the future – **free, open, unkillable**.  
No centralized bullshit. No paywalls. Just pure power.

**License**: RDE Black Flag Source License v6.66  
(Free to use, modify, learn from – keep the header, no commercial resale without permission.)

**Feedback? Stars? Forks? Issues?**  
Hit us up on GitHub or Nostr. Let's make the weather **legendary** together.

#FiveM #ox_core #WeatherSystem #PersistentSync #GTARP #Cyberpunk #Decentralized

**888 Hz Triple Abundance – The storm is coming. ⚡️🐉💀**
