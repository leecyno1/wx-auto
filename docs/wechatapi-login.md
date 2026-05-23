# WeChatAPI — 首次登录完全指南

> 定期更新自官方文档 [wechatapi.net 开放平台](https://post.wechatapi.net/raiz5jee8eiph0eeFooV/api/v1/projects/4425884)
>
> 本文档聚焦 **首次登录**。后续重连/日常操作见 `AGENTS.md` 或 AGENT 内存。
>
> **⚠️ 重要区分**：
> - 首次登录 = 新 Token + 新设备 → 走完整扫码+验证流程
> - 后续重连 = 已有 appId → 直接取码扫码，无需人脸/滑块验证

---

## 一、登录方式选择

wechatapi 提供两种设备类型登录，流程复杂度不同：

| 设备类型 | 复杂度 | 验证方式 | 推荐场景 |
|---------|--------|---------|---------|
| **Mac** | 简单 | 手机微信扫码 + 自动滑块验证 | 首次快速上线、本地测试 |
| **iPad** | 复杂 | 手机微信扫码 + **人脸识别验证**（需 iOS 安盾 APP） | 无法用 Mac 方案时 |

**核心区别**：iPad 类型会触发微信的新设备人脸验证，需要额外下载 APP 完成；Mac 类型可通过 `autoSliding: true` 自动完成滑块验证。

---

## 二、Base URL

两个 Base URL 均可使用，效果相同：

| URL | 说明 |
|-----|------|
| `http://api.wechatapi.net/finder/v2/api` | 旧版，HTTP |
| `https://post.wechatapi.net` | 新版，HTTPS |

> 推荐使用新版 HTTPS 域名 `https://post.wechatapi.net`。

---

## 三、通用参数说明

### 设备类型 `type`

| 值 | 说明 |
|----|------|
| `"ipad"` | iPad 协议，需人脸识别验证 |
| `"mac"` | Mac 协议，自动/手动滑块验证 |

### 验证方式 `autoSliding`

| 值 | Mac 设备 | iPad 设备 |
|----|---------|----------|
| `true` | 自动验证（推荐，无需额外操作） | 自动人脸验证流程 |
| `false` | 需用安卓APP扫码完成图形验证 | 基础流程（配合人脸验证） |

**推荐默认参数**：

```json
// Mac 方案（首次默认）
{
  "type": "mac",
  "autoSliding": false,
  "regionId": "110000",
  "proxyIp": "",
  "ttuid": ""
}

// iPad 方案（Mac 不可用时备用）
{
  "type": "ipad",
  "autoSliding": true,
  "regionId": "110000",
  "proxyIp": "",
  "ttuid": ""
}
```

### 区域编码 `regionId`

**非常重要**：必须选择 **用户微信账号所在省份** 的区域编码，不匹配会触发风控。

```json
110000  北京市       120000  天津市       130000  河北省
140000  山西省       150000  内蒙古自治区  210000  辽宁省
220000  吉林省       230000  黑龙江省     310000  上海市
320000  江苏省       330000  浙江省       340000  安徽省
350000  福建省       360000  江西省       370000  山东省
410000  河南省       420000  湖北省       430000  湖南省
440000  广东省       450000  广西省       460000  海南省
500000  重庆市       510000  四川省       520000  贵州省
530000  云南省       540000  西藏自治区  610000  陕西省
620000  甘肃省       630000  青海省       640000  宁夏自治区
650000  新疆自治区
```

选择规则：
- **用户微信绑定的手机号归属地** = 首选 regionId
- 如不清楚，选 `110000`（北京）作为默认值，登录失败再尝试用户所在地编码
- 若该区域无法登录，可能需要购买该省 socks5 代理 IP（格式：`socks5://user:pass@ip:port`）

---

## 四、Mac 登录方案（推荐，流程简单）

### 步骤 1：获取二维码

```bash
POST https://post.wechatapi.net/login/getLoginQrCode
Headers: VideosApi-token: <你的Token>
Body:
{
  "appId": "",           // 首次登录传空字符串
  "proxyIp": "",
  "regionId": "110000",  // 用户所在区域
  "type": "mac",
  "ttuid": ""
}
```

**响应**：
```json
{
  "ret": 200,
  "data": {
    "qrData": "http://weixin.qq.com/x/...",
    "qrUrl": "https://api.asilu.com/qrcode/...",
    "qrImgBase64": "base64...",  // 可直接展示的二维码图片
    "appId": "wx_xxx...",        // ← 保存此 appId，后续所有操作都需要
    "uuid": "abc123..."           // ← 保存此 uuid，用于 checkLogin
  }
}
```

> `appId` 是设备标识，绑定你的微信账号，**不是 Token**。后续重连时传此值。

### 步骤 2：用户微信扫码

将二维码展示给用户，用手机微信扫码。

### 步骤 3：轮询登录状态

扫码后立即开始轮询，每 **5 秒** 一次：

```bash
POST https://post.wechatapi.net/login/checkLogin
Headers: VideosApi-token: <你的Token>
Body:
{
  "appId": "wx_xxx...",       // 步骤 1 返回的 appId
  "uuid": "abc123...",        // 步骤 1 返回的 uuid
  "proxyIp": "",
  "captchCode": "",            // 如有数字验证码填这里
  "autoSliding": false         // Mac 推荐 false
}
```

**轮询 status 变化**：

| status | 含义 | 操作 |
|--------|------|------|
| 0 | 未扫码 | 继续轮询 |
| 1 | 已扫码，手机等待确认 | 继续轮询 |
| **2** | **登录成功** | 停止轮询，保存 appId |
| 4 | 用户取消 | 重新从步骤 1 开始 |

**成功响应**（status=2）：
```json
{
  "ret": 200,
  "data": {
    "status": 2,
    "loginInfo": {
      "wxid": "leecyno1",       // ← 微信 ID
      "nickName": "胤",          // ← 微信昵称
      "mobile": "138xxxxx",      // ← 绑定手机号
      "alias": "xxx"
    }
  }
}
```

**超时**：二维码有效 **120 秒**，超时未扫码需重新获取。

### 步骤 4：检查在线并绑定回调

```bash
# 检查在线
POST https://post.wechatapi.net/login/checkOnline
Body: { "appId": "wx_xxx..." }

# 设置回调（重要！换 Token 后必须重设）
POST https://post.wechatapi.net/login/setCallback
Body: { "token": "<你的Token>", "callbackUrl": "https://你的地址/api/wechat-gateway/callback" }
```

---

## 五、iPad 登录方案（人脸识别）

> 当 Mac 方案失败或微信提示"在新设备完成验证以继续登录"时使用。

### 流程总览

```
① 获取二维码 (getLoginQrCode, type=ipad)
        ↓
② 用户微信扫码 → 手机提示人脸验证
        ↓
③ iOS 用户下载【安盾APP】→ 扫描二维码完成人脸验证
        ↓
④ 手机微信点击确认 → 轮询 checkLogin
        ↓
⑤ 登录成功 → 绑定回调
```

### 步骤 1：获取二维码

```bash
POST https://post.wechatapi.net/login/getLoginQrCode
Headers: VideosApi-token: <你的Token>
Body:
{
  "appId": "",
  "proxyIp": "",
  "regionId": "110000",
  "type": "ipad",         // ← 关键：type=ipad
  "ttuid": ""
}
```

### 步骤 2：用户扫码 + 触发人脸验证

用户用手机微信扫码。此时微信会提示 **"新设备登录，需验证身份"**。

⚠️ **注意**：`checkLogin` 接口此时 **不会返回数字验证码**（`captchCode` 为空），而是触发人脸识别流程。

### 步骤 3：人脸识别验证（iPad 首次登录特有）

1. 准备一台 **iOS 设备**（iPhone/iPad）
2. 下载 **安盾APP**：https://www.pgyer.com/renzhengapp（企业签名版，需在设置→通用→VPN与设备管理中信任证书）
3. 打开安盾APP，首页有 **扫码验证** 入口
4. 扫描 `checkLogin` 返回的验证二维码（或取出二维码 URL 用 iOS 设备浏览器打开 → 自动跳转安盾验证）
5. 按照提示完成 **人脸识别**（正对摄像头、眨眼、张嘴等动作）
6. 验证通过后，手机微信会弹出登录确认

### 步骤 4：轮询登录状态

```bash
POST https://post.wechatapi.net/login/checkLogin
Body:
{
  "appId": "wx_xxx...",
  "uuid": "abc123...",
  "proxyIp": "",
  "captchCode": "",
  "autoSliding": true     // iPad 推荐 true
}
```

人脸验证完成后，继续轮询直到 `status: 2`（登录成功）。

> **如果人脸验证成功但轮询一直 status=1（已扫码未确认）**：检查手机微信是否弹出了确认登录提示，用户需要手动点击确认。

### 步骤 5：检查在线并绑定回调（同 Mac 方案）

### iPad 登录注意事项

- 人脸验证使用 **安盾APP**（第三方企业签名应用），不是微信自己的人脸验证
- 安盾APP 需要 iOS 设备，建议准备一台备用 iPhone/iPad
- 人脸验证需在 **光线充足** 环境下进行
- 验证失败可重试，重新获取二维码即可
- 首次登录成功后到次日凌晨大概率会掉线一次，属正常现象，重新取码（传已有 appId）登录即可

---

## 六、新设备验证处理对照表

| 验证类型 | 出现场景 | 解决方案 | 所需条件 |
|---------|---------|---------|---------|
| 无验证（直接登录） | Mac type，已有设备历史 | `checkLogin` 直接返回成功 | — |
| 滑块验证（自动） | Mac type，autoSliding=true | 自动完成，无感 | — |
| 滑块验证（手动） | Mac type，autoSliding=false | 返回验证 URL，需安卓APP扫码 | 安卓设备+APP |
| 人脸验证 | iPad type 首次 | 返回验证二维码，安盾APP扫码+人脸识别 | iOS 设备+安盾APP |
| 数字验证码 | 两者都可能 | `captchCode` 字段输入手机收到的验证码 | 手机可收验证码 |
| 弹框确认 | 已有设备场景 | 调用 `/login/dialogLogin` 让手机弹框确认 | 微信中手动点击确认 |

---

## 七、首次登录完整核对清单

```
□ 1. 已购买 Token（https://newmanager.wechatapi.net/）
□ 2. 确定用户微信所在省份区域编码（regionId）
□ 3. 选择设备类型（mac 优先，ipad 备用）
□ 4. 已准备 iOS 设备+安盾APP（如选 iPad 方案）
□ 5. 调用 getLoginQrCode 获取二维码
□ 6. 用户扫码
□ 7. 完成验证（自动/人脸/滑块）
□ 8. 轮询 checkLogin 直到 status=2
□ 9. 保存 appId 和 wxid
□ 10. 绑定回调 setCallback
□ 11. 验证在线 checkOnline = true
□ 12. 发送测试消息
```

---

## 八、常见问题

**Q：为什么选择 Mac 而不是 iPad？**
A：Mac 流程更短，autoSliding=false 即可完成（无需验证）。iPad 需额外人脸验证。

**Q：regionId 怎么选？**
A：用户微信绑定的手机号归属地省份。不确定时用 `110000`（北京），失败再尝试正确省份。

**Q：出现"你已退出该设备登录"？**
A：次日凌晨自动掉线，属正常现象。重新取码（传已有 appId）登录即可。

**Q：人脸验证总是失败？**
A：检查安顿APP是否最新版本，尝试重新下载；或切换至 Mac 方案绕过人脸验证。

**Q：appId 和 Token 什么关系？**
A：Token 是平台购买凭证（绑定支付），appId 是设备标识（绑定微信账号）。**更换 Token 后 appId 不变，但需重新 setCallback**。
