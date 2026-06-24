# Rollback

## Host
```bash
sudo virsh destroy ${VM_NAME}
sudo virsh undefine ${VM_NAME} --remove-all-storage
sudo virsh net-destroy ${LIBVIRT_NETWORK_NAME}
sudo virsh net-undefine ${LIBVIRT_NETWORK_NAME}
sudo systemctl disable --now wg-quick@${HOST_WG_IF}
sudo rm -f /etc/wireguard/${HOST_WG_IF}.conf
```

## VM
```bash
sudo systemctl disable --now colab-runtime
sudo docker swarm leave --force
sudo snap remove lxd
sudo systemctl disable --now wg-quick@${HOST_WG_IF}
sudo umount ${CEPHFS_MOUNT}
```

## Generated state
```bash
rm -rf generated/*
rm -rf .cache/cloud-images/*
```
