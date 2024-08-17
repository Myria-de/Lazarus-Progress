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
cp TeaTimerDemo.desktop.template TeaTimerDemo.desktop
sed -i "s#%%BINDIR%%#${BINDIR}#g" TeaTimerDemo.desktop
cp TeaTimerDemo.desktop $HOME/.local/share/applications
