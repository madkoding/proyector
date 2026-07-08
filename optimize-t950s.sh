#!/system/bin/sh
# ponytail: one-shot tuning for Amlogic t950s_be311 proyector (1GB RAM, Android 13, rooted, passive cooling)
# Re-apply after each reboot.

su 0 sh -c '
# ZRAM: switch to zstd (better ratio than lz4, ~2x usable swap)
swapoff /dev/block/zram0 2>/dev/null
echo 1 > /sys/block/zram0/reset
echo zstd > /sys/block/zram0/comp_algorithm
echo 1610612736 > /sys/block/zram0/disksize
mkswap /dev/block/zram0
swapon /dev/block/zram0

# VM tuning: less kswapd thrashing, reduce writeback bursts that cause UI stutter
echo 100 > /proc/sys/vm/swappiness
echo 30 > /proc/sys/vm/watermark_scale_factor
echo 1000 > /proc/sys/vm/watermark_boost_factor
echo 10 > /proc/sys/vm/dirty_ratio
echo 3 > /proc/sys/vm/dirty_background_ratio
echo 50 > /proc/sys/vm/vfs_cache_pressure

# LMKD: raise first kill threshold so we kill earlier, avoid stalls
setprop sys.lmk.minfree_levels "24576:0,30720:100,36864:200,40960:250,61440:900,81920:950"

# Thermal: throttle earlier (passive trip points 70C / 80C vs stock 95C / 105C)
echo 70000 > /sys/class/thermal/thermal_zone0/trip_point_0_temp
echo 80000 > /sys/class/thermal/thermal_zone0/trip_point_1_temp

# CPU: cap max freq 1.296GHz (stock 1.464GHz, was 1.2GHz) + ondemand responsive tuning
echo 1296000 > /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq
echo ondemand > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
echo 0 > /sys/devices/system/cpu/cpu0/cpufreq/ondemand/powersave_bias
echo 80 > /sys/devices/system/cpu/cpu0/cpufreq/ondemand/up_threshold
echo 4 > /sys/devices/system/cpu/cpu0/cpufreq/ondemand/sampling_down_factor
echo 1 > /sys/devices/system/cpu/cpu0/cpufreq/ondemand/io_is_busy

# I/O: increase readahead for faster app launches
echo 512 > /sys/block/mmcblk0/queue/read_ahead_kb

# Scheduler: disable EAS (no big.LITTLE, wastes time on energy calculations)
echo 0 > /proc/sys/kernel/sched_energy_aware
'

# Settings persist in /data, set once and done
settings put global window_animation_scale 0.5
settings put global transition_animation_scale 0.5
settings put global animator_duration_scale 0.5
settings put global stay_on_while_plugged_in 3
