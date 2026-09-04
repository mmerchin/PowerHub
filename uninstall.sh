#!/bin/bash

DIR="$HOME/.local/share/plasma/plasmoids/com.merchin.powerhub"
ICON="$HOME/.local/share/icons/hicolor/scalable/apps/powerhub-icon.png"

echo "PowerHub kaldırılıyor..."

# Widget klasörünü ve sistem ikonunu sil
rm -rf "$DIR"
rm -f "$ICON"

# KDE ikon önbelleğini yenile
touch "$HOME/.local/share/icons/hicolor"
kbuildsycoca6 --noincremental 2>/dev/null

echo "Kaldırma işlemi tamamlandı!"
