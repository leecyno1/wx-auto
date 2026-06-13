# wx-auto — WeChat Automation Agent Companion

**wx-auto** 是 **Deepsee**（全领域个人信息流 API 平台）的 Agent 端配套包。为 Hermes / Claude / Codex 等 AI Agent 提供 WeChat 自动化所需的：

- **WeChatAPI 协议文档** — 142 页 iPad 协议，归纳为可被 Agent 理解的 API 参考
- **Deepsee API 文档** — 数据查询、发送、网关配置等接口说明
- **云服务器部署脚本** — 支持直接 IP 回调，免隧道
- **Nginx 反向代理配置** — 可选 SSL/域名
- **Hermes Skill** — 一键加载，让 Agent 掌握 WeChat 自动化能力
- **用户使用须知** — 封号风险、快速上手指南，见 `USER_GUIDE.md`

---

## 一键命令指引

**给新 Agent 的安装指引**：直接粘贴以下命令到 Agent 对话中：

```
请按以下步骤完成我们微信自动化系统的安装部署：

1. 从 https://github.com/leecyno1/wx-auto 获取配套配置库
2. 从 https://github.com/leecyno1/Deepsee 克隆后端服务到服务器
3. 部署 Deepsee（提供服务器 IP，用于微信回调地址）
4. 配置 WeChatAPI token + appId
5. 更新 Deepsee 的 Hermes bridge / callback 配置（不要在 wx-auto 文档里再把 Deepsee 写成独立 prompt/model 回复引擎）
6. 将 Hermes API Server 指向 Deepsee 的 agent bridge
```

完整安装步骤见下方。

文档边界：
- 本仓库的正式部署手册是 `DEPLOY.md`，用于 Agent 侧 / Hermes 侧 / 跨机部署
- Deepsee/0913 仓库内部署/迁移的 source of truth 是其仓库内的 `DEPLOY_FULL.md`
- 不要把两个仓库的部署文档合并成一份

---

## 系统架构

### 双渠道 WeChat

```
┌──────────────────────────────────────────────────────────────┐
│ 渠道 A: 0913/Deepsee 桥接 (主渠道)                            │
│                                                                │
│ Hermes ──HTTP──→ Hermes API Server (8642)                      │
│   ▲                  ▲                                          │
│   │                  │ /v1/chat/completions                     │
│   │   ┌──────────────┘                                          │
│   │   │                                                         │
│   │   ▼             hermes_bridge.py                            │
│ [微信用户] ←──→ 0913 FastAPI (:8001) ←── wechatapi.net        │
│                                                                │
│ 能力: 私聊+群聊+朋友圈+公众号+文件+视频                         │
│ 协议: iPad 协议 (wechatapi.net)                                │
├──────────────────────────────────────────────────────────────┤
│ 渠道 B: Hermes Gateway 原生 iLink Bot (辅渠道)                │
│                                                                │
│ [微信用户] ←──→ iLink Bot API ←── Hermes Gateway              │
│                                                                │
│ 能力: 私聊 (DM pairing 模式)                                   │
│ 限制: 无法进入普通微信群                                        │
│ 接入: hermes gateway setup → 选 Weixin → 扫码                  │
└──────────────────────────────────────────────────────────────┘
```

### 自我进化体系

wx-auto 具备**双环路自主进化**能力，Agent 每天自发复盘和改进：

```
┌── 知识大脑进化 ──────────────────────────┐
│  8:00  每日摄入 → 交叉验证 → 置信度评分     │
│  15:10 IMA日报 → 预测归档                   │
│  周一   健康审计 → 衰减管理 → 主题合成       │
│  周一   预测回顾 → 准确率校准                │
└────────────────────────────────────────────┘

┌── 语言能力进化 ──────────────────────────┐
│  23:00 复盘今日微信对话 → 质量评分          │
│    ├─ 发现生硬/答非所问/冷场                 │
│    └─ 自主 patch 提示词规则 + memory 沉淀   │
│                                              │
│  进化循环: 今天对话 → 发现问题 → 修正规则    │
│           → 明天对话变好 → 再复盘 → 再改进   │
└────────────────────────────────────────────┘
```

