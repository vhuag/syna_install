#!/bin/bash

INSTALLER_MAJOR="1"
INSTALLER_MINOR="1"
echo "RPI4 android dev installer version: $INSTALLER_MAJOR.$INSTALLER_MINOR"

#function to install android development environment
function install_android_dev_env()
{
    echo ""
    echo "Install android development environment"
    echo ""
    sudo apt-get update
    sudo apt-get install git-core gnupg flex bison build-essential zip curl zlib1g-dev libc6-dev-i386 libncurses5 x11proto-core-dev libx11-dev lib32z1-dev libgl1-mesa-dev libxml2-utils xsltproc unzip fontconfig
    echo "Trying to install repo"
    export REPO=$(mktemp /tmp/repo.XXXXXXXXX)
    curl -o ${REPO} https://storage.googleapis.com/git-repo-downloads/repo
    gpg --recv-keys 8BB9AD793E8E6153AF0F9A4416530D5E920F5C65
    curl -s https://storage.googleapis.com/git-repo-downloads/repo.asc | gpg --verify - ${REPO} && install -m 755 ${REPO} ~/bin/repo
}

#function to download android rpi4 source code
function download_android_rpi4_source_code()
{
    echo ""
    echo "Download android rpi4 source code"
    echo ""
    sudo apt-get install bc coreutils dosfstools e2fsprogs fdisk kpartx mtools ninja-build pkg-config python3-pip
    sudo pip3 install meson mako jinja2 ply pyyaml dataclasses
    (
        mkdir -p aosp
        cd aosp
        repo init -u https://android.googlesource.com/platform/manifest -b android-13.0.0_r67
        curl --create-dirs -L -o .repo/local_manifests/manifest_brcm_rpi4.xml https://raw.githubusercontent.com/raspberry-vanilla/android_local_manifest/android-13.0/manifest_brcm_rpi4.xml
        repo sync
    )
}

#function to download android rpi4 kernel source code
function download_android_rpi4_kernel_source_code()
{
    echo ""
    echo "Download android rpi4 kernel source code"
    echo ""
    (
        mkdir -p kernel
        cd kernel
        repo init -u https://android.googlesource.com/kernel/manifest -b common-android13-5.15-lts
        curl --create-dirs -L -o .repo/local_manifests/manifest_brcm_rpi4.xml -O -L https://raw.githubusercontent.com/raspberry-vanilla/android_kernel_manifest/android-13.0/manifest_brcm_rpi4.xml
        repo sync
    )
}

#function to integrate kernel to aosp, this function should call integrate.sh in this folder
function integrate_kernel_to_aosp
{
    echo ""
    echo "Integrate kernel to aosp"
    echo ""
    #make sure there are aosp and kernel folder in this folder
    if [ ! -d "aosp" ]; then
        echo "aosp folder not found, please download android rpi4 source code first"
        return
    fi
    if [ ! -d "kernel" ]; then
        echo "kernel folder not found, please download android rpi4 kernel source code first"
        return
    fi
    #make sure integrate.sh is in this folder
    if [ ! -f "integrate.sh" ]; then
        echo "integrate.sh not found, please download build scripts first"
        return
    fi
    (
        ./integrate.sh
    )
}

#function to build kernel, this functino should call build_kernel.sh in this folder
function build_kernel()
{
    echo ""
    echo "Build kernel"
    echo ""
    #make sure there are aosp and kernel folder in this folder
    if [ ! -d "kernel" ]; then
        echo "kernel folder not found, please download android rpi4 kernel source code first"
        return
    fi
    #make sure build_kernel.sh is in this folder
    if [ ! -f "build_kernel.sh" ]; then
        echo "build_kernel.sh not found, please download build scripts first"
        return
    fi
    (
        ./build_kernel.sh
    )
    #ask user if they want to integrate kernel to aosp
    read -p "Do you want to integrate kernel to aosp? (y/n)" -n 1 -r
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        integrate_kernel_to_aosp
    fi
}

