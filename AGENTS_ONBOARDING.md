# Agent Onboarding: WeChat Automation

> 本文档是 **给新 AI Agent 看的**，不是给人看的。
> 新 Agent 首次加载 wx-auto 仓库时，先读取本文档，**将关键知识写入自己的 memory（持久记忆）**，确保后续操作不出错。

---

## 0. 为什么需要这个文件

WeChat 自动化的坑很多，而且不是每个 Agent 都懂这个领域。本文档将 6 个多月的踩坑经验浓缩成一份 Agent 能直接写进 memory 的知识清单。

---

## 1. 写入 Memory 的关键事实

以下条目是 Agent **必须保存到 memory 中的**（用 memory 工具 add）。按优先级排列。

### 1.1 系统架构 (必存)

```
Hermes Agent ──HTTP──► Deepsee Server(:8000) ──HTTP──► wechatapi.net
                              │
                         [SQLite DB]
                        data/app.db
```

- **Deepsee** = 后端 API（消息存储、AI 分析、微信网关回调），在云服务器运行
- **wechatapi.net** = iPad 协议底座，直接 POST HTTP 收发微信消息
- **wx-auto** = Agent 端配套仓库（技能 + API 文档 + 部署脚本）

### 1.2 两层认证 (必存)

| 层 | 认证方式 |
|----|---------|
| Deepsee API | `Authorization: Bearer <AGENT_API_TOKEN>` 或 `X-Api-Token` header |
| wechatapi.net | header: `VideosApi-token: <token>`, body: `appId: "wx_xxxxx"` |

### 1.3 wechatapi.net 基本参数 (必存)

- Base URL: `http://api.wechatapi.net/finder/v2/api`（HTTP only，不支持 HTTPS）
- Token 来源：在 https://newmanager.wechatapi.net/ 购买/试用后获取
- appId 来源：首次登录时由 wechatapi 分配，格式 `wx_xxxxx`

### 1.4 登录流程（最重要，最容易出错）

**首次登录一个微信账号（必须走 wechatapi 管理控制台）：**

```
1. 用户打开 https://newmanager.wechatapi.net/
2. 购买套餐（有 7 天免费试用）
3. 在控制台的登录管理页面，点击获取二维码
4. 微信扫码确认登录
5. 控制台自动分配 appId（wx_xxxxx 格式）
6. Agent 拿到这个 appId，后续 API 调用都用它
```

> ⚠️ 关键：首次登录 **必须在 wechatapi 控制台完成**，不是通过 Agent 的 API。因为控制台的首次登录才会分配 appId。Agent 的 API 调用 `get_login_qr_code` 时如果传空 `appId=""` **也会**分配新 appId，但那是另一个设备会话，不是控制台的。

**后续重连（Agent 通过 API 操作）：**

```
1. Agent 调用 /login/getLoginQrCode { appId: "wx_xxxxx", regionId: "11000", type: "ipad" }
2. 返回 qrUrl/uuid
3. 用户微信扫码
4. Agent 轮询 /login/checkLogin { appId, uuid, autoSliding: true }
5. status=2 成功，得到 loginInfo
6. Agent 更新配置 login_status="logged_in"
```

### 1.5 Token 与回调地址的关系 (必存)

- **Token 是 wechatapi 平台的 API 凭证**，不是微信密码
- 回调地址可以在控制台设置，也可以通过 API 设置
- 更换 Token 或回调地址后，必须重新调用 `/login/setCallback` 通知网关
- setCallback 请求 body 需要同时传 `token` 和 `callbackUrl`
- 回调地址支持 HTTP 和 HTTPS，但回调接口必须在 **3 秒内** 返回 200

### 1.6 常见失效原因 (必存)

| 症状 | 原因 | 解决 |
|------|------|------|
| checkOnline 返回 false | 微信会话过期 | 重新扫码登录 |
| 发消息返回 500 | Token 过期/无效 | 更新 Token + 重新绑定回调 |
| 收不到回调消息 | 回调地址未绑定/IP 变了 | 重新 setCallback |
| 扫码后登录失败 | appId 不对/最新微信需要二步验证 | 检查 appId，尝试 dialogLogin |

### 1.7 微信限制须知 (必存)

- 发消息频率不宜过高，建议消息间加 1-3 秒随机延迟
- 新注册/未实名/有封号记录的微信不能用
- 被风控可能导致消息发不出去

