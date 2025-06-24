#!/bin/bash

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
        print_info "正在安装Homebrew（可能需要几分钟）..."
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
        print_info "安装protobuf..."
        brew install protobuf
        print_success "protobuf安装完成"
    else
        print_success "protobuf已安装"
    fi
    
    # 安装Rust
    if ! command -v rustc &> /dev/null; then
        print_info "安装Rust..."
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
        source "$HOME/.cargo/env"
        print_success "Rust安装完成"
    else
        print_success "Rust已安装"
    fi
    
    export PATH="$HOME/.cargo/bin:$PATH"
}

# 安装Nexus CLI（改进版，防止卡死）
install_nexus_cli() {
    print_info "安装Nexus Network CLI..."
    
    # 方法1：使用timeout防止卡死
    if timeout 300 bash -c "echo 'y' | curl -s https://cli.nexus.xyz/ | sh" 2>/dev/null; then
        print_success "Nexus CLI安装完成"
    else
        print_warning "方法1失败，尝试方法2..."
        
        # 方法2：手动下载安装脚本
        curl -s https://cli.nexus.xyz/ -o /tmp/nexus_install.sh
        chmod +x /tmp/nexus_install.sh
        
        if echo "y" | timeout 300 /tmp/nexus_install.sh 2>/dev/null; then
            print_success "Nexus CLI安装完成"
        else
            print_warning "方法2失败，尝试方法3..."
            
            # 方法3：直接下载二进制文件（如果可用）
            print_info "尝试直接下载Nexus CLI..."
            mkdir -p "$HOME/.nexus"
            
            # 这里可能需要根据实际情况调整下载链接
            if curl -L -o "$HOME/.nexus/nexus-network" "https://github.com/nexus-xyz/nexus-cli/releases/latest/download/nexus-network-macos" 2>/dev/null; then
                chmod +x "$HOME/.nexus/nexus-network"
                print_success "Nexus CLI下载完成"
            else
                print_error "所有安装方法都失败了"
                print_info "请手动安装Nexus CLI:"
                echo "curl https://cli.nexus.xyz/ | sh"
                exit 1
            fi
        fi
        
        # 清理临时文件
        rm -f /tmp/nexus_install.sh
    fi
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

# 启动Nexus
start_nexus() {
    clear
    echo ""
    print_step "🎉 安装完成！准备启动Nexus Network"
    echo ""
    
    # 查找nexus-network命令
    nexus_cmd=""
    
    # 等待一下，确保安装完全完成
    sleep 3
    
    # 重新加载环境
    source ~/.zshrc 2>/dev/null || true
    export PATH="$HOME/.cargo/bin:$HOME/.nexus:$HOME/.local/bin:$PATH"
    
    if command -v nexus-network &> /dev/null; then
        nexus_cmd="nexus-network"
    elif [[ -x "$HOME/.nexus/nexus-network" ]]; then
        nexus_cmd="$HOME/.nexus/nexus-network"
    elif [[ -x "$HOME/.local/bin/nexus-network" ]]; then
        nexus_cmd="$HOME/.local/bin/nexus-network"
    else
        # 最后的搜索
        print_info "正在查找Nexus CLI..."
        nexus_cmd=$(find ~ -name "nexus-network" -type f -executable 2>/dev/null | head -1)
    fi
    
    if [[ -z "$nexus_cmd" ]]; then
        print_error "未找到nexus-network命令"
        print_info "请重启终端后手动运行:"
        echo "source ~/.zshrc"
        echo "nexus-network start --node-id <your-id>"
        print_info "或访问 https://docs.nexus.xyz 查看安装指南"
        exit 1
    fi
    
    print_success "找到Nexus CLI: $nexus_cmd"
    echo ""
    print_info "请访问 https://app.nexus.xyz 获取您的Node ID"
    echo ""
    
    # 获取Node ID
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

# 主函数
main() {
    show_banner
    check_system
    install_homebrew
    install_dependencies
    install_nexus_cli
    configure_environment
    start_nexus
}

# 按Ctrl+C停止脚本
trap 'echo -e "\n❌ 安装被中断"; exit 1' INT

main "$@"
