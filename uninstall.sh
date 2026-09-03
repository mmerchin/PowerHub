#!/bin/bash

echo "Uninstalling PowerHub KDE Plasma Widget..."

TGT="$HOME/.local/share/plasma/plasmoids/com.merchin.powerhub"
SYS_LOC_DIR="$HOME/.local/share/locale"

for lang in tr en de fr ru zh_CN es pt_BR ja; do
    rm -f "$SYS_LOC_DIR/$lang/LC_MESSAGES/plasma_applet_com.merchin.powerhub.mo"
    rm -f "$SYS_LOC_DIR/$lang/LC_MESSAGES/com.merchin.powerhub.mo"
done

rm -rf "$TGT"

if command -v kbuildsycoca6 &> /dev/null; then
    kbuildsycoca6 --noincremental &> /dev/null
fi

echo "PowerHub successfully removed."
