# Proyector — Philco H300P (Amlogic t950s_be311)

Persistent optimizations for the Philco H300P projector (Android 13, 1 GB RAM, userdebug root, passive cooling).

## Stock vs current settings

| Parameter | Stock | Current | What changed |
|-----------|-------|---------|--------------|
| **CPU** | | | |
| max_freq | 1.464 GHz | 1.296 GHz | Capped for thermal control |
| governor | ondemand | ondemand | — |
| powersave_bias | 0 | 0 | — (was 1000, reverted) |
| up_threshold | 95 | 80 | Ramps up freq earlier |
| sampling_down_factor | 1 | 4 | Holds high freq 4× longer after burst |
| io_is_busy | 0 | 1 | Ramps freq during I/O |
| sampling_rate | 10000 | 10000 | — |
| **I/O** | | | |
| scheduler | mq-deadline | mq-deadline | — |
| read_ahead_kb | 128 KB | 512 KB | 4× more readahead for app launches |
| **VM** | | | |
| swappiness | 60 (Android default) | 100 | More aggressive swap |
| watermark_scale | 10 | 40 | Smoother kswapd (reduces load spikes during video) |
| watermark_boost | 0 | 1000 | Boost after wakeup |
| dirty_ratio | 20 | 10 | Less dirty writeback before flush |
| dirty_background_ratio | 10 | 3 | Async flush starts earlier |
| vfs_cache_pressure | 100 | 50 | Retains more file cache |
| **ZRAM** | | | |
| algorithm | lz4 | zstd | Better compression (~2× ratio) |
| disksize | ~512 MB | 1.5 GB | More compressed swap |
| **Thermal** | | | |
| trip_0 (passive) | 95 °C | 70 °C | Throttle starts earlier |
| trip_1 (passive) | 105 °C | 80 °C | Second step earlier |
| trip_3 (critical) | 115 °C | 115 °C | — |
| **Scheduler / RT** | | | |
| sched_energy_aware | 1 | 0 | Disabled (4 identical cores, no big.LITTLE) |
| sched_rt_runtime_us | 950000 | 1000000 | No RT throttle, input dispatcher doesn't stall |
| GENTLE_FAIR_SLEEPERS | enabled | disabled | Input reader keeps priority on wakeup |
| **Animations** | | | |
| window_animation_scale | 1.0 | 0.5 | 2× faster |
| transition_animation_scale | 1.0 | 0.5 | 2× faster |
| animator_duration_scale | 1.0 | 0.5 | 2× faster |
| **Other** | | | |
| stay_on_while_plugged_in | 0 | 3 (AC+USB) | No deep sleep while plugged in |
| LMKD minfree | stock | `18432:0,30720:100,...` | First threshold 72 MB, kills cached apps earlier |
| max_cached_processes | default | 24 | Fewer apps in RAM, less swap during video |
| Bloatware | 15 packages active | Disabled | GMS, Play Store, Katniss, etc. |
| Boot malware | Downloaded remote scripts | Cleaned | ttyunos.sh/v9ying.sh sanitized |
| Build fingerprint | `redfin:12/SP1A.210812.015` (Android 12) | `redfin:13/TQ2A.230405.003.E1` (Android 13) | Stock spoofed as Android 12; Google Play detected 11/12. Fixed via `magisk resetprop` at boot |
| Typical temp | ~68 °C | ~60 °C | −8 °C |
| Mem Available | ~309 MB | variable (~473 MB peak after cleanup) | |

## Scripts

- `optimize-t950s.sh` — applies optimizations live (memory, CPU, thermal, I/O, scheduler, RT)
- `setup-proyector.sh` — full one-shot setup after firmware flash (disables bloatware, cleans malware, installs optimizations, configures ChillHub at boot, fixes fingerprint to Android 13)

Persistence via `/data/ttyunos/ttyunos.sh` (init service runs optimizations, fingerprint fix, and launches ChillHub on every boot).

## Installed apps

| App | Package |
|-----|---------|
| ChillHub (launcher) | `app.lumoslabs.chillhub` |
| Steam Link | `com.valvesoftware.steamlink` |
| SmartTube | `com.google.android.youtube.tv` |
| NewPipe | (F-Droid) |
| VLC / Kodi / Jellyfin | (F-Droid) |
| Pluto TV | `tv.pluto.android` |
| AnimeFLV Max | `com.equirozdev.animecastv5.app` |
| Termux | `com.termux` |
| F-Droid / Aurora Store | app stores |
| Netflix / Prime Video | preinstalled |

## Notes

- **Root**: userdebug build, `su 0` works, SELinux disabled. No functional Magisk (binaries present for `resetprop`).
- **Persistence without Magisk**: the `ttyunos` init service runs `/data/ttyunos/ttyunos.sh` at boot when `sys.jm.ttyunos=1`.
- **Build fingerprint**: stock spoofed as Pixel 5 (redfin) Android 12. Corrected to Android 13 via `magisk resetprop` at every boot.
- **Passive cooling**: no fan, thermal throttling only via CPU/GPU/DDR trip points.