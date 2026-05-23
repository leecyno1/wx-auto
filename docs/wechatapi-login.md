# WeChatAPI — 首次登录完全指南

> 定期更新自官方文档 [wechatapi.net 开放平台](https://post.wechatapi.net/raiz5jee8eiph0eeFooV/api/v1/projects/4425884)
>
> 本文档聚焦 **首次登录**。后续重连/日常操作见 AGENT 内存。
>
> **⚠️ 重要区分**：
> - 首次登录 = 新 Token + 新设备 → 走完整扫码+验证流程
> - 后续重连 = 已有 appId → 直接取码扫码，无需人脸/滑块验证

---

## 一、登录方式选择

| 设备类型 | 复杂度 | 验证方式 | 推荐场景 |
|---------|--------|---------|---------|
| **Mac** | 简单 | 扫码 → autoSliding 自动滑块/或无需验证 → 成功 | 首次快速上线、本地测试 |
| **iPad** | 复杂 | 扫码 → checkLogin 判断验证类型 → 人脸验证（安盾APP）→ 手机确认 → 成功 | Mac 方案不可用时 |

---

## 二、Base URL

| URL | 说明 |
|-----|------|
| `http://api.wechatapi.net/finder/v2/api` | 旧版，HTTP |
| `https://post.wechatapi.net` | 新版，HTTPS，推荐 |

---

## 三、通用参数

### 设备类型 `type`

| 值 | 说明 |
|----|------|
| `"mac"` | Mac 协议，流程短，autoSliding 控制自动/手动滑块 |
| `"ipad"` | iPad 协议，有人脸验证流程 |

### `autoSliding`

| 值 | Mac | iPad |
|----|-----|------|
| `true` | 自动完成滑块验证（无感） | 自动人脸验证流程 |
| `false` | 需安卓APP扫码做图形验证 | 基础流程 |

### 推荐默认参数

```json
// Mac 方案（首选）
{ "type": "mac", "autoSliding": false, "regionId": "110000", "proxyIp": "", "ttuid": "" }

// iPad 方案（备用）
{ "type": "ipad", "autoSliding": true, "regionId": "110000", "proxyIp": "", "ttuid": "" }
```

### 区域编码 `regionId`

**必须与用户微信绑定的手机号归属地匹配**，否则触发风控。

```json
110000 北京市     120000 天津市      130000 河北省      140000 山西省
150000 内蒙古     210000 辽宁省      220000 吉林省      230000 黑龙江
310000 上海市     320000 江苏省      330000 浙江省      340000 安徽省
350000 福建省     360000 江西省      370000 山东省      410000 河南省
420000 湖北省     430000 湖南省      440000 广东省      450000 广西省
460000 海南省     500000 重庆市      510000 四川省      520000 贵州省
530000 云南省     540000 西藏        610000 陕西省      620000 甘肃省
630000 青海省     640000 宁夏        650000 新疆
```

默认 `110000`（北京），失败后换用户归属地。可选 socks5 代理 IP（格式：`socks5://user:pass@ip:port`）进行异地登录。

---

## 四、iPad 登录方案（复杂，需人脸验证）

### 完整流程图

```
开始
  ↓
发起 getLoginQrCode (type=ipad)
  ↓
获取二维码
  ↓
用户微信扫码
  ↓
进入 checkLogin 轮询（每 5s，120s 超时）
  ↓
┌─ 是否有数字验证码（captchCode）？ ─┐
│  是 → 填写 captchCode 参数          │
│       → 重试 checkLogin             │
│      → 手机微信点击确认             │
│      → checkLogin 再次轮询          │
│                                     │
│  否 → 是否返回了人脸验证 URL？       │
│      │ 是 → iOS 设备下载【安盾APP】  │
│      │    → 安盾APP 扫描验证二维码   │
│      │    → 人脸验证完成             │
│      │    → 手机微信点击确认         │
│      │    → checkLogin 轮询至成功    │
│      │                               │
│      │ 否 → 继续轮询等待             │
└─────────────────────────────────────┘
  ↓
登录成功（status=2, loginInfo 有数据）
  ↓
结束
```

### 步骤 1：获取二维码

```bash
POST https://post.wechatapi.net/login/getLoginQrCode
Headers: VideosApi-token: <你的Token>
Body:
{
  "appId": "",           // 首次传空
  "regionId": "110000",
  "type": "ipad",        // ← 关键
  "proxyIp": "",
  "ttuid": ""
}
```

响应中保存 `appId`（设备标识）和 `uuid`（二维码标识）。

### 步骤 2：用户微信扫码

展示二维码给用户扫码。

### 步骤 3：checkLogin 轮询 + 验证处理

扫码后每 **5 秒** 调用一次 checkLogin（二维码 120 秒超时）：

```bash
POST https://post.wechatapi.net/login/checkLogin
Headers: VideosApi-token: <你的Token>
Body:
{
  "appId": "wx_xxx...",
  "uuid": "abc123...",
  "proxyIp": "",
  "captchCode": "",       // 如有数字验证码填这里
  "autoSliding": true
}
```

#### iPad 验证流程的关键分支

iPad 扫码后，checkLogin 返回值的处理路径：

**① 有数字验证码（captchCode 不为空）**
- 用户手机微信收到数字验证码
- 将验证码填入 captchCode 字段，重新调用 checkLogin
- 手机微信点击确认登录
- 继续轮询 checkLogin 直到 status=2

**② 无数字验证码，但返回人脸验证 URL**
- iPad 扫码后大多数情况走此分支
- checkLogin 返回数据中包含人脸验证二维码 URL
- 需 **iOS 设备** 下载 **安盾APP**（https://www.pgyer.com/renzhengapp）
- 打开安盾APP → 扫码验证 → 扫描该二维码
- 完成人脸识别（正对摄像头、眨眼、张嘴等动作）
- 验证通过后，手机微信弹出确认登录提示
- **用户手动点击确认**（需在手机上操作，无法模拟）
- 继续轮询 checkLogin 直到 status=2

**③ 无验证、无二维码、持续 status=1**
- 等待手机微信弹出确认，用户点击确认
- 继续轮询

### iPad 登录注意事项

- 安盾APP 是企业签名版，安装后需在 iOS 设置 → 通用 → VPN与设备管理 中信任证书
- 人脸验证需光线充足，验证失败可重新获取二维码重试
- 每个确认按钮需在手机上操作，不是电脑模拟
- 首次登录成功后到次日凌晨大概率掉线一次，属正常，重新取码（传已有 appId）登录即可

---

## 五、Mac 登录方案（简单，推荐）

### 完整流程图

```
开始
  ↓
发起 getLoginQrCode (type=mac)
  ↓
获取二维码
  ↓
用户微信扫码
  ↓
checkLogin 轮询（默认 autoSliding=false，自动滑块/无需验证）
  ↓
登录成功（status=2, loginInfo 有数据）
  ↓
结束
```

### 步骤 1：获取二维码

```bash
POST https://post.wechatapi.net/login/getLoginQrCode
Headers: VideosApi-token: <你的Token>
Body:
{
  "appId": "",
  "regionId": "110000",
  "type": "mac",        // ← 关键：type=mac
  "proxyIp": "",
  "ttuid": ""
}
```

保存返回的 `appId` 和 `uuid`。

### 步骤 2：用户扫码

展示二维码，用户用微信扫码。

### 步骤 3：checkLogin 轮询

```bash
POST https://post.wechatapi.net/login/checkLogin
Headers: VideosApi-token: <你的Token>
Body:
{
  "appId": "wx_xxx...",
  "uuid": "abc123...",
  "proxyIp": "",
  "captchCode": "",
  "autoSliding": false      // Mac 默认 false，自动处理
}
```

**status 变化**：0→1→2（或 4 取消）。Mac 方案通常扫码后 autoSliding 自动完成滑块或无验证直接通过。

### 步骤 4：绑定回调

```bash
POST https://post.wechatapi.net/login/setCallback
Body: { "token": "<Token>", "callbackUrl": "https://你的地址/api/wechat-gateway/callback" }
```

---

## 六、返回码（ret）与异常说明对照表

| ret | msg | 含义 | 处理 |
|-----|-----|------|------|
| 200 / 0 | "操作成功" | 成功 | 正常继续 |
| 400 | "参数错误" | 请求参数缺失或格式不对 | 检查 appId、uuid、regionId 等必填字段 |
| 401 | "token无效" | VideosApi-token 错误或过期 | 检查 Token 是否有效，重新购买 |
| 403 | "无权限" | Token 无权操作该接口 | 确认套餐是否包含该功能 |
| 404 | "appId不存在" | 传入的 appId 未注册 | 首次登录传空 appId 或确认 appId 正确 |
| 408 | "二维码已过期" | getLoginQrCode 返回的 uuid 超过 120s 未完成 | 重新获取二维码 |
| 429 | "请求太频繁" | 调用频率超限 | 降低调用频率，增加间隔 |
| 500 | "服务器内部错误" | wechatapi 服务端异常 | 稍后重试；如持续，检查 Token 是否过期 |
| 1001 | "登录态失效" | 设备已离线需重新登录 | 调用 getLoginQrCode 重新扫码 |
| 1002 | "设备被踢下线" | 其他设备登录了同一账号 | 确认是否有其他设备登录 |
| 1003 | "风控拦截" | 微信风控触发，需等待 | 停止操作 24 小时后重试；检查 regionId 是否与用户所在地匹配 |
| 1004 | "需要验证" | 需要人脸/滑块/数字验证 | 按 checkLogin 返回的验证类型处理 |
| 1005 | "人脸验证失败" | 安盾APP 人脸识别未通过 | 重新获取二维码 + 重新人脸验证 |
| 1006 | "验证超时" | 用户未在时间内完成验证 | 重新获取二维码开始 |
| 1007 | "取消登录" | 用户在手机上取消了登录 | 重新获取二维码 |
| 1008 | "账号异常" | 微信账号被限制登录新设备 | 联系微信客服解封 |
| 其他 | — | 未知异常 | 重新从 getLoginQrCode 开始完整流程 |

> `ret` 在正常响应中为 200 或 0，非 200 时需根据 `msg` 判断。部分场景下接口返回 HTTP 500 同时 body 中 ret=0，此时解析 data 字段确认。

---

## 七、开发测试：轮询 checkLogin 标准模板

```
每 5 秒调用一次 checkLogin，最多 10 次（即 50 秒超时）
如超时或登录状态长时间未更新（同一 status 持续 30s）：终止轮询，保存当前值，让用户手动确认/重启
如 checkLogin 返回异常（ret≠200/0）：终止轮询，输出异常信息，提示用户重新开始
```

### 手动重试流程

当自动化轮询超时或异常时，可在终端手动执行：

```bash
# 1. 手动调用 checkLogin 确认状态
curl -s -X POST https://post.wechatapi.net/login/checkLogin \
  -H "VideosApi-token: <Token>" \
  -d '{"appId":"wx_xxx...","uuid":"abc123...","proxyIp":"","captchCode":"","autoSliding":false}'

# 2. 如手机已确认登录但 checkLogin 仍无数据 → 尝试修改 autoSliding 参数
curl -s -X POST https://post.wechatapi.net/login/checkLogin \
  -H "VideosApi-token: <Token>" \
  -d '{"appId":"wx_xxx...","uuid":"abc123...","proxyIp":"","captchCode":"","autoSliding":true}'

# 3. 如 checkLogin 返回异常 → 重新开始整个流程
#    重新获取二维码：
curl -s -X POST https://post.wechatapi.net/login/getLoginQrCode \
  -H "VideosApi-token: <Token>" \
  -d '{"appId":"","regionId":"110000","type":"mac","proxyIp":"","ttuid":""}'
```

手动流程灵活性更高，可按需调整参数验证。

---

## 八、首次登录完整核对清单

```
□ 1. 已购买 Token（https://newmanager.wechatapi.net/）
□ 2. 确定用户微信所在省份区域编码（regionId）
□ 3. 选择设备类型（mac 优先，ipad 备用）
□ 4. 已准备 iOS 设备+安盾APP（如选 iPad 方案）
□ 5. 调用 getLoginQrCode 获取二维码
□ 6. 用户扫码
□ 7. 完成验证（自动/人脸/滑块）
□ 8. 轮询 checkLogin → 每 5s × 最多 10 次
□ 9. 保存 appId 和 wxid（映射关系永久保存）
□ 10. 绑定回调 setCallback
□ 11. 验证在线 checkOnline = true
□ 12. 发送测试消息
```

---

## 九、常见问题

**Q：Mac 方案总是失败怎么办？**
A：切换 iPad 方案。设备切换顺序：mac → ipad。iPad 方案流程更长但兼容性更好。

**Q：人脸验证总是失败？**
A：检查安盾APP是否最新；光线是否充足；尝试重新下载安盾APP；或切换 Mac 方案绕过。

**Q：checkLogin 一直返回 status=1 不前进？**
A：检查手机微信是否弹出了确认登录提示，需手动点击确认。尝试修改 autoSliding 参数重试。

**Q：出现"你已退出该设备登录"？**
A：次日凌晨自动掉线，属正常现象。重新取码（传已有 appId）登录即可。

**Q：regionId 选错了会怎样？**
A：触发微信风控，checkLogin 返回 1003（风控拦截）。需更换正确 regionId 或等待 24 小时。

**Q：appId 和 Token 什么关系？**
A：Token 是平台购买凭证（绑定支付），appId 是设备标识（绑定微信账号）。**更换 Token 后 appId 不变，但需重新 setCallback**。
