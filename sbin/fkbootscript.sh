#!/system/bin/sh
# Franco's Dev Team
# malaroth, osm0sis, joaquinf, The Gingerbread Man, pkgnex, Khrushy, shreddintyres

# custom busybox installation shortcut
bb=/system/xbin/busybox;

# disable sysctl.conf to prevent ROM interference with tunables
# backup and replace PowerHAL with custom build to allow OC/UC to survive screen off
# create and set permissions for /system/etc/init.d if it doesn't already exist
$bb mount -o rw,remount /system;
$bb [ -e /system/etc/sysctl.conf ] && $bb mv /system/etc/sysctl.conf /system/etc/sysctl.conf.fkbak;
$bb [ -e /system/lib/hw/power.tuna.so.fkbak ] || $bb cp /system/lib/hw/power.tuna.so /system/lib/hw/power.tuna.so.fkbak;
$bb cp /sbin/power.tuna.so /system/lib/hw/;
$bb chmod 644 /system/lib/hw/power.tuna.so;
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
  echo 0 > $i/rotational;
done;

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
    echo "-17" > /proc/$systemui/oom_adj;
    chmod 100 /proc/$systemui/oom_adj;
    renice -18 $systemui;
    exit;
  fi;
done&

# lmk whitelist for common launchers and increase its priority
list="com.android.launcher org.adw.launcher org.adwfreak.launcher com.anddoes.launcher com.gau.go.launcherex com.mobint.hololauncher com.mobint.hololauncher.hd com.teslacoilsw.launcher com.cyanogenmod.trebuchet org.zeam";
while sleep 60; do
  for class in $list; do
    pid=`$bb pidof $class`;
    if [ "$pid" ]; then
      echo "-17" > /proc/$pid/oom_adj;
      chmod 100 /proc/$pid/oom_adj;
      renice -18 $pid;
    fi;
  done;
  exit;
done&

