#!/bin/bash

echo "PowerHub resmi KDE paket yöneticisinden kaldırılıyor..."
kpackagetool6 -t Plasma/Applet --remove com.merchin.powerhub 2>/dev/null

echo "Kalıntılar ve ikon temizleniyor..."
rm -rf "$HOME/.local/share/plasma/plasmoids/com.merchin.powerhub"
rm -f "$HOME/.local/share/icons/hicolor/scalable/apps/powerhub-icon.svg"

echo "KDE sistem önbelleği yenileniyor..."
gtk-update-icon-cache -f -t "$HOME/.local/share/icons/hicolor" 2>/dev/null
kbuildsycoca6 --noincremental 2>/dev/null

echo "Kaldırma işlemi tamamlandı!"
