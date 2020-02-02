#!/bin/bash

# Copy this bash script to a directory below /Tasmota and run from there

CHECK_MARK="\033[0;32m\xE2\x9C\x94\033[0m"
rundir=$(dirname $(readlink -f $0))

# use default docker-tasmota image from hub.docker.com
$DOCKER_IMAGE=blakadder/docker-tasmota
# or uncomment and change if you want to run a locally built image
#$DOCKER_IMAGE=docker-tasmota


## Check whether Tasmota/ exists and fetch newest Tasmota version from development branch
if test -d `pwd`"/Tasmota"; then
    echo -e "Checking Tasmota GitHub for the most recent development version"
    cd Tasmota
    git fetch --all
    git reset --hard origin/development > /dev/null
    git pull
    cd $rundir
    echo -e "\nRunning Docker Tasmota\n"
    # Check if docker installed
    if [[ "$(type -t docker)" == "file" ]] ; then
        ## Display builds
        if  [ $# -eq 0 ]; then
            ## Check script dir for custom platformio.ini
            if test -f "platformio.ini"; then
                echo -e "Compiling builds defined in custom platformio.ini. Default file is overwritten.\n"
                cp platformio.ini Tasmota/platformio.ini
                else
                echo -e "\e[31mCompiling ALL BUILDS!!!!\n\n\e[7mIf you wish to quit use ctrl+C\e[0m"
                sleep 4
            fi
            else
                ## Display chosen builds
                echo -e "Compiling builds:"
                for build in "$@"
                do
                    echo -e "$build"
                    sleep 1
                done
                echo -e "\n"
        fi
        ## Check script dir for custom user_config_override.h
        if test -f "user_config_override.h"; then
            sed -i 's/^; *-DUSE_CONFIG_OVERRIDE/                            -DUSE_CONFIG_OVERRIDE/' Tasmota/platformio.ini
            cp user_config_override.h Tasmota/tasmota/user_config_override.h
            echo -e "Using your user_config_override.h and overwriting the existing file\n"
        fi
        ## Run container with provided arguments
        echo -n "Compiling..."
        if  [ $# -ne 0 ]; then
                if [[ $@ == "tasmota"* ]]; then
                    docker run -it --rm -v `pwd`/Tasmota:/tasmota -u $UID:$GID $DOCKER_IMAGE $(printf ' -e %s' $@) > docker-tasmota.log 2>&1 
                    echo -e "\\r${CHECK_MARK} Finished!  \tCompilation log in docker-tasmota.log\n"
                    else
                    echo -e "\\r\e[31mNot a valid buildname.\e[0m Try one of the builds:\ntasmota\t\ttasmota-minimal\ttasmota-basic\ttasmota-ircustom\ntasmota-knx\ttasmota-sensors\ttasmota-display\ttasmota-ir\nFor translated builds:\ntasmota-BG [BR,CN,CZ,DE,ES,FR,GR,HE,HU,IT,KO,NL,PL,PT,RU,SE,SK,TR,TW,UK]"
                    exit 1
                fi
            else
            docker run -it --rm -v `pwd`/Tasmota:/tasmota -u $UID:$GID $DOCKER_IMAGE > docker-tasmota.log 2>&1 
            echo -e "\\r${CHECK_MARK} Finished! \tCompilation log in docker-tasmota.log\n"
            echo -e "Find your builds in $rundir/Tasmota/build_output/firmware\n"
        fi
        ## After docker is completed copy firmware to script dir and rename to buildname
        for build in "$@"
        do
        cp "$rundir"/Tasmota/.pioenvs/"$build"/firmware.bin "$rundir"/"$build".bin
            if test -f "$build".bin; then
                echo -e "Completed! Your firmware is in $rundir/$build.bin\n"
            else
                echo -e "\e[31m\e[5mWARNING:\e[0m"
                echo -e "Something went wrong while compiling $build. Check compilation log\n"
            fi  
        done
    else
        echo -e "\nNo Docker detected. Please install docker:\n\n\tcurl -fsSL https://get.docker.com -o get-docker.sh\n\tsh get-docker.sh\n"
        # fi
    fi
else
    if [[ "$(type -t git)" == "file" ]] ; then
        echo -e "\nNo Tasmota Git repository found in directory.\nDo you wish to clone Tasmota GitHub repository to current directory?"
        read -p "Enter to exit, "yes" to proceed: " answer
            case ${answer:0:1} in
                y|yes )
                    git clone https://github.com/arendst/Tasmota.git
                    bash $(basename $0) && exit   
                ;;
                * )
                    exit 1
                ;;
            esac
    else
        echo -e "\nPlease install "git" to proceed:\n\n\tDebian/Ubuntu/Mint:\tsudo apt-get install git\n\tFedora:\t\t\tsu -c 'yum install git'\n\topenSUSE:\t\tsudo zypper in git\n"
        exit 1
    fi
fi
