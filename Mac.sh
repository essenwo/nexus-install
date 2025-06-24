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

# 自动配置和启动
auto_start() {
    print_step "自动配置环境并启动Nexus"
    
    # 自动更新环境变量
    source ~/.zshrc 2>/dev/null || true
    source ~/.bash_profile 2>/dev/null || true
    export PATH="$HOME/.cargo/bin:$HOME/.nexus:$PATH"
    
    print_success "环境变量已自动配置"
    
    # 检查是否设置了Node ID环境变量
    if [[ -n "$NEXUS_NODE_ID" ]]; then
        NODE_ID="$NEXUS_NODE_ID"
        print_success "使用环境变量Node ID: $NODE_ID"
    else
        print_step "Node ID配置"
        print_info "请访问 https://app.nexus.xyz 获取您的Node ID"
        echo ""
        
        while true; do
            read -p "请输入您的Node ID（一次性配置）: " NODE_ID
            if [[ -n "$NODE_ID" ]]; then
                # 保存到环境变量文件
                echo "export NEXUS_NODE_ID=\"$NODE_ID\"" >> ~/.zshrc
                export NEXUS_NODE_ID="$NODE_ID"
                break
            else
                print_warning "Node ID不能为空，请重新输入"
            fi
        done
    fi
    
    print_success "配置完成，正在启动Nexus Network..."
    print_warning "程序将在前台运行，按Ctrl+C可停止"
    echo ""
    
    # 查找并启动nexus-network
    if command -v nexus-network &> /dev/null; then
        nexus-network start --node-id "$NODE_ID"
    elif [[ -x "$HOME/.nexus/nexus-network" ]]; then
        "$HOME/.nexus/nexus-network" start --node-id "$NODE_ID"
    elif [[ -x "$HOME/.local/bin/nexus-network" ]]; then
        "$HOME/.local/bin/nexus-network" start --node-id "$NODE_ID"
    else
        print_error "无法找到nexus-network命令"
        print_info "请重新启动终端后运行: nexus-network start --node-id $NODE_ID"
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
    print_step "🎉 安装完成！开始自动配置..."
    echo ""
    
    # 直接自动启动，不再询问
    auto_start
}

main "$@"
