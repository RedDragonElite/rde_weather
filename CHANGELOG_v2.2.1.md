# 🌦️ RDE Weather & Time — v2.2.1 "Smooth Transitions" Patch

## 🐛 Root cause of the "instant / knopfdruck" weather snap

v2.2.0 already drove the sky blend manually via `SetWeatherTypeTransition`,
which was the right idea — but three things around it were quietly
sabotaging the smoothness:

1. **Coarse steps.** 90 steps over 45s = one update every **500ms**.
   GTA's sky/particle system visibly stair-steps at that resolution —
   it reads as chunky, not fluid.
2. **Linear blend.** A constant-speed crossfade doesn't match how real
   weather fronts move (slow in, fast through the middle, slow out).
3. **Wind snapped instantly.** The StateBag handler called
   `SetWindSpeed`/`SetWindDirection` the moment the new state arrived —
   completely decoupled from the sky blend that starts a few lines later.
   A 2 m/s → 12 m/s gust jump felt like "the weather just changed", even
   while the sky itself was still fading nicely. This was the single
   biggest contributor to the perceived "instant" feeling.

On top of that, the 10s wind-refresh loop and 60s weather-persistence
loop could yank values back to their target mid-blend if timing lined up
wrong, and the server's `isTransitioning` window had zero buffer for
network latency before clients finished their local blend.

## ✅ What changed

**`config.lua`**
- `transitionSteps`: 90 → **450** (one step every ~100ms instead of 500ms)
- New `transitionEasing = 'sine'` — eased blend curve instead of linear
- New `windTransition = true` — wind now lerps instead of snapping

**`client.lua`**
- `StartWeatherTransition()` rewritten: sine-eased percent curve, plus a
  synced wind lerp (speed *and* direction, shortest-path angle math so
  `350° → 10°` drifts +20° instead of spinning -340° the long way around)
- StateBag handler no longer snaps wind instantly — only does so as a
  fallback when no actual weather transition is about to run (e.g. an
  admin wind-only change while the weather itself stays the same)
- 10s wind-refresh loop now skips while a transition is actively lerping
  wind on its own, so it can't undo the lerp mid-blend
- New `State.weather.currentWindSpeed/currentWindDirection` track the
  *live* applied wind, separate from the *target* wind, so every new
  transition always lerps from where wind actually is, not from stale data

**`server.lua`**
- `isTransitioning` close-out timer now has a +2s safety buffer on top of
  `transitionDuration`, so a network-delayed client always finishes its
  local blend before the server lets the persistence/refresh loops touch
  weather/wind again

## 🎮 Result

Weather and wind now drift into each other over the full 45s window with
an eased curve instead of cutting hard at the end — clouds roll in, wind
picks up, and the transition actually finishes blending before anything
else is allowed to touch state again.

No DB migration needed. Drop-in replacement for v2.2.0.