#function to build aosp, this function should call build_aosp.sh in this folder
function build_aosp()
{
    echo ""
    echo "Build aosp"
    echo ""
    #make sure there are aosp and kernel folder in this folder
    if [ ! -d "aosp" ]; then
        echo "aosp folder not found, please download android rpi4 source code first"
        return
    fi
    #make sure build_aosp.sh is in this folder
    if [ ! -f "build_aosp.sh" ]; then
        echo "build_aosp.sh not found, please download build scripts first"
        return
    fi
    (
        ./build_aosp.sh
    )
}




#function to download build scripts
function download_build_scripts()
{
    echo ""
    echo "Download build scripts"
    echo ""
    #make sure there are aosp and kernel folder in this folder
    if [ ! -d "aosp" ]; then
        echo "aosp folder not found, please download android rpi4 source code first"
        return
    fi
    if [ ! -d "kernel" ]; then
        echo "kernel folder not found, please download android rpi4 kernel source code first"
        return
    fi
    cat << 'EOF' > build_aosp.sh
#!/bin/bash
(
    cd aosp
    . build/envsetup.sh
    lunch aosp_rpi4-userdebug
    make bootimage systemimage vendorimage -j\$(nproc)
    ./rpi4-mkimg.sh
)
EOF
    chmod +x build_aosp.sh
    cat << 'EOF' > build_kernel.sh
#!/bin/bash
(
    cd kernel
    BUILD_CONFIG=common/build.config.rpi4 build/build.sh
)
EOF
    chmod +x build_kernel.sh
    cat << 'EOF' > integrate.sh
#!/bin/bash
(
    cp kernel/out/common/arch/arm64/boot/Image aosp/device/brcm/rpi4-kernel/
    echo "copied image done"
    cp kernel/out/common/arch/arm64/boot/dts/broadcom/*.dtb aosp/device/brcm/rpi4-kernel/
    echo "copied all dtb files"
    cp kernel/out/common/arch/arm64/boot/dts/overlays aosp/device/brcm/rpi4-kernel/ -r
    echo "overlays copied finished"
)
EOF
    chmod +x integrate.sh
}

# ... function definitions ...

function main_menu() {
    while true; do
        echo ""
        read -p "Choose the steps you want to do:
1 - install android development environment,
2 - download android rpi4 source code,
3 - download android rpi4 kernel source code,
4 - download build scripts,
5 - build aosp,
6 - build kernel,
7 - exit
" -n 1 -r

        # output change line
        echo ""

        #if user input invalid, just loop here and wait for valid input
        while [[ ! $REPLY =~ ^[1-7]$ ]]; do
            read -p "Invalid input, please input again:
" -n 1 -r
            echo ""
        done

        case $REPLY in
            1)
                read -p "Do you want to download android rpi4 source code? (y/n)" -n 1 -r
                if [[ $REPLY =~ ^[Yy]$ ]]; then
                    install_android_dev_env
                fi
                ;;
            2)
                read -p "Do you want to download android rpi4 source code? (y/n)" -n 1 -r
                if [[ $REPLY =~ ^[Yy]$ ]]; then
                    download_android_rpi4_source_code
                fi
                ;;
            3)
                read -p "Do you want to download android rpi4 kernel source code? (y/n)" -n 1 -r
                if [[ $REPLY =~ ^[Yy]$ ]]; then
                    download_android_rpi4_kernel_source_code
                fi
                ;;
            4)
                read -p "Do you want to download build scripts? (y/n)" -n 1 -r
                if [[ $REPLY =~ ^[Yy]$ ]]; then
                    download_build_scripts
                fi
                ;;
            5)
                read -p "Do you want to build aosp? (y/n)" -n 1 -r
                if [[ $REPLY =~ ^[Yy]$ ]]; then
                    build_aosp
                fi
                ;;
            6)
                read -p "Do you want to build kernel? (y/n)" -n 1 -r
                if [[ $REPLY =~ ^[Yy]$ ]]; then
                    build_kernel
                fi
                ;;
            7)
                exit 0
                ;;
        esac
    done
}

echo "Install android development environment for rpi4"
main_menu