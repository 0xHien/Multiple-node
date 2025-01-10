#!/bin/bash

# 显示头部信息
echo "=============================================="
echo "         M  U  L  T  I  G  R  O  W           "
echo "           T  E  S  T  N  E  T              "
echo "        =============================       "
echo "           By Share It Hub                  "
echo "=============================================="
echo "  欢迎使用 MultiGrow 测试网安装程序  "
echo "  让我们开始安装过程！"
echo "=============================================="
echo ""
echo "=============================================="
echo "     要检查节点的状态，您可以使用以下命令：    "
echo "=============================================="
echo ""
echo "1. 检查节点进程是否正在运行："
echo "   ps aux | grep multiple-node"
echo ""
echo "2. 或者，使用 pgrep 查找进程 ID："
echo "   pgrep -af multiple-node"
echo ""
echo "3. 如果您使用的是 systemd（作为服务），可以运行："
echo "   systemctl status multiple-node.service"
echo ""
echo "4. 要查看节点的日志，检查 output.log 文件："
echo "   tail -f output.log"
echo ""
echo "=============================================="
echo "  如果您需要进一步的帮助，随时可以提问！ "
echo "=============================================="
echo ""

# 检查命令是否成功执行
check_command() {
    if [ $? -ne 0 ]; then
        echo "命令执行失败: $1"
        exit 1
    fi
}

# 停止节点并清理旧文件的函数
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

# 获取并校验用户输入
get_user_input() {
    while true; do
        echo "请输入您的账户 ID 和 PIN 来绑定您的账户："
        read -p "账户 ID: " IDENTIFIER
        read -p "设置您的 PIN: " PIN

        # 校验账户 ID 和 PIN 是否为空
        if [[ -z "$IDENTIFIER" || -z "$PIN" ]]; then
            echo "账户 ID 和 PIN 不能为空，请重新输入。"
        else
            break
        fi
    done

    # 获取带宽和存储的输入并校验
    while true; do
        echo "请输入您的下载带宽（单位：Mbps）："
        read BANDWIDTH_DOWNLOAD
        echo "请输入您的上传带宽（单位：Mbps）："
        read BANDWIDTH_UPLOAD
        echo "请输入您的存储（单位：GB）："
        read STORAGE

        # 校验输入是否为数字
        if [[ ! "$BANDWIDTH_DOWNLOAD" =~ ^[0-9]+$ || ! "$BANDWIDTH_UPLOAD" =~ ^[0-9]+$ || ! "$STORAGE" =~ ^[0-9]+$ ]]; then
            echo "请输入有效的数字，请重新输入带宽和存储。"
        else
            break
        fi
    done

    # 将输入的带宽和存储乘以1000
    BANDWIDTH_DOWNLOAD=$((BANDWIDTH_DOWNLOAD * 1000))
    BANDWIDTH_UPLOAD=$((BANDWIDTH_UPLOAD * 1000))
    STORAGE=$((STORAGE * 1000))
}

# 下载并安装节点
download_and_install_node() {
    echo "正在启动系统更新..."
    sudo apt update && sudo apt upgrade -y
    check_command "系统更新"

    echo "检查系统架构..."
    ARCH=$(uname -m)
    if [[ "$ARCH" == "x86_64" ]]; then
        CLIENT_URL="https://cdn.app.multiple.cc/client/linux/x64/multipleforlinux.tar"
    elif [[ "$ARCH" == "aarch64" ]]; then
        CLIENT_URL="https://cdn.app.multiple.cc/client/linux/arm64/multipleforlinux.tar"
    else
        echo "不支持的系统架构: $ARCH"
        exit 1
    fi

    echo "正在从 $CLIENT_URL 下载客户端..."
    wget $CLIENT_URL -O multipleforlinux.tar
    check_command "下载客户端"

    echo "正在解压文件..."
    tar -xvf multipleforlinux.tar
    check_command "解压客户端"

    cd multipleforlinux

    echo "正在授予权限..."
    chmod +x ./multiple-cli ./multiple-node
    check_command "授予执行权限"

    echo "正在将目录添加到系统路径..."
    echo "PATH=\$PATH:$(pwd)" >> ~/.bash_profile
    source ~/.bash_profile

    echo "正在设置权限..."
    chmod -R 777 $(pwd)
}

# 启动节点并绑定账户
start_node_and_bind_account() {
    echo "正在启动 multiple-node..."
    nohup ./multiple-node > output.log 2>&1 &
    check_command "启动 multiple-node"

    echo "正在绑定账户，ID: $IDENTIFIER，PIN: $PIN..."
    multiple-cli bind --bandwidth-download $BANDWIDTH_DOWNLOAD --identifier $IDENTIFIER --pin $PIN --storage $STORAGE --bandwidth-upload $BANDWIDTH_UPLOAD
    check_command "绑定账户"
}

# 询问用户是否要停止现有的节点并从头开始重新安装
echo "您是否想停止现有节点并从头开始重新安装？ (yes/no)"
read RESPONSE
if [[ "$RESPONSE" == "yes" ]]; then
    clean_up  # 停止节点并删除旧文件
    get_user_input  # 获取用户输入
    download_and_install_node  # 下载并安装节点
    start_node_and_bind_account  # 启动节点并绑定账户
else
    echo "跳过清理和重新安装。"
    exit 0
fi

echo "安装成功完成！"
echo "Telegram 频道： https://t.me/SHAREITHUB_COM"
