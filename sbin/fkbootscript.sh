#!/system/bin/sh
# Franco's Dev Team
# malaroth, osm0sis, joaquinf, The Gingerbread Man, pkgnex, Khrushy, shreddintyres

# custom busybox installation shortcut
bb=/system/xbin/busybox;

# disable sysctl.conf to prevent ROM interference with tunables
$bb mount -o rw,remount /system;
$bb [ -e /system/etc/sysctl.conf ] && $bb mv /system/etc/sysctl.conf /system/etc/sysctl.conf.fkbak;

# create and set permissions for /system/etc/init.d if it doesn't already exist
if [ ! -e /system/etc/init.d ]; then
  $bb mkdir /system/etc/init.d;
  $bb chown -R root.root /system/etc/init.d;
  $bb chmod -R 755 /system/etc/init.d;
fi;
$bb mount -o ro,remount /system;

# disable debugging
echo "0" > /sys/module/wakelock/parameters/debug_mask;
echo "0" > /sys/module/userwakelock/parameters/debug_mask;
echo "0" > /sys/module/earlysuspend/parameters/debug_mask;
echo "0" > /sys/module/alarm/parameters/debug_mask;
echo "0" > /sys/module/alarm_dev/parameters/debug_mask;
echo "0" > /sys/module/binder/parameters/debug_mask;

# general queue tweaks
for i in /sys/block/*/queue; do
  echo 512 > $i/nr_requests;
  echo 512 > $i/read_ahead_kb;
  echo 2 > $i/rq_affinity;
  echo 0 > $i/nomerges;
  echo 0 > $i/add_random;
  echo 0 > $i/iostats;
  echo 0 > $i/rotational;
done;

# Some fancy tuning
echo 1 > /sys/devices/system/cpu/cpu0/cpufreq/gpu_oc;
echo 2 > /sys/devices/system/cpu/sched_mc_power_savings;
echo 15000000 > /proc/sys/kernel/sched_latency_ns
echo 2000000 > /proc/sys/kernel/sched_min_granularity_ns
echo 3000000 > /proc/sys/kernel/sched_wakeup_granularity_ns
echo 92274688 > /proc/sys/vm/dirty_background_bytes
echo 104857600 > /proc/sys/vm/dirty_bytes
echo 35 > /proc/sys/vm/swappiness
echo 2 > /sys/block/mmcblk0/queue/rq_affinity

echo 91 > /dev/cpuctl/apps/bg_non_interactive/cpu.shares
echo 400000 > /dev/cpuctl/apps/bg_non_interactive/cpu.rt_runtime_us
echo 100000000 > /dev/cpuctl/apps/bg_non_interactive/timer_slack.min_slack_ns

# remount sysfs+sdcard with noatime,nodiratime since that's all they accept
$bb mount -o remount,nosuid,nodev,noatime,nodiratime -t auto /;
$bb mount -o remount,nosuid,nodev,noatime,nodiratime -t auto /proc;
$bb mount -o remount,nosuid,nodev,noatime,nodiratime -t auto /sys;
$bb mount -o remount,nosuid,nodev,noatime,nodiratime -t auto /sys/kernel/debug;
$bb mount -o remount,nosuid,nodev,noatime,nodiratime -t auto /mnt/shell/emulated;
for i in /storage/emulated/*; do
  $bb mount -o remount,nosuid,nodev,noatime,nodiratime -t auto $i;
  $bb mount -o remount,nosuid,nodev,noatime,nodiratime -t auto $i/Android/obb;
done;

# wait for systemui and increase its priority
while sleep 1; do
  if [ `$bb pidof com.android.systemui` ]; then
    systemui=`$bb pidof com.android.systemui`;
    renice -18 $systemui;
    echo -17 > /proc/$systemui/oom_adj;
    chmod 100 /proc/$systemui/oom_adj;
    exit;
  fi;
done&

# lmk whitelist for common launchers and increase launcher priority
list="com.android.launcher org.adw.launcher org.adwfreak.launcher com.anddoes.launcher com.android.lmt com.chrislacy.actionlauncher.pro com.cyanogenmod.trebuchet com.gau.go.launcherex com.mobint.hololauncher com.mobint.hololauncher.hd com.teslacoilsw.launcher com.tsf.shell org.zeam";
while sleep 60; do
  for class in $list; do
    if [ `$bb pgrep $class` ]; then
      launcher=`$bb pgrep $class`;
      echo -17 > /proc/$launcher/oom_adj;
      chmod 100 /proc/$launcher/oom_adj;
      renice -18 $launcher;
    fi;
  done;
  exit;
done&
