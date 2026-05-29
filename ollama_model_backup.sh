#!/usr/bin/bash

# Script version 1.0
# Creating backup as tar archive from already pulled model
# tested on:
#  Debian 13.5
#  Ollama 0.24.0

MODEL_NAME="qwen3.6"
MODEL_TAG="27b"

MODEL_REPOSITORY="registry.ollama.ai"
# for stable models
MODEL_STAGE="library"
# for experemental models
#MODEL_STAGE="x"

DATE_TIME=$(date +"%Y-%m-%d")
OLLAMA_VOL="/var/lib/docker/volumes/docker_ollama/_data"
BACKUP_NAME="$MODEL_NAME""_""$MODEL_TAG"
BACKUP_DIR="$OLLAMA_VOL/backup/$BACKUP_NAME"
MODEL_MANIFEST_DIR="models/manifests/$MODEL_REPOSITORY/`
                                    `$MODEL_STAGE/$MODEL_NAME"
MODEL_MANIFEST="$OLLAMA_VOL/$MODEL_MANIFEST_DIR/$MODEL_TAG"
MODEL_BLOB_DIR="models/blobs"
MODEL_BLOB="$OLLAMA_VOL/$MODEL_BLOB_DIR"
blob_list=""

if [ ! -d "$OLLAMA_VOL" ]; then
    echo "Ollama volume dir not found"
    exit 1
fi
if [ ! -f "$MODEL_MANIFEST" ]; then
    echo "Model manifest file not found"
    exit 1
fi

mkdir -p "$BACKUP_DIR"

if [ ! -d "$BACKUP_DIR" ]; then
    echo "BackUP dir not found"
    exit 1
fi


########## Backup manifest file
mkdir -p "$BACKUP_DIR/$MODEL_MANIFEST_DIR"

# copy manifest file
nice cp "$MODEL_MANIFEST" "$BACKUP_DIR/$MODEL_MANIFEST_DIR"


########## Backup blob files
# read manifest file and parsing blob files path
blob_list="$(cat $MODEL_MANIFEST |\
    grep -Po '"digest":.*?[^\\]",' |\
    awk -F "\"" '{print $4}' | sed -e "s\:\-\g")"

mkdir -p "$BACKUP_DIR/$MODEL_BLOB_DIR"

# copy each blob file
for blob_name in ${blob_list[@]}; do
    blob_file="$MODEL_BLOB/$blob_name"
    blob_backup="$BACKUP_DIR/$MODEL_BLOB_DIR/$blob_name"

    # skip if not exist
    if [ ! -f $blob_file ]; then
        echo "Blob file not found: $blolb_file"
        continue
    fi

    nice cp "$blob_file" "$blob_backup"
done


########## Compress backup
cd "$BACKUP_DIR"
cd ..

# compress by xz
tar -cvf - "./$BACKUP_NAME" |\
            nice xz -T2 > "$DATE_TIME-$BACKUP_NAME.tar.xz"

# delete tmp files
nice rm -rf "./$BACKUP_NAME"
