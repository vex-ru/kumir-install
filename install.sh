#!/bin/bash

# URL для скачивания Кумир
DOWNLOAD_URL="https://www.niisi.ru/kumir/Kumir2X-1462.tar.gz"
FILENAME="kumir.tar.gz"
DIR_NAME="Kumir2X-1462"
INSTALL_PATH="/opt/$DIR_NAME"

# Проверка наличия необходимых утилит
if ! command -v curl &> /dev/null; then
    echo "Ошибка: curl не установлен. Установите его с помощью: sudo apt install curl"
    exit 1
fi

if ! command -v tar &> /dev/null; then
    echo "Ошибка: tar не установлен. Установите его с помощью: sudo apt install tar"
    exit 1
fi

# Скачивание архива
echo "Скачивание Кумир..."
curl -L -o "$FILENAME" "$DOWNLOAD_URL"

# Проверка успешности скачивания
if [ $? -ne 0 ]; then
    echo "Ошибка при скачивании Кумир"
    rm -f "$FILENAME"
    exit 1
fi

# Распаковка архива
echo "Распаковка архива..."
tar -xzf "$FILENAME"

# Проверка успешности распаковки
if [ $? -ne 0 ]; then
    echo "Ошибка при распаковке архива"
    rm -f "$FILENAME"
    exit 1
fi

# Удаление архива
rm -f "$FILENAME"

# Перемещение в /opt/ (требуются права суперпользователя)
echo "Установка в $INSTALL_PATH..."
sudo mkdir -p /opt
sudo mv "$DIR_NAME" "$INSTALL_PATH"

# Проверка существования исполняемого файла
EXEC_FILE="kumir2"
if [ ! -f "$INSTALL_PATH/$EXEC_FILE" ]; then
    echo "Ошибка: Не найден исполняемый файл $INSTALL_PATH/$EXEC_FILE"
    exit 1
fi

# Создание .desktop файла
DESKTOP_FILE="$HOME/.local/share/applications/kumir.desktop"
echo "Создание файла запуска..."
cat > "$DESKTOP_FILE" << EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=Кумир
Comment=Среда программирования Кумир
Exec="$INSTALL_PATH/$EXEC_FILE" %f
Icon=$INSTALL_PATH/kumir2.png
Categories=Development;IDE;Education;
Terminal=false
EOF

# Даем права на выполнение .desktop файла
chmod +x "$DESKTOP_FILE"

# Обновляем кэш приложений
update-desktop-database "$HOME/.local/share/applications" &> /dev/null

echo -e "\033[1;32mКумир успешно установлен!\033[0m"
echo "Вы можете найти его в меню приложений в разделе Разработка (Development) или Образование (Education)"
echo ""
echo "Если возникнут проблемы с запуском, проверьте файл $DESKTOP_FILE"
echo "и убедитесь, что путь к исполняемому файлу корректен."
