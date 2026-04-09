#!/usr/bin/env bash
set -Eeuxo pipefail 
#ENV ANDROID_SDK_ROOT="/opt/android-sdk"
#ENV ANDROID_NDK_ROOT="/opt/android-sdk/ndk" 

if [ ! -f /opt/.initialized ]; then 
    echo '🔧 First run...'; 
    touch /opt/.initialized; 
    echo '✅ Flag created.'; 
    
    echo '⎆ Create directories ...'
    [[ -d /opt/workspace ]] || mkdir /opt/workspace  
    [[ -d /opt/workspace/download ]] || mkdir /opt/workspace/download/
    [[ -d /opt/qt-creator ]] || mkdir /opt/qt-creator     
    [[ -d /opt/android-sdk ]] || mkdir /opt/android-sdk 
    [[ -d /opt/cmake ]] || mkdir /opt/cmake   
    [[ -d ${ANDROID_NDK_ROOT}/samples ]] || mkdir -p ${ANDROID_NDK_ROOT}/samples 
    [[ -d /usr/local/src/fonts/adobe-fonts/source-code-pro ]] || mkdir -p /usr/local/src/fonts/adobe-fonts/source-code-pro
    [[ -d /opt/workspace/dracula ]] || mkdir /opt/workspace/dracula 
    (
     echo '⎆ Download in subshell ..'     
     wget -c -O /opt/workspace/download/cmake.tar.gz ${CMAKE_URL}
     wget -c -O /opt/workspace/download/qtcreator.deb ${QTCREATOR_URL}
     
     echo '▹ Download ndk samples'
     wget -c -O /opt/workspace/download/master.zip https://github.com/android/ndk-samples/archive/master.zip
     
     echo '▹ Download buildtool to generate aab packages in ${ANDROID_SDK_ROOT}'
     wget -c -O ${ANDROID_SDK_ROOT}/bundletool-all-1.3.0.jar https://github.com/google/bundletool/releases/download/1.3.0/bundletool-all-1.3.0.jar
     
     echo '▹ Download cmdline-tools'
     wget -c -O /opt/workspace/download/commandlinetools.zip ${CMDTOOLS_URL} 
    )&  
    last_task_pid=$! 
    wait  $last_task_pid    
    echo '▹ Untar cmake' 
    tar -xzf /opt/workspace/download/cmake.tar.gz --strip-components=1 -C /opt/cmake  
    echo '▹ Extract QtCreator from deb' 
    dpkg --extract  /opt/workspace/download/qtcreator.deb / 
    
    echo '▹ Unzip cmdLineTools'     
    unzip -f /opt/workspace/download/commandlinetools.zip -d /opt 

    echo '▹ Move ndk samples in ${ANDROID_NDK_ROOT}/samples'
    unzip -f /opt/workspace/download/master.zip -d ${ANDROID_NDK_ROOT}/samples      
else 
    echo 'ℹ️ Already initialized.'; 
fi

if [ ! -f /opt/.cloned ]; then 
    echo '🔧 First run git clone...'; 
    touch /opt/.cloned; 
    echo '✅ Flag created.';
    git config --global --add safe.directory '*'
    echo '⎆ Git clone sources KDAB openssl'
    cd /opt/android-sdk
    git clone --depth 1 https://github.com/KDAB/android_openssl.git || git -C /opt/android-sdk/android_openssl pull
  	
  	echo '⎆ Git clone source-code-pro fonts'
  	cd /usr/local/src/fonts/adobe-fonts/
    git clone https://github.com/adobe-fonts/source-code-pro.git || git -C /usr/local/src/fonts/adobe-fonts/source-code-pro pull  
        
    echo '⎆ Git clone darcula theme...'
    cd /opt/workspace/dracula 
    git clone https://github.com/dracula/qtcreator.git || git -C /opt/workspace/dracula/qtcreator pull 
    cd /opt/workspace/dracula/qtcreator     
    cp -u dracula.xml          /opt/qt-creator/share/qtcreator/styles 
    cp -u drakula.creatortheme /opt/qt-creator/share/qtcreator/themes 
    cp -u drakula.figmatokens  /opt/qt-creator/share/qtcreator/themes  
    
    echo "⎆ Git clone ${QT_VERSION}..."
    git clone --depth 1 --branch $QT_VERSION \
		https://invent.kde.org/qt/qt/qt5.git /usr/local/src/qt5 || git -C /usr/local/src/qt5 pull		
	ls -la /usr/local/src/qt5 	
    cd  /usr/local/src/qt5
    echo "▹ Git clone ${QT_VERSION} submodule..." 
    git -c submodule."qt3d".update=none \
        -c submodule."qtactiveqt".update=none \
        -c submodule."qtcanvas3d".update=none  \
        -c submodule."qtdatavis3d".update=none \
        -c submodule."qtgamepad".update=none \
        -c submodule."qtlottie".update=none    \
        -c submodule."qtmacextras".update=none \
        -c submodule."qtpim".update=none \
        -c submodule."qtquick3d".update=none   \
        -c submodule."qtscript".update=none \
        -c submodule."qtscxml".update=none \
        -c submodule."qtspeech".update=none    \
	    -c submodule."qtvirtualkeyboard".update=none \
	    -c submodule."qtwebengine".update=none \
	    -c submodule."qtwebglplugin".update=none \
        -c submodule."qtwebsockets".update=none \
        -c submodule."qtwebview".update=none  \
        -c submodule."qtwinextras".update=none  \
        -c submodule."qtxmlpatterns".update=none \
           submodule update --init --recursive               
else 
    echo 'ℹ️ Already cloned.'; 
fi

  if [ ! -f /opt/.builded_amd64 ]; then 
    echo '🔧 First run build Qt5 for target AMD64...'
    touch /opt/.cloned; 
    echo '✅ Flag created.'
    rm -f -r -d /tmp/build_qt
    [[ -d /tmp/build_qt ]] || mkdir /tmp/build_qt
    cd /tmp/build_qt
    echo '▹ Configure $QT_VERSION...'
    /usr/local/src/qt5/configure  \
        -release \
        -reduce-relocations \
        -optimized-qmake \
        -ccache \
        -opensource \
        -confirm-license \
        -dbus \
        -qt-zlib \
        -qt-libjpeg \
        -qt-libpng \
        -qt-freetype \
        -qt-pcre \
        -qt-harfbuzz \
        -feature-freetype \
        -fontconfig \
        -nomake tests \
        -nomake examples \
        -no-feature-d3d12 \
        -skip 3d \
        -skip activeqt \
        -skip canvas3d \
        -skip datavis3d \
        -skip doc \
        -skip gamepad \
        -skip qtdocgallery \
        -skip lottie \
        -skip macextras \
        -skip quick3d \
        -skip script \
        -skip scxml \
        -skip speech \
        -skip virtualkeyboard \
        -skip qtwebengine \
        -skip webchannel \
        -skip webengine \
        -skip webglplugin \
        -skip websockets \
        -skip webview \
        -skip winextras \
        -prefix  /opt/Qt/${QT_VERSION}-amd64-lts-lgpl -v -pkg-config
    echo '▹ Build $QT_VERSION...'
    make -j $(nproc) 
    echo '▹ Install $QT_VERSION...'
    make -j $(nproc) install 
else 
    echo 'ℹ️ Already builded Qt5 for target AMD64.'; 
fi
       
#chown ${USER_ID}:${GROUP_ID} -R /opt 
