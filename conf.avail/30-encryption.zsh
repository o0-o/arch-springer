#!/usr/bin/env zsh

# Prep
for dev in '/dev/md/boot_mirror' '/dev/md/root_mirror' "${home}1"; do

  yes 'YES'                                   |
  cryptsetup  open  --type      'plain'       \
                    --key-file  '/dev/random' \
                    "${dev}"                  \
                    'container'               ||
  [ "${pipestatus[2]}" = 0 ]
  # Uncomment when you do it for real
#  dd  if='/dev/zero'              \
#      of='/dev/mapper/container'  \
#      bs='1M'                     \
#      status='progress'           || : # Exit 1 expected
  while ! cryptsetup close 'container'; do; done

done

# Key file
dd  if='/dev/urandom' \
    of='luks.key'     \
    bs='512'          \
    count='1'
chmod '600' 'luks.key'

# Boot
yes 'YES'                                       |
cryptsetup  luksFormat  --type      'luks1'     \
                        --key-file  'luks.key'  \
                        '/dev/md/boot_mirror'   ||
[ "${pipestatus[2]}" = 0 ]
cryptsetup  open        --key-file  'luks.key'  \
                        '/dev/md/boot_mirror'   \
                        'boot_luks'

# Root
yes 'YES'                                       |
cryptsetup  luksFormat  --key-file  'luks.key'  \
                        '/dev/md/root_mirror'   ||
[ "${pipestatus[2]}" = 0 ]
cryptsetup  open        --key-file  'luks.key'  \
                        '/dev/md/root_mirror'   \
                        'root_luks'

# Home
yes 'YES'                                       |
cryptsetup  luksFormat  --key-file  'luks.key'  \
                        "${home}1"              ||
[ "${pipestatus[2]}" = 0 ]
cryptsetup  open        --key-file  'luks.key'  \
                        "${home}1"              \
                        'home_luks'
