#!/system/bin/sh
# setup-proyector.sh — one-shot full setup for Philco H300P (Amlogic t950s_be311)
# Run once after firmware flash. Everything else is automatic after.
# Usage: adb shell su 0 sh /data/local/tmp/setup-proyector.sh
#
# What this does:
#   1. Installs optimizations (memory, CPU, thermal) and makes them persist via boot script
#   2. Disables bloatware (GMS, Play Store, Google Assistant, Chinese apps)
#   3. Cleans malware from boot scripts (ttyunos.sh, v9ying.sh download remote code)
#   4. Re-enables useful system apps (tcorrection, jiumao, droidlogic)
#   5. Sets up ChillHub launcher as default home
#   6. Creates boot script that reapplies optimizations + launches ChillHub on every boot
#
# Prerequisites:
#   - Root access (su 0 works — this build is userdebug)
#   - ChillHub APK installed: adb install chillhub.apk
#   - ADB connected: adb connect <proyector-ip>

set -e

echo "=== [1/6] Installing optimization script ==="
cat > /data/local/tmp/optimize-t950s.sh << 'OPT'
#!/system/bin/sh
su 0 sh -c '
swapoff /dev/block/zram0 2>/dev/null
echo 1 > /sys/block/zram0/reset
echo zstd > /sys/block/zram0/comp_algorithm
echo 1610612736 > /sys/block/zram0/disksize
mkswap /dev/block/zram0
swapon /dev/block/zram0

echo 100 > /proc/sys/vm/swappiness
echo 40 > /proc/sys/vm/watermark_scale_factor
echo 1000 > /proc/sys/vm/watermark_boost_factor
echo 10 > /proc/sys/vm/dirty_ratio
echo 3 > /proc/sys/vm/dirty_background_ratio
echo 50 > /proc/sys/vm/vfs_cache_pressure

setprop sys.lmk.minfree_levels "18432:0,30720:100,36864:200,40960:250,61440:900,81920:950"

echo 70000 > /sys/class/thermal/thermal_zone0/trip_point_0_temp
echo 80000 > /sys/class/thermal/thermal_zone0/trip_point_1_temp

echo 1296000 > /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq
echo ondemand > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
echo 0 > /sys/devices/system/cpu/cpu0/cpufreq/ondemand/powersave_bias
echo 80 > /sys/devices/system/cpu/cpu0/cpufreq/ondemand/up_threshold
echo 4 > /sys/devices/system/cpu/cpu0/cpufreq/ondemand/sampling_down_factor
echo 1 > /sys/devices/system/cpu/cpu0/cpufreq/ondemand/io_is_busy

echo 512 > /sys/block/mmcblk0/queue/read_ahead_kb

echo 0 > /proc/sys/kernel/sched_energy_aware

echo 1000000 > /proc/sys/kernel/sched_rt_runtime_us

echo NO_GENTLE_FAIR_SLEEPERS > /sys/kernel/debug/sched/features
'
settings put global window_animation_scale 0.5
settings put global transition_animation_scale 0.5
settings put global animator_duration_scale 0.5
settings put global stay_on_while_plugged_in 3
settings put global activity_manager_constants_max_cached_processes 24
OPT
chmod 755 /data/local/tmp/optimize-t950s.sh
echo "Done: optimize-t950s.sh installed"

echo "=== [2/6] Disabling bloatware ==="
for pkg in \
  com.google.android.gms \
  com.google.android.katniss \
  com.google.android.tvrecommendations \
  com.android.vending \
  com.google.android.partnersetup \
  com.droidlogic.android.tv \
  com.softwinner.tcorrection \
  com.master.accessibility \
  com.master.apps \
  com.jiumao.projection \
  com.bozee.usbdisplay \
  com.ht1.launcher \
  com.master.tv.market \
  com.overseas.store.appstore \
  com.android.mgstv \
  com.amazon.avod.thirdpartyclient \
  com.mxtech.videoplayer.ad \
  com.android.chrome \
  com.netflix.mediaclient \
  com.topjohnwu.magisk \
; do
  pm disable-user --user 0 "$pkg" 2>/dev/null && echo "  disabled: $pkg" || echo "  skip (not found): $pkg"
done
echo "Done: bloatware disabled"

echo "=== [3/6] Re-enabling useful system apps ==="
for pkg in \
  com.softwinner.tcorrection \
  com.jiumao.projection \
  com.droidlogic.android.tv \
  com.htc.htcsettings \
  com.jm.jmlauncher \
