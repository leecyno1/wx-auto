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
  "appId": "",           // 首次为空；二次登录必须优先复用已保存的 appId
  "proxyIp": "",         // 代理IP（可选）
  "regionId": "110000",  // 地区代码；实测该部署使用 110000
  "type": "ipad",        // 设备类型
  "ttuid": ""            // 可选
}
```

**Response** `{ "qrData": "...", "qrUrl": "...", "qrImgBase64": "...", "uuid": "...", "appId": "..." }`

> 运维建议：登录成功后保存 `token`、`appId`、`wxid`、`regionId`、`type`、`callbackUrl` 的对应关系。二次登录先用已保存的 `appId` 获取二维码；只有接口明确返回“设备不存在”时，才把 `appId` 置空重新创建设备。

---

## 检查登录状态

```
POST /login/checkLogin
```

> 注意：公开文档页面 URL 可能显示为 `/login/checklogin`，但当前 `http://api.wechatapi.net/finder/v2/api` 实际 API 路径是驼峰 `/login/checkLogin`；小写路径可能返回 404。

**Body**:
```json
{
  "appId": "<appid>",
  "uuid": "<uuid>",
  "autoSliding": false,
  "captchCode": ""
}
```

字段说明：

- `uuid`: 从 `getLoginQrCode` 返回。
- `autoSliding`: 是否自动处理滑块/验证。新设备人脸验证场景下，实测 `false` 更容易返回人脸认证二维码 URL。
- `captchCode`: 首次 iPad 登录出现“新设备验证”且手机端显示数字验证码时，填入该字段继续轮询。

**Response**: 轮询此接口直到登录成功或超时。成功时返回含用户信息的 payload。

状态语义：

| 状态 | 含义 | 下一步 |
| --- | --- | --- |
| `ret=200`, `data.status=0` | 未扫码/等待扫码 | 继续轮询 |
| `ret=200`, `data.status=1` | 已扫码，等待手机确认或新设备验证 | 等待确认；若无按钮则继续捕获 `data.url` |
| `ret=200`, `data.status=2` 或 `data.loginInfo != null` | 登录成功 | 保存 `appId` / `wxid` / `token` 映射，绑定回调 |
| `ret=500`, `msg=二维码已过期` | 二维码过期 | 重新取码 |
| `ret=500`, `msg=请求处理中，请勿重复请求` | 轮询过密或服务端正在处理 | 降低轮询频率 |

新设备 / 人脸验证：

当 iPad 首次登录出现新设备验证且没有数字验证码时，`checkLogin` 可能返回：

```json
{
  "ret": 200,
  "msg": "操作成功",
  "data": {
    "url": "http://api.asilu.com/qrcode/?t=http://.../s/..."
  }
}
```

此时：

1. 将 `data.url` 渲染成二维码，或直接打开该 URL。
2. 使用 iOS 认证 APP 扫描该认证二维码做人脸验证：`https://www.pgyer.com/renzhengapp`。
3. 人脸通过后继续调用 `checkLogin`。
4. 手机端出现确认时点击确认；最终应返回 `status=2` 或非空 `loginInfo`。

实操轮询示例：

```bash
curl --location 'http://api.wechatapi.net/finder/v2/api/login/checkLogin' \
  --header 'VideosApi-token: <token>' \
  --header 'Content-Type: application/json' \
  --data '{
    "appId": "<appid>",
    "uuid": "<uuid>",
    "autoSliding": false
  }'
```

---

## 检查在线状态

```
POST /login/checkOnline
```

**Body**: `{ "appId": "<appid>" }`

**Response**: `{ "ret": 200, "data": true/false }`

---

## 设置回调

```
POST /login/setCallback
```

**Body**:
```json
{
  "appId": "<appid>",
  "callbackUrl": "http://<server_public_ip>:8001/api/wechat-gateway/callback",
  "token": "<wechatapi-token>"
}
```

常见错误：

- `push msg err`: WeChatAPI 无法从公网访问 `callbackUrl`。确认服务监听 `0.0.0.0`，公网 IP/端口可达，且回调路径返回 200。

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
