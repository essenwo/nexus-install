#!/bin/bash

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

print_success() { echo -e "${GREEN}✅ $1${NC}"; }
print_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
print_step() { echo -e "${PURPLE}🚀 $1${NC}"; }

echo ""
print_step "Nexus Network 一键安装脚本"
echo ""

# 检查系统
print_info "检查系统..."
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo "❌ 仅支持macOS"
    exit 1
fi

# 安装依赖
print_info "安装依赖..."
if ! command -v brew &> /dev/null; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

if ! command -v protoc &> /dev/null; then
    brew install protobuf
fi

if ! command -v rustc &> /dev/null; then
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source "$HOME/.cargo/env"
fi

# 安装Nexus CLI（使用官方方法）
print_info "安装Nexus CLI..."

# 直接使用官方安装命令，强制非交互
echo "y" | curl https://cli.nexus.xyz/ | sh

# 更新环境变量
source ~/.zshrc 2>/dev/null || true
source ~/.bash_profile 2>/dev/null || true
export PATH="$HOME/.local/bin:$HOME/.nexus:$PATH"

print_success "安装完成"

# 查找nexus-network命令
nexus_cmd=""
if command -v nexus-network &> /dev/null; then
    nexus_cmd="nexus-network"
elif [[ -x "$HOME/.local/bin/nexus-network" ]]; then
    nexus_cmd="$HOME/.local/bin/nexus-network"
elif [[ -x "$HOME/.nexus/nexus-network" ]]; then
    nexus_cmd="$HOME/.nexus/nexus-network"
else
    echo "❌ 未找到nexus-network"
    exit 1
fi

# 获取Node ID（真正等待用户输入）
echo ""
print_step "请输入Node ID（访问 https://app.nexus.xyz 获取）"
echo ""

# 这次真正等待用户输入
while true; do
    echo -n "请输入您的Node ID: "
    read NODE_ID
    
    if [[ -n "$NODE_ID" && "$NODE_ID" != "" ]]; then
        echo ""
        print_info "Node ID已设置: $NODE_ID"
        break
    else
        echo "❌ Node ID不能为空，请重新输入"
    fi
done

echo ""
print_info "启动Nexus Network..."
echo ""

# 启动
exec "$nexus_cmd" start --node-id "$NODE_ID"
