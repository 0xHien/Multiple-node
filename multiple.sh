#!/bin/bash

# 清理旧的 multiple-node 进程和文件
clean_up() {
    echo "正在停止节点并清理进程..."
    
    # 停止所有与 multiple-node 相关的进程
    sudo pkill -f multiple-node
    check_command "停止 multiple-node 进程"

    # 等待几秒钟确保进程完全停止
    sleep 5

    echo "检查进程是否已停止..."
    if ps aux | grep -v grep | grep -q multiple-node; then
        echo "仍然存在多个 multiple-node 进程，尝试强制停止..."
        sudo pkill -9 -f multiple-node
        check_command "强制停止 multiple-node 进程"
    fi

    echo "删除旧的安装文件..."
    rm -rf multipleforlinux multipleforlinux.tar
    check_command "删除旧文件"

    echo "节点已停止，旧文件已删除。"
}

# 检查命令是否执行成功
check_command() {
    if [ $? -ne 0 ]; then
        echo "错误: $1 失败"
        exit 1
    else
        echo "$1 成功"
    fi
}

# 步骤 1: 清理旧进程和文件
clean_up

# 步骤 2: 安装 multiple-cli
echo "步骤 1: 安装 multiple-cli"
wget https://mdeck-download.s3.us-east-1.amazonaws.com/client/linux/install.sh
source ./install.sh
check_command "安装 multiple-cli"

# 步骤 3: 更新 multiple-cli
echo "步骤 2: 更新多个 CLI"
wget https://mdeck-download.s3.us-east-1.amazonaws.com/client/linux/update.sh
source ./update.sh
check_command "更新 multiple-cli"

# 步骤 4: 启动服务
echo "步骤 3: 启动服务"
wget https://mdeck-download.s3.us-east-1.amazonaws.com/client/linux/start.sh
source ./start.sh
check_command "启动 multiple-cli 服务"

# 步骤 5: 绑定识别码
# 请替换下面的 U8C73H3T 和 PIN 码为你自己的
echo "步骤 4: 绑定识别码"
multiple-cli bind --bandwidth-download 200000 --identifier U8C73H3T --pin 535152 --storage 20000 --bandwidth-upload 200000
check_command "绑定识别码"

echo "安装和配置完成"
