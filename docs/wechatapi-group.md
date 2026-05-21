# WeChatAPI — 群管理模块

**Base URL**: `http://api.wechatapi.net/finder/v2/api`

---

## 创建群聊

```
POST /group/createChatroom
```
```json
{ "appId": "<appid>", "wxids": ["wxid1", "wxid2", "wxid3"] }
```
需至少 2 个好友才能建群。

---

## 修改群名称

```
POST /group/modifyChatroomName
```
```json
{ "appId": "<appid>", "chatroomId": "xxx@chatroom", "name": "新群名" }
```

---

## 修改群备注

```
POST /group/modifyChatroomRemark
```
```json
{ "appId": "<appid>", "chatroomId": "xxx@chatroom", "remark": "群备注" }
```

---

## 修改我在群里的昵称

```
POST /group/modifyChatroomNicknameForSelf
```
```json
{ "appId": "<appid>", "chatroomId": "xxx@chatroom", "nickName": "我的群昵称" }
```

---

## 邀请成员

```
POST /group/inviteMember
```
```json
{ "appId": "<appid>", "chatroomId": "xxx@chatroom", "wxids": ["wxid1"] }
```

---

## 移除成员

```
POST /group/removeMember
```
```json
{ "appId": "<appid>", "chatroomId": "xxx@chatroom", "wxid": "wxid1" }
```

---

## 退出群聊

```
POST /group/quitChatroom
```
```json
{ "appId": "<appid>", "chatroomId": "xxx@chatroom" }
```

---

## 获取群信息

```
POST /group/getChatroomInfo
```
```json
{ "appId": "<appid>", "chatroomId": "xxx@chatroom" }
```

---

## 获取群成员列表

```
POST /group/getChatroomMemberList
```
```json
{ "appId": "<appid>", "chatroomId": "xxx@chatroom" }
```

---

## 获取群成员详细信息

```
POST /group/getChatroomMemberDetail
```
```json
{
  "appId": "<appid>", "chatroomId": "xxx@chatroom",
  "memberWxids": ["wxid1", "wxid2"]
}
```

---

## 设置群公告

```
POST /group/setChatroomAnnouncement
```
```json
{ "appId": "<appid>", "chatroomId": "xxx@chatroom", "announcement": "公告内容" }
```

---

## 获取群公告

```
POST /group/getChatroomAnnouncement
```
```json
{ "appId": "<appid>", "chatroomId": "xxx@chatroom" }
```

---

## 同意进群申请

```
POST /group/agreeJoinRoom
```
```json
{ "appId": "<appid>", "chatroomId": "xxx@chatroom", "url": "<url>" }
```

---

## 通过群加好友

```
POST /group/addGroupMemberAsFriend
```
```json
{ "appId": "<appid>", "chatroomId": "xxx@chatroom", "memberWxid": "wxid" }
```

---

## 获取群二维码

```
POST /group/getChatroomQrcode
```
```json
{ "appId": "<appid>", "chatroomId": "xxx@chatroom" }
```

---

## 保存到通讯录

```
POST /group/saveContractList
```
```json
{ "appId": "<appid>", "chatroomId": "xxx@chatroom" }
```

---

## 群管理员操作

```
POST /group/adminOperate
```
```json
{ "appId": "<appid>", "chatroomId": "xxx@chatroom", "wxid": "wxid", "opType": 1 }
```
opType: 1=设管理员, 2=取消管理员

---

## 群聊置顶

```
POST /group/pinChat
```
```json
{ "appId": "<appid>", "chatroomId": "xxx@chatroom", "pin": true }
```

---

## 群消息免打扰

```
POST /group/setMsgSilence
```
```json
{ "appId": "<appid>", "chatroomId": "xxx@chatroom", "silence": true }
```

---

## 扫码进群

```
POST /group/joinRoomUsingQrcode
```
```json
{ "appId": "<appid>", "qrUrl": "<qrcode_url>" }
```

---

## 群聊邀请确认

```
POST /group/roomAccessApplyCheckApprove
```
```json
{ "appId": "<appid>", "chatroomId": "xxx@chatroom", "url": "<url>", "approve": true }
```
