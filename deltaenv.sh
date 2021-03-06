#!/bin/bash

# Create delta updates using OpenDelta (https://github.com/omnirom/android_packages_apps_OpenDelta) guidelines. 
# Author: bitrvmpd (e.noyer.silva@gmail.com)

# ============ Vars/Dir Structure ===================== #
# - LOS_DIR :             LineageOS output directory    #
# - DLT_DIR :             Deltas root dir               #
#   |- LST_DIR/$DEVICE :  Last LOS output zip.          #
#   |- CRR_DIR/$DEVICE :  Current LOS output zip.       #
#   |- DEP_DIR :          Dependencies dir              #
#     |- JNI_DIR :        zipadjust source dir          #
#       |- XDL_DIR :      Xdelta source dir             #
# ===================================================== #

# Note:
# The delta update will have the name of the Last LOS build, but the content of the new one (Current).
# Because that way:
# 1. Download Current Name delta
# 2. Download/Apply your delta
# 3. Now you have the recent version!

export LOS_DIR=$WORKSPACE/out/target/product/$1
export DLT_DIR=$WORKSPACE/deltas
export LST_DIR=$DLT_DIR/last/$1
export CRR_DIR=$DLT_DIR/current/$1
export DEP_DIR=$DLT_DIR/deps
export JNI_DIR=$DLT_DIR/jni
export XDL_DIR=$JNI_DIR/xdelta3-3.0.7

# Create delta updates dir structure (if doesn't exists yet)
if [ ! -d "$LST_DIR" ]; then
  mkdir -p $LST_DIR &&  mkdir -p $CRR_DIR
fi

# Remove oldest build (if exists)
if [ -f $LST_DIR/*.zip ]; then
  rm $LST_DIR/*.zip  
fi

if [ -f $CRR_DIR/*.zip ]; then    
    echo "Moving your previous build to $LST_DIR folder"
    mv $CRR_DIR/lineage-*.zip $LST_DIR/.  
    # Tell the script we're able to create a delta update
    CREATE_DELTA=1
fi

echo "Moving your latest build to $CRR_DIR folder"
mv $LOS_DIR/lineage-*.zip $CRR_DIR/.

if [[ $CREATE_DELTA -eq 1 ]]; then
  # If jni dir exists, remove it to get latest sources
  if [ -d "$JNI_DIR" ]; then
    rm -rfv $JNI_DIR
  fi  
  echo "Copying dependencies..."
  cp -rfv $WORKSPACE/packages/apps/OpenDelta/jni $DLT_DIR/.
  # Remove Android.mk inside JNI_DIR to avoid build errors.
  rm $JNI_DIR/Android.mk
  echo "Compiling dependencies..."
    
  echo "> Compiling xdelta3..."
  cd $XDL_DIR
  ./configure && make
    
  echo "> Compiling zipadjust..."
  cd $JNI_DIR
  gcc -o zipadjust zipadjust.c zipadjust_run.c -lz
    
  echo "> Compiling dedelta..."
  gcc -o dedelta xdelta3-3.0.7/xdelta3.c delta.c delta_run.c
    
  # Copy Omni's delta build script.
  cp -rfv $WORKSPACE/packages/apps/OpenDelta/server/* $DLT_DIR/.
  
  echo "Creating delta update..."
  source $DLT_DIR/opendelta.sh $1
else
  echo "This is your first build!, I can't create any delta until your next build."  
fi

# Make sure LOS output directory is empty for the next build.
rm -rfv "$LOS_DIR"/lineage-*.zip
