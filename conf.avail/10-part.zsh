#!/usr/bin/env zsh

# Create partitions for boot mirror, swap mirror and root mirror, create
# both biosboot and esp partitions to keep future options open
for drive in "${boot_swap_root_mirror[@]}"; do
  sgdisk  --zap-all                                                   \
          --new             '1:0:+1M'                                 \
          --typecode        '1:ef02'                                  \
          --change-name     '1:biosboot'                              \
          --partition-guid  '1:21686148-6449-6E6F-744E-656564454649'  \
          --new             '2:0:+550M'                               \
          --typecode        '2:ef00'                                  \
          --change-name     '2:ESP'                                   \
          --new             '3:0:+8G'                                 \
          --typecode        '3:fd00'                                  \
          --change-name     '3:boot_mirror_part'                      \
          --new             '4:0:+4G'                                 \
          --typecode        '4:fd00'                                  \
          --change-name     '4:swap_mirror_part'                      \
          --new             '5:0:-100M'                               \
          --typecode        '5:fd00'                                  \
          --change-name     '5:root_mirror_part'                      \
          "${drive}"
done

# Create partition for home (luks)
sgdisk  --zap-all                   \
        --new         '1:0:-100M'   \
        --typecode    '1:8309'      \
        --change-name '1:home_part' \
        "${home}"
