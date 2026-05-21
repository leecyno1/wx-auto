# Deepsee API Reference

**Base URL**: `http://<server>:8000`  
**认证**: `Authorization: Bearer <AGENT_API_TOKEN>` 或 `X-Api-Token: <API_TOKEN>`  
**时区**: 全程北京时间 UTC+8

---

## 系统

### 健康检查

```
GET /api/health
```
Response: `{ "status": "ok", "version": "0.8.0", "uptime": ... }`

### 就绪检查

```
GET /api/ready
```
Response: 数据库连接、后台任务状态、Chatlog 连通性等。

### 后台任务状态

```
GET /api/background/runtime
```
Response: 各模块运行状态、模式、心跳时间。

---

## 消息

### 消息列表

```
GET /api/messages?q=<关键词>&chat_id=<wxid>&page=1&size=20&start_time=&end_time=&sender=
```
- `q`: 全文搜索（FTS5）
- `chat_id`: 按聊天筛选（wxid 或 @chatroom）
- `start_time` / `end_time`: 时间范围（ISO 格式）

### 公众号消息

```
GET /api/messages/mp?page=1&size=20&q=
```
公众号文章列表，支持搜索。

---

## 联系人

### 搜索联系人

```
GET /api/contacts?q=<关键词>
```

### 联系人评分列表

```
GET /api/contact-scoring/contacts?page=1&size=20&sort=score
```
按价值评分排序的联系人列表。

### 联系人评分卡

```
GET /api/contact-scoring/contacts/{id}/scorecard
```
观点命中、服务价值、风险提示、交流密度等维度的详细评分。

---

## AI 分析

### AI 消息摘要

```
POST /api/ai/summary
```
```json
{
  "chat_id": "xxx@chatroom",
  "days": 7,
  "force": false
}
```

### 联系人一页通

```
GET /api/ai/one-pager/{contact_id}
```
联系人完整画像：基本信息、交流历史、观点提取、价值评分。

---

## 发送消息（通过 Deepsee）

### 发送文本

```
POST /api/send/text
```
```json
{
  "to_wxid": "wxid_xxx",
  "text": "消息内容",
  "ats": ""           // 群聊@某人
}
```

### 发送图片

```
POST /api/send/image
```
```json
{
  "to_wxid": "wxid_xxx",
  "image_url": "http://..."
}
```

### 发送链接卡片

```
POST /api/send/link
```
```json
{
  "to_wxid": "wxid_xxx",
  "title": "...",
  "desc": "...",
  "url": "...",
  "thumb_url": "..."
}
```

---

## 微信网关

### 获取网关配置

```
GET /api/wechat-gateway/config
```

### 设置网关配置

```
POST /api/wechat-gateway/config
```
```json
{
  "base_url": "http://api.wechatapi.net/finder/v2/api",
  "token": "<wechatapi-token>",
  "app_id": "<wechatapi-appid>",
  "callback_public_url": "http://<public-ip>:8000/api/wechat-gateway/callback"
}
```

### 绑定回调

```
POST /api/wechat-gateway/bind-callback
```
向 wechatapi.net 注册回调地址，微信消息实时推送到 callback。

### 获取触发规则

```
GET /api/wechat-gateway/trigger-rules
```

### 设置触发规则

```
POST /api/wechat-gateway/trigger-rules
```
```json
{
  "prefixes": ["ai", "bot", "/"],
  "wakeup_keywords": ["@助手"],
  "enable_auto_reply": true,
  "silence_hours": "23:00-07:00",
  "suppression_seconds": 120,
  "rate_limit_per_minute": 5
}
```

### 评估回复

```
POST /api/wechat-gateway/evaluate-reply
```
```json
{
  "chat_id": "xxx@chatroom",
  "sender_id": "wxid_xxx",
  "text": "消息内容",
  "is_group": true
}
```

### 子会话配置

```
GET  /api/wechat-gateway/subsession-config/{id}
POST /api/wechat-gateway/subsession-config/{id}
```
管理 WeChat 子会话的自有角色、模型路由、历史管理策略。

---

## 新闻聚合

### 获取新闻

```
GET /api/newsfeed?category=&limit=20
```
新闻聚合分类：财经、科技、政策、自媒体等。
