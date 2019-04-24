#! /bin/bash

BUILD_MODE="debug"
ARCHS_ARM="arm64,armv7"
FLUTTER_ROOT=".flutter"
PRODUCT_DIR="product"
PRODUCT_ZIP="product.zip"

BUILD_PATH=".build_ios/${BUILD_MODE}"
PRODUCT_PATH="${BUILD_PATH}/${PRODUCT_DIR}"
PRODUCT_APP_PATH="${PRODUCT_PATH}/Flutter"
# git repository path
PRODUCT_GIT_DIR="/xx/xx/x"

usage() {
    echo
    echo "build_ios.sh [-h | [-m <build_mode>] [-s]]"
    echo ""
    echo "-h    - Help."
    echo "-m    - Build model, valid values are 'debug', 'profile', or 'release'. "
    echo "        Default values: 'debug'."
    echo ""
    echo "Build product in 'build_ios/<builde_model>/${PRODUCT_DIR}' directory."
    echo
}

EchoError() {
    echo "$@" 1>&2
}

flutter_get_packages() {
    echo "================================="
    echo "Start get flutter app plugin"

    local flutter_wrapper="./flutterw"
    if [ -e $flutter_wrapper ]; then
        echo 'flutterw installed' >/dev/null
    else
        bash -c "$(curl -fsSL https://raw.githubusercontent.com/passsy/flutter_wrapper/master/install.sh)"
        if [[ $? -ne 0 ]]; then
            EchoError "Failed to installed flutter_wrapper."
            exit -1
        fi
    fi

    ${flutter_wrapper} packages get --verbose
    if [[ $? -ne 0 ]]; then
        EchoError "Failed to install flutter plugins."
        exit -1
    fi

    echo "Finish get flutter app plugin"
}

build_flutter_app() {
    echo "================================="
    echo "Start Build flutter app"
    echo "Build mode: ${BUILD_MODE}"

    mkdir -p -- "${PRODUCT_APP_PATH}"

    local target_path="lib/main.dart"

    local artifact_variant="unknown"
    case "$BUILD_MODE" in
    release*)
        artifact_variant="ios-release"
        ;;
    profile*)
        artifact_variant="ios-profile"
        ;;
    debug*)
        artifact_variant="ios"
        ;;
    *)
        EchoError "========================================================================"
        EchoError "ERROR: Unknown FLUTTER_BUILD_MODE: ${BUILD_MODE}."
        EchoError "Valid values are 'debug', 'profile', or 'release'."
        EchoError "This is controlled by the -m environment varaible."
        EchoError "========================================================================"
        exit -1
        ;;
    esac

    if [[ "${BUILD_MODE}" != "debug" ]]; then
        if [[ $ARCHS_ARM =~ .*i386.* || $ARCHS_ARM =~ .*x86_64.* ]]; then
            EchoError "========================================================================"
            EchoError "ERROR: Flutter does not support running in profile or release mode on"
            EchoError "the Simulator (this build was: '$BUILD_MODE')."
            EchoError "mode by setting '-m debug'"
            EchoError "========================================================================"
            exit -1
        fi

        echo "Build archs: ${ARCHS_ARM}"

        ${FLUTTER_ROOT}/bin/flutter clean

        # build fLutter app
        ${FLUTTER_ROOT}/bin/flutter --suppress-analytics \
            --verbose \
            build aot \
            --output-dir="${BUILD_PATH}" \
            --target-platform=ios \
            --target="${target_path}" \
            --${BUILD_MODE} \
            --ios-arch="${ARCHS_ARM}"

        if [[ $? -ne 0 ]]; then
            EchoError "Failed to build flutter app"
            exit -1
        fi
    else
        echo "Build archs: x86_64 ${ARCHS_ARM}"
        local app_framework_debug="iOSApp/Debug/App.framework"
        cp -r -- "${app_framework_debug}" "${BUILD_PATH}"
    fi

    app_plist_path=".ios/Flutter/AppFrameworkInfo.plist"
    cp -- "${app_plist_path}" "${BUILD_PATH}/App.framework/Info.plist"

    # copy flutter sdk
    local framework_path="${FLUTTER_ROOT}/bin/cache/artifacts/engine/${artifact_variant}"
    local flutter_framework="${framework_path}/Flutter.framework"
    local flutter_podspec="${framework_path}/Flutter.podspec"

    cp -r -- "${BUILD_PATH}/App.framework" "${PRODUCT_APP_PATH}"
    cp -r -- "${flutter_framework}" "${PRODUCT_APP_PATH}"
    cp -r -- "${flutter_podspec}" "${PRODUCT_APP_PATH}"

    local precompilation_flag=""
    if [[ "$BUILD_MODE" != "debug" ]]; then
        precompilation_flag="--precompiled"
    fi

    # build bundle
    ${FLUTTER_ROOT}/bin/flutter --suppress-analytics \
        --verbose \
        build bundle \
        --target-platform=ios \
        --target="${target_path}" \
        --${BUILD_MODE} \
        --depfile="${BUILD_PATH}/snapshot_blob.bin.d" \
        --asset-dir="${BUILD_PATH}/flutter_assets" \
        ${precompilation_flag}

    if [[ $? -ne 0 ]]; then
        EchoError "Failed to build flutter assets"
        exit -1
    fi
    
    cp -rf -- "${BUILD_PATH}/flutter_assets" "${PRODUCT_APP_PATH}/App.framework"

    # setting podspec
    # replace:
    # 'Flutter.framework'
    # to:
    # 'Flutter.framework', 'App.framework'
    sed -i '' -e $'s/\'Flutter.framework\'/\'Flutter.framework\', \'App.framework\'/g' ${PRODUCT_APP_PATH}/Flutter.podspec

    echo "Finish build flutter app"
}