---

## 2. Agent 首次处理用户请求的 Checklist

当用户说"帮我安装/设置微信自动化"时，按以下顺序问/查：

```
□ 服务器有没有？（云服务器、固定公网 IP）
□ wechatapi.net 有没有注册？（Token）
□ 微信有没有在控制台首次登录过？（appId）
□ 回调地址配了没有？
□ 现在在线吗？（checkOnline）
```

核心原则：**先确认 Token + appId 齐全，再往下走。**

---

## 3. 常用操作代码块（可直接用）

### 检查在线状态

```python
import requests
r = requests.post(
    "http://api.wechatapi.net/finder/v2/api/login/checkOnline",
    headers={"VideosApi-token": "<token>"},
    json={"appId": "<appId>"}
)
print(r.json().get("data", {}))  # True/False
```

### 发送文本消息

```python
r = requests.post(
    "http://api.wechatapi.net/finder/v2/api/message/postText",
    headers={"VideosApi-token": "<token>"},
    json={"appId": "<appId>", "toWxid": "filehelper", "content": "hello"}
)
```

### 重新扫码登录（重连用）

```python
# 1. 获取二维码
qr = requests.post(
    "http://api.wechatapi.net/finder/v2/api/login/getLoginQrCode",
    headers={"VideosApi-token": "<token>"},
    json={"appId": "<appId>", "regionId": "11000", "type": "ipad"}
)
uuid = qr.json()["data"]["uuid"]
print("QR URL:", qr.json()["data"]["qrUrl"])

# 2. 用户扫码后，轮询检查
while True:
    r = requests.post(
        "http://api.wechatapi.net/finder/v2/api/login/checkLogin",
        headers={"VideosApi-token": "<token>"},
        json={"appId": "<appId>", "uuid": uuid, "autoSliding": True}
    )
    data = r.json().get("data", {})
    status = data.get("status")
    if status == 2:  # 成功
        print("Logged in as:", data.get("loginInfo", {}).get("nickName"))
        break
    elif status == 4:  # 取消
        print("Cancelled by user")
        break
    time.sleep(3)
```

### 绑定回调地址

```python
r = requests.post(
    "http://api.wechatapi.net/finder/v2/api/login/setCallback",
    headers={"VideosApi-token": "<token>"},
    json={
        "token": "<token>",      # 注意：body 也要传 token
        "callbackUrl": "http://<公网IP>:8000/api/wechat-gateway/callback"
    }
)
```

---

## 4. 部署全过程速览（供 Agent 指挥用）

```
[Human] → 买云服务器 + wechatapi 套餐
[Agent] → SSH 到服务器
[Agent] → git clone Deepsee, 配置 .env, start
[Agent] → 设置 wechat_gateway_config (token, appId, callback)
[Agent] → 绑定回调地址
[Human] → 去控制台首次扫码登录获取 appId
[Agent] → 用 appId 重新扫码并确认在线
[Agent] → 测试发送消息
```

---

## 5. 关键文件索引

| 文件 | 用途 |
|------|------|
| `AGENTS.md` | 主 Agent 指令文件（每次加载） |
| `DEPLOY.md` | 完整部署操作手册 |
| `skill/skill.md` | Hermes Skill |
| `docs/wechatapi-login.md` | 登录 API 参考 |
| `docs/wechatapi-message.md` | 消息 API 参考 |
| `docs/deepsee-api.md` | Deepsee 服务端 API |

---

## 6. 历史踩坑记录

以下是为啥这些规则存在的原因，Agent 读一遍就行，不用存 memory：

1. **首次登录在控制台** — Agent 调 API 首次扫码也会出 appId，但新 Agent 不知道这个 appId 和用户在控制台配的回调地址是绑在不同设备会话上的。两套系统会打架。
2. **setCallback body 要传 token** — 文档上是 `token` 字段，不是 `VideosApi-token` header。传 header 不够，body 也要带。
3. **回调地址 HTTP/HTTPS 均可** — 不需要 HTTPS，公网 HTTP 也能用，但公网 IP 需固定。
4. **调了 config 后必须 bind-callback** — 只 POST config 不会自动触发 setCallback，需要额外调 `/api/wechat-gateway/bind-callback`。
5. **checkLogin 的 autoSliding** — ipad 设备类型需要传 `autoSliding: true`。
