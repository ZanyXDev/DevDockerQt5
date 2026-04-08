#!/usr/bin/env bash
set -Eeuxo pipefail # https://vaneyckt.io/posts/safer_bash_scripts_with_set_euxo_pipefail/

# Загружаем статические конфиги в текущую сессию (опционально)
set -a
source .env
set +a
 
echo "USER_ID=$(id -u)" >generate.env
echo "GROUP_ID=$(id -g)" >>generate.env
# Пути для X11
echo "XSOCK=/tmp/.X11-unix" >>generate.env
echo "XAUTH=${HOME}/.Xauthority" >>generate.env

# Имена томов
echo "SRC_VOLUME_NAME=${QT_VERSION}-src-volume" >>generate.env
echo "OPT_VOLUME_NAME=${QT_VERSION}-opt-volume" >>generate.env
echo "CCACHE_VOLUME=ccache-volume" >>generate.env

docker compose --env-file generate.env  build

#docker compose run --env-file generate.env --rm --service-ports qtcreator ls /opt
