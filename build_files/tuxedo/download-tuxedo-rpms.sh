#!/usr/bin/bash

set ${CI:+-x} -euo pipefail

# Cache TUXEDO Control Center from TUXEDO's official repository.
#
# TCC is userspace (Electron app + tccd daemon), not a kmod: we only cache the
# RPM so consuming images can install it without wiring up the TUXEDO repo
# themselves. Its "(tuxedo-drivers >= 4.0.0 or tuxedo-keyboard >= 3.1.2)"
# requirement is satisfied by tuxedo-drivers-kmod-common (built alongside the
# tuxedo-drivers akmod), which Provides: tuxedo-drivers.
#
# NOTE for consuming images: the RPM installs into /opt/tuxedo-control-center,
# which atomic/ostree images must handle at image build time (relocate to /usr
# and symlink, or equivalent), and tccd.service / tccd-sleep.service must be
# enabled.

ARCH="$(rpm -E '%_arch')"
RELEASE="$(rpm -E '%fedora')"

# TUXEDO only publishes x86_64 packages.
if [[ "${ARCH}" != "x86_64" ]]; then
    echo "Skipping tuxedo-control-center on ${ARCH}"
    exit 0
fi

# Mirrors https://rpm.tuxedocomputers.com/fedora/tuxedo.repo with $releasever
# pinned to the build release.
cat > /etc/yum.repos.d/tuxedo.repo <<EOF
[tuxedo]
name=Tuxedo - F${RELEASE}
baseurl=https://rpm.tuxedocomputers.com/fedora/${RELEASE}/x86_64/base/
enabled=1
gpgcheck=1
gpgkey=https://rpm.tuxedocomputers.com/fedora/${RELEASE}/0x54840598.pub.asc
skip_if_unavailable=False
EOF

mkdir -p /var/cache/rpms/common
dnf download --destdir /var/cache/rpms/common \
    tuxedo-control-center

rm -f /var/cache/rpms/common/*.src.rpm

rm -f /etc/yum.repos.d/tuxedo.repo
