# Deepsee + WeChat Automation 部署操作手册

> 面向：新服务器运维人员
> 目标：从零部署一套微信自动化系统，包含服务器端部署、微信绑定、Hermes 集成、回复机制配置。

---

## 一、系统架构

```
┌──────────────────┐      HTTP       ┌──────────────────────────┐      POST      ┌──────────────────┐
│  Hermes Agent     │ ◄─────────────► │   Deepsee Server         │ ◄─────────────► │  wechatapi.net   │
│  (AI 决策层)      │   /api/*       │   (消息存储 + 微信网关 +  │   callback     │  (iPad 协议)     │
│                   │                │    队列/规则执行)        │                │                  │
│  本地 / 另一台    │                │   :8000                  │                │  收发微信消息    │
└──────────────────┘                └──────────────────────────┘                └──────────────────┘
                                              │
                                       [SQLite DB]
                                      data/app.db
```

**三个角色：**

| 角色 | 位置 | 用途 |
|------|------|------|
| **Deepsee** | 云服务器（有固定公网 IP） | 核心后端：消息存储、接收微信回调、触发规则、队列与发送编排；自动回复文本由 Hermes bridge 统一生成 |
| **Hermes** | 本地或另一台机器 | AI 决策层：调用 Deepsee API 查询数据、发送消息、管理配置，并作为唯一 prompt/model 解释与生成入口 |
| **wechatapi.net** | 第三方服务 | iPad 协议底座：收发微信消息的底层通道 |

**关键设计：**
- 微信消息 → wechatapi.net → 回调到 Deepsee → 存储入库
- Deepsee 根据触发规则判断是否进入自动回复队列
- Hermes bridge 基于 subsession 配置统一解释 prompt 并生成回复
- Deepsee 负责最终发送、日志、重试与状态记录

---

## 二、服务器准备

### 2.1 最低配置

| 项目 | 要求 |
|------|------|
| OS | Ubuntu 22.04+ / Debian 12+ |
| CPU | 2 核 |
| 内存 | 4 GB |
| 磁盘 | 20 GB+ |
| Python | 3.11+ |
| 网络 | 固定公网 IP（必需，微信回调用） |

### 2.2 初始环境

```bash
# 更新系统
apt update && apt upgrade -y

# 安装基础工具
apt install -y git curl vim python3 python3-venv python3-pip

# 验证 Python 版本（需 >= 3.11）
python3 --version
```

---

## 三、部署 Deepsee

### 3.1 克隆仓库

```bash
git clone https://github.com/leecyno1/Deepsee.git /opt/deepsee
cd /opt/deepsee
```

### 3.2 创建 .env 配置文件

```bash
cp .env.production-lite.example .env
vim .env
```

### 3.3 参数说明

以下为**必须配置**的参数：

| 参数 | 值示例 | 说明 |
|------|--------|------|
| `HOST` | `0.0.0.0` | **必须改**。监听所有网络接口，默认只监听 127.0.0.1 |
| `PORT` | `8000` | 服务端口，可自定义 |
| `AGENT_API_TOKEN` | 随机字符串如 `dGp8...` | Hermes 调用 Deepsee 的认证密钥，**请生成一个强随机串** |
| `SILICONFLOW_API_KEY` | `sk-xxx...` | Deepsee 本地分析/兼容链路使用；生产自动回复主链路由 Hermes bridge 负责 |
| `SILICONFLOW_API_URL` | `https://api.siliconflow.cn/v1` | 默认即可 |
| `SILICONFLOW_MODEL` | `Qwen/Qwen3-30B-A3B` | 默认即可，如需更换模型 |
| `SILICONFLOW_TOOL_MODEL` | `Qwen/Qwen3-8B` | 工具调用模型，默认即可 |

以下为**可选**参数：

| 参数 | 默认值 | 说明 |
|------|--------|------|
| `DATABASE_URL` | `sqlite:///./data/app.db` | 数据库路径，默认 SQLite |
| `AI_MAX_PARALLEL` | `2` | AI 分析最大并行数，4C 可改为 4 |
| `SYNC_INTERVAL_SECONDS` | `0` | 同步间隔（秒），0 为手动触发 |
| `NEWSNOW_REFRESH_INTERVAL_SECONDS` | `3600` | 新闻刷新间隔 |

以下参数**不需要**在 .env 中填写（通过 Deepsee API 配置）：

| 参数 | 说明 |
|------|------|
| `WECHATPAD_HTTP_BASE` | 已内置默认值，通常不需改 |
| wechatapi token/appId | 部署完成后通过 API 设置（见第 4 章） |

### 3.4 标准 .env 示例

