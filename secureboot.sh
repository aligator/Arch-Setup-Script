#!/bin/bash

sudo pacman -S --noconfirm sbctl efitools openssl jq
sbctl status

secureBoot=$(sbctl status --json | jq '.secure_boot')
if [ "$secureBoot" == "false" ]; then
        echo "Secure Boot is disabled. Please enable it in the BIOS/UEFI settings and restart this script."
        echo "https://wiki.archlinux.org/title/Unified_Extensible_Firmware_Interface/Secure_Boot#Enabling_Secure_Boot"
        exit 1
fi

setupMode=$(sbctl status --json | jq '.setup_mode')
if [ "$setupMode" == "false" ]; then
        echo "Setup Mode is disabled. Please enable it in the BIOS/UEFI settings and restart this script."
        echo "https://wiki.archlinux.org/title/Unified_Extensible_Firmware_Interface/Secure_Boot#Putting_firmware_in_%22Setup_Mode%22"
        exit 1
fi

setupMode=$(sbctl status --json | jq '.installed')
if [ "$setupMode" == "true" ]; then
        echo "sbctl is already installed."
        exit 1
fi
sudo sbctl create-keys

echo "Warning: Some firmware is signed and verified with Microsoft's keys when secure boot is enabled. Not validating devices could brick them."
echo "Only do this if you know what you are doing."
read -r -p "If you want to skip the Microsoft keys type 'without microsoft keys' else just press Enter" response
if [ "$response" == "without microsoft keys" ]; then
        echo enroll without microsoft keys
        sbctl enroll-keys
else
        echo enroll with microsoft keys
        sbctl enroll-keys -m
fi

sbctl status
sudo sbctl verify
sudo sbctl sign -s /boot/vmlinuz-linux
sudo sbctl sign -s /boot/efi/EFI/GRUB/grubx64.efi

echo "sbctl contains a pacman hook to sign the kernel and grub on updates automatically from now on."
echo "Now reboot and check again with 'sbctl status'"
