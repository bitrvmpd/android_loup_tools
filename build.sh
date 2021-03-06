#!/bin/bash

# if you want to build without using ccache, comment
# the next 4 lines
export USE_CCACHE=1
export CCACHE_DIR="$WORKSPACE/.ccache"
export CCACHE_MAX_SIZE=15G
ccache -M $CCACHE_MAX_SIZE

# encapsulate the build's temp directory.
# This way it's easier to clean up afterwards
TMP=$(mktemp -dt)
TMPDIR=$TMP
TEMP=$TMP

export TMP TMPDIR TEMP

#make sure jack-server is restarted in TMP
$WORKSPACE/prebuilts/sdk/tools/jack-admin kill-server

# fix USER: unbound variable
export USER=$(whoami)

# set max jack-vm size
export JACK_SERVER_VM_ARGUMENTS="-Dfile.encoding=UTF-8 -XX:+TieredCompilation -Xmx12288m"
#export JACK_SERVER_VM_ARGUMENTS="-Dfile.encoding=UTF-8 -Xmx4096m"

# start jack with new vars
$WORKSPACE/prebuilts/sdk/tools/jack-admin start-server

# we want all compiler messages in English
export LANGUAGE=C

# set up the environment (variables and functions)
source $WORKSPACE/build/envsetup.sh

# export Loup kernel config
if [[ "$1" == *"santoni"* ]]
then
        export KBUILD_LOUP_CFLAGS="-Wno-misleading-indentation -Wno-bool-compare -mtune=cortex-a53 -march=armv8-a+crc+simd+crypto -mcpu=cortex-a53 -O2"
fi
if [[ "$1" == *"ether"* ]]
then
        export KBUILD_LOUP_CFLAGS="-Wno-misleading-indentation -Wno-bool-compare -mtune=cortex-a57.cortex-a53 -march=armv8-a+crc+simd+crypto -mcpu=cortex-a57.cortex-a53 -O2"
fi
# clean the out dir; comment out, if you want to do
# a dirty build
#make -j9 ARCH=arm clean

# fire up the building process and also log stdout
# and stderrout
#breakfast lineage_santoni-user 2>&1 | tee breakfast.log && \
# brunch lineage_$1-user 2>&1 | tee make.log
breakfast lineage_$1-userdebug && make -j$(nproc --all) bacon 

if [ $? -eq 0 ]
then
  # remove all temp directories
  rm -r ${TMP}
else
  echo -e "\033[0;31m> Compilation failed, exiting...\033[0;0m\n"
  exit 1
fi
