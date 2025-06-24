#!/bin/bash

# =======================================================
# Nexus Network CLI Mac 一键安装脚本
# 安装完成后提示输入Node ID，输入完自动启动
# =======================================================

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

print_success() { echo -e "${GREEN}✅ $1${NC}"; }
print_error() { echo -e "${RED}❌ $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
print_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
print_step() { echo -e "${PURPLE}🚀 $1${NC}"; }

show_banner() {
    clear
    echo ""
    print_step "========================================="
    print_step "   Nexus Network Mac 一键安装脚本"
    print_step "========================================="
    echo ""
}

# 检查系统
check_system() {
    print_info "检查系统兼容性..."
    if [[ "$OSTYPE" != "darwin"* ]]; then
        print_error "此脚本仅适用于 macOS 系统"
        exit 1
    fi
    print_success "系统检查通过"
}

# 安装Homebrew
install_homebrew() {
    print_info "检查并安装Homebrew..."
    if command -v brew &> /dev/null; then
        print_success "Homebrew已安装"
    else
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        # Apple Silicon Mac路径配置
        if [[ -f /opt/homebrew/bin/brew ]]; then
            echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
            eval "$(/opt/homebrew/bin/brew shellenv)"
        fi
        print_success "Homebrew安装完成"
    fi
}

# 安装系统依赖
install_dependencies() {
    print_info "安装系统依赖..."
    
    # 安装protobuf
    if ! command -v protoc &> /dev/null; then
        brew install protobuf > /dev/null 2>&1
    fi
    
    # 安装Rust
    if ! command -v rustc &> /dev/null; then
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y > /dev/null 2>&1
        source "$HOME/.cargo/env"
    fi
    
    export PATH="$HOME/.cargo/bin:$PATH"
    print_success "系统依赖安装完成"
}

# 安装Nexus CLI
install_nexus_cli() {
    print_info "安装Nexus Network CLI..."
    
    # 静默安装，自动确认
    echo "y" | bash <(curl -s https://cli.nexus.xyz/) > /dev/null 2>&1
    
    print_success "Nexus CLI安装完成"
}

# 配置环境变量
configure_environment() {
    print_info "配置环境变量..."
    
    # 更新所有可能的配置文件
    source ~/.zshrc 2>/dev/null || true
    source ~/.bash_profile 2>/dev/null || true
    source ~/.cargo/env 2>/dev/null || true
    
    # 设置PATH
    export PATH="$HOME/.cargo/bin:$HOME/.nexus:$HOME/.local/bin:$PATH"
    
    # Apple Silicon Mac特殊处理
    if [[ -f /opt/homebrew/bin/brew ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
    
    print_success "环境配置完成"
}

# 启动Nexus（包含Node ID输入）
start_nexus() {
    clear
    echo ""
    print_step "🎉 安装完成！准备启动Nexus Network"
    echo ""
    
    # 查找nexus-network命令
    nexus_cmd=""
    if command -v nexus-network &> /dev/null; then
        nexus_cmd="nexus-network"
    elif [[ -x "$HOME/.nexus/nexus-network" ]]; then
        nexus_cmd="$HOME/.nexus/nexus-network"
    elif [[ -x "$HOME/.local/bin/nexus-network" ]]; then
        nexus_cmd="$HOME/.local/bin/nexus-network"
    else
        # 搜索nexus-network
        nexus_cmd=$(find ~ -name "nexus-network" -type f -executable 2>/dev/null | head -1)
    fi
    
    if [[ -z "$nexus_cmd" ]]; then
        print_error "未找到nexus-network命令"
        print_info "请重启终端后手动运行: nexus-network start --node-id <your-id>"
        exit 1
    fi
    
    print_success "Nexus CLI已就绪"
    echo ""
    print_info "请访问 https://app.nexus.xyz 获取您的Node ID"
    echo ""
    
    # 获取Node ID输入
    while true; do
        read -p "$(echo -e "${BLUE}请输入您的Node ID: ${NC}")" NODE_ID
        if [[ -n "$NODE_ID" && "$NODE_ID" != " " ]]; then
            break
        else
            print_warning "Node ID不能为空，请重新输入"
        fi
    done
    
    echo ""
    print_success "Node ID已设置: $NODE_ID"
    print_info "正在启动Nexus Network..."
    print_warning "程序开始运行，按Ctrl+C可停止"
    echo ""
    echo "================================================================"
    echo ""
    
    # 启动nexus-network
    "$nexus_cmd" start --node-id "$NODE_ID"
}

# 错误处理
handle_error() {
    print_error "安装失败"
    print_info "请检查网络连接和系统权限"
    exit 1
}

trap 'handle_error' ERR

# 主函数
main() {
    show_banner
    check_system
    install_homebrew
    install_dependencies
    install_nexus_cli
    configure_environment
    
    # 等待2秒确保安装完成
    sleep 2
    
    # 启动节点（包含用户输入Node ID）
    start_nexus
}

main "$@"
