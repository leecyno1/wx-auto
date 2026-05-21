# WeChatAPI — 消息模块

**Base URL**: `http://api.wechatapi.net/finder/v2/api`  
**认证**: `VideosApi-token` in header

**通用参数**：所有请求均需在 body 中包含 `appId`。

---

## 发送文字消息

```
POST /message/postText
```
```json
{ "appId": "<appid>", "toWxid": "<wxid>", "content": "你好", "ats": "" }
```
`ats`：群聊@某人时用 `wxid1,wxid2`，@所有人用 `notify@all`

---

## 发送图片消息

```
POST /message/postImage
```
```json
{ "appId": "<appid>", "toWxid": "<wxid>", "imgUrl": "http://..." }
```
返回 cdn 信息，同一图片第二次发可用[转发图片](#转发图片)加速。

---

## 发送文件

```
POST /message/postFile
```
```json
{ "appId": "<appid>", "toWxid": "<wxid>", "fileUrl": "http://...", "fileName": "doc.pdf" }
```

---

## 发送链接卡片

```
POST /message/postLink
```
```json
{
  "appId": "<appid>", "toWxid": "<wxid>",
  "title": "标题", "desc": "描述", "url": "https://...", "thumbUrl": "https://..."
}
```

---

## 发送视频消息

```
POST /message/postVideo
```
```json
{
  "appId": "<appid>", "toWxid": "<wxid>",
  "videoUrl": "http://...", "videoName": "video.mp4",
  "videoDuration": 30
}
```

---

## 发送语音消息

```
POST /message/postVoice
```
```json
{
  "appId": "<appid>", "toWxid": "<wxid>",
  "voiceUrl": "http://...", "voiceDuration": 5
}
```

---

## 发送表情

```
POST /message/postEmoji
```
```json
{
  "appId": "<appid>", "toWxid": "<wxid>",
  "emojiMd5": "<md5>", "emojiSize": 1024
}
```

---

## 发送小程序

```
POST /message/postMiniApp
```
```json
{
  "appId": "<appid>", "toWxid": "<wxid>",
  "userName": "gh_xxx@app", "title": "小程序名",
  "imageUrl": "http://...", "path": "pages/index/index"
}
```

---

## 发送名片

```
POST /message/postNameCard
```
```json
{
  "appId": "<appid>", "toWxid": "<wxid>",
  "nickName": "张三", "nameCardWxid": "wxid_xxx"
}
```

---

## 发送位置

```
POST /message/postLocation
```
```json
{
  "appId": "<appid>", "toWxid": "<wxid>",
  "contentXml": "<msg><location x=\"...\" y=\"...\" scale=\"15\" label=\"...\"/></msg>"
}
```

---

## 发送 AppMsg

```
POST /message/postAppMsg
```
```json
{
  "appId": "<appid>", "toWxid": "<wxid>",
  "appmsgXml": "<appmsg appid=\"\" sdkver=\"0\"><title>...</title>..."
}
```

---

## 发送视频号消息

```
POST /message/sendFinderMsg
```
```json
{
  "appId": "<appid>", "toWxid": "<wxid>",
  "xml": "<finderMsg>...</finderMsg>"
}
```

---

## 转发消息（图片/视频/文件/链接/小程序）

```
POST /message/forwardImage
POST /message/forwardVideo
POST /message/forwardFile
POST /message/forwardUrl
POST /message/forwardMiniApp
```
```json
{ "appId": "<appid>", "toWxid": "<wxid>", "xml": "<cdn xml from original message>" }
```
需要先通过下载接口获取原始消息的 cdn xml。

---

## 下载资源

| 端点 | 用途 | 关键参数 |
|------|------|---------|
| `POST /message/downloadImage` | 下载图片 | aesKey, fileId, imgType |
| `POST /message/downloadVideo` | 下载视频 | aesKey, fileId |
| `POST /message/downloadFile` | 下载文件 | aesKey, fileId |
| `POST /message/downloadVoice` | 下载语音 | aesKey, fileId |
| `POST /message/downloadEmojiMd5` | 下载表情 | emojiMd5 |

```json
{ "appId": "<appid>", "aesKey": "...", "fileId": "...", "imgType": "mid" }
```

---

## 撤回消息

```
POST /message/revokeMsg
```
```json
{
  "appId": "<appid>", "toWxid": "<wxid>",
  "msgId": "<msgId>", "newMsgId": "<newMsgId>", "createTime": "<timestamp>"
}
```