; do
  pm enable "$pkg" 2>/dev/null && echo "  enabled: $pkg" || echo "  skip: $pkg"
done
echo "Done: useful apps enabled"

echo "=== [4/6] Cleaning malware from boot scripts ==="
# Original malware: ttyunos.sh and v9ying.sh download+execute remote scripts
# from jm.v7ying.com / jm.v9ying.com / 123.207.77.74 on every boot
mkdir -p /data/ttyunos
cat > /data/ttyunos/ttyunos.sh << 'EOF'
#!/system/bin/sh
# Cleaned by madkoding - removed malware downloader
# Apply system optimizations at boot
su 0 sh /data/local/tmp/optimize-t950s.sh

# Fix build fingerprint to Android 13 (stock spoofed as Android 12)
su 0 /data/adb/magisk/magisk resetprop ro.build.fingerprint "google/redfin/redfin:13/TQ2A.230405.003.E1/7679548:user/release-keys"
su 0 /data/adb/magisk/magisk resetprop ro.system.build.fingerprint "google/redfin/redfin:13/TQ2A.230405.003.E1/7679548:user/release-keys"
su 0 /data/adb/magisk/magisk resetprop ro.vendor.build.fingerprint "google/redfin/redfin:13/TQ2A.230405.003.E1/7679548:user/release-keys"
su 0 /data/adb/magisk/magisk resetprop ro.odm.build.fingerprint "google/redfin/redfin:13/TQ2A.230405.003.E1/7679548:user/release-keys"
su 0 /data/adb/magisk/magisk resetprop ro.system_ext.build.fingerprint "google/redfin/redfin:13/TQ2A.230405.003.E1/7679548:user/release-keys"
su 0 /data/adb/magisk/magisk resetprop ro.bootimage.build.fingerprint "google/redfin/redfin:13/TQ2A.230405.003.E1/7679548:user/release-keys"
su 0 /data/adb/magisk/magisk resetprop ro.product.build.fingerprint "google/redfin/redfin:13/TQ2A.230405.003.E1/7679548:user/release-keys"
su 0 /data/adb/magisk/magisk resetprop ro.odm_dlkm.build.fingerprint "google/redfin/redfin:13/TQ2A.230405.003.E1/7679548:user/release-keys"
su 0 /data/adb/magisk/magisk resetprop ro.system_dlkm.build.fingerprint "google/redfin/redfin:13/TQ2A.230405.003.E1/7679548:user/release-keys"
su 0 /data/adb/magisk/magisk resetprop ro.vendor_dlkm.build.fingerprint "google/redfin/redfin:13/TQ2A.230405.003.E1/7679548:user/release-keys"

# Launch ChillHub as home (Android does not auto-switch from FallbackHome on this build)
sleep 8
am force-stop com.android.tv.settings
am start -a android.intent.action.MAIN -c android.intent.category.HOME
sleep 2
am start -n app.lumoslabs.chillhub/.LauncherActivity
EOF
chmod 755 /data/ttyunos/ttyunos.sh

cat > /data/ttyunos/v9ying.sh << 'EOF'
#!/system/bin/sh
# Cleaned by madkoding - removed malware downloader
EOF
chmod 755 /data/ttyunos/v9ying.sh

cat > /data/ttyunos/custom.sh << 'EOF'
#!/system/bin/sh
# Cleaned by madkoding - removed malware downloader
EOF
chmod 755 /data/ttyunos/custom.sh
echo "Done: malware cleaned from boot scripts"

echo "=== [5/6] Setting ChillHub as default home ==="
pm enable app.lumoslabs.chillhub 2>/dev/null
cmd package set-home-activity app.lumoslabs.chillhub/.LauncherActivity 2>/dev/null
am start -n app.lumoslabs.chillhub/.LauncherActivity 2>/dev/null
echo "Done: ChillHub set as home"

echo "=== [6/6] Applying optimizations now ==="
sh /data/local/tmp/optimize-t950s.sh
echo "Done: optimizations applied"

echo ""
echo "=== SETUP COMPLETE ==="
echo "Reboot to verify everything works automatically:"
echo "  adb reboot"
echo ""
echo "After reboot, optimizations + ChillHub launch automatically."
echo "To re-run this script after a firmware reflash:"
echo "  adb push setup-proyector.sh /data/local/tmp/"
echo "  adb shell su 0 sh /data/local/tmp/setup-proyector.sh"