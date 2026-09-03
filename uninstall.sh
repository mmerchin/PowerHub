#!/bin/bash

DIR="$HOME/.local/share/plasma/plasmoids/com.merchin.powerhub"
ICON="$HOME/.local/share/icons/powerhub-icon.png"

echo "PowerHub kaldırılıyor..."

# Widget klasörünü ve sistem ikonunu sil
rm -rf "$DIR"
rm -f "$ICON"

echo "Kaldırma işlemi tamamlandı!"
