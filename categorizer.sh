#!/bin/bash

# ---------- 固定値 ----------
# ファイル格納先,マウント先
MOUNT_PATH="$1"
MOUNT_TARGET_PATH="$2"


# 拡張子
IMAGE_EXTs=("JPG" "jpg" "PNG" "png" "GIF" "gif")
VIDEO_EXTs=("MP4" "mp4" "MOV" "mov")

# フォルダ
SAVE_DIR="save"
SYNC_DIR="sync"

CATEGORY_DIR="year"
IMAGE_DIR="image"
VIDEO_DIR="video"



# ---------- メソッド ----------
function GetRecordYearByImage () {
    RecordDatetime=`identify -verbose "$1" | grep DateTime: | awk '{print $2}' | awk -F ':' '{print $1}'`
    echo $RecordDatetime
}

function GetRecordYearByVideo () {
    RecordDatetime=`ffmpeg -i "$1" 2>&1 | grep -E 'creation_time' | head -1 | awk -F ': ' '{print $2}' | awk -F '-' '{print $1}'`
    echo $RecordDatetime
}

function IsImageExt() {
    local ret=0
    local ith
    for ith in ${IMAGE_EXTs[@]}; do
        if [[ ${ith} = ${1} ]]; then
            local ret=1
        fi
    done
    echo $ret
}

function IsVideoExt() {
    local ret=0
    local ith
    for ith in ${VIDEO_EXTs[@]}; do
        if [[ ${ith} = ${1} ]]; then
            local ret=1
        fi
    done
    echo $ret
}



# ---------- 実処理 ----------
if [[ ! -d $MOUNT_PATH ]]; then
    sudo mkdir $MOUNT_PATH
fi

sudo mount -t drvfs -o metadata,uid=1000,gid=1000 $MOUNT_TARGET_PATH $MOUNT_PATH
cd $MOUNT_PATH

echo '処理ファイル一覧取得中'
files=`find ./${SYNC_DIR} -maxdepth 9 -type f`

for ithfile in $files;
do
    echo "$ithfile"
    # read -p "Press [Enter] key to resume."

    ext=${ithfile##*.}
    isImage=$(IsImageExt $ext)

    targetCategory=""
    if [[ 1 == $isImage ]]; then
        targetCategory=$IMAGE_DIR

    elif [[ 1 != $isImage ]]; then
        isVideo=$(IsVideoExt $ext)

        if [ 1 == $isVideo ]; then
            targetCategory=$VIDEO_DIR
        fi
    else
        # 画像・動画でない場合スキップ
        continue
    fi

    year="unknown"
    if [[ $IMAGE_DIR == $targetCategory ]]; then
        year=$(GetRecordYearByImage $ithfile)

    elif [[ $VIDEO_DIR == $targetCategory ]]; then
        year=$(GetRecordYearByVideo $ithfile)
    fi

    # 撮影日時の情報がなければスキップ
    if [[ -z $year ]]; then
        continue
    fi

    # 格納先がなければ作成
    targetPath=${MOUNT_PATH}/${SAVE_DIR}/${CATEGORY_DIR}/${year}/${targetCategory}
    if [[ ! -d $targetPath ]]; then
        sudo mkdir -p $targetPath
    fi

    fname=`basename "$ithfile"`
    cp -rpf "$ithfile" ${targetPath}/${fname}

    # 異常がなければ削除
    if [[ -z $ERRORLEVEL ]]; then
        rm -f "$ithfile"
    else
        ERRORLEVEL=
        continue
    fi
done
