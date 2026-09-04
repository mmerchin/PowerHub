#!/bin/bash

# Değişken tanımları
PLUGIN_DIR="$HOME/.local/share/plasma/plasmoids/com.merchin.powerhub"
ICON_DIR="$HOME/.local/share/icons/hicolor/scalable/apps"
SOURCE_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "Eski hatalı kalıntılar ve önbellekler temizleniyor..."
rm -rf "$PLUGIN_DIR"
rm -rf "$HOME/.cache/plasma*"
rm -rf "$HOME/.cache/kpackage*"

echo "Özel SVG ikon sistem scalable dizinine kopyalanıyor..."
mkdir -p "$ICON_DIR"
cp "$SOURCE_DIR/contents/icons/powerhub-icon.svg" "$ICON_DIR/powerhub-icon.svg"

echo "PowerHub dosyaları doğrudan eklenti dizinine kopyalanıyor..."
mkdir -p "$PLUGIN_DIR"
cp -r "$SOURCE_DIR/contents" "$PLUGIN_DIR/"
cp "$SOURCE_DIR/metadata.json" "$PLUGIN_DIR/"

echo "Plasma servis yöneticisine kaydediliyor..."
kpackagetool6 -t Plasma/Applet --upgrade "$SOURCE_DIR" 2>/dev/null || kpackagetool6 -t Plasma/Applet --install "$SOURCE_DIR" 2>/dev/null

echo "İzinler ayarlanıyor..."
chmod -R u+rwX "$PLUGIN_DIR"

echo "KDE sistem önbelleği yenileniyor..."
gtk-update-icon-cache -f -t "$HOME/.local/share/icons/hicolor" 2>/dev/null
kbuildsycoca6 --noincremental 2>/dev/null

echo "Kurulum başarıyla tamamlandı! Widget araç takımlarında hazır."
