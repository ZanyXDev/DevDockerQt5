#!/usr/bin/env bash
set -Eeuxo pipefail # https://vaneyckt.io/posts/safer_bash_scripts_with_set_euxo_pipefail/
# Версии и пути
APP_LOCATION=$HOME/qtcreator_app
CCACHE_DIR=/ccache

QT_VERSION=v5.15.8-lts-lgpl
QT_VERSION_SHORT=5.15.8
# Образы и URL
QTCREATOR_IMAGE_NAME=${USER}/${QT_VERSION_SHORT}-qtcreator:v15.0.0
QTCREATOR_URL=https://github.com/qt-creator/qt-creator/releases/download/v15.0.0/qtcreator-linux-x64-15.0.0.deb
CMAKE_URL=https://github.com/Kitware/CMake/releases/download/v3.31.4/cmake-3.31.4-linux-x86_64.tar.gz
CMDTOOLS_URL=https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip

echo "QT_VERSION=${QT_VERSION}" >.env
echo "QT_VERSION_SHORT=${QT_VERSION_SHORT}"  >>.env
echo "QTCREATOR_IMAGE_NAME=${QTCREATOR_IMAGE_NAME}" >>.env
echo "QTCREATOR_URL=${QTCREATOR_URL}" >>.env
echo "CMAKE_URL=${CMAKE_URL}" >>.env
echo "CMDTOOLS_URL=${CMDTOOLS_URL}" >>.env

echo "USER_ID=$(id -u)" >>.env
echo "GROUP_ID=$(id -g)" >>.env
# Пути для X11
echo "XSOCK=/tmp/.X11-unix" >>.env
echo "XAUTH=${HOME}/.Xauthority" >>.env

# Имена томов
echo "SRC_VOLUME_NAME=${QT_VERSION}-src-volume" >>.env
echo "OPT_VOLUME_NAME=${QT_VERSION}-opt-volume" >>.env
echo "CCACHE_VOLUME=ccache-volume" >>.env

printenv

# Загружаем статические конфиги в текущую сессию (опционально)
set -a
source .env
set +a

#docker compose  build

docker compose   run --rm --service-ports qtcreator bash
