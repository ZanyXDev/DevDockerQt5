#!/usr/bin/env bash
set -Eeuxo pipefail 
#ENV ANDROID_SDK_ROOT="/opt/android-sdk"
#ENV ANDROID_NDK_ROOT="/opt/android-sdk/ndk" 

if [ ! -f /opt/.initialized ]; then 
    echo '🔧 First run...'; 
    touch /opt/.initialized; 
    echo '✅ Flag created.'; 
    git config --global --add safe.directory '*'
    
    echo '⎆ Create directories ...'
    [[ -d /opt/workspace ]] || mkdir /opt/workspace  
    [[ -d /opt/workspace/download ]] || mkdir /opt/workspace/download/
    [[ -d /opt/qt-creator ]] || mkdir /opt/qt-creator     
    [[ -d /opt/android-sdk ]] || mkdir /opt/android-sdk 
    [[ -d /opt/cmake ]] || mkdir /opt/cmake   
    [[ -d ${ANDROID_NDK_ROOT}/samples ]] || mkdir -p ${ANDROID_NDK_ROOT}/samples 
    [[ -d /usr/local/src/fonts/adobe-fonts/source-code-pro ]] || mkdir -p /usr/local/src/fonts/adobe-fonts/source-code-pro
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
  
    echo '⎆ Clone sources KDAB openssl'
    cd /opt/android-sdk
    git clone --depth 1 https://github.com/KDAB/android_openssl.git || git -C /opt/android-sdk/android_openssl pull
  	
  	echo '⎆ Clone source-code-pro fonts'
  	cd /usr/local/src/fonts/adobe-fonts/
    git clone https://github.com/adobe-fonts/source-code-pro.git || git -C /usr/local/src/fonts/adobe-fonts/source-code-pro pull  
        
    echo '⎆ Setup darcula theme...'
    [[ -d /opt/workspace/dracula ]] || mkdir /opt/workspace/dracula 
    cd /opt/workspace/dracula 
    git clone https://github.com/dracula/qtcreator.git || git -C /opt/workspace/dracula/qtcreator pull 
    cd /opt/workspace/dracula/qtcreator     
    cp -u dracula.xml          /opt/qt-creator/share/qtcreator/styles 
    cp -u drakula.creatortheme /opt/qt-creator/share/qtcreator/themes 
    cp -u drakula.figmatokens  /opt/qt-creator/share/qtcreator/themes  

else 
    echo 'ℹ️ Already initialized.'; 
fi
 
#chown ${USER_ID}:${GROUP_ID} -R /opt 
