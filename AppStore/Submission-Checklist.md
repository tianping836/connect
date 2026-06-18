# App Store 上架清单

> 按顺序逐项完成。预计 2-4 周。

---

## 前置条件

- [ ] Apple Developer Program 会员（$99/年）
  - 登录 [developer.apple.com](https://developer.apple.com) 检查状态
  - 如果未加入：在 App Store Connect 或 Xcode 中购买
- [ ] Xcode 26+ 已安装（当前版本 26.5 ✅）
- [ ] 代码已提交 + 推送（当前 main 分支 ✅）

---

## 第一步：Xcode 项目准备

### 1.1 打开项目
```bash
cd ~/.myagents/projects/casenetwork
open Package.swift  # 在 Xcode 中打开
```

### 1.2 配置 Bundle Identifier
1. Xcode → 选择 CaseNetwork target → General 标签
2. Bundle Identifier: `com.zhouyijunlawyer.casenetwork`（建议格式）
3. Team: 选择你的 Apple Developer 账号

### 1.3 配置 Info.plist
在 Xcode Build Settings 中添加：
- `ITSAppUsesNonExemptEncryption` = `NO`
- 参考 `AppStore/Info.plist` 中的其他必要字段

### 1.4 配置 Capabilities
在 Xcode → Signing & Capabilities 中：
- [ ] **iCloud** → 勾选 CloudKit
  - CloudKit Container: `iCloud.com.zhouyijunlawyer.casenetwork`
- [ ] **App Groups**（如果启用了 CloudKit 同步）
  - Group: `group.com.casenetwork.data`

### 1.5 配置代码签名
- [ ] Provisioning Profile: Xcode Managed（自动管理）推荐
- [ ] 或手动配置（如果使用手动签名）

---

## 第二步：App Store Connect 创建 App

### 2.1 登录
访问 [appstoreconnect.apple.com](https://appstoreconnect.apple.com)

### 2.2 新建 App
- **平台**: iOS
- **名称**: CaseNetwork
- **主要语言**: Simplified Chinese（中文）
- **Bundle ID**: 与 Xcode 中的一致
- **SKU**: `casenetwork-001`（内部唯一标识）
- **用户访问权限**: 完全访问

### 2.3 填写 App 信息
- **副标题**: 案件与人脉，一网打尽
- **描述**: 复制 `AppStore/AppStore-Description.md` 中的中文描述
- **关键词**: 复制中文关键词
- **宣传文本**: 复制中文宣传文本
- **类别**:
  - 主要: 商务 (Business)
  - 次要: 效率 (Productivity)

### 2.4 上传截图
需要以下尺寸（可先从模拟器截图）：

| 设备 | 尺寸 | 数量 |
|------|------|------|
| iPhone 6.7" (Pro Max) | 1290×2796 | 至少 3 张 |
| iPhone 6.5" (Pro/Plus) | 1242×2688 | 至少 3 张 |
| iPad 12.9" (Pro) | 2048×2732 | 至少 3 张 |

**截图内容建议：**
1. 案件列表页（展示 Pipeline 阶段）
2. 案件详情页（展示参与人及角色）
3. 人脉详情页（展示关联案件）
4. 日历月视图
5. 全局搜索
6. 添加参与人弹窗

### 2.5 隐私政策 URL
- 需托管一个可公开访问的隐私政策页面
- 内容见 `AppStore/PrivacyPolicy.md`
- 建议 URL: `https://zhouyijunlawyer.com/privacy/casenetwork/`

### 2.6 隐私标签
- 参考 `AppStore/PrivacyLabels.md`
- 在 App Store Connect → App Privacy 中逐项填写
- 所有数据类别选择 **"不收集数据"**

---

## 第三步：上传构建版本

### 3.1 准备归档
```bash
cd ~/.myagents/projects/casenetwork
xcodebuild -scheme CaseNetwork \
  -destination 'generic/platform=iOS' \
  archive \
  -archivePath ./build/CaseNetwork.xcarchive
```

### 3.2 上传到 App Store Connect
在 Xcode → Organizer → Archives 中：
1. 选择最新的 Archive
2. 点击 "Distribute App"
3. 选择 "App Store Connect"
4. 按向导完成上传

或使用命令行：
```bash
xcodebuild -exportArchive \
  -archivePath ./build/CaseNetwork.xcarchive \
  -exportOptionsPlist exportOptions.plist \
  -exportPath ./build/
```

### 3.3 等待处理
上传后，App Store Connect 会处理构建版本（通常 15-30 分钟）。处理完成后会收到邮件通知。

---

## 第四步：TestFlight 内测

### 4.1 创建内部测试组
1. App Store Connect → TestFlight → Internal Testing
2. 添加测试人员（App Store Connect 用户）
3. 选择构建版本 → 开始测试

### 4.2 收集反馈
- 至少邀请 2-3 人测试 1-2 天
- 关注：数据导入/导出是否正常、关联跳转是否流畅、提醒是否准时
- 也可使用外部测试（External Testing），需先通过 Beta App Review

---

## 第五步：提交审核

### 5.1 最终检查
- [ ] App 描述、关键词准确
- [ ] 截图与当前版本一致
- [ ] 隐私政策 URL 可访问
- [ ] 隐私标签填写正确
- [ ] App 内无崩溃或明显 bug
- [ ] 构建版本不含调试代码

### 5.2 提交
1. App Store Connect → App 详情页
2. 选择要提交的构建版本
3. 填写 "App Review Information"（测试账号等——若不需登录则留空）
4. 选择 "Manually release this version"（手动发布）——建议
5. 点击 "Submit for Review"

### 5.3 审核时间
- 通常 24-48 小时
- 首次提交可能略长

---

## 常见被拒原因及预防

| 原因 | 预防措施 |
|------|---------|
| 隐私政策不完整 | 确保隐私政策页面包含：数据收集、存储、使用、第三方共享、用户权利 |
| 数据收集说明不准确 | 如果 App 不上传数据，隐私标签全部填"不收集" |
| App 功能过于简单 | 确保描述与实际功能匹配，不要夸大 |
| UI 不一致或崩溃 | 在真实设备上跑遍所有页面 |
| 缺少必要权限说明 | Face ID 权限已配置 `NSFaceIDUsageDescription` |
| 不支持 IPv6 | SwiftUI App 天然支持，非问题 |

---

## 上架后

- [ ] 在 App Store Connect 中点击 "Release" 发布
- [ ] 检查 App Store 页面显示是否正确
- [ ] 准备下一版本迭代计划
- [ ] 收集用户评价和反馈
