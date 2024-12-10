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

# 检查 Prover 是否可执行
check_prover_executable() {
    local prover_path="$NEXUS_HOME/prover"
    if [ ! -f "$prover_path" ]; then
        echo -e "${RED}Prover 文件未找到: $prover_path${NC}"
        exit 1
    fi
    if [ ! -x "$prover_path" ]; then
        chmod +x "$prover_path"
        echo -e "${YELLOW}已赋予 Prover 可执行权限${NC}"
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
        echo -e "${GREEN}日志文件路径: $PROVER_LOG${NC}"
    else
        echo -e "${RED}Prover 启动失败，请检查日志: $PROVER_LOG${NC}"
        exit 1
    fi
}

# 检查日志内容
check_log_output() {
    if [ -s "$PROVER_LOG" ]; then
        echo -e "${GREEN}日志文件内容:${NC}"
        tail -n 10 "$PROVER_LOG"
    else
        echo -e "${RED}日志文件为空，请检查 Prover 是否正确运行${NC}"
    fi
}

# 主逻辑
main() {
    echo -e "${YELLOW}=== 开始部署 Nexus Prover ===${NC}"

    # 停止已运行的 Prover
    stop_prover

    # 检查 Prover 文件
    check_prover_executable

    # 启动 Prover
    start_prover

    # 检查日志输出
    echo -e "${YELLOW}检查日志内容...${NC}"
    check_log_output

    echo -e "${GREEN}部署完成！使用 screen -r $SCREEN_SESSION 查看运行状态${NC}"
}

# 脚本入口
main
