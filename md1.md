# StudyMate Pro 会话记忆（md1）

> 生成时间：2026-04-26  
> 项目路径：`E:\测试\studymate`  
> 用途：下次新会话快速恢复上下文

---

## 1. 项目背景

- 项目名：**StudyMate Pro（全能学习效率伴侣）**
- 技术栈：Flutter 3.x + Riverpod + Hive + Material 3（含 fl_chart）
- 主要模块：Dashboard、课程、任务、番茄钟、闪卡、笔记、习惯、记账、个人中心

---

## 2. 本次会话核心目标与过程

### 阶段 A：预设题库数据与显示一致性

用户目标：
- 修复“预设题库里计算机专业课简介题目数量和真实题目数量不一致”的问题。

完成内容：
- 统计并修正以下题库真实题数：
  - 数据结构：51
  - 计算机组成原理：40
  - 操作系统：49
  - 计算机网络：45
- 更新了页面展示的 `description` 和 `count`。
- 同步修正对应 JSON 的 `description` 字段。

涉及文件：
- `lib/pages/flashcard/preset_decks_page.dart`
- `assets/data/data_structure.json`
- `assets/data/operating_system.json`
- `assets/data/computer_network.json`

---

### 阶段 B：Flutter 运行问题修复（此前延续）

会话中已落实/确认的关键修复：

1. 主题类型兼容
- `CardTheme` -> `CardThemeData`
- `DialogTheme` -> `DialogThemeData`
- 文件：`lib/theme/app_theme.dart`

2. 动画构建器参数
- `AnimatedBuilder(animation: ...)` -> `AnimatedBuilder(listenable: ...)`
- 文件：`lib/pages/flashcard/flashcard_study_page.dart`

3. 本地化日期初始化
- 增加 `intl` 日期格式初始化：`initializeDateFormatting('zh_CN', null)`
- 文件：`lib/main.dart`

---

### 阶段 C：个人中心登录与游客模式（本次新功能）

用户需求：
- 个人中心增加登录体系。
- 登录后个人资料可保存。
- 不登录可游客使用。
- 支持修改昵称、头像、个人标签。

已实现：

1. 用户模型（本地 Hive）
- 新增：`lib/models/user_profile.dart`
- 新增：`lib/models/user_profile.g.dart`
- 关键字段：`id`、`username`、`passwordHash`、`nickname`、`avatarIndex`、`avatarPath`、`tags`、`bio`、`createdAt`
- Hive `typeId = 11`

2. 用户状态管理
- 新增：`lib/providers/user_provider.dart`
- 能力：
  - 注册 / 登录 / 登出
  - 自动恢复会话（从 `settings.current_user_id`）
  - 修改昵称/签名
  - 修改头像（内置 emoji）
  - 添加/删除标签

3. 登录注册页
- 新增：`lib/pages/profile/login_page.dart`
- Tab 切换登录/注册，表单校验，密码显示切换

4. 资料编辑页
- 新增：`lib/pages/profile/profile_edit_page.dart`
- 支持：昵称、个性签名、头像、标签管理

5. 个人中心页重构
- 修改：`lib/pages/profile/profile_page.dart`
- 逻辑：
  - 未登录：显示游客模式 + 登录/注册按钮
  - 已登录：显示头像/昵称/标签 + 编辑资料 + 退出登录

6. 应用初始化接入用户模块
- 修改：`lib/main.dart`
- 新增：
  - `import 'models/user_profile.dart';`
  - `Hive.registerAdapter(UserProfileAdapter());`
  - `Hive.openBox<UserProfile>('users');`

---

## 3. 已确认的数据存储说明

用户提问“个人数据存储在哪里”后，已明确：

- 完全本地存储（Hive），无云端。
- 用户账号资料：`users` box。
- 当前登录用户标识：`settings` box 的 `current_user_id`。
- 其他模块数据仍是全局 box（当前版本尚未按 userId 隔离）。

说明：
- 目前“登录系统”主要管理个人资料与会话；
- 课程/任务/笔记等业务数据尚未做“多账号数据隔离”。

---

## 4. 本会话中处理过的脚本/数据工作（上下文）

1. 英语词库生成与合并（历史延续）
- CET-6 与考研词汇扩充到 1500。
- 使用开源数据：`KyleBing/english-vocabulary`。
- 相关脚本：
  - `tools/convert_words.ps1`
  - `tools/merge_words.ps1`

2. 脚本问题与处理过的方向
- PowerShell 编码/Unicode 字符串问题
- 中文路径导致目录异常问题
- 执行策略与 profile 干扰
- 通过脚本相对路径和 UTF-8 输出进行规避

---

## 5. 关键文件变更清单（本次会话相关）

### 新增
- `lib/models/user_profile.dart`
- `lib/models/user_profile.g.dart`
- `lib/providers/user_provider.dart`
- `lib/pages/profile/login_page.dart`
- `lib/pages/profile/profile_edit_page.dart`
- `md1.md`（本文件）

### 修改
- `lib/pages/profile/profile_page.dart`
- `lib/main.dart`
- `lib/pages/flashcard/preset_decks_page.dart`
- `assets/data/data_structure.json`
- `assets/data/operating_system.json`
- `assets/data/computer_network.json`

（以及此前延续修复中提及）
- `lib/theme/app_theme.dart`
- `lib/pages/flashcard/flashcard_study_page.dart`

---

## 6. 当前功能状态（给下一次会话快速判断）

### 已完成
- 计算机专业课预设题库数量与文案已一致。
- 个人中心已具备：游客模式 + 本地账号登录体系 + 资料编辑（昵称/头像/标签/签名）。
- 用户会话可本地恢复。

### 建议下一步（优先级）
1. 做“多账号数据隔离”
- 给课程/任务/笔记/习惯/记账/闪卡/番茄记录增加 `userId`。
- Provider 层按当前登录用户过滤与写入。

2. 安全性升级
- 当前是简易本地 hash；可升级为更稳妥的密码方案（如加盐 hash）。

3. UX 细化
- 登录成功提示、首次引导、头像上传（文件选择）
- 个人中心设置项拆分与统一样式

4. 稳定性/质量
- 增加关键页面与 provider 的单元测试/组件测试
- 增加数据迁移策略（Hive schema 变更）

---

## 7. 运行与验证建议

1. 常规启动：
```bash
flutter pub get
flutter run
```

2. 若出现 Hive 类型或旧缓存异常（尤其 Web）：
- 清理浏览器存储（Application/Storage/IndexedDB）后重启。

3. 登录功能手测清单：
- 注册新用户 -> 自动登录
- 退出登录 -> 游客模式
- 重新进入应用 -> 会话恢复
- 修改昵称/头像/标签 -> 重启后仍保留

---

## 8. 给下次会话的启动提示词（可直接复制）

```text
请先阅读项目根目录的 md1.md，按其中“关键文件变更清单”和“建议下一步（优先级）”继续开发。
当前优先做：多账号数据隔离（给课程/任务/笔记/习惯/记账/闪卡/番茄记录加 userId，并在 provider 中按当前登录用户过滤）。
```
