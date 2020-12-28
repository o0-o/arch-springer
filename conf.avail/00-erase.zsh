#!/usr/bin/env zsh

# Unmount everything but live environment
declare notypes='nooverlay,noproc,nosysfs,nodevtmpfs,notmpfs,noiso9660'
declare notypes="${notypes},nodevpts,nocgroup2"
umount    --force --recursive '/mnt' || :
umount    --force --all         \
          --types "${notypes}"  || :
# Turn off swap
swapoff   --all

# Deactivate all LVM logical volumes
lvchange  --yes --activate 'n'                              \
          $( lvs  --noheadings --rows --options 'lv_path' ) || :

# Forcefully remove all LVM physical volumes
pvremove  --yes --force --force                             \
          $( pvs  --noheadings --rows --options 'pv_name' ) || :

# Close all LUKS containers
lsblk --noheadings                \
      --list                      \
      --output NAME,TYPE          |
tac                               |
grep "crypt$"                     |
while read -r crypt; do
  cryptsetup close "${crypt% *}"
done

# Remove all md devices
for md in '/dev/md'?*; do
  umount --lazy   "${md}"                             || :
  echo idle > "/sys/block/${md##*/}/md/sync_action"   || :
  echo none > "/sys/block/${md##*/}/md/resync_start"  || :
  mdadm --stop    "${md}"                             || :
  mdadm --remove  "${md}"                             || :
done
lsblk --noheadings                                            \
      --list                                                  \
      --output NAME                                           |
tac                                                           |
while read -r dev; do
  mdadm --misc --force --zero-superblock "/dev/${dev}"  || :
done

# Clear partitions
for drive in "${boot_swap_root_mirror[@]}" "${home}"; do
  sgdisk  --zap-all "${drive}"
done
