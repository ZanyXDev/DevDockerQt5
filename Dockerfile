# ------------------- Base images ----------------------------------------------
FROM ubuntu:22.04 AS stage_0
ARG QT_VERSION
ARG TARGETARCH
ARG CMAKE_URL
ARG QTCREATOR_URL    
ARG CMDTOOLS_URL 
ENV ANDROID_SDK_ROOT="/opt/android-sdk"
ENV ANDROID_NDK_ROOT="/opt/android-sdk/ndk"    

RUN <<EOF
    set -eux; 
    echo "go-faster apt" 
    echo 'Acquire::Languages "none";' > /etc/apt/apt.conf.d/90nolanguages
    echo 'APT::Get::Install-Recommends "false";'> /etc/apt/apt.conf.d/99nosuggest
    echo 'APT::Get::Install-Suggests "false";' >> /etc/apt/apt.conf.d/99nosuggest
    export DEBIAN_FRONTEND=noninteractive 
    apt-get -y update  
    apt-get -y upgrade 
    apt-get -y install wget unzip git
EOF

RUN <<EOF
    set -eux; \
    [[ -d /opt/cmake ]] || mkdir /opt/cmake   
    [[ -d /opt/download/ ]] || mkdir /opt/download/ 
    [[ -d /opt/qt-creator ]] || mkdir /opt/qt-creator     
    [[ -d /opt/android-sdk]] || mkdir /opt/android-sdk 
    [[ -d ${ANDROID_NDK_ROOT}/samples ]] || mkdir -p ${ANDROID_NDK_ROOT}/samples 
    (  
     wget -O /opt/download/cmake.tar.gz ${CMAKE_URL}
     wget -O /opt/download/qtcreator.deb ${QTCREATOR_URL}
     echo "Download ndk samples"
     wget -O /opt/download/master.zip https://github.com/android/ndk-samples/archive/master.zip
     echo "Download buildtool to generate aab packages in ${ANDROID_SDK_ROOT}"
     wget -O ${ANDROID_SDK_ROOT}/bundletool-all-1.3.0.jar https://github.com/google/bundletool/releases/download/1.3.0/bundletool-all-1.3.0.jar
     echo "Download cmdline-tools"
     wget -O /opt/download/commandlinetools.zip ${CMDTOOLS_URL} 
    )&  
    last_task_pid=$! 
    wait  $last_task_pid    
    tar -xzf /opt/download/cmake.tar.gz  --strip-components=1 -C /opt/cmake  
    dpkg --extract  /opt/download/qtcreator.deb / 
    echo "Unzip cmdLineTools" 
    unzip /opt/download/commandlinetools.zip -d /opt 
    echo "Move ndk samples in ${ANDROID_NDK_ROOT}/samples" 
    cd /opt/download/ 
    unzip -q master.zip 
    mv ndk-samples-master ${ANDROID_NDK_ROOT}/samples    
EOF

RUN set -eux; \   
    echo "Use Clone sources KDAB openssl" ;\
    git clone --depth 1 https://github.com/KDAB/android_openssl.git || git -C /opt/android-sdk/android_openssl pull

RUN set -eux; \  	
      mkdir -p /usr/local/src/fonts/adobe-fonts/source-code-pro ;\
      git clone https://github.com/adobe-fonts/source-code-pro.git /usr/local/src/fonts/adobe-fonts/source-code-pro 

#-------------------------------------------------------------------------------
FROM ubuntu:22.04 AS stage_1

LABEL Description="This image based on Ubuntu 22.04,provides a base development \
                   environment (Linux and Android) for Qt developers"
ARG QT_WEBKIT
ARG QT_WEBENGINE
ARG QT_VERSION
ARG TARGETARCH

ENV QT_WEBKIT=${QT_WEBKIT:-"n"}
ENV QT_WEBENGINE=${QT_WEBENGINE:-"n"}

