#!/bin/bash
# Script outline to install and build kernel.
# Author: Siddhant Jajoo.

set -e
set -u

OUTDIR=/tmp/aeld
KERNEL_REPO=git://git.kernel.org/pub/scm/linux/kernel/git/stable/linux-stable.git
KERNEL_VERSION=v5.15.163
BUSYBOX_VERSION=1_33_1
FINDER_APP_DIR=$(realpath $(dirname $0))
ARCH=arm64
CROSS_COMPILE=aarch64-none-linux-gnu-
MAKEJOBS=$(nproc)
if [ $# -lt 1 ]
then
	echo "Using default directory ${OUTDIR} for output"
else
	OUTDIR=$1
	echo "Using passed directory ${OUTDIR} for output"
fi

mkdir -p ${OUTDIR}

cd "$OUTDIR"
if [ ! -d "${OUTDIR}/linux-stable" ]; then
    #Clone only if the repository does not exist.
	echo "CLONING GIT LINUX STABLE VERSION ${KERNEL_VERSION} IN ${OUTDIR}"
	git clone ${KERNEL_REPO} --depth 1 --single-branch --branch ${KERNEL_VERSION}
fi
if [ ! -e ${OUTDIR}/linux-stable/arch/${ARCH}/boot/Image ]; then
    cd linux-stable
    echo "Checking out version ${KERNEL_VERSION}"
    git checkout ${KERNEL_VERSION}

    # TODO: Add your kernel build steps here

     echo "Building kernel (ARCH=${ARCH})..."
    # ensure a clean starting point
    make mrproper
    # basic defconfig (generic)
    make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} defconfig
    # build Image and dtbs
    make -j${MAKEJOBS} ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} Image
    make -j${MAKEJOBS} ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} dtbs
fi

echo "Adding the Image in outdir"
  cp ${OUTDIR}/linux-stable/arch/${ARCH}/boot/Image ${OUTDIR}/Image  # ADD THIS LINE

echo "Creating the staging directory for the root filesystem"
cd "$OUTDIR"
if [ -d "${OUTDIR}/rootfs" ]
then
	echo "Deleting rootfs directory at ${OUTDIR}/rootfs and starting over"
    sudo rm  -rf ${OUTDIR}/rootfs
fi

# TODO: Create necessary base directories


echo "Creating the rootfs staging directory"
mkdir -p "${OUTDIR}/rootfs"
cd "${OUTDIR}/rootfs"


mkdir -p bin dev etc home root lib lib64 mnt proc sbin sys tmp usr var
mkdir -p usr/bin usr/sbin usr/lib var/log




cd "$OUTDIR"
if [ ! -d "${OUTDIR}/busybox" ]
then
git clone git://busybox.net/busybox.git
    cd busybox
    git checkout ${BUSYBOX_VERSION}
    # TODO:  Configure busybox



      echo "Configuring BusyBox"
    make distclean || true
    # default config then enable static
    make defconfig
    # enable static: set CONFIG_STATIC=y in .config if not set
    if ! grep -q "CONFIG_STATIC=y" .config 2>/dev/null; then
        sed -i 's/# CONFIG_STATIC is not set/CONFIG_STATIC=y/' .config || true
    fi



else
    cd busybox
fi

# TODO: Make and install busybox

# Configure busybox
echo "Configuring BusyBox..."
make distclean || true
make defconfig

# Enable static compilation
if ! grep -q "CONFIG_STATIC=y" .config; then
    sed -i 's/# CONFIG_STATIC is not set/CONFIG_STATIC=y/' .config
fi


echo "Building BusyBox (cross-compile)"
make -j${MAKEJOBS} CROSS_COMPILE=${CROSS_COMPILE}
echo "Installing BusyBox into rootfs"
make CONFIG_PREFIX=${OUTDIR}/rootfs CROSS_COMPILE=${CROSS_COMPILE} install





echo "Library dependencies"
#${CROSS_COMPILE}readelf -a bin/busybox | grep "program interpreter"
#${CROSS_COMPILE}readelf -a bin/busybox | grep "Shared library"


${CROSS_COMPILE}readelf -a ${OUTDIR}/rootfs/bin/busybox | grep "program interpreter" || echo "Could not read dependencies"
${CROSS_COMPILE}readelf -a ${OUTDIR}/rootfs/bin/busybox | grep "Shared library" || echo "Static binary or no shared libraries"



# TODO: Add library dependencies to rootfs
echo "Adding library dependencies from cross toolchain sysroot"
SYSROOT=$(${CROSS_COMPILE}gcc -print-sysroot)
echo "Detected sysroot: ${SYSROOT}"

# For aarch64, runtime loader is usually in lib/ or lib64
# Copy loader and required libs if they exist
if [ -d "${SYSROOT}/lib" ]; then
    mkdir -p "${OUTDIR}/rootfs/lib"
    cp -a "${SYSROOT}/lib/"*.so* "${OUTDIR}/rootfs/lib/" 2>/dev/null || true
fi
if [ -d "${SYSROOT}/lib64" ]; then
    mkdir -p "${OUTDIR}/rootfs/lib64"
    cp -a "${SYSROOT}/lib64/"*.so* "${OUTDIR}/rootfs/lib64/" 2>/dev/null || true
