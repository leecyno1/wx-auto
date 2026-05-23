# WeChatAPI — 登录模块

**Base URL**: `http://api.wechatapi.net/finder/v2/api`  (HTTP only)
**认证**: `VideosApi-token` in header, `appId` in body

---

## 重要说明：首次登录 vs 后续重连

### 首次登录（必须走管理控制台）

**不能通过 Agent API 完成！** 首次登录需要在 https://newmanager.wechatapi.net/ 上操作：

1. 购买套餐获得 Token（有 7 天免费试用）  
2. 在控制台的登录管理页面获取二维码  
3. 微信扫码确认登录  
4. 控制台自动分配 appId（格式 `wx_xxxxx`）  
5. 在控制台 → 访问控制 → 配置回调地址（推荐），或后续通过 API setCallback 设置

首次登录后得到的 **appId** 是后续所有 API 调用的设备标识。

### 后续重连（通过 API）

微信会话过期后，Agent 可以直接通过 API 重新扫码：

1. `POST /login/getLoginQrCode` — 获取二维码（传已有 appId）
2. 用户微信扫码
3. `POST /login/checkLogin` — 轮询检查登录状态
4. 在线后使用 `send_text` 等接口

---

## 获取登录二维码

```
POST /login/getLoginQrCode
```

**Body**:
```json
{
  "appId": "wx_xxxxx",    // 首次在控制台获取后，后续一直用这个
  "proxyIp": "",
  "regionId": "11000",
  "type": "ipad",
  "ttuid": ""
}
```

> 注意：传 `appId=""` 会给这个 Token 分配一个新的设备会话，**不要这样做**（除非你确实要绑定另一个微信）。

**Response**:
```json
{
  "ret": 200,
  "data": {
    "qrData": "http://weixin.qq.com/x/xxx",
    "qrUrl": "http://api.asilu.com/qrcode/...",
    "qrImgBase64": "...",
    "uuid": "abc123...",
    "appId": "wx_xxxxx"
  }
}
```

---

## 检查登录状态

```
POST /login/checkLogin
```

轮询此接口，每 3-5 秒一次，直到 status 变为 2（成功）或 4（取消）。

**Body**:
```json
{
  "appId": "wx_xxxxx",
  "uuid": "abc123...",
  "proxyIp": "",
  "captchCode": "",
  "autoSliding": true   // iPad 类型必须传 true
}
```

**Response（成功）**:
```json
{
  "ret": 200,
  "data": {
    "uuid": "abc123...",
    "nickName": "张三",
    "status": 2,
    "loginInfo": {
      "wxid": "leecyno1",
      "nickName": "张三",
      "mobile": "138xxxx"
    }
  }
}
```

status 含义:
- 0 = 未扫码
- 1 = 已扫码未确认
- 2 = 登录成功
- 4 = 用户取消

---

## 检查在线状态

```
POST /login/checkOnline
```

**Body**: `{ "appId": "wx_xxxxx" }`
**Response**: `{ "ret": 200, "data": true/false }`

> data=false 表示掉线，需要重新扫码登录。

---

## 设置回调地址

```
POST /login/setCallback
```

**注意**：更换 Token 或回调地址后必须重新调用此接口。

**Body**:
```json
{
  "token": "your-token-here",       // 必填，和 header 里的 VideosApi-token 要一致
  "callbackUrl": "http://公网IP:8000/api/wechat-gateway/callback"
}
```

> 回调地址支持 HTTP 和 HTTPS。回调接口必须在 3 秒内返回 HTTP 200。

---

## 弹框登录（二步验证）

```
POST /login/dialogLogin
```

某些场景（如风控、新设备）微信要求二步验证，扫码后弹框输入验证码。

**Body**: `{ "appId": "wx_xxxxx" }`

---

## 登出

```
POST /login/logout
```

**Body**: `{ "appId": "wx_xxxxx" }`

---

## 重连

```
POST /login/reconnection
```

微信异常断线后尝试重连，不重新扫码。

**Body**: `{ "appId": "wx_xxxxx" }`

---

## 设置代理

```
POST /login/setProxy
```

**Body**:
```json
{
  "appId": "wx_xxxxx",
  "proxyIp": "代理IP"
}
```

---

## Token 管理（重要）

- Token 可以在 https://newmanager.wechatapi.net/ 续费/更换
- Token 过期后所有接口返回 500，需要更新 Token 并重新 setCallback
- 更换 Token 后 appId 不变（appId 绑定微信账号，Token 是平台凭证）
