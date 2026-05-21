# WeChatAPI — 个人信息 / 标签 / 收藏夹 / 企微同步

**Base URL**: `http://api.wechatapi.net/finder/v2/api`

---

## 个人信息模块

### 获取我的资料

```
POST /personal/getProfile
```
Body: `{ "appId": "<appid>" }`

### 获取二维码

```
POST /personal/getQrcode
```
Body: `{ "appId": "<appid>" }`

### 获取安全信息

```
POST /personal/getSafetyInfo
```
Body: `{ "appId": "<appid>" }`

### 隐私设置

```
POST /personal/privacySettings
```
```json
{ "appId": "<appid>", "option": 1 }
```
options: 加我方式、朋友圈权限等枚举值。

### 更新个人资料

```
POST /personal/updateProfile
```
```json
{ "appId": "<appid>", "fieldName": "NickName", "fieldValue": "新昵称" }
```

### 更新头像

```
POST /personal/updateHeadImage
```
```json
{ "appId": "<appid>", "headImgUrl": "http://..." }
```

---

## 标签模块

### 添加标签

```
POST /label/addLabel
```
```json
{ "appId": "<appid>", "labelName": "同事" }
```

### 删除标签

```
POST /label/deleteLabel
```
```json
{ "appId": "<appid>", "labelId": "<id>" }
```

### 标签列表

```
POST /label/listLabels
```
Body: `{ "appId": "<appid>" }`

### 修改成员标签

```
POST /label/modifyMemberLabels
```
```json
{
  "appId": "<appid>",
  "labelIds": ["label_id1", "label_id2"],
  "wxids": ["wxid1", "wxid2"]
}
```

---

## 收藏夹模块

### 同步收藏夹

```
POST /favor/syncFavorites
```
Body: `{ "appId": "<appid>" }`

### 获取收藏内容

```
POST /favor/getFavContent
```
```json
{ "appId": "<appid>", "favId": 12345 }
```

### 删除收藏

```
POST /favor/deleteFav
```
```json
{ "appId": "<appid>", "favId": 12345 }
```

---

## 企微同步模块

### 企微同步详情

```
POST /im/detail
```
```json
{ "appId": "<appid>" }
```

### 企微同步

```
POST /im/sync
```
```json
{ "appId": "<appid>" }
```
