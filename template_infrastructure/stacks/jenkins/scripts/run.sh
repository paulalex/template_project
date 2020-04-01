#!/bin/bash

mapfile -t < plugins.txt
source install-plugins.sh "${MAPFILE[@]}"