```ini
APP_ENV=production
HOST=0.0.0.0
PORT=8000
DATABASE_URL=sqlite:///./data/app.db

SYNC_INTERVAL_SECONDS=0
AI_MAX_PARALLEL=2

SILICONFLOW_API_KEY=sk-your-key-here
SILICONFLOW_API_URL=https://api.siliconflow.cn/v1
SILICONFLOW_MODEL=Qwen/Qwen3-30B-A3B
SILICONFLOW_TOOL_MODEL=Qwen/Qwen3-8B

AGENT_API_TOKEN=<请替换为强随机字符串>
```

### 3.5 启动 Deepsee

```bash
# 安装依赖并初始化
bash scripts/manage.sh prod-lite

# 启动服务
bash scripts/manage.sh start
```

### 3.6 验证服务

```bash
# 健康检查
curl http://127.0.0.1:8000/api/health

# 期望输出：
# {"status":"ok","version":"0.8.0","uptime":"..."}
```

如果一切正常，Deepsee 已运行在 `http://<服务器公网IP>:8000`。

### 3.7 管理命令速查

```bash
bash scripts/manage.sh start      # 启动
bash scripts/manage.sh stop       # 停止
bash scripts/manage.sh restart    # 重启
bash scripts/manage.sh logs       # 查看日志

# 日志文件位于：uvicorn.log
tail -f uvicorn.log               # 实时查看日志
```

---

## 四、配置 WeChat 连接

### 4.1 准备凭证

需要以下信息（由用户提供）：

| 凭证 | 说明 |
|------|------|
| wechatapi token | API 认证令牌，格式如 `v_xxx...` |
| wechatapi appId | 微信设备 ID，格式如 `wx_xxx...` |

### 4.2 设置网关配置

```bash
# 将 <token> 和 <appId> 替换为实际值
# 将 <server_public_ip> 替换为服务器公网 IP

curl -X POST http://127.0.0.1:8000/api/wechat-gateway/config \
  -H "Content-Type: application/json" \
  -d '{
    "base_url": "http://api.wechatapi.net/finder/v2/api",
    "token": "<wechatapi-token>",
    "app_id": "<wechatapi-appid>",
    "callback_public_url": "http://<server_public_ip>:8000/api/wechat-gateway/callback"
  }'

# 验证配置已写入
curl http://127.0.0.1:8000/api/wechat-gateway/config
```

### 4.3 绑定回调

向 wechatapi.net 注册回调地址，使微信消息能实时推送到 Deepsee：

```bash
curl -X POST http://127.0.0.1:8000/api/wechat-gateway/bind-callback
```

### 4.4 微信登录

方式 A — 通过浏览器访问管理界面：

```
http://<服务器公网IP>:8000/
```
进入 WeChat → 登录设置 → 获取二维码 → 微信扫码 → 确认登录。

方式 B — 通过 API 获取二维码：

```bash
curl http://127.0.0.1:8000/api/wechat-gateway/login-qrcode
```

扫码登录后验证在线状态：

```bash
curl http://127.0.0.1:8000/api/wechat-gateway/check-online
```

---

## 五、回复机制（Trigger Rules）

### 5.1 工作原理

```
用户发消息 → wechatapi.net → 回调 → Deepsee 接收
                                           │
                                   触发规则判断
                                   是否应该自动回复？
                                           │
                              ┌────────────┼────────────┐
                              YES          条件不足        NO
                              │             │             │
                         生成回复       记录消息      静默跳过
                         发送消息       等待后续        不处理
                         回复用户       AI 决策
```

触发规则让 Deepsee 判断**哪些消息需要自动回复、什么时候回复**。

### 5.2 默认规则

```bash
curl http://127.0.0.1:8000/api/wechat-gateway/trigger-rules
```

会看到当前生效的规则。默认情况下，Deepsee 的触发规则包含：

| 规则 | 说明 |
|------|------|
| `enable_auto_reply` | 是否开启自动回复（默认 true） |
| `prefixes` | 消息前缀触发列表，如 `["ai", "bot", "/"]` |
| `wakeup_keywords` | 唤醒词列表，如 `["@助手"]` |
| `suppression_seconds` | 同一会话回复冷却时间（秒），默认 120 |
| `silence_hours` | 免打扰时段，如 `23:00-07:00` |
| `rate_limit_per_minute` | 每分钟全局最大回复数，默认 5 |

### 5.3 自定义触发规则

```bash
curl -X POST http://127.0.0.1:8000/api/wechat-gateway/trigger-rules \
  -H "Content-Type: application/json" \
  -d '{
    "enable_auto_reply": true,
    "prefixes": ["ai", "bot", "/", "!"],
    "wakeup_keywords": ["@助手", "小助手"],
    "suppression_seconds": 120,
    "silence_hours": "23:00-07:00",
    "rate_limit_per_minute": 5
  }'
```

