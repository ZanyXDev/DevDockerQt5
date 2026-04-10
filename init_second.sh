#!/usr/bin/env bash
set -Euo pipefail
# set -x  # Раскомментируйте только для отладки
#Пт 10 апр 2026 20:24:21 
# =============================================================================
# 1. Валидация и дефолты критических переменных
# =============================================================================
: "${QT_VERSION:?❌ Error: QT_VERSION is not set. Pass via ENV/ARG.}"
: "${CMAKE_URL:?❌ Error: CMAKE_URL is not set.}"
: "${QTCREATOR_URL:?❌ Error: QTCREATOR_URL is not set.}"
: "${CMDTOOLS_URL:?❌ Error: CMDTOOLS_URL is not set.}"

export USER_ID="${USER_ID:-1000}"
export GROUP_ID="${GROUP_ID:-1000}"
export ANDROID_HOME="/opt/android-sdk"
export ANDROID_SDK_ROOT="${ANDROID_HOME}"
export ANDROID_NDK_ROOT="${ANDROID_HOME}/ndk/22.1.7171670"

echo "📦 Configuring environment: Qt=${QT_VERSION}, UID=${USER_ID}:GID=${GROUP_ID}"

# =============================================================================
# 2. Создание директорий
# =============================================================================
echo '📁 Creating directory structure...'
mkdir -p /opt/workspace/download \
         /opt/qt-creator \
         "${ANDROID_HOME}" \
         "${ANDROID_NDK_ROOT}/samples" \
         /opt/cmake \
         /usr/local/src/fonts/adobe-fonts/source-code-pro \
         /opt/workspace/dracula \
         /tmp/build_qt_amd64 \
         /tmp/build_qt_android

# =============================================================================
# 3. Загрузка и распаковка зависимостей
# =============================================================================
if [ ! -f /opt/.initialized ]; then
    echo '⬇️ Downloading dependencies...'
    NDK_SAMPLES="https://github.com/android/ndk-samples/archive/master.zip"
    BUNDLE_TOOLS="https://github.com/google/bundletool/releases/download/1.3.0/bundletool-all-1.3.0.jar" 
    declare -a DOWNLOADS=(
        "${CMAKE_URL}#/opt/workspace/download/cmake.tar.gz"
        "${QTCREATOR_URL}#/opt/workspace/download/qtcreator.deb"
        "${NDK_SAMPLES}#/opt/workspace/download/master.zip"
        "${CMDTOOLS_URL}#/opt/workspace/download/commandlinetools.zip"
        "${BUNDLE_TOOLS}#/opt/workspace/download/bundletool.jar"
    )
    for item in "${DOWNLOADS[@]}"; do
        IFS='#' read -r url dest <<< "$item"
