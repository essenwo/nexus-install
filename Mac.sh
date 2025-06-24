#!/bin/bash

# =======================================================
# Nexus Network CLI Mac 一键安装脚本（全自动）
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
    echo ""
    print_step "========================================="
    print_step "   Nexus Network CLI Mac 一键安装"
    print_step "   安装完成后自动启动"
    print_step "========================================="
    echo ""
}

# 检查系统是否为Mac
check_system() {
    if [[ "$OSTYPE" != "darwin"* ]]; then
        print_error "此脚本仅适用于 macOS 系统"
        exit 1
    fi
    print_success "系统检查通过 - macOS"
}

# 安装Homebrew
install_homebrew() {
    print_info "检查Homebrew安装状态..."
    
    if command -v brew &> /dev/null; then
        print_success "Homebrew已安装，跳过安装步骤"
    else
        print_info "安装Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        
        if [[ -f /opt/homebrew/bin/brew ]]; then
            echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
            eval "$(/opt/homebrew/bin/brew shellenv)"
        fi

        print_success "Homebrew安装完成"
    fi
}

# 安装protobuf
install_protobuf() {
    print_info "安装protobuf..."
    
    if command -v protoc &> /dev/null; then
        print_success "protobuf已安装，版本: $(protoc --version)"
    else
        brew install protobuf
        print_success "protobuf安装完成，版本: $(protoc --version)"
    fi
}

# 安装Rust
install_rust() {
    print_info "检查Rust安装状态..."
    
    if command -v rustc &> /dev/null; then
        print_success "Rust已安装，版本: $(rustc --version)"
    else
        print_info "安装Rust..."
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
        source "$HOME/.cargo/env"
        print_success "Rust安装完成，版本: $(rustc --version)"
    fi
    
    export PATH="$HOME/.cargo/bin:$PATH"
}

# 安装Nexus CLI（自动接受协议）
install_nexus_cli() {
    print_info "安装Nexus Network CLI..."
    
    yes y | curl https://cli.nexus.xyz/ | sh

    print_success "Nexus CLI安装完成"
}

# 等待安装完成并自动配置环境变量
wait_and_configure() {
    print_info "等待安装完成..."
    sleep 3

    print_info "自动配置环境变量..."
    source ~/.zshrc 2>/dev/null || true
    source ~/.bash_profile 2>/dev/null || true
    source ~/.cargo/env 2>/dev/null || true
    export PATH="$HOME/.cargo/bin:$HOME/.nexus:$HOME/.local/bin:$PATH"
    
    if [[ -f /opt/homebrew/bin/brew ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    fi

    print_success "环境变量配置完成"
}

# 自动启动Nexus
auto_start_nexus() {
    echo ""
    print_step "🎉 安装完成！准备启动Nexus Network"
    echo ""

    nexus_cmd=""
    if command -v nexus-network &> /dev/null; then
        nexus_cmd="nexus-network"
    elif [[ -x "$HOME/.nexus/nexus-network" ]]; then
        nexus_cmd="$HOME/.nexus/nexus-network"
    elif [[ -x "$HOME/.local/bin/nexus-network" ]]; then
        nexus_cmd="$HOME/.local/bin/nexus-network"
    else
        print_warning "正在查找nexus-network命令..."
        possible_paths=$(find ~ -name "nexus-network" -type f 2>/dev/null | head -1)
        if [[ -n "$possible_paths" ]]; then
            nexus_cmd="$possible_paths"
            chmod +x "$nexus_cmd"
        fi
    fi

    if [[ -z "$nexus_cmd" ]]; then
        print_error "未找到nexus-network命令"
        print_info "请重新启动终端，然后手动运行："
        echo "nexus-network start --node-id <your-node-id>"
        return 1
    fi

    print_success "找到Nexus命令: $nexus_cmd"

    echo ""
    print_step "配置Node ID"
    print_info "请访问 https://app.nexus.xyz 获取您的Node ID"
    echo ""

    while true; do
        read -p "请输入您的Node ID: " NODE_ID
        if [[ -n "$NODE_ID" ]]; then
            break
        else
            print_warning "Node ID不能为空，请重新输入"
        fi
    done

    print_success "Node ID设置完成: $NODE_ID"
    echo ""
    print_info "正在启动Nexus Network..."
    print_warning "程序将在前台运行，按Ctrl+C可停止"
    echo ""

    exec "$nexus_cmd" start --node-id "$NODE_ID"
}

# 错误处理
handle_error() {
    print_error "安装过程中发生错误"
    print_info "请检查："
    echo "  1. 网络连接是否正常"
    echo "  2. 系统权限是否足够"
    echo "  3. 是否为macOS系统"
    echo ""
    print_info "如需帮助，请访问: https://docs.nexus.xyz"
    exit 1
}

trap 'handle_error' ERR

# 主函数
main() {
    show_banner
    check_system
    install_homebrew
    install_protobuf
    install_rust
    install_nexus_cli
    wait_and_configure
    auto_start_nexus
}

main "$@"