RUN set -eux; \
    echo "go-faster apt"; \
    echo 'Acquire::Languages "none";' > /etc/apt/apt.conf.d/90nolanguages;\
    echo 'APT::Get::Install-Recommends "false";'> /etc/apt/apt.conf.d/99nosuggest;\
    echo 'APT::Get::Install-Suggests "false";' >> /etc/apt/apt.conf.d/99nosuggest;\
    export DEBIAN_FRONTEND=noninteractive ;\
    apt-get -y update  ;\
    apt-get -y upgrade ;\
    echo "Build essentials for ubuntu/debian" ;\
    apt-get -y install build-essential perl python3 ccache ;\
	echo "Ninja build tools"; \
	apt-get install ninja-build ;\
    echo "Other cpp tools"; \
    apt-get install -y cppcheck graphviz doxygen git meld gdb lldb clang-format autoconf;\
    echo "Other debug tools"; \
    apt-get install -y strace;\    
    echo "Memory leaks cpp tools"; \
    apt-get install -y valgrind;\
    echo "Fontconfig library"; \
    apt-get install -y libfontconfig1-dev fontconfig;\   
    echo "Crypto tools"; \
    apt-get install -y apt-transport-https  ca-certificates gnupg libssl3 openssl ;\
    echo "#Install some libs";\
    apt-get install -y locales libncurses5 libdouble-conversion3 libc6 libc-bin libicu70  libtool xmlstarlet;\    
    echo "Libxcb packets" ;\
    apt-get -y install '^libxcb.*-dev' libx11-xcb-dev libglu1-mesa-dev libxrender-dev libxi-dev libxkbcommon-dev libxkbcommon-x11-dev \
                        libxcb-xinerama0-dev libxcb-xinput-dev libxcb-xkb-dev libxkbfile-dev ;\
    echo "Mesa-specific OpenGL extensions" ;\
    apt-get -y install mesa-common-dev libgl1-mesa-dev ;\ 
    echo "Qt Multimedia You'll need at least alsa-lib [>= 1.0.15] and gstreamer [>=0.10.24] with the base-plugins package."  ;\
    apt-get -y install  pulseaudio libpulse-dev ; \    
    apt-get -y install  libasound2-dev libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev libgstreamer-plugins-good1.0-dev libgstreamer-plugins-bad1.0-dev ;\
    apt-get -y install  gstreamer1.0-plugins-good gstreamer1.0-plugins-bad gstreamer1.0-libav ; \    
    echo "QDoc Documentation Generator Tool Ubuntu/Debian " ;\
    apt-get -y install clang libclang-dev ;\
    if [ "$QT_WEBKIT" = "y" ]; then \
      echo "Qt WebKit Ubuntu/Debian" >>/root/installed_deb.log;\	
      apt-get -y install flex bison gperf libicu-dev libxslt-dev ruby; \
    fi; \
    if [ "$QT_WEBENGINE" = "y" ]; then \
        echo "Qt WebEngine Ubuntu/Debian" ;\	
        apt-get -y install libxcursor-dev libxcomposite-dev libxdamage-dev libxrandr-dev libxtst-dev libxss-dev libdbus-1-dev libevent-dev \
	                   libcap-dev libpulse-dev libudev-dev libpci-dev libnss3-dev libasound2-dev libegl1-mesa-dev \
			           gperf bison nodejs; \
    fi; \   
    echo "Auth Tool Ubuntu/Debian " ;\
    apt-get -y install sudo nano mc ;\   
    echo "Add small X11 tools Ubuntu/Debian " ;\
    apt-get -y install xprintidle ;\      
    apt-get clean -y && rm -rf /var/lib/apt/lists/*
    
FROM stage_1 AS stage_2
# Declare build parameters.
ARG QT_VERSION
ARG TARGETARCH
ARG BUILD_TAG
ARG QTCREATOR_URL
ARG USER_ID
ARG GROUP_ID
ARG QTCREATOR_URL
ARG TZ
# Set environment variables, see Readme.md
# Allow colored output on command line.
ENV TERM=xterm-color  
# +Timezone (если надо на этапе сборки)
ENV TZ=Europe/Moscow
# Add libusb dans library path
ENV LD_LIBRARY_PATH=/usr/local/lib
ENV xdg_runtime_dir=/run/user/"${USER_ID}"
ENV DISPLAY=:0
ENV PERSIST=1
ENV DEBIAN_FRONTEND="noninteractive" 
ENV PS1="\u@${BUILD_TAG}:\w\$ "
ENV LANG=ru_RU.UTF-8
ENV LANGUAGE=ru_RU:ru
ENV LC_LANG=ru_RU.UTF-8
ENV LC_ALL=ru_RU.UTF-8
ENV HOME=/home/developer

#Troubleshooting
#Enabling the logging categories under qt.qpa is a good idea in general. This will show some debug prints both from eglfs and the input handlers.
#ENV QT_LOGGING_RULES=qt.qpa.*=true

ENV QT_HOST_PATH="/opt/Qt/${QT_VERSION}-amd64-lts-lgpl/:${QT_HOST_PATH}"
ENV QT_HOST_PATH="/opt/Qt/${QT_VERSION}-android-lts-lgpl/:${QT_HOST_PATH}"
ENV QT_PLUGIN_PATH="/opt/Qt/${QT_VERSION}-amd64-lts-lgpl/plugins:${QT_PLUGIN_PATH}"
ENV QT_PLUGIN_PATH="/opt/Qt/${QT_VERSION}-android-lts-lgpl/plugins:${QT_PLUGIN_PATH}"
ENV QML_IMPORT_PATH="/opt/Qt/${QT_VERSION}-amd64-lts-lgpl/qml:${QML_IMPORT_PATH}"
ENV QML_IMPORT_PATH="/opt/Qt/${QT_VERSION}-android-lts-lgpl/qml:${QML_IMPORT_PATH}"
ENV QML2_IMPORT_PATH="/opt/Qt/${QT_VERSION}-amd64-lts-lgpl/qml:${QML2_IMPORT_PATH}"
ENV QML2_IMPORT_PATH="/opt/Qt/${QT_VERSION}-android-lts-lgpl/qml:${QML2_IMPORT_PATH}"
ENV QT_QPA_FONTDIR="/usr/share/fonts/truetype"

ENV OPENSSL_ROOT_DIR="/opt/android_openssl/ssl_1.1"

ENV JAVA_HOME=/opt/java/openjdk
ENV JRE_CACERTS_PATH=/opt/java/openjdk/lib/security/cacerts
ENV JAVA_VERSION="jdk-17.0.13"

ENV PATH="/opt/cmake/bin:${PATH}"
ENV PATH="${JAVA_HOME}/bin:${PATH}"
ENV PATH="/opt/Qt/${QT_VERSION}-amd64-lts-lgpl/bin:${PATH}"
ENV PATH="/opt/Qt/${QT_VERSION}-android-lts-lgpl/bin:${PATH}"
ENV PATH="/opt/qt-creator/bin:${PATH}"

ENV ANDROID_SDK_ROOT="/opt/android-sdk"
ENV ANDROID_NDK_ROOT="/opt/android-sdk/ndk"    

ENV FONT_PATH="/usr/local/src/fonts/adobe-fonts/source-code-pro"

#Чтобы внутри контейнера работал отладчик, добавил это, решение взял отсюда
#https://askubuntu.com/questions/41629/after-upgrade-gdb-wont-attach-to-process
#RUN echo 0 > /etc/sysctl.d/10-ptrace.conf

RUN <<EOF
    set -eux
    echo "/usr/local/lib" >> /etc/ld.so.conf.d/x86_64-linux-gnu.conf 
    echo "/opt/Qt/${QT_VERSION}-amd64-lts-lgpl/lib" >> /etc/ld.so.conf.d/x86_64-linux-gnu.conf 
    echo "/opt/Qt/${QT_VERSION}-android-lts-lgpl/lib" >> /etc/ld.so.conf.d/x86_64-linux-gnu.conf 
    /sbin/ldconfig 
    echo "Generate locale" 
    sed -i -e 's/# ru_RU.UTF-8 UTF-8/ru_RU.UTF-8 UTF-8/' /etc/locale.gen 
    locale-gen 
    echo "Setup timezone" 
    ln -snf /usr/share/zoneinfo/$TZ /etc/localtime 
    echo $TZ > /etc/timezone 
    if [ ${USER_ID:-0} -ne 0 ] && [ ${GROUP_ID:-0} -ne 0 ]; then 
      groupadd -g ${GROUP_ID} developer
      useradd -u ${USER_ID} -g ${GROUP_ID} developer
      install -d -m 0755 -o developer -g ${GROUP_ID} /home/developer
      adduser developer sudo
      echo "adding user developer to audio group"
      adduser developer audio
      echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers
      mkdir -p /home/developer                   
      chown ${USER_ID}:${GROUP_ID} -R /home/developer
      echo "finished installing"        
    fi    
EOF
COPY --from=eclipse-temurin:17 $JAVA_HOME $JAVA_HOME
COPY --from=stage_0 /opt /opt
COPY --from=stage_0 $FONT_PATH $FONT_PATH

RUN --mount=type=tmpfs,target=/workspace/build \
    cd /workspace/build && \
    echo "setup darcula theme..." && \   
    git clone https://github.com/dracula/qtcreator.git || git -C /workspace/build/qtcreator pull && \
    cd /workspace/build/qtcreator && \
    ls -la && \
    ls -la /opt/qt-creator/share/qtcreator && \    
    cp dracula.xml          /opt/qt-creator/share/qtcreator/styles && \
    cp drakula.creatortheme /opt/qt-creator/share/qtcreator/themes && \
    cp drakula.figmatokens  /opt/qt-creator/share/qtcreator/themes  
RUN chown ${USER_ID}:${GROUP_ID} -R /opt   

USER developer  
RUN set -eux; \
    git config --global --add safe.directory '*'
WORKDIR /home/developer
    
ENTRYPOINT [ "/bin/bash", "-l", "-c" ]    
