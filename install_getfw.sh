#/bin/bash

echo "Install for getfw script"
# Parse command-line arguments
for arg in "$@"
do
    case $arg in
        ROOT_DIR=*)
        ROOT_DIR="${arg#*=}"
        shift
        ;;
        *)
        # Unknown argument
        echo "Unknown argument: $arg"
        exit 1
        ;;
    esac
done

# Set ROOT_DIR if it is not already set
if [ -z "$ROOT_DIR" ]; then
    ROOT_DIR="/etc/spm"
fi
# Use ROOT_DIR in the script
echo "Using ROOT_DIR: $ROOT_DIR"

#TOKEN="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"
TOKEN_URL="http://pc.synaptics.com:8888/resources/driver1/spm/spm_token.txt"

TOKEN=$(curl -s -w "%{http_code}" -o /dev/null $TOKEN_URL)

if [ "$TOKEN" != "200" ]; then
    echo "Cannot retrieve token, check access rights to token URL"
    exit 1
fi


TOKEN=$(curl -s $TOKEN_URL)

OWNER="vhuag"
REPO="spm"
PATH_TO_FILE="package/getfw/get_firmware.sh"
FILE_NAME=$(basename $PATH_TO_FILE)

curl -f -H "Authorization: token $TOKEN" \
     -H 'Accept: application/vnd.github.v3.raw' \
     -o $FILE_NAME \
     -L https://api.github.com/repos/$OWNER/$REPO/contents/$PATH_TO_FILE



# Check if the curl command was successful
if [ $? -eq 0 ]; then
    echo "File downloaded successfully"
else
    echo "File download failed"
    exit 1
fi

OS=$(uname -s)
#check if this is linux system
if [ "$OS" = "Linux" ]; then
    echo "Linux system."
else
    echo "System $OS is not supported."
    exit 1
fi
# copy the file to the destination
sudo cp $FILE_NAME $ROOT_DIR/$PATH_TO_FILE
sudo rm $FILE_NAME

echo "finished"