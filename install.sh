#!/bin/bash
INSTALLER_MAJOR="1"
INSTALLER_MINOR="42"
echo "Installer version: $INSTALLER_MAJOR.$INSTALLER_MINOR"

# Check if a version number was provided
if [ -z "$1" ]; then
    echo "No version specified, will get latest one."
fi


# Determine the architecture of the system
ARCH=$(uname -m)
echo "Architecture: $ARCH"
BINARCH=""
# Adjust the architecture string to match the one used in your .deb file names
if [ "$ARCH" = "x86_64" ]; then
    ARCH="amd64"
    BINARCH="x86-64"
elif [ "$ARCH" = "aarch64" ]; then
    ARCH="arm64"
    BINARCH="arm"
elif [ "$ARCH" = "i686" ]; then
    ARCH="i386"
    BINARCH="i386"
elif [ "$ARCH" = "armv7l" ]; then
    ARCH="armhf"
    BINARCH="arm"
else
    echo "Unsupported architecture: $ARCH"
    exit 1
fi

OS=$(uname -s)
if [ "$OS" = "Linux" ]; then
    if [ -f "/etc/chrome_dev.conf" ]; then
        echo "Chrome OS system."
        OS="ChromeOS"
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

API_URL="https://api.github.com/repos/vhuag/rmi4utils/releases"



if [ "$OS" = "ChromeOS" ]; then
    #VERSION=${1:-$(curl -s $API_URL/latest | grep -Po '"tag_name": "\K.*?(?=")')}
    if [ -z "$1" ]; then
        echo "Need to input version on chromeOS."
        exit 1
    fi
    VERSION=$1
    echo "Installing rmi4update v${VERSION}..."
    echo "Install for chromeOS"
    BIN_URL="https://github.com/vhuag/rmi4utils/releases/download/v${VERSION}/rmi4update_${BINARCH}"
    echo "Download from $BIN_URL"
    # Download the .deb file
    curl -f -L -O "$BIN_URL"
    # Check if curl was successful
    if [ $? -ne 0 ]; then
        echo "Failed to download file, the version may be invalid."
        exit 1
    fi
    cp rmi4update_${BINARCH} /usr/local/bin/rmi4update
    sudo chmod +x /usr/local/bin/rmi4update

else
    VERSION=${1:-$(curl -s $API_URL/latest | grep -Po '"tag_name": "\K.*?(?=")')}
    VERSION=${VERSION#v}
    echo "Installing rmi4utils v${VERSION}..."
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


TOKEN_URL="http://pc.synaptics.com:8888/resources/driver1/spm/spm_token.txt"
TOKEN=$(curl -s -w "%{http_code}" -o /dev/null $TOKEN_URL)

if [ "$TOKEN" != "200" ]; then
    echo "Cannot retrieve token, check access rights to token URL"
    exit 1
fi
echo "Trying to install spm"

TOKEN=$(curl -s $TOKEN_URL)
OWNER="vhuag"
REPO="spm"
PATH_TO_FILE="spm"
SPM_FILE_NAME=$(basename $PATH_TO_FILE)

curl -f -H "Authorization: token $TOKEN" \
     -H 'Accept: application/vnd.github.v3.raw' \
     -o $SPM_FILE_NAME \
     -L https://api.github.com/repos/$OWNER/$REPO/contents/$PATH_TO_FILE

# Check if the curl command was successful
if [ $? -eq 0 ]; then
    echo "spm downloaded successfully"
else
    echo "spm download failed"
    exit 1
fi

sudo chmod +x $SPM_FILE_NAME

PATH_TO_FILE="spm.json"
JSON_FILE_NAME="spm.json_"

curl -f -H "Authorization: token $TOKEN" \
     -H 'Accept: application/vnd.github.v3.raw' \
     -o $JSON_FILE_NAME \
     -L https://api.github.com/repos/$OWNER/$REPO/contents/$PATH_TO_FILE

# Check if the curl command was successful
if [ $? -eq 0 ]; then
    echo "cfg downloaded successfully"
else
    echo "cfg download failed"
    exit 1
fi

sudo mkdir -p /etc/spm
sudo mv $SPM_FILE_NAME /etc/spm/spm
sudo ln -s /etc/spm/spm /usr/local/bin/spm
sudo mv $JSON_FILE_NAME /etc/spm/spm.json
sudo mkdir -p /etc/spm/package
echo "spm installed successfully"

# Echo a success message
echo "Installation complete."