# wx-auto — Agent 指令文件

> 加载此文件以获得 WeChat 自动化系统的完整上下文。
> 建议：Agent 首次启动时先阅读 README.md 获得整体概览，然后按需查阅具体文档。

---

## 系统概况

当前 WeChat 自动化系统由两个仓库组成：

| 仓库 | 用途 | URL |
|------|------|-----|
| **Deepsee** | 后端 API 服务器 | https://github.com/leecyno1/Deepsee |
| **wx-auto** | Agent 端配套（= 本仓库） | https://github.com/leecyno1/wx-auto |

### 部署拓扑（云服务器）

```
[Hermes Agent] ──HTTP──► [Deepsee Server :8000] ──HTTP──► [wechatapi.net iPad 协议]
                                │
                           [SQLite DB]
                          data/app.db
```

- Hermes Agent 通过 HTTP 调用 Deepsee API
- Deepsee 内部封装了 wechatapi.net 的复杂调用
- 回调地址 = `http://<服务器公网IP>:8000/api/wechat-gateway/callback`
- 无隧道、无 n8n，全走 HTTP API

### 认证方式

**Deepsee API**：`Authorization: Bearer <AGENT_API_TOKEN>` 或 `X-Api-Token: <API_TOKEN>`
**wechatapi.net**：`VideosApi-token: <token>` header + `appId` 在请求 body 中

---

## 关键 API 端点速查

### Deepsee API（推荐日常使用）

| 端点 | 方法 | 用途 |
|------|------|------|
| `/api/health` | GET | 健康检查 |
| `/api/messages?q=&chat_id=&page=&size=` | GET | 查询消息 |
| `/api/messages/mp?page=&size=` | GET | 公众号消息 |
| `/api/contacts?q=` | GET | 搜索联系人 |
| `/api/contact-scoring/contacts` | GET | 联系人评分列表 |
| `/api/contact-scoring/contacts/{id}/scorecard` | GET | 联系人评分卡 |
| `/api/ai/summary` | POST | AI 消息摘要 |
| `/api/ai/one-pager/{contact_id}` | GET | 联系人一页通 |
| `/api/send/text` | POST | 发送文本消息 |
| `/api/send/image` | POST | 发送图片消息 |
| `/api/send/link` | POST | 发送链接卡片 |
| `/api/newsfeed` | GET | 新闻聚合 |
| `/api/email/messages` | GET | 邮件列表 |
| `/api/background/runtime` | GET | 后台任务状态 |
| `/api/wechat-gateway/config` | GET/POST | 网关配置读写 |
| `/api/wechat-gateway/trigger-rules` | GET/POST | 触发规则读写 |
| `/api/wechat-gateway/callback` | POST | 微信回调入口 |
| `/api/wechat-gateway/bind-callback` | POST | 绑定回调地址 |
| `/api/wechat-gateway/subsession-config/{id}` | GET/POST | 子会话配置 |

### wechatapi.net 原生 API（直接调用）

**Base URL**: `http://api.wechatapi.net/finder/v2/api`

**通用参数**: `appId` 在 body 中，`VideosApi-token` 在 header 中。

**常用端点**：

