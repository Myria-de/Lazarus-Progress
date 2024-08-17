#!/usr/bin/env bash
#Dependencies
if [ $UID = "0" ]; then
 echo "Diese Script bitte nicht als root ausführen"
 exit 1
fi
# aktuelles Verzeichnis
BINDIR=`pwd`

if [ ! -d $HOME/.local/share/applications ]
then
mkdir -p $HOME/.local/share/applications
fi
cp ProgressDemo.desktop.template ProgressDemo.desktop
sed -i "s#%%BINDIR%%#${BINDIR}#g" ProgressDemo.desktop
cp ProgressDemo.desktop $HOME/.local/share/applications