# Срезаем возможные лишние пробелы в начале и конце строки
    	url=$(echo "$url" | xargs)
    	dest=$(echo "$dest" | xargs)
	wget -v -c -O "$dest" "$url" || { echo "❌ Failed to download $url to $dest"; exit 1; }
    done &
    wait $! || exit 1

    echo '📦 Extracting dependencies...'
    tar -xzf /opt/workspace/download/cmake.tar.gz --strip-components=1 -C /opt/cmake
    # Безопасная установка .deb 
    apt-get install -y /opt/workspace/download/qtcreator.deb 
    unzip -o /opt/workspace/download/commandlinetools.zip -d /opt
    unzip -o /opt/workspace/download/ndk-samples.zip -d "${ANDROID_NDK_ROOT}/samples"
    cp /opt/workspace/download/bundletool.jar "${ANDROID_HOME}/bundletool-all-1.3.0.jar"

    # Настройка структуры cmdline-tools для sdkmanager
    CMDLINE_TOOLS_ROOT="/opt/cmdline-tools"
    if [[ -d "${CMDLINE_TOOLS_ROOT}" ]] && [[ ! -d "${CMDLINE_TOOLS_ROOT}/latest" ]]; then
        mkdir -p "${CMDLINE_TOOLS_ROOT}"
        mkdir -p "${CMDLINE_TOOLS_ROOT}/latest"
        mv "${CMDLINE_TOOLS_ROOT}"/* "${CMDLINE_TOOLS_ROOT}/latest/" 2>/dev/null || true
    fi
    export PATH="${CMDLINE_TOOLS_ROOT}/latest/bin:/opt/cmake/bin:${PATH}"

    echo '📲 Installing Android SDK/NDK components...'
    yes | sdkmanager --sdk_root=${ANDROID_SDK_ROOT} --licenses > /dev/null 2>&1
    sdkmanager --sdk_root=${ANDROID_SDK_ROOT} "platforms;android-31" "build-tools;31.0.0" "ndk;22.1.7171670"
    touch /opt/.initialized
    echo '✅ Initialization stage complete.'
else
    echo 'ℹ️ Already initialized. Skipping download/extract.'
fi

# =============================================================================
# 4. Git-репозитории и субмодули
# =============================================================================
if [ ! -f /opt/.cloned ]; then
    echo '🔧 Initializing git repositories...'
    git config --global --add safe.directory '*'

    clone_or_pull() {
        local repo="$1" target="$2"
        if [[ -d "${target}/.git" ]]; then
            echo "   ⬆️ Updating $(basename "$target")..."
            git -C "$target" pull --ff-only
        else
            echo "   📥 Cloning $(basename "$target")..."
            rm -rf "$target"
            git clone --depth 1 "$repo" "$target"
        fi
    }

    clone_or_pull "https://github.com/KDAB/android_openssl.git" "/opt/android-sdk/android_openssl"
    clone_or_pull "https://github.com/adobe-fonts/source-code-pro.git" "/usr/local/src/fonts/adobe-fonts/source-code-pro"
    clone_or_pull "https://github.com/dracula/qtcreator.git" "/opt/workspace/dracula/qtcreator"

    # Исправлена опечатка: drakula -> dracula
    cd /opt/workspace/dracula/qtcreator
    cp -u dracula.xml /opt/qt-creator/share/qtcreator/styles/
    cp -u dracula.creatortheme /opt/qt-creator/share/qtcreator/themes/
    cp -u dracula.figmatokens /opt/qt-creator/share/qtcreator/themes/

    echo "📥 Cloning Qt5 ${QT_VERSION}..."
    if [[ -d "/usr/local/src/qt5/.git" ]]; then
        git -C /usr/local/src/qt5 fetch --depth 1 origin "$QT_VERSION"
        git -C /usr/local/src/qt5 checkout "$QT_VERSION"
    else
        rm -rf /usr/local/src/qt5
        git clone --depth 1 --branch "$QT_VERSION" https://invent.kde.org/qt/qt/qt5.git /usr/local/src/qt5
    fi

    cd /usr/local/src/qt5
    echo "🔗 Initializing Qt5 submodules (skipping heavy ones)..."
    git -c submodule.qt3d.update=none \
        -c submodule.qtactiveqt.update=none \
        -c submodule.qtcanvas3d.update=none \
        -c submodule.qtdatavis3d.update=none \
        -c submodule.qtgamepad.update=none \
        -c submodule.qtlottie.update=none \
        -c submodule.qtmacextras.update=none \
        -c submodule.qtpim.update=none \
        -c submodule.qtquick3d.update=none \
        -c submodule.qtscript.update=none \
        -c submodule.qtscxml.update=none \
        -c submodule.qtspeech.update=none \
        -c submodule.qtvirtualkeyboard.update=none \
        -c submodule.qtwebengine.update=none \
        -c submodule.qtwebglplugin.update=none \
        -c submodule.qtwebsockets.update=none \
        -c submodule.qtwebview.update=none \
        -c submodule.qtwinextras.update=none \
        -c submodule.qtxmlpatterns.update=none \
        submodule update --init --recursive --jobs "$(nproc)"

    touch /opt/.cloned
    echo '✅ Git stage complete.'
else
    echo 'ℹ️ Already cloned. Skipping git.'
fi

# =============================================================================
# 5. Сборка Qt5 для AMD64
# =============================================================================
if [ ! -f /opt/.builded_amd64 ]; then
    echo '🔨 Building Qt5 for amd64...'
    rm -rf /tmp/build_qt_amd64
    mkdir -p /tmp/build_qt_amd64
    cd /tmp/build_qt_amd64

    /usr/local/src/qt5/configure \
        -release -optimize-size -ccache -opensource -confirm-license -dbus \
        -qt-zlib -qt-libjpeg -qt-libpng -qt-freetype -qt-pcre -qt-harfbuzz \
        -fontconfig -nomake tests -nomake examples -no-feature-d3d12 \
        -skip 3d -skip activeqt -skip canvas3d -skip datavis3d -skip doc \
        -skip gamepad -skip lottie -skip macextras -skip quick3d -skip script \
        -skip scxml -skip speech -skip virtualkeyboard -skip qtwebengine \
        -skip webchannel -skip webengine -skip webglplugin -skip websockets \
        -skip webview -skip winextras \
        -prefix "/opt/Qt/${QT_VERSION}-amd64-lts-lgpl" -pkg-config

    make -j "$(nproc)" && make install
    touch /opt/.builded_amd64
    echo '✅ amd64 build complete.'
else
    echo 'ℹ️ Already built for amd64. Skipping.'
fi

# =============================================================================
# 6. Сборка Qt5 для Android
# =============================================================================
if [ ! -f /opt/.builded_android ]; then
    echo '🔨 Building Qt5 for Android...'
    rm -rf /tmp/build_qt_android
    mkdir -p /tmp/build_qt_android
    cd /tmp/build_qt_android

    export ANDROID_NDK_PLATFORM=android-21
    export ANDROID_API_VERSION=android-31
    export ANDROID_BUILD_TOOLS_REVISION=31.0.0

/usr/local/src/qt5/configure  \
    -ccache \
    -opensource \
    -confirm-license \
    -xplatform android-clang \
    -disable-rpath \
    -android-ndk ${ANDROID_NDK_ROOT} \
    -android-sdk ${ANDROID_HOME} \
    -android-ndk-host linux-x86_64 \
    -no-warnings-are-errors \
    -nomake tests \
    -nomake examples \
    -qt-freetype \
    -qt-harfbuzz \
    -qt-libjpeg \
    -qt-libpng \
    -qt-pcre \
    -qt-zlib \
    -skip 3d \
    -skip qtdocgallery \
    -skip activeqt \
    -skip canvas3d \
    -skip connectivity \
    -skip datavis3d \
    -skip doc \
    -skip gamepad \
    -skip location \
    -skip lottie \
    -skip macextras  \
    -skip networkauth \
    -skip qtwebengine \
    -skip quick3d \
    -skip quicktimeline \
    -skip remoteobjects \
    -skip script \
    -skip scxml \
    -skip sensors \
    -skip serialbus \
    -skip serialport \
    -skip speech \
    -skip virtualkeyboard \
    -skip wayland \
    -skip webchannel \
    -skip webengine \
    -skip webglplugin \
    -skip websockets \
    -skip webview \
    -skip x11extras \
    -skip xmlpatterns \
    -no-feature-d3d12 \
    -ssl \
    -skip winextras \
    OPENSSL_INCDIR='/opt/android-sdk/android_openssl/ssl_1.1/include/' \
    OPENSSL_LIBS_DEBUG="-llibssl -llibcrypto" \
    OPENSSL_LIBS_RELEASE="-llibssl -llibcrypto" \
    -prefix /opt/Qt/${QT_VERSION}-android-lts-lgpl

    make -j "$(nproc)" && make install
    touch /opt/.builded_android
    echo '✅ Android build complete.'
else
    echo 'ℹ️ Already built for Android. Skipping.'
fi

# =============================================================================
# 7. Финализация
# =============================================================================
echo '👤 Applying ownership permissions...'
chown -R "${USER_ID}:${GROUP_ID}" /opt
echo '🎉 Initialization & Build finished successfully.'