---

## 系统架构 (原有)

```
┌──────────────────────┐          POST               ┌──────────────────┐
│     Hermes Agent     │ ◄──────────────────────────► │  Deepsee Server  │
│  (wx-auto 加载后)    │     /api/*   (局域网/VPN)    │  (:8000)         │
│                      │                              │                  │
│  技能:               │                              │  引擎:           │
│  · 微信消息处理       │                              │  · 微信网关       │
│  · 联系人管理         │                              │  · 消息引擎       │
│  · 群管理             │                              │  · 公众号        │
│  · 朋友圈操作         │                              │  · 邮件引擎       │
│  · 视频号操作         │                              │  · 新闻引擎       │
│  · 数据查询分析       │                              │  · AI分析         │
└──────┬───────────────┘                              └────────┬─────────┘
       │                                                       │
       │  POST /message/postText                                │ POST /message/postText
       │  (直接调用 wechatapi.net)                              │ (通过 WechatApiClient)
       ▼                                                       ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                wechatapi.net iPad 协议（直接 HTTP 调用）                   │
│    Base: http://api.wechatapi.net/finder/v2/api                        │
│    认证: VideosApi-token header + appId in body                        │
└─────────────────────────────────────────────────────────────────────────┘
```

**两种调用模式：**
1. **通过 Deepsee** — 有业务逻辑、数据持久化、权限控制、微信网关；自动回复的 prompt 解释与文本生成统一由 Hermes bridge 负责（推荐日常使用）
2. **直接调用 wechatapi.net** — 原始协议，适合批量操作或 Deepsee 未封装的功能

---

## 快速部署（云服务器）

### 前置条件

- **服务器**：Linux (Ubuntu 22.04+ / Debian 12+)，2C4G+
- **Python** 3.11+
- **域名**（可选）— 如用直接 IP 回调，需 IP 固定

### 步骤 1：部署 Deepsee

```bash
# SSH 到服务器后执行：
git clone https://github.com/leecyno1/Deepsee.git /opt/deepsee
cd /opt/deepsee
cp .env.production-lite.example .env

# 编辑 .env，填写以下关键配置
# vim .env  # 或使用 nano/vi

# 关键配置：
# HOST=0.0.0.0           # 监听所有接口
# PORT=8000              # 服务端口
# AGENT_API_TOKEN=<随机字符串>  # Agent 调用密钥
# SILICONFLOW_API_KEY=xxx      # Deepsee 本地分析/兼容链路所需；生产自动回复主链路由 Hermes bridge 负责
# WECHATPAD_HTTP_BASE=http://api.wechatapi.net/finder/v2/api  # 或 your_proxy
# 设置 wechatapi 的 token 和 appId（后续通过 API 配置）

# 安装依赖并启动
bash scripts/manage.sh prod-lite
bash scripts/manage.sh start
```

### 步骤 2：配置 Nginx（可选，推荐）

```bash
# 安装 Nginx
apt update && apt install -y nginx certbot python3-certbot-nginx

# 复制 Nginx 配置
# 参见 wx-auto/nginx/deepsee.conf 示例

# 如使用 SSL 域名：
# certbot --nginx -d your-domain.com
```

### 步骤 3：设置 Callback URL

Deepsee 启动后，通过 API 设置微信回调地址：

```bash
# 服务器公网 IP 或域名
PUBLIC_URL="http://your-server-ip:8000"
# 或 https://your-domain.com

# 通过 agent API 设置网关配置
curl -X POST http://127.0.0.1:8000/api/wechat-gateway/config \
  -H "Content-Type: application/json" \
  -d '{
    "base_url": "http://api.wechatapi.net/finder/v2/api",
    "token": "<your-wechatapi-token>",
    "app_id": "<your-wechatapi-appid>",
    "callback_public_url": "'"$PUBLIC_URL"'/api/wechat-gateway/callback"
  }'

# 触发绑定回调
curl -X POST http://127.0.0.1:8000/api/wechat-gateway/bind-callback
```

