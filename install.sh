#!/bin/bash

set -e

# Конфигурация
DOWNLOAD_URL="https://www.niisi.ru/kumir/Kumir2X-1462.tar.gz"
FILENAME="kumir.tar.gz"
DIR_NAME="Kumir2X-1462"
INSTALL_PATH="/opt/$DIR_NAME"
EXEC_FILE="bin/kumir2-classic"

GREEN='\033[1;32m'
YELLOW='\033[1;33m'
RED='\033[1;31m'
NC='\033[0m'

echo -e "${GREEN}Установка среды программирования Кумир${NC}"
echo "=========================================="

# Проверка архитектуры (только amd64/x86_64 поддерживается)
if [ "$(uname -m)" != "x86_64" ]; then
    echo -e "${RED}Ошибка: Поддерживается только архитектура x86_64 (64-bit)${NC}"
    exit 1
fi

# === УСТАНОВКА ЗАВИСИМОСТЕЙ QT4 ЧЕРЕЗ .DEB ПАКЕТЫ ===
echo -e "${YELLOW}Установка библиотек Qt4 из пакетов Ubuntu Focal...${NC}"

QT4_DEBS=(
    "http://archive.ubuntu.com/ubuntu/pool/main/q/qt4-x11/libqtcore4_4.8.7+dfsg-18ubuntu2_amd64.deb"
    "http://archive.ubuntu.com/ubuntu/pool/main/q/qt4-x11/libqtgui4_4.8.7+dfsg-18ubuntu2_amd64.deb"
    "http://archive.ubuntu.com/ubuntu/pool/main/q/qt4-x11/libqt4-svg_4.8.7+dfsg-18ubuntu2_amd64.deb"
    "http://archive.ubuntu.com/ubuntu/pool/main/q/qt4-x11/libqt4-xml_4.8.7+dfsg-18ubuntu2_amd64.deb"
    "http://archive.ubuntu.com/ubuntu/pool/main/q/qt4-x11/libqt4-script_4.8.7+dfsg-18ubuntu2_amd64.deb"
    "http://archive.ubuntu.com/ubuntu/pool/main/q/qt4-x11/libqt4-network_4.8.7+dfsg-18ubuntu2_amd64.deb"
    "http://archive.ubuntu.com/ubuntu/pool/main/q/qt4-x11/libqt4-dbus_4.8.7+dfsg-18ubuntu2_amd64.deb"
    "http://archive.ubuntu.com/ubuntu/pool/main/libx/libxss/libxss1_1.2.3-1_amd64.deb"
    "http://archive.ubuntu.com/ubuntu/pool/main/libp/libpng/libpng16-16_1.6.37-3build1_amd64.deb"
    "http://archive.ubuntu.com/ubuntu/pool/main/libj/libjpeg-turbo/libjpeg-turbo8_2.1.1-0ubuntu2_amd64.deb"
)

TEMP_DEB_DIR=$(mktemp -d)
cd "$TEMP_DEB_DIR"

echo "Скачивание пакетов..."
for url in "${QT4_DEBS[@]}"; do
    curl -sLO "$url" || { echo "Не удалось скачать $url"; exit 1; }
done

echo "Установка пакетов..."
sudo dpkg -i *.deb 2>&1 | grep -v "warning: symbol" || true
sudo apt-get install -f -y 2>&1 | grep -v "warning" || true

cd - > /dev/null
rm -rf "$TEMP_DEB_DIR"
sudo ldconfig

echo -e "${GREEN}✓ Библиотеки Qt4 установлены${NC}"

# === СКАЧИВАНИЕ И УСТАНОВКА КУМИР ===
echo -e "${YELLOW}Скачивание Кумир...${NC}"
rm -f "$FILENAME"
curl -L -# -o "$FILENAME" "$DOWNLOAD_URL"

echo -e "${YELLOW}Распаковка архива...${NC}"
TEMP_DIR=$(mktemp -d)
tar -xzf "$FILENAME" -C "$TEMP_DIR"

# Определяем структуру распаковки
if [ -d "$TEMP_DIR/$DIR_NAME" ]; then
    EXTRACTED_DIR="$TEMP_DIR/$DIR_NAME"
else
    EXTRACTED_DIR="$TEMP_DIR"
fi

echo "Структура: $(basename "$EXTRACTED_DIR")"

sudo rm -rf "$INSTALL_PATH"
sudo mkdir -p "$INSTALL_PATH"
sudo cp -r "$EXTRACTED_DIR"/* "$INSTALL_PATH"/

rm -f "$FILENAME"
rm -rf "$TEMP_DIR"

# Проверка исполняемого файла
if [ ! -f "$INSTALL_PATH/$EXEC_FILE" ]; then
    echo -e "${RED}Ошибка: исполняемый файл не найден по пути $INSTALL_PATH/$EXEC_FILE${NC}"
    ls -la "$INSTALL_PATH/bin/" 2>/dev/null || echo "Папка bin не найдена"
    exit 1
fi

# === СОЗДАНИЕ ЯРЛЫКА ===
DESKTOP_FILE="$HOME/.local/share/applications/kumir.desktop"

ICON_CANDIDATES=(
    "$INSTALL_PATH/share/icons/hicolor/256x256/apps/kumir2.png"
    "$INSTALL_PATH/share/pixmaps/kumir2.png"
    "$INSTALL_PATH/kumir2.png"
)
ACTUAL_ICON="kumir2"
for icon in "${ICON_CANDIDATES[@]}"; do
    [ -f "$icon" ] && ACTUAL_ICON="$icon" && break
done

cat > "$DESKTOP_FILE" << EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=Кумир
Name[ru]=Кумир
Comment=Среда программирования алгоритмического языка
Exec=$INSTALL_PATH/$EXEC_FILE %f
Icon=$ACTUAL_ICON
Categories=Development;Education;Science;
Keywords=алгоритмы;робот;исполнитель;школьный;Кумир;
Terminal=false
StartupNotify=true
EOF

chmod +x "$DESKTOP_FILE"
update-desktop-database "$HOME/.local/share/applications" &>/dev/null || true

echo -e "\n${GREEN}✅ Кумир успешно установлен!${NC}"
echo ""
echo "💡 Запуск:"
echo "   • Меню приложений → Разработка → Кумир"
echo "   • Или в терминале: ${GREEN}$INSTALL_PATH/$EXEC_FILE${NC}"
echo ""
echo -e "${YELLOW}ℹ️  Совет:${NC} Для работы с Роботом:"
echo "   Меню «Инструменты» → «Поле Робота»"

# Предложение запуска
read -p "Запустить Кумир сейчас? [Y/n] " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ || -z $REPLY ]]; then
    echo "Запуск Кумир..."
    nohup "$INSTALL_PATH/$EXEC_FILE" >/dev/null 2>&1 &
    sleep 2
    echo "Готово! Если окно не появилось, запустите вручную: $INSTALL_PATH/$EXEC_FILE"
fi