| 端点 | 用途 | 关键参数 |
|------|------|---------|
| `POST /message/postText` | 发送文本 | toWxid, content, ats |
| `POST /message/postImage` | 发送图片 | toWxid, imgUrl |
| `POST /message/postFile` | 发送文件 | toWxid, fileUrl, fileName |
| `POST /message/postLink` | 发送链接卡片 | toWxid, title, desc, url, thumbUrl |
| `POST /message/postVideo` | 发送视频 | toWxid, videoUrl, videoName |
| `POST /message/postVoice` | 发送语音 | toWxid, voiceUrl, voiceDuration |
| `POST /message/postEmoji` | 发送表情 | toWxid, emojiMd5, emojiSize |
| `POST /message/postMiniApp` | 发送小程序 | toWxid, userName, title, imageUrl, path |
| `POST /message/postNameCard` | 发送名片 | toWxid, nickName, nameCardWxid |
| `POST /message/postLocation` | 发送位置 | toWxid, contentXml |
| `POST /contacts/fetchContactsList` | 获取联系人列表 | 无额外参数 |
| `POST /contacts/getBriefInfo` | 批量获取简要信息 | wxids |
| `POST /contacts/getDetailInfo` | 批量获取详细信息 | wxids |
| `POST /contacts/search` | 搜索联系人 | contactsInfo |
| `POST /contacts/addContacts` | 添加联系人 | scene, content, [其他参数] |
| `POST /contacts/setFriendRemark` | 设置备注 | wxid, remark |
| `POST /group/createChatroom` | 创建群聊 | wxids |
| `POST /group/getChatroomInfo` | 获取群信息 | chatroomId |
| `POST /group/getChatroomMemberList` | 获取群成员 | chatroomId |
| `POST /group/inviteMember` | 邀请入群 | chatroomId, wxids |
| `POST /group/removeMember` | 踢出群成员 | chatroomId, wxid |
| `POST /sns/sendTextSns` | 发文字朋友圈 | content |
| `POST /sns/sendImgSns` | 发图片朋友圈 | imageIds, description |
| `POST /sns/sendVideoSns` | 发视频朋友圈 | videoId, description |
| `POST /sns/snsList` | 朋友圈列表 | maxId, firstPageMd5 |
| `POST /login/getLoginQrCode` | 获取登录二维码 | regionId, type |
| `POST /login/checkLogin` | 检查登录状态 | uuid |
| `POST /login/checkOnline` | 检查是否在线 | 无额外参数 |
| `POST /login/setCallback` | 设置回调地址 | callbackUrl |

> 完整端点列表见 `docs/` 下各模块文档。

---

## 新建环境安装流程

当用户要求在一个**全新环境**（新服务器、新 Agent）中安装 WeChat 自动化系统时，执行以下步骤：

### 步骤 1：部署 Deepsee 服务器

```bash
# SSH 到云服务器，执行：
ssh root@<服务器IP>

git clone https://github.com/leecyno1/Deepsee.git /opt/deepsee
cd /opt/deepsee
bash scripts/manage.sh prod-lite

# 编辑 .env 配置：
vim .env
# 必须配置：
#   HOST=0.0.0.0
#   AGENT_API_TOKEN=<强随机字符串>
#   SILICONFLOW_API_KEY=sk-xxx
#   SILICONFLOW_MODEL=Qwen/Qwen3-30B-A3B

bash scripts/manage.sh start
```

### 步骤 2：配置微信协议

通过 Deepsee API 配置 wechatapi 凭证：

```bash
# 获取 wechatapi token + appId（用户提供）
# 调用 API 设置：
curl -X POST http://localhost:8000/api/wechat-gateway/config \
  -H "Content-Type: application/json" \
  -d '{
    "base_url": "http://api.wechatapi.net/finder/v2/api",
    "token": "<wechatapi-token>",
    "app_id": "<wechatapi-appid>",
    "callback_public_url": "http://<服务器公网IP>:8000/api/wechat-gateway/callback"
  }'

# 绑定回调
curl -X POST http://localhost:8000/api/wechat-gateway/bind-callback

# 检查在线状态
curl http://localhost:8000/api/health
```

### 步骤 3：配置 Hermes API Server（可选）

如 Hermes 与 Deepsee 在不同主机，配置 Hermes 连接：

```yaml
# ~/.hermes/config.yaml
api_server:
  enabled: true
  host: "0.0.0.0"
  port: 8642

# 配置 gateway 桥接
gateway:
  wechat_gateway_default:
    base_url: "http://<deepsee-server>:8000"
    api_key: "<AGENT_API_TOKEN>"
```

### 步骤 4：启动微信

1. 访问 Deepsee 管理界面 `http://<服务器IP>:8000/`
2. 进入 WeChat → 登录设置
3. 获取二维码 → 微信扫码 → 确认登录
4. 在线后发送 `ai test` 测试自动回复

---

## 注意事项

- **时区**：全程使用北京时间（UTC+8），`datetime.fromtimestamp()` 不要用 `utcfromtimestamp()`
- **回调 URL**：云服务器公网 IP 需固定；若不固定，使用域名 + DDNS
- **安全**：设置 `API_TOKEN` 后再对外暴露端口；Nginx 反向代理加 SSL
- **token 有效期**：wechatapi 的 token 有有效期，过期后需更新并重新绑定回调
- **微信限制**：发送频率不宜过高，建议消息间加随机延迟
- **日志**：Deepsee 日志在 `uvicorn.log`，问题排查先看日志
