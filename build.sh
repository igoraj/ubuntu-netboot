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
# We need 'community' for cloud-init
cat <<EOF > etc/apk/repositories
http://dl-cdn.alpinelinux.org/alpine/v3.23/main
http://dl-cdn.alpinelinux.org/alpine/v3.23/community
EOF

echo "--- 3. Defining Base Packages ---"
# ONLY packages required to boot and run cloud-init.
# We REMOVED nfs-utils, mdadm, etc.
cat <<EOF > etc/apk/world
alpine-base
cloud-init
# e2fsprogs is useful to keep in base for cloud-init's fs_setup module, 
# but you can move it to user-data if you really want minimal.
e2fsprogs 
EOF

echo "--- 4. Enabling Services ---"
# Link Cloud-Init services to default runlevel
ln -s /etc/init.d/cloud-init etc/runlevels/default/cloud-init
ln -s /etc/init.d/cloud-init-local etc/runlevels/default/cloud-init-local
ln -s /etc/init.d/cloud-config etc/runlevels/default/cloud-config
ln -s /etc/init.d/cloud-final etc/runlevels/default/cloud-final

# Enable Networking (standard alpine networking)
ln -s /etc/init.d/networking etc/runlevels/default/networking

echo "--- 5. Configuring Cloud-Init ---"
# Force the 'nocloud' datasource so it doesn't waste time waiting for EC2/GCP metadata services
cat <<EOF > etc/cloud/cloud.cfg.d/10_datasource.cfg
datasource_list: [ NoCloud, None ]
datasource:
  NoCloud:
    seedfrom: /kernel-command-line
EOF

echo "--- 6. Packing Overlay ---"
# Tarball must be owned by root.
# Since GitHub Actions runner is often not root, we use --owner=0 --group=0 
# to fake root ownership inside the tarball.
tar -czf ../$OUTPUT_FILE --owner=0 --group=0 *

echo "Build Complete: $OUTPUT_FILE"