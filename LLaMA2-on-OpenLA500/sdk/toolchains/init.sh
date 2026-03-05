#!/bin/bash

# 1. 下载并解压 Loongson GNU 工具链
wget https://gitee.com/loongson-edu/la32r-toolchains/releases/download/v0.0.3/loongson-gnu-toolchain-8.3-x86_64-loongarch32r-linux-gnusf-v2.0.tar.xz
tar Jxvf loongson-gnu-toolchain-8.3-x86_64-loongarch32r-linux-gnusf-v2.0.tar.xz

# 2. 下载并解压 picolibc
mkdir -p picolibc
cd picolibc
wget https://gitee.com/ffshff/la32r-picolibc/releases/download/V1.0/picolibc.tar.gz
tar zxvf picolibc.tar.gz
cd ..

# 3. 下载并解压 newlib
mkdir -p newlib
cd newlib
wget https://gitee.com/ffshff/newlib-la32r/releases/download/V1.0/newlib.tar.gz
tar zxvf newlib.tar.gz
cd ..

# 4. 配置环境变量到 ~/.bashrc
current_dir=$(pwd)
# 添加工具链到 PATH
echo "export PATH=$current_dir/loongson-gnu-toolchain-8.3-x86_64-loongarch32r-linux-gnusf-v2.0/bin:\$PATH" >> ~/.bashrc
# 修正 CICIEC_WINDOWS_HOME 为你的真实路径
sed -i '$a\export CICIEC_WINDOWS_HOME="/home/f0d471/workspace/Loongarch/LLaMA2-on-OpenLA500"' ~/.bashrc

# 5. 立即生效环境变量（当前终端）
source ~/.bashrc

