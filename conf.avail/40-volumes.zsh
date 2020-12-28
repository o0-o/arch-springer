#!/usr/bin/env zsh

# Boot
pvcreate  --yes                   \
          --force --force         \
          '/dev/mapper/boot_luks'
vgcreate  'boot_vg'               \
          '/dev/mapper/boot_luks'
lvcreate  --size    '4G'      \
          --name    'boot_lv' \
          --addtag  'os'      \
          'boot_vg'

# Root
pvcreate  --yes                   \
          --force --force         \
          '/dev/mapper/root_luks'
vgcreate  'root_vg'               \
          '/dev/mapper/root_luks'
lvcreate  --size    '24G'     \
          --name    'root_lv' \
          --addtag  'os'      \
          'root_vg'
# Var
lvcreate  --size    '16G'     \
          --name    'var_lv'  \
          --addtag  'os'      \
          'root_vg'
# Log
lvcreate  --size    '8G'          \
          --name    'var_log_lv'  \
          --addtag  'log'         \
          'root_vg'

# Home
pvcreate  --yes                   \
          --force --force         \
          '/dev/mapper/home_luks'
vgcreate  'home_vg'               \
          '/dev/mapper/home_luks'
lvcreate  --extents '67%FREE' \
          --name    'home_lv' \
          --addtag  'local'   \
          --addtag  'user'    \
          'home_vg'
