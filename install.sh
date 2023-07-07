#!/bin/bash
INSTALLER_MAJOR="1"
INSTALLER_MINOR="10"
echo "Installer version: $INSTALLER_MAJOR.$INSTALLER_MINOR"

# Check if a version number was provided
if [ -z "$1" ]; then
    echo "No version specified, will get latest one."
fi

API_URL="https://api.github.com/repos/vhuag/rmi4utils/releases"
VERSION=${1:-$(curl -s $API_URL/latest | grep -Po '"tag_name": "\K.*?(?=")')}
VERSION=${VERSION#v}
echo "Installing rmi4utils v${VERSION}..."
# Determine the architecture of the system
ARCH=$(uname -m)
echo "Architecture: $ARCH"

# Adjust the architecture string to match the one used in your .deb file names
if [ "$ARCH" = "x86_64" ]; then
    ARCH="amd64"
elif [ "$ARCH" = "aarch64" ]; then
    ARCH="arm64"
elif [ "$ARCH" = "i686" ]; then
    ARCH="i386"
elif [ "$ARCH" = "armv7l" ]; then
    ARCH="armhf"
else
    echo "Unsupported architecture: $ARCH"
    exit 1
fi

OS=$(uname -s)
if [ "$OS" = "Linux" ]; then
    if [ -f "/etc/chrome_dev.conf" ]; then
        echo "Chrome OS system."
        $OS="ChromeOS"
    else
        echo "Linux system."
    fi
elif [ "$OS" = "Darwin" ]; then
    echo "MacOS system is not supported yet."
    exit 1
elif [[ "$OS" == MINGW64_NT-10.0* ]]; then
    echo "Windows system is not supported yet."
    exit 1
else
    echo "System not recognized."
    exit 1
fi




if [ "$OS" = "ChromeOS" ]; then
    echo "Install for chromeOS"
    if [ "$ARCH" = "x86_64" ]; then
        BINARCH="x86-64"
    elif [ "$ARCH" = "aarch64" ]; then
        BINARCH="arm"
    elif [ "$ARCH" = "i686" ]; then
        BINARCH="i386"
    elif [ "$ARCH" = "armv7l" ]; then
        BINARCH="arm"
    BIN_URL="https://github.com/vhuag/rmi4utils/releases/download/v${VERSION}/rmi4update_${BINARCH}"
    # Download the .deb file
    curl -f -L -O "$BIN_URL"
    # Check if curl was successful
    if [ $? -ne 0 ]; then
        echo "Failed to download file, the version may be invalid."
        exit 1
    fi

elif
    # Set the URL of your .deb file
    DEB_URL="https://github.com/vhuag/rmi4utils/releases/download/v${VERSION}/rmi4utils_${VERSION}_${ARCH}.deb"

    # Download the .deb file
    curl -f -L -O "$DEB_URL"

    # Check if curl was successful
    if [ $? -ne 0 ]; then
        echo "Failed to download file, the version may be invalid."
        exit 1
    fi
    # Extract the filename from the URL
    DEB_FILE=$(basename "$DEB_URL")

    # Install the .deb file
    sudo dpkg -i "$DEB_FILE"

    # Remove the .deb file
    rm "$DEB_FILE"

    # If there are any missing dependencies, try to install them
    sudo apt-get install -f

    # Check if SSH is installed and running
    SSH_STATUS=$(systemctl is-active ssh)

    if [ "$SSH_STATUS" = "inactive" ]; then
        if [ "$ARCH" = "aarch64" ] || [ "$ARCH" = "armv7l" ]; then
            sudo apt-get update
        fi
        sudo apt install openssh-server
        sudo systemctl enable ssh
        sudo systemctl start ssh
    else
        echo "SSH is already installed and active."
    fi
fi
# Echo a success message
echo "Installation complete."