#!/bin/bash

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# 变量定义
NEXUS_HOME="$HOME/.nexus"
PROVER_ID_FILE="$NEXUS_HOME/prover-id"
SCREEN_SESSION="nexus-prover"
PROVER_LOG="$NEXUS_HOME/prover.log"
ARCH=$(uname -m)
OS=$(uname -s)

# 检查 OpenSSL 版本
check_openssl_version() {
    if ! command -v openssl &> /dev/null; then
        echo -e "${RED}未安装 OpenSSL，正在安装...${NC}"
        if [ "$OS" = "Linux" ]; then
            sudo apt update
            sudo apt install -y openssl
        elif [ "$OS" = "Darwin" ]; then
            brew install openssl
        fi
    fi

    local version=$(openssl version | cut -d' ' -f2)
    local major_version=$(echo $version | cut -d'.' -f1)
    if [ "$major_version" -lt "3" ]; then
        echo -e "${YELLOW}OpenSSL 版本过低，正在升级...${NC}"
        if [ "$OS" = "Linux" ]; then
            sudo apt install -y openssl
        elif [ "$OS" = "Darwin" ]; then
            brew upgrade openssl
        fi
    fi
    echo -e "${GREEN}OpenSSL 检查完成${NC}"
}

# 检查依赖
check_dependencies() {
    if ! command -v screen &> /dev/null; then
        echo -e "${YELLOW}screen 未安装，正在安装...${NC}"
        if [ "$OS" = "Linux" ]; then
            sudo apt update && sudo apt install -y screen
        elif [ "$OS" = "Darwin" ]; then
            brew install screen
        fi
    fi

    if ! command -v curl &> /dev/null; then
        echo -e "${YELLOW}curl 未安装，正在安装...${NC}"
        if [ "$OS" = "Linux" ]; then
            sudo apt update && sudo apt install -y curl
        elif [ "$OS" = "Darwin" ]; then
            brew install curl
        fi
    fi
}

# 下载 Prover
download_prover() {
    mkdir -p "$NEXUS_HOME"
    local prover_path="$NEXUS_HOME/prover"

    if [ ! -f "$prover_path" ]; then
        echo -e "${YELLOW}下载 Prover...${NC}"
        if [ "$OS" = "Linux" ] && [ "$ARCH" = "x86_64" ]; then
            curl -L "https://github.com/qzz0518/nexus-run/releases/download/v0.4.2/prover-amd64" -o "$prover_path"
        elif [ "$OS" = "Darwin" ] && [ "$ARCH" = "arm64" ]; then
            curl -L "https://github.com/qzz0518/nexus-run/releases/download/v0.4.2/prover-arm64" -o "$prover_path"
        elif [ "$OS" = "Darwin" ] && [ "$ARCH" = "x86_64" ]; then
            curl -L "https://github.com/qzz0518/nexus-run/releases/download/v0.4.2/prover-macos-amd64" -o "$prover_path"
        else
            echo -e "${RED}不支持的操作系统或架构: $OS/$ARCH${NC}"
            exit 1
        fi
        chmod +x "$prover_path"
        echo -e "${GREEN}Prover 下载完成${NC}"
    fi
}

# 设置 Prover ID
setup_prover_id() {
    if [ -n "$1" ]; then
        echo "$1" > "$PROVER_ID_FILE"
        echo -e "${GREEN}使用传入的 Prover ID: $1${NC}"
    elif [ ! -f "$PROVER_ID_FILE" ];then
        local random_id=$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 28)
        echo "$random_id" > "$PROVER_ID_FILE"
        echo -e "${GREEN}生成新的 Prover ID: $random_id${NC}"
    else
        echo -e "${GREEN}已存在 Prover ID: $(cat $PROVER_ID_FILE)${NC}"
    fi
}

# 停止 Prover
stop_prover() {
    if screen -list | grep -q "$SCREEN_SESSION"; then
        echo -e "${YELLOW}停止当前运行的 Prover 会话...${NC}"
        screen -S "$SCREEN_SESSION" -X quit
        echo -e "${GREEN}Prover 会话已停止${NC}"
    else
        echo -e "${RED}没有正在运行的 Prover 会话${NC}"
    fi
}

# 启动 Prover
start_prover() {
    echo -e "${YELLOW}启动 Prover 会话...${NC}"
    screen -dmS "$SCREEN_SESSION" bash -c "cd '$NEXUS_HOME' && ./prover beta.orchestrator.nexus.xyz > $PROVER_LOG 2>&1"

    sleep 2  # 等待 screen 稳定
    if screen -list | grep -q "$SCREEN_SESSION"; then
        echo -e "${GREEN}Prover 已启动，screen 会话名称: $SCREEN_SESSION${NC}"
    else
        echo -e "${RED}Prover 启动失败，请检查日志: $PROVER_LOG${NC}"
        exit 1
    fi
}

# 主逻辑
main() {
    local prover_id="$1"

    echo -e "${YELLOW}=== 开始部署 Nexus Prover ===${NC}"

    # 停止已运行的 Prover
    stop_prover

    # 检查依赖
    check_openssl_version
    check_dependencies

    # 下载 Prover
    download_prover

    # 设置 Prover ID
    setup_prover_id "$prover_id"

    # 启动 Prover
    start_prover

    echo -e "${GREEN}部署完成！使用 screen -r $SCREEN_SESSION 查看运行状态${NC}"
    echo -e "${GREEN}日志文件: $PROVER_LOG${NC}"
}

# 脚本入口
main "$1"
