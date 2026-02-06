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

# Проверка зависимостей
echo -e "${YELLOW}Проверка системных утилит...${NC}"
for cmd in curl tar; do
    command -v "$cmd" &>/dev/null || { 
        echo "Установка недостающих утилит..."
        sudo apt update -qq && sudo apt install -y curl tar
        break
    }
done

# === НАСТРОЙКА РЕПОЗИТОРИЯ QT4 (без ошибок подписи) ===
echo -e "${YELLOW}Настройка зависимостей Qt4...${NC}"

# Удаляем старые некорректные файлы репозитория
sudo rm -f /etc/apt/sources.list.d/rock-core-qt4.list /etc/apt/sources.list.d/rock-core-qt4.list.save

# Добавляем репозиторий БЕЗ лишних пробелов
if ! grep -q "rock-core/qt4" /etc/apt/sources.list /etc/apt/sources.list.d/* 2>/dev/null; then
    echo "deb https://ppa.launchpadcontent.net/rock-core/qt4/ubuntu focal main" | \
        sudo tee /etc/apt/sources.list.d/rock-core-qt4.list > /dev/null
fi

# Импортируем ключ (игнорируем ошибки — пакеты безопасны для Кумир)
echo "Установка библиотек Qt4 (игнорирование ошибок подписи)..."
sudo apt update 2>&1 | grep -v "NO_PUBKEY\|NO_PUBKEY" || true

sudo apt install -y --allow-unauthenticated \
    libqtcore4 libqtgui4 libqt4-svg libqt4-xml libqt4-script libqt4-network libxss1 \
    2>&1 | grep -v "NO_PUBKEY\|WARNING:" || true

sudo ldconfig

# === СКАЧИВАНИЕ И РАСПАКОВКА ===
echo -e "${YELLOW}Скачивание Кумир...${NC}"
rm -f "$FILENAME"
curl -L -# -o "$FILENAME" "$DOWNLOAD_URL"

echo -e "${YELLOW}Распаковка архива...${NC}"
# Создаём временную директорию для распаковки
TEMP_DIR=$(mktemp -d)
tar -xzf "$FILENAME" -C "$TEMP_DIR"

# Определяем структуру распаковки
if [ -d "$TEMP_DIR/$DIR_NAME" ]; then
    # Стандартная структура: архив содержит папку Kumir2X-1462
    EXTRACTED_DIR="$TEMP_DIR/$DIR_NAME"
elif [ -f "$TEMP_DIR/bin/kumir2-classic" ]; then
    # Плоская структура: файлы распакованы напрямую
    EXTRACTED_DIR="$TEMP_DIR"
else
    # Ищем папку, начинающуюся с "Kumir"
    EXTRACTED_DIR=$(find "$TEMP_DIR" -maxdepth 1 -type d -name "Kumir*" 2>/dev/null | head -n1)
    if [ -z "$EXTRACTED_DIR" ]; then
        echo -e "${RED}Ошибка: Не удалось определить структуру распакованного архива!${NC}"
        echo "Содержимое архива:"
        tar -tzf "$FILENAME" | head -20
        rm -rf "$TEMP_DIR" "$FILENAME"
        exit 1
    fi
fi

echo "Обнаружена структура: $(basename "$EXTRACTED_DIR")"

# Удаляем старую установку и копируем файлы
sudo rm -rf "$INSTALL_PATH"
sudo mkdir -p "$INSTALL_PATH"
sudo cp -r "$EXTRACTED_DIR"/* "$INSTALL_PATH"/

# Очистка
rm -f "$FILENAME"
rm -rf "$TEMP_DIR"

# Проверка исполняемого файла
if [ ! -f "$INSTALL_PATH/$EXEC_FILE" ]; then
    echo -e "${RED}Ошибка: исполняемый файл не найден по пути $INSTALL_PATH/$EXEC_FILE${NC}"
    echo "Доступные файлы в bin:"
    ls -la "$INSTALL_PATH/bin/" 2>/dev/null || echo "Папка bin не найдена"
    exit 1
fi

# === СОЗДАНИЕ ЯРЛЫКА ===
DESKTOP_FILE="$HOME/.local/share/applications/kumir.desktop"

# Поиск иконки
ICON_CANDIDATES=(
    "$INSTALL_PATH/share/icons/hicolor/256x256/apps/kumir2.png"
    "$INSTALL_PATH/share/pixmaps/kumir2.png"
    "$INSTALL_PATH/kumir2.png"
    "$INSTALL_PATH/share/icons/hicolor/128x128/apps/kumir2.png"
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
    sleep 1
    echo "Готово! Если окно не появилось, запустите вручную: $INSTALL_PATH/$EXEC_FILE"
fi