fi
# copy dynamic loader if present
if [ -e "${SYSROOT}/lib/ld-linux-aarch64.so.1" ]; then
    cp -a "${SYSROOT}/lib/ld-linux-aarch64.so.1" "${OUTDIR}/rootfs/lib/"
elif [ -e "${SYSROOT}/lib64/ld-linux-aarch64.so.1" ]; then
    cp -a "${SYSROOT}/lib64/ld-linux-aarch64.so.1" "${OUTDIR}/rootfs/lib64/"
fi

# TODO: Make device nodes
echo "Creating device nodes (requires sudo)"
sudo mknod -m 666 ${OUTDIR}/rootfs/dev/null c 1 3 || true
sudo mknod -m 600 ${OUTDIR}/rootfs/dev/console c 5 1 || true

# TODO: Create init script
echo "Creating init script"
cat > "${OUTDIR}/rootfs/init" << 'EOF'
#!/bin/sh
# Minimal init for initramfs
mount -t proc none /proc
mount -t sysfs none /sys
echo "Booted initramfs. Running /bin/sh on console."
# If autorun script exists in /home, run it (non-blocking)
if [ -x /home/autorun-qemu.sh ]; then
  /home/autorun-qemu.sh &
fi
# Provide interactive sh on console
exec /bin/sh
EOF
chmod +x "${OUTDIR}/rootfs/init"

# TODO: Clean and build the writer utility
echo "Building writer utility"
cd ${FINDER_APP_DIR}
make clean
make CROSS_COMPILE=${CROSS_COMPILE}
mkdir -p ${OUTDIR}/rootfs/home
cp writer ${OUTDIR}/rootfs/home/

# TODO: Copy the finder related scripts and executables to the /home directory
# on the target rootfs
echo "Copying finder scripts, conf files and autorun script"
mkdir -p "${OUTDIR}/rootfs/home"
# finder.sh, finder-test.sh, conf/... and autorun expected to be in finder-app parent or current dir
# copy if available
for f in finder.sh finder-test.sh autorun-qemu.sh; do
    if [ -f "${FINDER_APP_DIR}/${f}" ]; then
        cp "${FINDER_APP_DIR}/${f}" "${OUTDIR}/rootfs/home/"
    elif [ -f "${FINDER_APP_DIR}/../${f}" ]; then
        cp "${FINDER_APP_DIR}/../${f}" "${OUTDIR}/rootfs/home/"
    fi
done

# copy conf files
if [ -d "${FINDER_APP_DIR}/conf" ]; then
    mkdir -p "${OUTDIR}/rootfs/home/conf"
    cp -a "${FINDER_APP_DIR}/conf/"* "${OUTDIR}/rootfs/home/conf/" || true
elif [ -d "${FINDER_APP_DIR}/../conf" ]; then
    mkdir -p "${OUTDIR}/rootfs/home/conf"
    cp -a "${FINDER_APP_DIR}/../conf/"* "${OUTDIR}/rootfs/home/conf/" || true
fi

# Ensure finder-test.sh references conf/assignment.txt (not ../conf/...)
if [ -f "${OUTDIR}/rootfs/home/finder-test.sh" ]; then
    sed -i 's|\.\./conf/assignment.txt|conf/assignment.txt|g' "${OUTDIR}/rootfs/home/finder-test.sh" || true
    chmod +x "${OUTDIR}/rootfs/home/finder-test.sh"
fi

# Make autorun script executable if present
if [ -f "${OUTDIR}/rootfs/home/autorun-qemu.sh" ]; then
    chmod +x "${OUTDIR}/rootfs/home/autorun-qemu.sh"
fi

# TODO: Chown the root directory
echo "Setting ownership to root:root for rootfs"
sudo chown -R root:root "${OUTDIR}/rootfs" || true

# TODO: Create initramfs.cpio.gz
echo "Creating initramfs.cpio.gz at ${OUTDIR}/initramfs.cpio.gz"
cd "${OUTDIR}/rootfs"
# ensure files permissions are set
find . -print | cpio -o -H newc --owner root:root | gzip > "${OUTDIR}/initramfs.cpio.gz"

echo "Build complete."
echo "Files created:"
echo "  Kernel Image: ${OUTDIR}/Image"
echo "  Initramfs:    ${OUTDIR}/initramfs.cpio.gz"
echo "  Rootfs dir:   ${OUTDIR}/rootfs"
echo ""
echo "To start QEMU (example):"
echo "qemu-system-aarch64 -M virt -cpu cortex-a53 -m 1024 -nographic \\"
echo "  -kernel ${OUTDIR}/Image -initrd ${OUTDIR}/initramfs.cpio.gz -append 'console=ttyAMA0 init=/init'"

exit 0




# TODO: Add library dependencies to rootfs

# TODO: Make device nodes

# TODO: Clean and build the writer utility

# TODO: Copy the finder related scripts and executables to the /home directory
# on the target rootfs

# TODO: Chown the root directory

# TODO: Create initramfs.cpio.gz
