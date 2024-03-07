#!/bin/bash

# Copy this bash script to a directory below /Tasmota and run from there

CHECK_MARK="\033[0;32m\xE2\x9C\x94\033[0m"
rundir=$(dirname $(readlink -f $0))

CONFIG="$1"

if [ -z "$CONFIG" ]; then
    echo -e "Usage: $0 <config>\n"
    echo -e "Available configs:"
    ls -1 $rundir/configs
    exit 1
fi

CONFIG_DIR="configs/$CONFIG"

cd $rundir

## Check script dir for custom user_config_override.h
if test -e "$CONFIG_DIR/user_config_override.h"; then
    ## new Tasmota builds have this enabled as default
    ##    sed -i 's/^; *-DUSE_CONFIG_OVERRIDE/                            -DUSE_CONFIG_OVERRIDE/' Tasmota/platformio.ini
    cp "$CONFIG_DIR/user_config_override.h" Tasmota/tasmota/user_config_override.h
    echo -e "Using your $CONFIG_DIR/user_config_override.h and overwriting the existing file\n"
fi

if test -e "$CONFIG_DIR/platformio_override.ini"; then
    echo -e "Compiling builds defined in $CONFIG_DIR/platformio_override.ini. Default file is overwritten.\n"
    cp "$CONFIG_DIR/platformio_override.ini" Tasmota/platformio_override.ini
fi

if test -e "$CONFIG_DIR/lib"; then
    echo -e "Adding additional libraries.\n"
    cp -r "$CONFIG_DIR/lib" Tasmota/
fi

if ls $CONFIG_DIR/*.patch 1> /dev/null 2>&1; then
    repo_sha=$(cd Tasmota && git rev-parse HEAD)
    echo "Current Tasmota repository SHA: $repo_sha"
    
    ## Apply all *.patch files in CONFIG_DIR to Tasmota
    echo -e "Applying patches in $CONFIG_DIR to Tasmota.\n"
    for patch_file in $CONFIG_DIR/*.patch; do
        $(cd Tasmota && git apply "../$patch_file")
    done
fi

cd Tasmota

pio run

if [ ! -z "$repo_sha" ]; then
    git checkout -f "$repo_sha"
fi
