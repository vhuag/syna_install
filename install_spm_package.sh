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

# Get the list of files in the package directory on Github
FILES_URL="https://api.github.com/repos/$OWNER/$REPO/contents/package/$PACKAGE"
FILES_JSON=$(curl -s -H "Authorization: token $TOKEN" $FILES_URL)

# Parse the JSON to get the file paths
file_paths=$(echo $FILES_JSON | python3 -c "import sys, json; print(' '.join([file['path'] for file in json.load(sys.stdin)]))")

# Iterate over file paths and download each file
for file_path in $file_paths; do
    # Download each file
    echo "Downloading '$file_path'"
    TEMP_FILE_NAME="_$(basename $file_path)"
    FILE_URL="https://api.github.com/repos/$OWNER/$REPO/contents/$file_path"
    curl -f -H "Authorization: token $TOKEN" \
         -H 'Accept: application/vnd.github.v3.raw' \
         -o $TEMP_FILE_NAME \
         -L $FILE_URL

    # Check if the curl command was successful
    if [ $? -eq 0 ]; then
        echo "File downloaded successfully"
        DEST_PATH="$ROOT_DIR/$file_path"
        sudo mkdir -p $(dirname $DEST_PATH)
        # copy the file to the destination
        sudo cp $TEMP_FILE_NAME $DEST_PATH
        sudo rm $TEMP_FILE_NAME
    else
        echo "File download failed"
        exit 1
    fi
done


echo completed