**参数详解：**

| 参数 | 说明 | 建议值 |
|------|------|--------|
| `prefixes` | 消息以此前缀开头时触发回复。如 "ai 你好" → 触发 | `["ai", "bot", "/"]` |
| `wakeup_keywords` | 消息包含这些词即触发，不论位置 | `["@助手"]` |
| `enable_auto_reply` | 总开关 | `true` |
| `suppression_seconds` | 同一聊天窗口连续回复的间隔，防止刷屏 | `120`（2 分钟） |
| `silence_hours` | 免打扰时间段，格式 `HH:MM-HH:MM` | `"23:00-07:00"` |
| `rate_limit_per_minute` | 全局每分钟最大回复数 | `5` |

### 5.4 测试回复

```bash
# 模拟一条消息，让 Deepsee 评估是否触发回复
curl -X POST http://127.0.0.1:8000/api/wechat-gateway/evaluate-reply \
  -H "Content-Type: application/json" \
  -d '{
    "chat_id": "wxid_xxx",
    "sender_id": "wxid_xxx",
    "text": "ai 你好",
    "is_group": false
  }'
```

---

## 六、Hermes 集成

Hermes 是 AI 决策层，负责复杂的消息处理、数据分析、上下文记忆。需要通过 gateway 配置连接到 Deepsee。

### 6.1 Hermes config.yaml 配置

编辑 `~/.hermes/config.yaml`，添加 gateway 段：

```yaml
gateway:
  platforms:
    deepsee_wechat:
      type: webhook
      enabled: true
      base_url: "http://<服务器公网IP>:8000"
      api_key: "<AGENT_API_TOKEN>"
      extra:
        host: 127.0.0.1
        port: 8643
```

关键参数：

| 参数 | 说明 |
|------|------|
| `base_url` | Deepsee 服务器地址，含端口 |
| `api_key` | 必须与 Deepsee .env 中的 `AGENT_API_TOKEN` 一致 |
| `extra.host` | Hermes 本地监听地址，默认 127.0.0.1 |
| `extra.port` | Hermes 监听端口，不要与 API Server 冲突 |

### 6.2 验证连接

```bash
# Hermes 重启后检查 gateway 是否正常
hermes gateway list

# 测试调用 Deepsee API
curl -H "Authorization: Bearer <AGENT_API_TOKEN>" \
  http://<服务器公网IP>:8000/api/health
```

### 6.3 Hermes API Server（可选）

如果 Hermes 和 Deepsee 需要双向通信，同时开启 API Server：

```yaml
api_server:
  enabled: true
  host: "0.0.0.0"
  port: 8642
  api_key: "your-hermes-api-key"
```

---

## 七、子会话（Subsession）配置

子会话机制让 Deepsee 为每个微信联系人/群维护独立的会话配置；其中 `system_prompt` 是权威数据源，但只允许 Hermes bridge 统一解释，Deepsee 不再作为第二套 prompt/model 回复引擎。

### 7.1 查看当前子会话配置

```bash
# 查看某个联系人或群的子会话配置
# {id} 可以是 wxid 或群 @chatroom
curl http://127.0.0.1:8000/api/wechat-gateway/subsession-config/<chat_id>
```

### 7.2 配置子会话

```bash
curl -X POST http://127.0.0.1:8000/api/wechat-gateway/subsession-config/<chat_id> \
  -H "Content-Type: application/json" \
  -d '{
    "system_prompt": "你是一个投资研究助手，专注于金融领域分析。回复简洁、数据驱动。",
    "model": "Qwen/Qwen3-30B-A3B",
    "history_limit": 50,
    "enable_summary": true,
    "summary_interval": 10
  }'
```

**参数说明：**

| 参数 | 说明 | 默认值 |
|------|------|--------|
| `system_prompt` | 该联系人的专属角色设定（由 Hermes bridge 解释） | 全局默认 |
| `model` | 兼容/调试字段；生产自动回复不应依赖这里作为第二生成出口 | 全局默认 |
| `history_limit` | 上下文保留的最大消息数 | 50 |
| `enable_summary` | 是否启用历史摘要压缩 | true |
| `summary_interval` | 每 N 条消息生成一次摘要 | 10 |

### 7.3 典型场景

**场景 A：群聊助手**
```json
{
  "chat_id": "xxx@chatroom",
  "system_prompt": "你是群聊助手，回复简洁有趣，适当使用表情。仅在 @你 时回复。",
  "history_limit": 30
}
```

