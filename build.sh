#!/bin/bash
set -e

# Configuration
OVERLAY_DIR="alpine-overlay"
OUTPUT_FILE="alpine-cloud-init.apkovl.tar.gz"

echo "--- 1. Preparing Workspace ---"
rm -rf $OVERLAY_DIR
mkdir -p $OVERLAY_DIR/etc/apk
mkdir -p $OVERLAY_DIR/etc/cloud/cloud.cfg.d
mkdir -p $OVERLAY_DIR/etc/runlevels/default

cd $OVERLAY_DIR

echo "--- 2. Configuring Repositories ---"
cat <<EOF > etc/apk/repositories
http://dl-cdn.alpinelinux.org/alpine/v3.23/main
http://dl-cdn.alpinelinux.org/alpine/v3.23/community
EOF

echo "--- 3. Defining Base Packages ---"
cat <<EOF > etc/apk/world
alpine-base
cloud-init
openssh
util-linux
e2fsprogs
e2fsprogs-extra
EOF

echo "--- 4. Enabling Services ---"
# Cloud-Init
ln -s /etc/init.d/cloud-init etc/runlevels/default/cloud-init
ln -s /etc/init.d/cloud-init-local etc/runlevels/default/cloud-init-local
ln -s /etc/init.d/cloud-config etc/runlevels/default/cloud-config
ln -s /etc/init.d/cloud-final etc/runlevels/default/cloud-final

# Networking & SSH
ln -s /etc/init.d/sshd etc/runlevels/default/sshd
ln -s /etc/init.d/networking etc/runlevels/default/networking

# Modloop
ln -s /etc/init.d/modloop etc/runlevels/default/modloop

echo "--- 5. Packing Overlay ---"
tar -czf ../$OUTPUT_FILE --owner=0 --group=0 *

echo "Build Complete: $OUTPUT_FILE"
