#!/bin/bash

set -e
set -x

TMP_DIRECTORY=~/.rpcsx-setup-wsl
REBOOT_REQUIRED=0
mkdir -p $TMP_DIRECTORY
cd $TMP_DIRECTORY
sudo add-apt-repository -y ppa:oibaf/graphics-drivers
sudo apt install -y build-essential cmake libunwind-dev libglfw3-dev libvulkan-dev libsox-dev git libasound2-dev nasm g++-14
sudo apt install -y pkgconf libasound2-plugins vainfo mesa-va-drivers

if ! [[ -f ~/.asoundrc ]] || [[ ! `grep 'pcm.default pulse' ~/.asoundrc` ]]; then
    echo "pcm.default pulse" >> ~/.asoundrc
    REBOOT_REQUIRED=1
fi

if ! [[ ! `grep 'ctl.default pulse' ~/.asoundrc` ]]; then
    echo "ctl.default pulse" >> ~/.asoundrc
    REBOOT_REQUIRED=1
fi

git clone --depth 1 https://github.com/KhronosGroup/Vulkan-ExtensionLayer.git
git clone --depth 1 --recursive https://github.com/RPCSX/rpcsx.git

cd Vulkan-ExtensionLayer
cmake -B build -D UPDATE_DEPS=ON -DCMAKE_BUILD_TYPE=Release
cmake --build build -j$(nproc)
sudo cmake --build build --target install -j$(nproc)

cd ../rpcsx
cmake -B build -DCMAKE_BUILD_TYPE=Release -DCMAKE_CXX_FLAGS_INIT="-march=native" -DCMAKE_CXX_COMPILER=g++-14
cmake --build build -j$(nproc)
sudo cp build/bin/rpcsx /bin
cd ~
rm -rf $TMP_DIRECTORY

if [[ ! `grep 'export VK_LAYER_PATH=/usr/local/share/vulkan/explicit_layer.d/:$VK_LAYER_PATH'` ]]; then
    echo 'export VK_LAYER_PATH=/usr/local/share/vulkan/explicit_layer.d/:$VK_LAYER_PATH' >> ~/.profile
fi

if [[ ! `grep 'export VK_INSTANCE_LAYERS=VK_LAYER_KHRONOS_shader_object'` ]]; then
    echo 'export VK_INSTANCE_LAYERS=VK_LAYER_KHRONOS_shader_object' >> ~/.profile
fi

if [[ $REBOOT_REQUIRED == 1 ]]; then
    sudo init 0
fi
