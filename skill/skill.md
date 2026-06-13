# wx-auto — WeChat Automation Skill for Hermes

> 加载此 skill 后，Hermes Agent 获得完整的微信自动化能力。
> 包括：消息收发、联系人管理、群管理、朋友圈、视频号操作、
> 微信自动回复优化、语言能力自我进化。
>
> **触发关键词**：wx、wx-auto、微信、微信自动化、/wx、iLink、微信进化、提示词优化

---

## 触发方式

以下关键词会自动激活此 skill（不区分大小写）：

| 输入 | 效果 |
|------|------|
| 在对话中提到「**wx**」「**微信**」「**微信自动化**」| Agent 自动加载 skill 并进入微信操作模式 |
| 输入 **`/wx`** | 直接加载技能 |
| 说「**帮我用微信** 发消息/查联系人/看在线状态」| 自动调用微信功能 |
| 提到「**微信进化**」「**提示词优化**」「**回复质量**」| 触发语言进化分析 |

> 准确提及实操对象（如「给王总发消息」而非「帮我发个消息」）效果更佳。

---

## 系统架构

### 双渠道 WeChat

- **渠道 A: Deepsee 桥接** (主) — wechatapi.net iPad 协议，全功能（私聊+群聊+朋友圈+公众号）
- **渠道 B: iLink Bot** (辅) — Hermes Gateway 原生，扫码即用，仅私聊
- **Deepsee Server** = 后端 API（消息存储、微信网关回调、队列、规则执行；自动回复文本统一交给 Hermes bridge 生成）
- **wx-auto** = Agent 端配套（技能、API 文档、部署指引、使用须知）
- **wechatapi.net** = iPad 协议底座（已完全封装，用户无需接触）

### 自我进化

- **每天 23:00** — 语言进化 cron：复盘微信对话 → 评分 → patch 提示词规则 → memory 沉淀
- **每天 8:00** — 知识摄入+交叉验证+置信度
- **每周一** — 健康审计（衰减+聚类） + 预测回顾

**部署拓扑**（云服务器）：
```
Agent ──HTTP──► Deepsee(:8001) ──HTTP──► wechatapi.net
                    │
               [SQLite DB + AI]
```

**认证**：
- Deepsee API: `Authorization: Bearer <AGENT...EN>`
- wechatapi.net: header `VideosApi-token` + body `appId`

---

## 调用方式

Agent 有两种方式操作微信：

### 方式 A：通过 Deepsee API（推荐，有数据持久化和网关编排；自动回复生成由 Hermes bridge 负责）

```bash
# 发送消息
curl -X POST http://<deepsee-ip>:8000/api/send/text \
  -H "Authorization: Bearer *** \
  -H "Content-Type: application/json" \
  -d '{"to_wxid": "wxid_xxx", "text": "你好"}'

# 查询联系人
curl -H "Authorization: Bearer *** \
  "http://<deepsee-ip>:8000/api/contacts?q=张三"

# 查询消息
curl -H "Authorization: Bearer *** \
  "http://<deepsee-ip>:8000/api/messages?q=关键词"
```

### 方式 B：直接调用 wechatapi.net（原始协议，无缓存/分析）

```bash
POST http://api.wechatapi.net/finder/v2/api/message/postText
Headers: VideosApi-token: <token>
Body: {"appId": "<appid>", "toWxid": "wxid", "content": "text"}
```

---

## API 端点速查

### 常用 Deepsee 端点

| 端点 | 用途 |
|------|------|
| `GET /api/health` | 健康检查 |
| `GET /api/messages?q=&chat_id=` | 消息搜索 |
| `GET /api/contacts?q=` | 联系人搜索 |
| `GET /api/contact-scoring/contacts` | 联系人评分 |
| `POST /api/send/text` | 发送文本 |
| `POST /api/send/image` | 发送图片 |
| `POST /api/send/link` | 发送链接卡片 |
| `GET/POST /api/wechat-gateway/config` | 网关配置 |
| `POST /api/wechat-gateway/bind-callback` | 绑定回调 |
| `GET/POST /api/wechat-gateway/trigger-rules` | 触发规则 |
| `GET /api/newsfeed` | 新闻聚合 |

### 常用 wechatapi.net 端点

| 端点 | 用途 |
|------|------|
| `POST /message/postText` | 发文字 |
| `POST /message/postImage` | 发图片 |
| `POST /message/postLink` | 发链接卡片 |
| `POST /message/postFile` | 发文件 |
| `POST /message/postVoice` | 发语音 |
| `POST /message/postVideo` | 发视频 |
| `POST /contacts/fetchContactsList` | 获取联系人列表 |
| `POST /contacts/getBriefInfo` | 批量获取联系人信息 |
| `POST /contacts/setFriendRemark` | 设置备注 |
| `POST /contacts/search` | 搜索联系人 |
| `POST /group/createChatroom` | 创建群聊 |
| `POST /group/inviteMember` | 邀请成员 |
| `POST /group/getChatroomInfo` | 获取群信息 |
| `POST /group/getChatroomMemberList` | 获取群成员列表 |
| `POST /sns/sendTextSns` | 发文字朋友圈 |
| `POST /sns/sendImgSns` | 发图片朋友圈 |
| `POST /sns/snsList` | 朋友圈列表 |
| `POST /login/checkOnline` | 检查在线状态 |
| `POST /login/getLoginQrCode` | 获取登录二维码 |

> 完整 API 文档见 `docs/wechatapi-*.md`

---

## 部署指引

### 新服务器（云服务器，直接 IP 回调）

```bash
# SSH 到服务器
ssh root@<server-ip>

git clone https://github.com/leecyno1/Deepsee.git /opt/deepsee
cd /opt/deepsee

# 生产环境配置
cp .env.production-lite.example .env
vim .env   # 配置 HOST=0.0.0.0, AGENT_API_TOKEN, SILICONFLOW_API_KEY 等（SILICONFLOW 仅保留给本地分析/兼容链路）
bash scripts/manage.sh prod-lite
bash scripts/manage.sh start
```

### 配置微信

通过 Deepsee API 设置 wechatapi 凭证：
```bash
curl -X POST http://localhost:8000/api/wechat-gateway/config \
  -H "Content-Type: application/json" \
  -d '{
    "base_url": "http://api.wechatapi.net/finder/v2/api",
    "token": "<wechatapi-token>",
    "app_id": "<wechatapi-appid>",
    "callback_public_url": "http://<server-public-ip>:8000/api/wechat-gateway/callback"
  }'

curl -X POST http://localhost:8000/api/wechat-gateway/bind-callback
```

---

## 注意事项

- **时区**：全程北京时间 UTC+8，使用 `datetime.fromtimestamp()`
- **频率控制**：发消息间隔建议 1-3 秒，防止被风控
- **回调地址**：云服务器需固定 IP，或用域名 + DDNS
- **安全**：设置 `API_TOKEN` 后再对外暴露；Nginx 代理加 SSL
- **token 有效期**：wechatapi 的 token 会过期，需定期检查 `checkOnline` 并续期

### 用户指引

人类用户请阅读 **`USER_GUIDE.md`**（本仓库根目录），包含：
- 封号风险与规避
- 账号注册资质要求
- 快速使用说明
- 故障排查