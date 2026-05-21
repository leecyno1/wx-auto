# WeChatAPI — 视频号模块

**Base URL**: `http://api.wechatapi.net/finder/v2/api`

---

## 搜索视频号

```
POST /finder/search
```
```json
{ "appId": "<appid>", "keyword": "<搜索词>" }
```

---

## 获取视频号主页

```
POST /finder/getProfile
```
```json
{ "appId": "<appid>", "finderUsername": "<username>" }
```

---

## 创建视频号

```
POST /finder/createFinder
```
```json
{ "appId": "<appid>", "name": "视频号名", "description": "简介" }
```

---

## 发送私信

```
POST /finder/postPrivateLetter
```
```json
{ "appId": "<appid>", "msgSessionId": "<id>", "content": "你好" }
```

---

## 发送图片私信

```
POST /finder/postPrivateLetterImg
```
```json
{ "appId": "<appid>", "msgSessionId": "<id>", "imageUrl": "http://..." }
```

---

## 获取联系人列表（视频号）

```
POST /finder/contactList
```
Body: `{ "appId": "<appid>" }`

---

## 获取消息会话ID

```
POST /finder/getMsgSessionId
```
```json
{ "appId": "<appid>", "finderUsername": "<username>" }
```

---

## 获取个人信息

```
POST /finder/getFinderInfo
```
Body: `{ "appId": "<appid>" }`

---

## 扫描登录通道

```
POST /finder/scanLoginChannels
```
```json
{ "appId": "<appid>", "username": "" }
```

---

## 扫描二维码

```
POST /finder/scanQrcode
```
```json
{ "appId": "<appid>", "qrData": "<qr_data>" }
```

---

## 关注

```
POST /finder/follow
```
```json
{ "appId": "<appid>", "finderUsername": "<username>" }
```

## 取消关注

```
POST /finder/scanFollow
```
```json
{ "appId": "<appid>", "finderUsername": "<username>" }
```

---

## 点赞

```
POST /finder/like
```
```json
{ "appId": "<appid>", "objectId": "<id>" }
```

## 取消点赞

```
POST /finder/scanLike
```
```json
{ "appId": "<appid>", "objectId": "<id>" }
```

---

## 收藏

```
POST /finder/idFav
```
```json
{ "appId": "<appid>", "objectId": "<id>" }
```

## 取消收藏

```
POST /finder/scanFav
```
```json
{ "appId": "<appid>", "objectId": "<id>" }
```

---

## 评论

```
POST /finder/comment
```
```json
{ "appId": "<appid>", "objectId": "<id>", "content": "评论" }
```

## 取消评论

```
POST /finder/scanComment
```
```json
{ "appId": "<appid>", "objectId": "<id>", "content": "" }
```

---

## 获取推荐流

```
POST /finder/browse
```
Body: `{ "appId": "<appid>" }`

## 扫码浏览

```
POST /finder/scanBrowse
```
Body: `{ "appId": "<appid>" }`

---

## 获取我的二维码

```
POST /finder/getQrcode
```
Body: `{ "appId": "<appid>" }`

---

## 发布视频号内容

```
POST /finder/publishFinderWeb
```
```json
{ "appId": "<appid>", "finderXml": "<发布xml>" }
```

---

## 更新视频号资料

```
POST /finder/updateProfile
```
```json
{ "appId": "<appid>", "field": "fieldName", "value": "value" }
```

---

## 关注列表

```
POST /finder/followList
```
Body: `{ "appId": "<appid>" }`

---

## 点赞/收藏列表

```
POST /finder/likeFavList
```
Body: `{ "appId": "<appid>" }`

---

## 评论列表

```
POST /finder/commentList
```
Body: `{ "appId": "<appid>" }`

---

## @我列表

```
POST /finder/mentionList
```
Body: `{ "appId": "<appid>" }`

---

## 用户主页

```
POST /finder/userPage
```
```json
{ "appId": "<appid>", "finderUsername": "<username>" }
```
