# WeChatAPI — 联系人模块

**Base URL**: `http://api.wechatapi.net/finder/v2/api`

---

## 获取联系人列表

```
POST /contacts/fetchContactsList
```
Body: `{ "appId": "<appid>" }`
Response: 完整联系人列表（含 wxid, nickname, remark, avatar 等）

---

## 获取联系人列表缓存

```
POST /contacts/fetchContactsListCache
```
Body: `{ "appId": "<appid>" }`
返回 V3 数据，可配合 `getDetailInfo` 补齐信息。

---

## 搜索联系人

```
POST /contacts/search
```
```json
{ "appId": "<appid>", "contactsInfo": "<微信号/手机号>" }
```

---

## 添加联系人

```
POST /contacts/addContacts
```
```json
{
  "appId": "<appid>",
  "scene": 3,          // 添加场景: 3=微信号, 7=群聊, 14=手机号
  "content": "<wxid>", // 或手机号
  "content1": "<备注>",
  "content2": "<描述>",
  "content3": "<手机号>",
  "addOrg": ""         // 来自好友请求的 v3 值
}
```

---

## 删除好友

```
POST /contacts/deleteFriend
```
```json
{ "appId": "<appid>", "wxid": "<wxid>" }
```

---

## 批量获取简要信息

```
POST /contacts/getBriefInfo
```
```json
{ "appId": "<appid>", "wxids": ["wxid1", "wxid2"] }
```

---

## 批量获取详细信息

```
POST /contacts/getDetailInfo
```
```json
{ "appId": "<appid>", "wxids": ["wxid1", "wxid2"] }
```

---

## 设置好友备注

```
POST /contacts/setFriendRemark
```
```json
{ "appId": "<appid>", "wxid": "<wxid>", "remark": "新备注" }
```

---

## 设置好友权限

```
POST /contacts/setFriendPermissions
```
```json
{ "appId": "<appid>", "wxid": "<wxid>", "onlyChat": true }
```
`onlyChat`: true=仅聊天，false=聊天+朋友圈

---

## 检查好友关系

```
POST /contacts/checkRelation
```
```json
{ "appId": "<appid>", "wxids": ["wxid1"] }
```

---

## 获取手机通讯录

```
POST /contacts/getPhoneAddressList
```
Body: `{ "appId": "<appid>" }`

---

## 上传手机通讯录

```
POST /contacts/uploadPhoneAddressList
```
```json
{ "appId": "<appid>", "phones": ["138xxxx", "139xxxx"] }
```
