#!/bin/bash

echo "🚀 Nexus Network 一键安装"

# 安装依赖
if ! command -v brew &> /dev/null; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi
brew install protobuf

if ! command -v rustc &> /dev/null; then
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source "$HOME/.cargo/env"
fi

# 安装Nexus CLI
curl https://cli.nexus.xyz/ | sh

# 更新环境
source ~/.zshrc

echo "✅ 安装完成"
echo ""
echo "请访问 https://app.nexus.xyz 获取Node ID"
echo -n "请输入Node ID: "
read NODE_ID

echo "🚀 启动中..."
nexus-network start --node-id "$NODE_ID"
