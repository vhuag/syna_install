#/bin/bash

echo "Install for rmi4update_test"

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

TOKEN="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"
OWNER="vhuag"
REPO="spm"
PATH_TO_FILE="package/rmi4update_test/rmi4update_test.py"
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
#check if this is linux system
if [ "$OS" = "Linux" ]; then
    echo "Linux system."
else
    echo "System $OS is not supported."
    exit 1
fi
# copy the file to the destination /etc/spm/package/rmi4update_test
sudo cp $FILE_NAME $ROOT_DIR/$PATH_TO_FILE
sudo rm $FILE_NAME

echo "finished"