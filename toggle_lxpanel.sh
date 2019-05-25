#!/bin/bash

# Check if xdo is installed
#xdo_path=$(which xdo)
#if [ $? -ne 0 ]; then
 #   echo "Cannot find \`xdo\` command." 1>&2
 #   exit 1
#fi
# Obtain bar's window id
#id=$(xdo id -N "lxpanel")
# Toggle bar visibility
#if xprop -id $id | grep -q "Normal"; then
#    xdo hide -N "lxpanel"
#else
#    xdo show -N "lxpanel"
#fi

PROC_ID=$(pgrep lxpanel)

if [ $PROC_ID ]; then
	lxpanelctl exit
else
	lxpanel
fi
