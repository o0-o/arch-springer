#!/usr/bin/env zsh

# Create mirror for boot
yes                                                   |
mdadm --create                                        \
      --force                                         \
      --level         '1'                             \
      --metadata      '1.0'                           \
      --bitmap        'internal'                      \
      --homehost      "${hostname%%.*}"               \
      --raid-devices  "${#boot_swap_root_mirror[@]}"  \
      '/dev/md/boot_mirror'                           \
      "${boot_swap_root_mirror[@]/%/3}"               ||
[ "${pipestatus[2]}" = 0 ]

# Create mirror for swap
yes                                                   |
mdadm --create                                        \
      --force                                         \
      --level         '1'                             \
      --metadata      '1.2'                           \
      --bitmap        'internal'                      \
      --homehost      "${hostname%%.*}"               \
      --raid-devices  "${#boot_swap_root_mirror[@]}"  \
      '/dev/md/swap_mirror'                           \
      "${boot_swap_root_mirror[@]/%/4}"               ||
[ "${pipestatus[2]}" = 0 ]
shred --zero  --size '20MiB'  '/dev/md/swap_mirror'

# Create mirror for root
yes                                                   |
mdadm --create                                        \
      --force                                         \
      --level         '1'                             \
      --metadata      '1.2'                           \
      --bitmap        'internal'                      \
      --homehost      "${hostname%%.*}"               \
      --raid-devices  "${#boot_swap_root_mirror[@]}"  \
      '/dev/md/root_mirror'                           \
      "${boot_swap_root_mirror[@]/%/5}"               ||
[ "${pipestatus[2]}" = 0 ]
