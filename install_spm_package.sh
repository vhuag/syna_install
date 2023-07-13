#/bin/bash

for arg in "$@"
do
  key=$(echo $arg | cut -f1 -d=)
  value=$(echo $arg | cut -f2 -d=)

  case $key in
    ROOT_DIR)   ROOT_DIR=$value;;
    PACKAGE)  PACKAGE=$value;;
    BIN_NAME)  BIN_NAME=$value;;
    *)
    echo "Invalid argument $key"
    exit 1
    ;;
  esac
done

echo "Install for $PACKAGE"
echo "ROOT_DIR=$ROOT_DIR"
echo "PACKAGE=$PACKAGE"
echo "BIN_NAME=$BIN_NAME"

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
DIR_PATH="package/$PACKAGE"
PATH_TO_FILE="$DIR_PATH/$BIN_NAME"
FILE_NAME=$(basename $PATH_TO_FILE)


# Get list of all files in the directory
files_json=$(curl -H "Authorization: token $TOKEN" \
  https://api.github.com/repos/$OWNER/$REPO/contents/$DIR_PATH)

# Parse the JSON response to get an array of all the file paths
file_paths=$(python3 -c "import json; print([item['path'] for item in json.loads('''$files_json''')])")

print(file_paths)

# Convert python list (string format) to bash array
file_paths=($(echo $file_paths | tr -d '[],'))

print(file_paths)

# Iterate over the array and download each file
for file_path in "${file_paths[@]}"
do
  FILE_NAME=$(basename $file_path)
  TEMP_FILE_NAME="_$FILE_NAME" # temporary filename
  curl -f -H "Authorization: token $TOKEN" \
    -H 'Accept: application/vnd.github.v3.raw' \
    -o $TEMP_FILE_NAME \
    -L https://api.github.com/repos/$OWNER/$REPO/contents/$file_path

  # Check if the curl command was successful
  if [ $? -eq 0 ]; then
    echo "File $TEMP_FILE_NAME downloaded successfully"
    # Check if the destination directory exists
    if [ ! -d "$ROOT_DIR/$DIR_PATH" ]; then
        sudo mkdir -p $ROOT_DIR/$DIR_PATH
    fi
    # Move and rename the file back to its original name
    sudo mv $TEMP_FILE_NAME $ROOT_DIR/$file_path
  else
    echo "File download failed"
    exit 1
  fi
done


echo completed
exit 1




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

# Generate the test script filename
TEST_BIN_NAME="test_$BIN_NAME"

# Download the test script
TEST_PATH_TO_FILE="package/$PACKAGE/$TEST_BIN_NAME"
TEST_FILE_NAME=$(basename $TEST_PATH_TO_FILE)

curl -f -H "Authorization: token $TOKEN" \
     -H 'Accept: application/vnd.github.v3.raw' \
     -o $TEST_FILE_NAME \
     -L https://api.github.com/repos/$OWNER/$REPO/contents/$TEST_PATH_TO_FILE

# Check if the curl command was successful
if [ $? -eq 0 ]; then
    echo "$TEST_FILE_NAME downloaded successfully"
else
    echo "no TEST file found, skip it"
    if [ -f "$TEST_FILE_NAME" ]; then
        sudo rm $TEST_FILE_NAME
    fi
    # No need to exit if the test file is not present
fi


OS=$(uname -s)
#check if this is linux system
if [ "$OS" = "Linux" ]; then
    echo "Linux system."
else
    echo "System $OS is not supported."
    exit 1
fi

# Check if the destination directory exists
if [ ! -d "$ROOT_DIR/package/$PACKAGE" ]; then
    sudo mkdir -p $ROOT_DIR/package/$PACKAGE
fi

# copy the file to the destination
sudo cp $FILE_NAME $ROOT_DIR/$PATH_TO_FILE
sudo rm $FILE_NAME
if [ -f "$TEST_FILE_NAME" ]; then
    sudo cp $TEST_FILE_NAME $ROOT_DIR/$TEST_PATH_TO_FILE
    sudo rm $TEST_FILE_NAME
fi
echo "finished"