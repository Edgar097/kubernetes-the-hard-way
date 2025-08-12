#!/usr/bin/env bash
#
# setup-lvm-k8s.sh
#
# This script:
# - Creates an LVM volume
# - Mounts it
# - Sets up Kubernetes bind mounts
# - Disables swap
# - Enables IP forwarding
# - Loads required kernel modules
# - Applies required sysctl settings
#

set -e

# -------------------------------------------
# Configurable variables
# -------------------------------------------

DISK="/dev/sdb"
VG_NAME="data-vg"
LV_NAME="data"
LV_SIZE="100%FREE"
MOUNT_POINT="/mnt/data"
FS_TYPE="ext4"
NODE_ROLE="control-plane"   # or "worker"

# -------------------------------------------
# System prep
# -------------------------------------------

echo "✅ Disabling swap..."
swapoff -a
sed -i '/swap/d' /etc/fstab

echo "✅ Enabling IP forwarding..."
echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
echo "net.ipv6.conf.all.forwarding=1" >> /etc/sysctl.conf

echo "✅ Loading kernel modules..."
modprobe overlay
modprobe br_netfilter

echo "✅ Writing kernel modules to /etc/modules-load.d/k8s.conf..."
cat <<EOF | tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

echo "✅ Writing sysctl settings to /etc/sysctl.d/k8s.conf..."
cat <<EOF | tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF

sysctl --system

# -------------------------------------------
# LVM Setup
# -------------------------------------------

if [ ! -b "$DISK" ]; then
  echo "ERROR: Disk device $DISK does not exist."
  exit 1
fi

if [[ "$FS_TYPE" != "ext4" && "$FS_TYPE" != "xfs" ]]; then
  echo "ERROR: Filesystem type must be 'ext4' or 'xfs'."
  exit 1
fi

if [[ "$NODE_ROLE" != "control-plane" && "$NODE_ROLE" != "worker" ]]; then
  echo "ERROR: NODE_ROLE must be 'control-plane' or 'worker'."
  exit 1
fi

echo "✅ Creating physical volume on $DISK..."
pvcreate "$DISK"

echo "✅ Creating volume group $VG_NAME..."
vgcreate "$VG_NAME" "$DISK"

echo "✅ Creating logical volume $LV_NAME with size $LV_SIZE..."
lvcreate -l "$LV_SIZE" -n "$LV_NAME" "$VG_NAME"

if [ "$FS_TYPE" = "ext4" ]; then
  echo "✅ Formatting as ext4..."
  mkfs.ext4 "/dev/$VG_NAME/$LV_NAME"
else
  echo "✅ Formatting as xfs..."
  mkfs.xfs "/dev/$VG_NAME/$LV_NAME"
fi

echo "✅ Creating mount point $MOUNT_POINT..."
mkdir -p "$MOUNT_POINT"

echo "✅ Adding LVM mount to /etc/fstab..."
echo "/dev/$VG_NAME/$LV_NAME $MOUNT_POINT $FS_TYPE defaults 0 0" >> /etc/fstab

echo "✅ Mounting LVM volume..."
mount -a

echo "✅ Creating Kubernetes data directories..."
mkdir -p "$MOUNT_POINT/k8s/containerd"
mkdir -p "$MOUNT_POINT/k8s/kubelet"
if [ "$NODE_ROLE" = "control-plane" ]; then
  mkdir -p "$MOUNT_POINT/k8s/etcd"
fi

echo "✅ Creating target directories in /var/lib..."
mkdir -p /var/lib/containerd
mkdir -p /var/lib/kubelet
if [ "$NODE_ROLE" = "control-plane" ]; then
  mkdir -p /var/lib/etcd
fi

echo "✅ Adding bind mounts to /etc/fstab..."
echo "$MOUNT_POINT/k8s/containerd /var/lib/containerd none bind 0 0" >> /etc/fstab
echo "$MOUNT_POINT/k8s/kubelet /var/lib/kubelet none bind 0 0" >> /etc/fstab
if [ "$NODE_ROLE" = "control-plane" ]; then
  echo "$MOUNT_POINT/k8s/etcd /var/lib/etcd none bind 0 0" >> /etc/fstab
fi

echo "✅ Mounting Kubernetes bind mounts..."
mount -a

echo "🎉 All done!"
echo "✅ $MOUNT_POINT is mounted and Kubernetes directories are bound:"
echo "   - /var/lib/containerd"
echo "   - /var/lib/kubelet"
if [ "$NODE_ROLE" = "control-plane" ]; then
  echo "   - /var/lib/etcd"
fi
sed -i \
  's/^#*PermitRootLogin.*/PermitRootLogin yes/' \
  /etc/ssh/sshd_config
systemctl restart sshd