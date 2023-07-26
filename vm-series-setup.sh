#!/bin/bash
# Enkelt eksempel skript for kopiering og start av vm-serie på Proxmox

echo
echo "Lage en katalog, samt laste opp de to filene til Proxmox."
ssh -i proxmox-key root@192.168.10.30 "mkdir /var/lib/vz/template/qcow"
scp -i proxmox-key PA-VM-KVM-10.2.4.qcow2 root@192.168.10.30:/var/lib/vz/template/qcow
scp -i proxmox-key vm-series-bootstrap.iso root@192.168.10.30:/var/lib/vz/template/iso

echo
echo "Lage ein ny virtuell maskin med nummer 120 på Proxmox."
ssh -i proxmox-key root@192.168.10.30 \
"qm create 120 --name 'panos-vm-series' --memory 7000 --net0 virtio,bridge=vmbr0  -cpu host --cores 2"

echo 
echo "Kople fleire nettverks interfacer til ny virtuell maskin"
ssh -i proxmox-key root@192.168.10.30 \
"qm set 120 --net1 virtio,bridge=vmbr0"
ssh -i proxmox-key root@192.168.10.30 \
"qm set 120 --net2 virtio,bridge=vmbr0"

echo
echo "Importere boot image og knytte det til den nye virtuell maskinen."
ssh -i proxmox-key root@192.168.10.30 \
"qm importdisk 120 /var/lib/vz/template/qcow/PA-VM-KVM-10.2.4.qcow2 local-lvm"
ssh -i proxmox-key root@192.168.10.30 \
"qm set 120 --scsihw virtio-scsi-pci --scsi0 local-lvm:vm-120-disk-0"
ssh -i proxmox-key root@192.168.10.30 \
"qm set 120 --boot c --bootdisk scsi0"

echo
echo "Importere config iso fil og knytte det til den nye virtuell maskinen."
ssh -i proxmox-key root@192.168.10.30 \
"qm set 120 -cdrom /var/lib/vz/template/iso/vm-series-bootstrap.iso"

echo 
echo "Lage eit serial kopla til virtuell maskin (nødvendig for vm-serie i kvm)."
ssh -i proxmox-key root@192.168.10.30 \
"qm set 120 -serial0 socket"

echo
echo "Starte ny virtuell maskin"
ssh -i proxmox-key root@192.168.10.30 \
"qm start 120"