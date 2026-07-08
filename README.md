# Proyector — Philco H300P (Amlogic t950s_be311)

Optimizaciones persistentes para proyector Philco H300P (Android 13, 1 GB RAM, root userdebug, passive cooling).

## Ajustes originales vs actuales

| Parámetro | Original (stock) | Ahora | Qué cambió |
|-----------|-----------------|-------|------------|
| **CPU** | | | |
| max_freq | 1.464 GHz | 1.296 GHz | Capado para control térmico |
| governor | ondemand | ondemand | — |
| powersave_bias | 0 | 0 | — (fue 1000, revertido) |
| up_threshold | 95 | 80 | Sube de freq antes |
| sampling_down_factor | 1 | 4 | Mantiene freq alta 4× más tras burst |
| io_is_busy | 0 | 1 | Sube freq durante E/S |
| sampling_rate | 10000 | 10000 | — |
| **I/O** | | | |
| scheduler | mq-deadline | mq-deadline | — |
| read_ahead_kb | 128 KB | 512 KB | 4× más datos leídos adelantados |
| **VM** | | | |
| swappiness | 60 (default Android) | 100 | Swap más agresivo |
| watermark_scale | 10 | 40 | kswapd más gradual (reduce picos de carga durante video) |
| watermark_boost | 0 | 1000 | Boost tras wakeup |
| dirty_ratio | 20 | 10 | Menos writeback sucio antes de flush |
| dirty_background_ratio | 10 | 3 | Flush async empieza antes |
| vfs_cache_pressure | 100 | 50 | Retiene más cache de ficheros |
| **ZRAM** | | | |
| algoritmo | lz4 | zstd | Mejor compresión (~2× ratio) |
| disksize | ~512 MB | 1.5 GB | Más swap comprimido |
| **Térmico** | | | |
| trip_0 (passive) | 95 °C | 70 °C | Throttle empieza antes |
| trip_1 (passive) | 105 °C | 80 °C | Segundo escalón antes |
| trip_3 (critical) | 115 °C | 115 °C | — |
| **Scheduler / RT** | | | |
| sched_energy_aware | 1 | 0 | Desactivado (4 cores iguales, no big.LITTLE) |
| sched_rt_runtime_us | 950000 | 1000000 | Sin throttle RT, input dispatcher no se estanca |
| GENTLE_FAIR_SLEEPERS | activo | desactivado | Input reader mantiene prioridad al despertar |
| **Animaciones** | | | |
| window_animation_scale | 1.0 | 0.5 | 2× más rápido |
| transition_animation_scale | 1.0 | 0.5 | 2× más rápido |
| animator_duration_scale | 1.0 | 0.5 | 2× más rápido |
| **Otros** | | | |
| stay_on_while_plugged_in | 0 | 3 (AC+USB) | No duerme mientras enchufado |
| LMKD minfree | stock | `18432:0,30720:100,...` | Primer threshold 72 MB, mata cached apps antes |
| max_cached_processes | default | 24 | Menos apps en RAM, reduce swap durante video |
| Bloatware | 15 paquetes activos | Deshabilitados | GMS, Play Store, Katniss, etc. |
| Boot malware | Descargaba scripts remotos | Limpio | ttyunos.sh/v9ying.sh sanitizados |
| Build fingerprint | `redfin:12/SP1A.210812.015` (Android 12) | `redfin:13/TQ2A.230405.003.E1` (Android 13) | Stock spoofeaba como Android 12; Google Play detectaba 11/12. Fix via `magisk resetprop` en boot |
| Temp típica | ~68 °C | ~60 °C | −8 °C |
| Mem Available | ~309 MB | variable (~473 MB pico post-limpieza) | |

## Scripts

- `optimize-t950s.sh` — aplica optimizaciones en caliente (memoria, CPU, térmica, I/O, scheduler, RT)
- `setup-proyector.sh` — one-shot completo tras flasheo (deshabilita bloatware, limpia malware, instala optimizaciones, configura ChillHub al boot, fix fingerprint Android 13)

Persistencia vía `/data/ttyunos/ttyunos.sh` (servicio init ejecuta optimizaciones, fix fingerprint, y lanza ChillHub en cada boot).

## Apps instaladas

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
| F-Droid / Aurora Store | tiendas |
| Netflix / Prime Video | preinstaladas |

## Notas

- **Root**: userdebug build, `su 0` funciona, SELinux disabled. Sin Magisk funcional (binarios presentes para `resetprop`).
- **Persistencia sin Magisk**: el servicio init `ttyunos` ejecuta `/data/ttyunos/ttyunos.sh` al boot cuando `sys.jm.ttyunos=1`.
- **Build fingerprint**: stock spoofeaba como Pixel 5 (redfin) Android 12. Se corrige a Android 13 via `magisk resetprop` en cada boot.
- **Cooling pasivo**: sin ventilador, solo throttle térmico vía trip points CPU/GPU/DDR.