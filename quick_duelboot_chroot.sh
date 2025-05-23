#!/bin/bash


if [ -z "$1" ]; then
  echo "No argument provided"
  exit 1
fi

PARTITION="/dev/$1"
TARGET="/mnt/$1/"
TARGET_EXISTS=1

if [ ! -e "$PARTITION" ]; then
    echo "That partition does not exist"
    exit 1
fi

# Ensure the script is run with sudo
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root. Try again with 'sudo'" 
   exit 1
fi

echo "Creating mount point files..."
# Check if the mount point already exists
if [ ! -d "$TARGET" ]; then
    # If it doesn't exist, create it
    mkdir "$TARGET"
    TARGET_EXISTS=0

    # If it does, check if it is empty
elif [ -n "$(ls -A $TARGET)" ]; then
    echo "The mount point $TARGET is not empty and may be already mounted"
    exit 1
fi

# Mount the partition to the target
echo "Mounting partition..."
sudo mount "$PARTITION" "$TARGET"

# Mount necessary filesystems
echo "Mounting system directories into chroot..."
mount --bind /dev "$TARGET/dev"
mount --bind /dev/pts "$TARGET/dev/pts"
mount --bind /proc "$TARGET/proc"
mount --bind /sys "$TARGET/sys"
mount --bind /run "$TARGET/run"
mount --bind /tmp "$TARGET/tmp"

# Enter the chroot
echo "Entering chroot environment in $TARGET..."
chroot "$TARGET" /bin/bash

# After exiting chroot, unmount everything
echo "Cleaning up mounts..."
umount -l "$TARGET/dev/pts"
umount -l "$TARGET/dev"
umount -l "$TARGET/proc"
umount -l "$TARGET/sys"
umount -l "$TARGET/run"
umount -l "$TARGET/tmp"

echo "Unmounting partition..."
umount "$PARTITION"

# Clean up created files
# Leave them if they already existed
if [ "$TARGET_EXISTS" -eq 0 ]; then
    echo "Cleaning mount point files..."
    rm -d "$TARGET"
fi

echo "Done."
