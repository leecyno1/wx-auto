# WeChatAPI — 登录模块

**Base URL**: `http://api.wechatapi.net/finder/v2/api`  
**认证**: `VideosApi-token` in header, `appId` in body

---

## 获取登录二维码

```
POST /login/getLoginQrCode
```

**Body**:
```json
{
  "appId": "",          // 首次为空，后续用已知 appId
  "proxyIp": "",        // 代理IP（可选）
  "regionId": "11000",  // 地区代码
  "type": "ipad",       // 设备类型
  "ttuid": ""           // 可选
}
```

**Response** `{ "qrData": "...", "qrUrl": "...", "qrImgBase64": "...", "uuid": "...", "appId": "..." }`

---

## 检查登录状态

```
POST /login/checkLogin
```

**Body**:
```json
{
  "appId": "<appid>",
  "uuid": "<uuid>",       // 从上一步获取
  "proxyIp": ""           // 可选
}
```

**Response**: 轮询此接口直到登录成功或超时。成功时返回含用户信息的 payload。

---

## 检查在线状态

```
POST /login/checkOnline
```

**Body**: `{ "appId": "<appid>" }`
**Response**: `{ "ret": 200, "data": { "online": true/false } }`

---

## 弹框登录（二步验证）

```
POST /login/dialogLogin
```

**Body**: `{ "appId": "<appid>" }`

---

## 登出

```
POST /login/logout
```

**Body**: `{ "appId": "<appid>" }`

---

## 重连

```
POST /login/reconnection
```

**Body**: `{ "appId": "<appid>" }`

---

## 设置代理

```
POST /login/setProxy
```

**Body**:
```json
{
  "appId": "<appid>",
  "proxyIp": "<proxy_ip>"
}
```