flutter_copy_packages() {
    echo "================================="
    echo "Start copy flutter app plugin"

    local flutter_plugin_registrant="FlutterPluginRegistrant"
    local flutter_plugin_registrant_path=".ios/Flutter/${flutter_plugin_registrant}"
    echo "copy 'flutter_plugin_registrant' from '${flutter_plugin_registrant_path}' to '${PRODUCT_PATH}/${flutter_plugin_registrant}'"
    cp -rf -- "${flutter_plugin_registrant_path}" "${PRODUCT_PATH}/${flutter_plugin_registrant}"

    local flutter_plugin=".flutter-plugins"
    if [ -e $flutter_plugin ]; then
        OLD_IFS="$IFS"
        IFS="="
        cat ${flutter_plugin} | while read plugin; do
            local plugin_info=($plugin)
            local plugin_name=${plugin_info[0]}
            local plugin_path=${plugin_info[1]}

            if [ -e ${plugin_path} ]; then
                local plugin_path_ios="${plugin_path}ios"
                if [ -e ${plugin_path_ios} ]; then
                    if [ -s ${plugin_path_ios} ]; then
                        echo "copy plugin 'plugin_name' from '${plugin_path_ios}' to '${PRODUCT_PATH}/${plugin_name}'"
                        cp -rf ${plugin_path_ios} "${PRODUCT_PATH}/${plugin_name}"
                    fi
                fi
            fi
        done
        IFS="$OLD_IFS"
    fi

    echo "Finish copy flutter app plugin"
}

upload_product() {
    echo "================================="
    echo "upload product"

    echo "${PRODUCT_PATH}"
    echo "${PRODUCT_GIT_DIR}"

    cp -r -f -- "${PRODUCT_PATH}/" "${PRODUCT_GIT_DIR}"

    local app_version=$(./get_version.sh)

    pushd ${PRODUCT_GIT_DIR}
    
    git add .
    git commit -m "Flutter product ${app_version}"
    git push

    popd    
}

start_build() {

    rm -rf ${BUILD_PATH}

    flutter_get_packages

    build_flutter_app

    flutter_copy_packages

    if [[ "${BUILD_MODE}" == "release" ]]; then
        upload_product
    fi

    echo ""
    echo "done!"
}

show_help=0
while getopts "m:sh" arg; do
    case $arg in
    m)
        BUILD_MODE="$OPTARG"
        ;;
    h)
        show_help=1
        ;;
    ?)
        show_help=1
        ;;
    esac
done

if [ $show_help == 1 ]; then
    usage
    exit 0
fi

BUILD_PATH=".build_ios/${BUILD_MODE}"
PRODUCT_PATH="${BUILD_PATH}/${PRODUCT_DIR}"
PRODUCT_APP_PATH="${PRODUCT_PATH}/Flutter"

start_build

exit 0
