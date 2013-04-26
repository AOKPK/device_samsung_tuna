#!/system/bin/sh
# malaroth, osm0sis, joaquinf, The Gingerbread Man, pkgnex, Khrushy, shreddintyres

# custom busybox installation shortcut
bb=/system/xbin/busybox;

# disable sysctl.conf to prevent ROM interference with tunables
# backup and replace PowerHAL with custom build to allow OC/UC to survive screen off
# create and set permissions for /system/etc/init.d if it doesn't already exist
$bb mount -o rw,remount /system;
$bb [ -e /system/etc/sysctl.conf ] && $bb mv /system/etc/sysctl.conf /system/etc/sysctl.conf.fkbak;
$bb [ -e /system/lib/hw/power.tuna.so.fkbak ] || $bb cp /system/lib/hw/power.tuna.so
/system/lib/hw/power.tuna.so.fkbak;
$bb cp /sbin/power.tuna.so /system/lib/hw/;
$bb chmod 644 /system/lib/hw/power.tuna.so;
if [ ! -e /system/etc/init.d ]; then
  $bb mkdir /system/etc/init.d
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

# lmk whitelist for common launchers
list="com.android.launcher org.adw.launcher org.adwfreak.launcher com.anddoes.launcher
com.gau.go.launcherex com.mobint.hololauncher com.mobint.hololauncher.hd com.teslacoilsw.launcher
com.cyanogenmod.trebuchet org.zeam";
sleep 60;
for class in $list; do
  pid=`pidof $class`;
  if [ $pid != "" ]; then
    echo "-17" > /proc/$pid/oom_adj;
    chmod 100 /proc/$pid/oom_adj;
  fi;
done;
