# WeChatAPI — 朋友圈模块

**Base URL**: `http://api.wechatapi.net/finder/v2/api`

---

## 发文字朋友圈

```
POST /sns/sendTextSns
```
```json
{ "appId": "<appid>", "content": "今天天气真好" }
```

---

## 发图片朋友圈

```
POST /sns/sendImgSns
```
```json
{ "appId": "<appid>", "imageIds": ["img_id1","img_id2"], "description": "描述文字" }
```
先通过 `uploadSnsImage` 上传图片获取 imageId。

---

## 发视频朋友圈

```
POST /sns/sendVideoSns
```
```json
{ "appId": "<appid>", "videoId": "<video_id>", "description": "描述", "previewId": "" }
```
先通过 `uploadSnsVideo` 上传视频。

---

## 发链接朋友圈

```
POST /sns/sendUrlSns
```
```json
{ "appId": "<appid>", "url": "https://...", "title": "标题", "description": "描述" }
```

---

## 发视频号到朋友圈

```
POST /sns/sendFinderSns
```
```json
{ "appId": "<appid>", "finderXml": "<xml>" }
```

---

## 转发朋友圈

```
POST /sns/forwardSns
```
```json
{ "appId": "<appid>", "snsId": 12345, "wxid": "wxid", "description": "转发文案" }
```

---

## 朋友圈列表

```
POST /sns/snsList
```
```json
{ "appId": "<appid>", "maxId": 0, "firstPageMd5": "", "decrypt": true }
```
maxId=0 获取第一页；后续用返回的 maxId 翻页。

---

## 联系人朋友圈

```
POST /sns/contactSnsList
```
```json
{ "appId": "<appid>", "wxid": "wxid_xxx", "maxId": 0, "firstPageMd5": "" }
```

---

## 朋友圈详情

```
POST /sns/snsDetails
```
```json
{ "appId": "<appid>", "snsId": 12345 }
```

---

## 评论朋友圈

```
POST /sns/commentSns
```
```json
{ "appId": "<appid>", "snsId": 12345, "content": "评论内容" }
```

---

## 点赞朋友圈

```
POST /sns/likeSns
```
```json
{ "appId": "<appid>", "snsId": 12345, "wxid": "wxid", "operType": 1 }
```
operType: 1=点赞, 0=取消

---

## 删除朋友圈

```
POST /sns/delSns
```
```json
{ "appId": "<appid>", "snsId": 12345 }
```

---

## 设置朋友圈权限

```
POST /sns/snsSetPrivacy
```
```json
{ "appId": "<appid>", "wxid": "wxid", "privacy": 1 }
```
privacy: 1=不让看, 0=恢复

---

## 朋友圈可见范围

```
POST /sns/snsVisibleScope
```
```json
{ "appId": "<appid>", "wxid": "wxid", "scope": 0 }
```
scope: 0=不看他, 1=看他

---

## 上传朋友圈图片

```
POST /sns/uploadSnsImage
```
```json
{ "appId": "<appid>", "imageUrl": "http://.../image.jpg" }
```
返回 imageId，用于 sendImgSns。

---

## 上传朋友圈视频

```
POST /sns/uploadSnsVideo
```
```json
{ "appId": "<appid>", "videoUrl": "http://.../video.mp4" }
```
返回 videoId，用于 sendVideoSns。
