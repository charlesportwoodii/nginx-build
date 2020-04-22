#!/bin/bash

rm -rf .envs

if [ -n "$DRONE_TAG" ]; then
    echo "VERSION=$(cut -d '-' -f 1 <<< $DRONE_TAG)" | tee -a .envs
    echo "RELEASEVER=$(cut -d '-' -f 2 <<< $DRONE_TAG)" | tee -a .envs
else
    echo "VERSION=$DEFAULT_VERSION" | tee -a .envs
    echo "RELEASEVER=$DEFAULT_REVISION" | tee -a .envs;
fi