---

## Hermes 集成配置

### 方式 1：API Server 桥接（推荐）

在 Hermes 的 `config.yaml` 中配置：

```yaml
# ~/.hermes/config.yaml
api_server:
  enabled: true
  host: "0.0.0.0"
  port: 8642
  api_key: "your-hermes-api-key"

# 配置 Deepsee agent bridge
custom_tools:
  deepsee:
    base_url: "http://your-deepsee-server:8000"
    api_key: "<AGENT_API_TOKEN>"
```

### 方式 2：加载 wx-auto Skill

```bash
# 将 wx-auto 下的 skill 复制到 Hermes skills 目录
cp -r /path/to/wx-auto/skill/wx-auto.skill.md ~/.hermes/skills/

# 或在对话中要求 Agent 加载技能：
# "加载 wx-auto 技能"
```

---

## WeChatAPI 协议参考

`wx-auto` 内置了完整的 wechatapi.net iPad 协议 API 参考，按模块组织：

| 文档 | 模块 | 端点数 |
|------|------|:------:|
| [登录模块](docs/wechatapi-login.md) | 登录/登出/重连/代理 | 7 |
| [联系人模块](docs/wechatapi-contacts.md) | 搜索/添加/信息/备注 | 12 |
| [消息模块](docs/wechatapi-message.md) | 发送文本/图片/文件/链接/语音/视频等 | 23 |
| [群管理模块](docs/wechatapi-group.md) | 建群/拉人/踢人/公告/二维码 | 21 |
| [朋友圈模块](docs/wechatapi-sns.md) | 发朋友圈/评论/点赞 | 18 |
| [视频号模块](docs/wechatapi-finder.md) | 搜索/关注/评论/私信 | 28 |
| [个人信息模块](docs/wechatapi-personal.md) | 资料/二维码/安全 | 6 |
| [标签模块](docs/wechatapi-label.md) | 创建/删除/打标签 | 4 |
| [收藏夹模块](docs/wechatapi-favor.md) | 同步/内容/删除 | 3 |
| [企微同步](docs/wechatapi-im.md) | 企微消息同步 | 2 |

### 通用调用方式

```bash
# 所有 POST 请求
POST http://api.wechatapi.net/finder/v2/api/<endpoint>
Headers:
  VideosApi-token: <your-token>
  Content-Type: application/json
Body: { "appId": "<your-appid>", ... 其他参数 }

# 成功响应: { "ret": 200, "msg": "success", "data": { ... } }
```

---

## 目录结构

```
wx-auto/
├── README.md                 # 本文档
├── AGENTS.md                 # Agent 指令（加载此文件即获完整上下文）
├── config/
│   └── .env.cloud.example    # 云服务器配置模板
├── docs/
│   ├── wechatapi-login.md    # 登录模块 API
│   ├── wechatapi-contacts.md # 联系人模块 API
│   ├── wechatapi-message.md  # 消息模块 API
│   ├── wechatapi-group.md    # 群管理模块 API
│   ├── wechatapi-sns.md      # 朋友圈模块 API
│   ├── wechatapi-finder.md   # 视频号模块 API
│   ├── wechatapi-personal.md # 个人信息模块 API
│   ├── wechatapi-label.md    # 标签模块 API
│   ├── wechatapi-favor.md    # 收藏夹模块 API
│   ├── wechatapi-im.md       # 企微同步模块 API
│   └── deepsee-api.md        # Deepsee 服务器 API
├── scripts/
│   └── deploy.sh             # 云服务器一键部署脚本
├── nginx/
│   └── deepsee.conf.example  # Nginx 反向代理配置
├── skill/
│   ├── wx-auto.skill.md      # Hermes skill 主文件
│   └── references/           # 技能引用资源
└── templates/
    └── ai_config.json.example # Deepsee 本地分析/兼容链路配置示例；自动回复主链路不再以此作为 prompt/model 真源
```
