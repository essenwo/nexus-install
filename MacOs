#!/bin/bash

# =======================================================
# Nexus Network CLI Mac 一键安装脚本
# 适用于 macOS 系统
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
        
        # 添加Homebrew到PATH（适用于Apple Silicon Mac）
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
    
    # 确保Rust在PATH中
    export PATH="$HOME/.cargo/bin:$PATH"
}

# 安装Nexus CLI
install_nexus_cli() {
    print_info "安装Nexus Network CLI..."
    
    # 下载并运行安装脚本
    curl https://cli.nexus.xyz/ | sh
    
    print_success "Nexus CLI安装完成"
}

# 刷新环境变量
refresh_environment() {
    print_info "刷新环境变量..."
    
    # 重新加载shell配置
    if [[ $SHELL == *"zsh"* ]]; then
        source ~/.zshrc 2>/dev/null || true
        print_info "已重新加载zsh配置"
    elif [[ $SHELL == *"bash"* ]]; then
        source ~/.bashrc 2>/dev/null || true
        print_info "已重新加载bash配置"
    fi
    
    # 确保各种环境变量都已设置
    export PATH="$HOME/.cargo/bin:$PATH"
    
    # 如果是Apple Silicon Mac，确保Homebrew路径
    if [[ -f /opt/homebrew/bin/brew ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
    
    print_success "环境变量刷新完成"
}

# 验证安装
verify_installation() {
    print_info "验证安装..."
    
    # 检查nexus-network命令是否可用
    if command -v nexus-network &> /dev/null; then
        print_success "Nexus CLI验证成功"
        return 0
    else
        # 尝试查找nexus-network命令
        NEXUS_PATHS=(
            "$HOME/.nexus/nexus-network"
            "$HOME/.local/bin/nexus-network"
            "/usr/local/bin/nexus-network"
        )
        
        for path in "${NEXUS_PATHS[@]}"; do
            if [[ -x "$path" ]]; then
                print_success "找到Nexus CLI: $path"
                export PATH="$(dirname $path):$PATH"
                return 0
            fi
        done
        
        print_warning "未找到nexus-network命令，但安装可能成功"
        print_info "请手动检查或重新启动终端"
        return 0
    fi
}

# 启动Nexus节点
start_nexus_node() {
    print_step "启动Nexus Network节点"
    echo ""
    print_info "请访问 https://app.nexus.xyz 获取您的Node ID"
    echo ""
    
    # 获取Node ID
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
    print_info "正在启动Nexus Network节点..."
    print_warning "节点将在前台运行，按Ctrl+C可停止"
    echo ""
    
    # 尝试启动节点
    if command -v nexus-network &> /dev/null; then
        nexus-network start --node-id "$NODE_ID"
    else
        # 尝试使用完整路径
        NEXUS_PATHS=(
            "$HOME/.nexus/nexus-network"
            "$HOME/.local/bin/nexus-network"
            "/usr/local/bin/nexus-network"
        )
        
        for path in "${NEXUS_PATHS[@]}"; do
            if [[ -x "$path" ]]; then
                "$path" start --node-id "$NODE_ID"
                exit 0
            fi
        done
        
        print_error "无法找到nexus-network命令"
        print_info "请尝试重新启动终端，然后运行:"
        echo "nexus-network start --node-id $NODE_ID"
    fi
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
    refresh_environment
    verify_installation
    
    echo ""
    print_step "🎉 安装完成！"
    echo ""
    
    # 询问是否立即启动
    read -p "是否现在启动Nexus节点？(y/N): " start_now
    if [[ $start_now =~ ^[Yy]$ ]]; then
        start_nexus_node
    else
        echo ""
        print_info "稍后启动节点请运行："
        echo "nexus-network start --node-id <your-node-id>"
        echo ""
        print_info "获取Node ID请访问: https://app.nexus.xyz"
    fi
}

main "$@"
