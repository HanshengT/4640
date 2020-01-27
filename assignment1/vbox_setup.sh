#!/bin/bash

# This is a shortcut function that makes it shorter and more readable
vbmg () { C:/Program\ Files/Oracle/VirtualBox/VBoxManage.exe "$@"; }

# If you are using a Mac, you can just use
# vbmg () { VBoxManage "$@"; }

NET_NAME="4640"
VM_NAME="VM4640"
SSH_PORT="8022"
WEB_PORT="8000"

# This function will clean the NAT network and the virtual machine
clean_all () {
    vbmg natnetwork remove --netname "$NET_NAME"
    vbmg unregistervm "$VM_NAME" --delete
}

create_network () {
    vbmg natnetwork add --netname "$NET_NAME" --network 192.168.230.0/24 \
    --enable

    vbmg natnetwork modify --netname "$NET_NAME" --dhcp off\
    --port-forward-4 "my_rule:tcp:[127.0.0.1]:$SSH_PORT:[192.168.230.10]:22"\
    --port-forward-4 "my_rule2:tcp:[127.0.0.1]:$WEB_PORT:[192.168.230.10]:80"
}

create_vm () {
    vbmg createvm --name "$VM_NAME" --ostype "RedHat_64" --register
    vbmg modifyvm "$VM_NAME" --memory 1024 --vram 16 --acpi on --boot1 dvd --nic1 natnetwork --nat-network1 "$NET_NAME"

    SED_PROGRAM="/^Config file:/ { s/^.*:\s\+\(\S\+\)/\1/; s|\\\\|/|gp }"
    VBOX_FILE=$(vbmg showvminfo "$VM_NAME" | sed -ne "$SED_PROGRAM")
	VM_DIR=$(dirname "$VBOX_FILE")

    vbmg createmedium disk --filename "$VM_DIR/$VM_NAME".vdi --size 10000
    
    vbmg storagectl "$VM_NAME" --name "IDE Controller" --add ide --controller PIIX4 
    vbmg storagectl "$VM_NAME" --name "SATA Controller" --add sata --controller IntelAhci --portcount 1

    vbmg storageattach "$VM_NAME" --storagectl "IDE Controller" --port 0 --device 1 --type dvddrive --medium D:/VB\ backup/CentOS-7-x86_64-Minimal-1908.iso
    vbmg storageattach "$VM_NAME" --storagectl "SATA Controller" --port 0 --device 0 --type hdd --medium "$VM_DIR/$VM_NAME".vdi
}

echo "Starting script..."

clean_all
create_network
create_vm

echo "DONE!"
