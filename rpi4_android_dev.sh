#!/bin/bash

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

#function to download build scripts
function download_build_scripts()
{
    echo ""
    echo "Download build scripts"
    echo ""
    
}


echo "Install android development environment for rpi4"

read -p "Choose the steps you want to do:
1 - install android development environment,
2 - download android rpi4 source code,
3 - download android rpi4 kernel source code,
4 - download build scripts
" -n 1 -r

# output change line
echo ""

#if user input invalid, just loop here and wait for valid input
while [[ ! $REPLY =~ ^[1-4]$ ]]; do
    read -p "Invalid input, please input again:
" -n 1 -r
    echo ""
done

#if user choose 1
if [[ $REPLY =~ ^[1]$ ]]; then
    read -p "Do you want to download android rpi4 source code? (y/n)" -n 1 -r
    #if they want to download android rpi4 source code
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        #call function to download android rpi4 source code
        install_android_dev_env
    fi
    exit 1
#if user choose 2
elif [[ $REPLY =~ ^[2]$ ]]; then
    read -p "Do you want to download android rpi4 source code? (y/n)" -n 1 -r
    #if they want to download android rpi4 source code
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        #call function to download android rpi4 source code
        download_android_rpi4_source_code
    fi
    exit 1
#if user choose 3
elif [[ $REPLY =~ ^[3]$ ]]; then
    read -p "Do you want to download android rpi4 kernel source code? (y/n)" -n 1 -r
    #if they want to download android rpi4 kernel source code
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        #call function to download android rpi4 kernel source code
        download_android_rpi4_kernel_source_code
    fi
    exit 1
#if user choose 4
elif [[ $REPLY =~ ^[4]$ ]]; then
    read -p "Do you want to download build scripts? (y/n)" -n 1 -r
    #if they want to download build scripts
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        #call function to download build scripts
        download_build_scripts
    fi
    exit 1
fi