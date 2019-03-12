#!/usr/bin/env bash

FILE_PATH=""
FILE_PATH_DEF="./pubspec.yaml"
# 过滤 version name 的正则表达式
VERSION_NAME_REGEX="^version: "
# 过滤 version code 的正则表达式
VERSION_CODE_REGEX="^version_code: "

throw () {
  echo "error: $*" >&2
  exit 1
}

usage() {
  echo
  echo "Usage: get_version.sh [-h] [--name] [--code] [<file>]"
  echo "       [e.g.]: /get_version.sh                     // Get version name from def file ${FILE_PATH_DEF}."
  echo "       [e.g.]: /get_version.sh --name example.txt  // Get version name from the specified file."
  echo "       [e.g.]: /get_version.sh --code example.txt  // Get version code from the specified file."
  echo
  echo "--name         - [Default] Get version name from the specified file, the def file is ${FILE_PATH_DEF}."
  echo "--code         - Get version code from the specified file, the def file is ${FILE_PATH_DEF}."
  echo "-h             - This help text."
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
      --name) FILE_PATH=$2
              get_version_name
      ;;
      --code) FILE_PATH=$2
              get_version_code
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

get_version_name() {
    get_file
    #echo "get version name from ${FILE_PATH} ..."
    version_name=`egrep ${VERSION_NAME_REGEX} ${FILE_PATH}`
    # 取`:`右边
    version_name=`echo ${version_name} | sed 's/^.*://g'`
    # 删除`;`
    version_name=`echo ${version_name} | sed 's/;.*$//g'`
    # 删除`"`
    version_name=`echo ${version_name} | sed 's/\"//g'`
    # 删除`'`
    version_name=`echo ${version_name} | sed "s/\'//g"`
    #echo "version name: 【${version_name}】"
    echo ${version_name}
    finish
}

get_version_code() {
    get_file
    #echo "get version code from ${FILE_PATH} ..."
    version_code=`egrep ${VERSION_CODE_REGEX} ${FILE_PATH}`
    # 取`:`右边
    version_code=`echo ${version_code} | sed 's/^.*://g'`
    # 删除`;`
    version_code=`echo ${version_code} | sed 's/;.*$//g'`
    #echo "version code: 【${version_code}】"
    echo ${version_code}
    finish
}

get_file() {
  if [ "$FILE_PATH"x = ""x ]; then
    FILE_PATH=${FILE_PATH_DEF}
  fi
}

finish() {
  exit 0
}

default_action() {
  get_version_name
}

if ([ "$0" = "$BASH_SOURCE" ] || ! [ -n "$BASH_SOURCE" ]);
then
  parse_options "$@"
  default_action
fi
