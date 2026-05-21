#!/usr/bin/env bash
# deploy.sh — Deepsee 云服务器一键部署脚本
# 用法：bash deploy.sh [server_ip]
# 在本地执行，通过 SSH 部署到远程服务器
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info()  { echo -e "${GREEN}[INFO]${NC} $1"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }
err()   { echo -e "${RED}[ERR]${NC} $1"; }

if [ $# -lt 1 ]; then
    echo "用法: bash deploy.sh <server-ip> [ssh-user]"
    echo "示例: bash deploy.sh 123.123.123.123 root"
    exit 1
fi

SERVER_IP="$1"
SSH_USER="${2:-root}"
SSH_DEST="${SSH_USER}@${SERVER_IP}"
DEEPSEE_DIR="/opt/deepsee"

info "=== Deepsee 云服务器部署 ==="
info "目标服务器: $SERVER_IP"
info "安装目录: $DEEPSEE_DIR"
echo ""

# 1. 检查 SSH 连接
info "检查 SSH 连接..."
ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=accept-new "$SSH_DEST" "echo 'SSH OK'" || {
    err "SSH 连接失败，请检查: ssh ${SSH_DEST}"
    exit 1
}

# 2. 安装系统依赖
info "安装系统依赖..."
ssh "$SSH_DEST" bash -s << 'REMOTE'
set -euo pipefail
if command -v apt-get &>/dev/null; then
    apt-get update -qq
    apt-get install -y -qq python3 python3-venv python3-pip git curl nginx certbot python3-certbot-nginx 2>/dev/null || true
elif command -v yum &>/dev/null; then
    yum install -y python3 python3-pip git nginx 2>/dev/null || true
fi
REMOTE

# 3. 克隆 Deepsee
info "克隆 Deepsee 仓库..."
ssh "$SSH_DEST" "rm -rf ${DEEPSEE_DIR} && git clone https://github.com/leecyno1/Deepsee.git ${DEEPSEE_DIR}"

# 4. 配置 .env
info "配置 .env..."
# 生成随机 API token
API_TOKEN=$(openssl rand -hex 32)
AGENT_TOKEN=$(openssl rand -hex 32)

cat > /tmp/deepsee_env.txt << ENVEOF
APP_ENV=production
HOST=0.0.0.0
PORT=8000
DATABASE_URL=sqlite:///./data/app.db
AI_MAX_PARALLEL=2
SILICONFLOW_API_KEY=sk-your-key
SILICONFLOW_API_URL=https://api.siliconflow.cn/v1
SILICONFLOW_MODEL=Qwen/Qwen3-30B-A3B
SILICONFLOW_TOOL_MODEL=Qwen/Qwen3-8B
API_TOKEN=${API_TOKEN}
AGENT_API_TOKEN=${AGENT_TOKEN}
AGENT_API_ALLOWLIST=/api/health,/api/ready,/api/messages,/api/email,/api/newsfeed,/api/ai,/api/send,/api/wechat-gateway,/api/config
AGENT_API_BLOCKLIST=/api/admin/cleanup,/api/admin/aggregation-retention/prune
SYNC_INTERVAL_SECONDS=0
NEWSNOW_REFRESH_INTERVAL_SECONDS=3600
WECHATPAD_HTTP_BASE=http://api.wechatapi.net/finder/v2/api
ENVEOF

scp /tmp/deepsee_env.txt "${SSH_DEST}:${DEEPSEE_DIR}/.env" >/dev/null 2>&1
rm -f /tmp/deepsee_env.txt

# 5. 安装 Python 依赖
info "安装 Python 依赖..."
ssh "$SSH_DEST" "cd ${DEEPSEE_DIR} && python3 -m venv .venv && .venv/bin/pip install -q -r requirements.txt"

# 6. 初始化数据库
info "初始化数据库..."
ssh "$SSH_DEST" "cd ${DEEPSEE_DIR} && .venv/bin/python -c 'from app.db import init_db; init_db()'"

# 7. 启动服务
info "启动 Deepsee 服务..."
ssh "$SSH_DEST" "cd ${DEEPSEE_DIR} && nohup .venv/bin/uvicorn app.main:app --host 0.0.0.0 --port 8000 > uvicorn.log 2>&1 &"
sleep 3

# 8. 检查服务状态
info "检查服务状态..."
HEALTH=$(ssh "$SSH_DEST" "curl -s http://127.0.0.1:8000/api/health" 2>/dev/null || echo "failed")
if echo "$HEALTH" | grep -q '"status":"ok"'; then
    info "✓ Deepsee 启动成功！"
else
    warn "服务启动中或未正常运行，请检查日志："
    warn "  ssh ${SSH_DEST} 'cat ${DEEPSEE_DIR}/uvicorn.log'"
fi

# 9. 配置 Nginx（可选）
read -p "是否配置 Nginx 反向代理？(y/n): " SETUP_NGINX
if [ "$SETUP_NGINX" = "y" ] || [ "$SETUP_NGINX" = "Y" ]; then
    read -p "请输入域名（留空则绑定 IP）: " DOMAIN
    if [ -n "$DOMAIN" ]; then
        ssh "$SSH_DEST" "cat > /etc/nginx/sites-available/deepsee << 'NGINX'
server {
    listen 80;
    server_name ${DOMAIN};
    client_max_body_size 50M;
    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
    }
}
NGINX
ln -sf /etc/nginx/sites-available/deepsee /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default
nginx -t && systemctl reload nginx"

        info "Nginx 已配置。如需 SSL，执行："
        info "  ssh ${SSH_DEST} 'certbot --nginx -d ${DOMAIN}'"
    fi
fi

# 输出摘要
echo ""
info "═══════════════════════════════════════"
info " 部署完成！"
info "═══════════════════════════════════════"
info "服务地址：http://${SERVER_IP}:8000"
info "API Token：${API_TOKEN}"
info "Agent Token：${AGENT_TOKEN}"
info ""
info "下一步："
info "1. 访问管理界面：http://${SERVER_IP}:8000/"
info "2. 设置 wechatapi token + appId："
info "   curl -X POST http://${SERVER_IP}:8000/api/wechat-gateway/config \\"
info "     -H 'Content-Type: application/json' \\"
info "     -d '{\"token\":\"<your-token>\",\"app_id\":\"<your-appid>\",\"base_url\":\"http://api.wechatapi.net/finder/v2/api\",\"callback_public_url\":\"http://${SERVER_IP}:8000/api/wechat-gateway/callback\"}'"
info "3. 绑定回调："
info "   curl -X POST http://${SERVER_IP}:8000/api/wechat-gateway/bind-callback"
info "4. 微信扫码登录：在管理界面操作"
info "5. 配置 AI 模型：在管理界面 → AI 设置"
info ""
info "wx-auto 文档（Agent 加载用）：https://github.com/leecyno1/wx-auto"
echo ""
