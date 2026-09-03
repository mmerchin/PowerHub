#!/bin/bash

echo "Installing PowerHub KDE Plasma Widget..."

TGT="$HOME/.local/share/plasma/plasmoids/com.merchin.powerhub"
SYS_LOC_DIR="$HOME/.local/share/locale"

mkdir -p "$TGT"
cp -r ./* "$TGT/"
rm -f "$TGT/install.sh" "$TGT/uninstall.sh" "$TGT/README.md"

for lang in tr en de fr ru zh_CN es pt_BR ja; do
    if [ -d "$TGT/contents/locale/$lang/LC_MESSAGES" ]; then
        mkdir -p "$SYS_LOC_DIR/$lang/LC_MESSAGES"
        ln -sf "$TGT/contents/locale/$lang/LC_MESSAGES/plasma_applet_com.merchin.powerhub.mo" "$SYS_LOC_DIR/$lang/LC_MESSAGES/plasma_applet_com.merchin.powerhub.mo"
        ln -sf "$TGT/contents/locale/$lang/LC_MESSAGES/com.merchin.powerhub.mo" "$SYS_LOC_DIR/$lang/LC_MESSAGES/com.merchin.powerhub.mo"
    fi
done

if command -v kbuildsycoca6 &> /dev/null; then
    kbuildsycoca6 --noincremental &> /dev/null
fi

echo "----------------------------------------"
echo "PowerHub successfully installed!"
echo "Please restart your Plasma shell (plasmashell --replace &) to add the widget to your panel."
echo "----------------------------------------"