**场景 B：一对一投资咨询**
```json
{
  "chat_id": "wxid_xxx",
  "system_prompt": "你是一位资深投资顾问，回复专业、数据驱动，引用具体数据支撑观点。",
  "history_limit": 100
}
```

**场景 C：静默群（只记录不回复）**
```json
{
  "chat_id": "xxx@chatroom",
  "enable_auto_reply": false
}
```

---

## 八、日常运维

### 8.1 查看运行状态

```bash
# Deepsee 健康检查
curl http://127.0.0.1:8000/api/health

# 后台任务状态
curl http://127.0.0.1:8000/api/background/runtime

# 查看日志
tail -f /opt/deepsee/uvicorn.log
```

### 8.2 更新 Deepsee

```bash
cd /opt/deepsee
git pull origin main
bash scripts/manage.sh restart
```

### 8.3 更新 WeChat 回调

如果服务器 IP 变更或 wechatapi token 更新：

```bash
# 重新设置网关配置（IP 或 token 有变动时）
curl -X POST http://127.0.0.1:8000/api/wechat-gateway/config \
  -H "Content-Type: application/json" \
  -d '{
    "base_url": "http://api.wechatapi.net/finder/v2/api",
    "token": "<新token>",
    "app_id": "<appId>",
    "callback_public_url": "http://<新IP>:8000/api/wechat-gateway/callback"
  }'

# 重新绑定回调
curl -X POST http://127.0.0.1:8000/api/wechat-gateway/bind-callback
```

### 8.4 检查微信在线状态

```bash
# 通过 Deepsee 查询
curl http://127.0.0.1:8000/api/wechat-gateway/check-online

# 微信掉线时，重新获取二维码登录
curl http://127.0.0.1:8000/api/wechat-gateway/login-qrcode
```

### 8.5 数据备份

```bash
# 备份 SQLite 数据库
cp /opt/deepsee/data/app.db /opt/deepsee/backups/app.db.$(date +%Y%m%d)
```

---

## 九、常见问题

### Q1: Deepsee 启动后无法访问

```bash
# 检查服务是否运行
bash scripts/manage.sh status

# 检查端口是否监听
ss -tlnp | grep 8000

# 检查防火墙
ufw status
# 如需开放端口
ufw allow 8000
```

### Q2: 微信消息收不到

1. 检查回调是否已绑定：重新执行 `bind-callback`
2. 检查服务器 IP 是否可达：`curl http://<IP>:8000/api/health`
3. 检查微信是否在线：`curl http://127.0.0.1:8000/api/wechat-gateway/check-online`
4. 查看 Deepsee 日志：`tail -f /opt/deepsee/uvicorn.log | grep callback`

### Q3: 自动回复不生效

1. 检查 trigger-rules 配置：`enable_auto_reply` 是否为 `true`
2. 检查消息前缀是否匹配：发送 `ai hello` 测试
3. 检查是否在免打扰时段内
4. 检查 `rate_limit_per_minute` 是否已达上限

### Q4: Hermes 连不上 Deepsee

1. 确认 `AGENT_API_TOKEN` 在两边一致
2. 确认服务器防火墙已放行 8000 端口
3. 直接 `curl` 测试：`curl -H "Authorization: Bearer <token>" http://<IP>:8000/api/health`

---

## 十、快速参考卡

### 部署一条命令

```bash
# 在服务器上执行
git clone https://github.com/leecyno1/Deepsee.git /opt/deepsee
cd /opt/deepsee
cp .env.production-lite.example .env
# 编辑 .env：修改 HOST=0.0.0.0、AGENT_API_TOKEN、SILICONFLOW_API_KEY（SILICONFLOW 仅保留给兼容链路）
bash scripts/manage.sh prod-lite
bash scripts/manage.sh start
```

### 配置微信一条命令

```bash
# 替换 <token> <appId> <IP>
curl -X POST http://127.0.0.1:8000/api/wechat-gateway/config \
  -H "Content-Type: application/json" \
  -d '{"base_url":"http://api.wechatapi.net/finder/v2/api","token":"<token>","app_id":"<appId>","callback_public_url":"http://<IP>:8000/api/wechat-gateway/callback"}'
curl -X POST http://127.0.0.1:8000/api/wechat-gateway/bind-callback
```

### Hermes config 一条配置

```yaml
# 添加到 ~/.hermes/config.yaml
gateway:
  platforms:
    deepsee_wechat:
      type: webhook
      enabled: true
      base_url: "http://<IP>:8000"
      api_key: "<AGENT_API_TOKEN>"
      extra:
        host: 127.0.0.1
        port: 8643
```
