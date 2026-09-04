#!/bin/bash

DIR="$HOME/.local/share/plasma/plasmoids/com.merchin.powerhub"
ICON_DIR="$HOME/.local/share/icons/hicolor/scalable/apps"

echo "PowerHub kuruluyor..."

# 1. Eski sürümü temizle ve klasörü oluştur
rm -rf "$DIR"
mkdir -p "$DIR"

# 2. Proje dosyalarını kopyala
cp -r contents "$DIR/"
cp metadata.json "$DIR/"

# 3. İkonu KDE'nin her boyutta (Hakkında menüsü dahil) okuyabilmesi için scalable klasörüne kopyala
mkdir -p "$ICON_DIR"
cp contents/icons/powerhub-icon.png "$ICON_DIR/powerhub-icon.png"

# 4. KDE ikon önbelleğini yenile
touch "$HOME/.local/share/icons/hicolor"
kbuildsycoca6 --noincremental 2>/dev/null

echo "Kurulum tamamlandı!"
echo "Lütfen Plasma'yı yeniden başlatın!"
