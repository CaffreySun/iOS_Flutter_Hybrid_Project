#!/usr/bin/env bash

FILE_NAME="flutter.zip"
FILE_PATH="xxx"
VERSION=""
MAVEN_PATH="http://xxx"
MAVEN_USER="xxx:xxx"
LOCAL_FILE_PATH=""

throw () {
  echo "error: $*" >&2
  exit 1
}

usage() {
  echo
  echo "Usage: maven.sh [-h] [upload] [download]"
  echo
  echo "upload <version> <file>  - Upload to maven. [e.g.]: ./maven.sh upload 1.0.0 localFile.zip"
  echo "download <version>       - Download from maven. [e.g.]: ./maven.sh download 1.0.1"
  echo "-h                       - This help text."
  echo
}

parse_options() {
  set -- "$@"
  local ARGN=$#
  while [ "$ARGN" -ne 0 ]
  do
    case $1 in
      -h) usage
          exit 0
      ;;
      upload) VERSION=$2
              LOCAL_FILE_PATH=$3
              upload
      ;;
      download) VERSION=$2
                download
      ;;
      ?*) echo "ERROR: Unknown option."
          usage
          exit 0
      ;;
    esac
    shift 1
    ARGN=$((ARGN-1))
  done
}

upload() {
  if [ "$VERSION"x = ""x ]; then
    throw "version null"
  fi
  if [ "$LOCAL_FILE_PATH"x = ""x ]; then
    throw "file null"
  fi
  if ! [ -f $LOCAL_FILE_PATH ]; then
    throw "file $LOCAL_FILE_PATH not exist"
  fi
  echo
  echo "Uploading..."
  echo "$LOCAL_FILE_PATH -> $MAVEN_PATH/$FILE_PATH/$VERSION/$FILE_NAME"
  curl -u$MAVEN_USER -T $LOCAL_FILE_PATH "$MAVEN_PATH/$FILE_PATH/$VERSION/$FILE_NAME"
  echo
  echo "Done!"
  echo
  exit 0
}

download() {
  if [ "$VERSION"x = ""x ]; then
    throw "version null"
  fi
  echo
  echo "Downloading..."
  echo "$MAVEN_PATH/$FILE_PATH/$VERSION/$FILE_NAME"
  curl -u$MAVEN_USER -O "$MAVEN_PATH/$FILE_PATH/$VERSION/$FILE_NAME"
  echo "Done!"
  echo
  exit 0
}

if ([ "$0" = "$BASH_SOURCE" ] || ! [ -n "$BASH_SOURCE" ]);
then
  parse_options "$@"
  usage
  exit 0
fi
