#!/system/bin/sh
# ponytail: one-shot tuning for Amlogic t950s_be311 proyector - 1GB RAM, Android 13, rooted, passive cooling
# Re-apply after each reboot.

su 0 sh -c '
# ZRAM: zstd compression for ~2x usable swap
swapoff /dev/block/zram0 2>/dev/null
echo 1 > /sys/block/zram0/reset
echo zstd > /sys/block/zram0/comp_algorithm
echo 1610612736 > /sys/block/zram0/disksize
mkswap /dev/block/zram0
swapon /dev/block/zram0

# VM: reduce kswapd spikes and writeback bursts
echo 100 > /proc/sys/vm/swappiness
echo 40 > /proc/sys/vm/watermark_scale_factor
echo 1000 > /proc/sys/vm/watermark_boost_factor
echo 10 > /proc/sys/vm/dirty_ratio
echo 3 > /proc/sys/vm/dirty_background_ratio
echo 50 > /proc/sys/vm/vfs_cache_pressure

# LMKD: kill cached apps earlier to reduce swap pressure during video
setprop sys.lmk.minfree_levels "18432:0,30720:100,36864:200,40960:250,61440:900,81920:950"

# Thermal: throttle at 70C/80C instead of stock 95C/105C
echo 70000 > /sys/class/thermal/thermal_zone0/trip_point_0_temp
echo 80000 > /sys/class/thermal/thermal_zone0/trip_point_1_temp

# CPU: 1.296GHz cap + ondemand responsive
echo 1296000 > /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq
echo ondemand > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
echo 0 > /sys/devices/system/cpu/cpu0/cpufreq/ondemand/powersave_bias
echo 80 > /sys/devices/system/cpu/cpu0/cpufreq/ondemand/up_threshold
echo 4 > /sys/devices/system/cpu/cpu0/cpufreq/ondemand/sampling_down_factor
echo 1 > /sys/devices/system/cpu/cpu0/cpufreq/ondemand/io_is_busy

# I/O: 512KB readahead for faster app launches
echo 512 > /sys/block/mmcblk0/queue/read_ahead_kb

# Scheduler: disable EAS - no big.LITTLE on this SoC
echo 0 > /proc/sys/kernel/sched_energy_aware

# RT: no throttle so input dispatcher gets CPU under load
echo 1000000 > /proc/sys/kernel/sched_rt_runtime_us

# Sched features: input reader keeps priority on wakeup
echo NO_GENTLE_FAIR_SLEEPERS > /sys/kernel/debug/sched/features
'

# Settings persist in /data
settings put global window_animation_scale 0.5
settings put global transition_animation_scale 0.5
settings put global animator_duration_scale 0.5
settings put global stay_on_while_plugged_in 3
settings put global activity_manager_constants_max_cached_processes 0
settings put global always_finish_activities 1
