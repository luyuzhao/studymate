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

---

## 9. 后续会话操作续写（2026-05-17 汇总）

### 阶段一：多账号数据隔离与账号体系强化

- **7 个业务模型统一加 `userId`**：`Course`、`Task`、`Note`、`Habit`、`Expense`、`FlashcardDeck`、`PomodoroRecord` 均新增 `@HiveField userId` 字段，默认 `'guest'`
- **适配器更新**：所有 `.g.dart` 适配器已重新生成，读取旧数据时 `userId` 自动回退为 `'guest'`
- **`currentUserIdProvider`**：新增全局 Provider，所有业务 Provider 依赖它实现自动数据隔离
- **7 个 Provider 重写**：构造函数接收 `userId`，加载时按 `userId` 过滤，新增数据自动设置 `userId`
- **数据迁移机制**：新增 `lib/utils/data_migration.dart`，基于 `schema_version` 做版本化迁移（V0→V1：旧数据 `userId` 回填为当前登录用户或 `guest`），在 `main.dart` 中 boxes 打开后自动执行
- **账号安全升级**：
  - 密码改为加盐 SHA-256（`crypto` 包），注册时自动生成随机 `salt`
  - 新增登录失败限制：5 次失败后锁定 5 分钟（`loginAttempts` / `lastAttemptTime`）
  - 输入校验：昵称 1-20 字符禁特殊字符、标签最多 10 个每个最多 10 字符、签名最多 50 字
  - 兼容旧账号：盐值为空时回退到旧哈希比对
- **手机号注册**：注册/登录改为手机号（正则 `^1[3-9]\d{9}$`），非法手机号明确提示，登录页 UI 更新为手机号输入框 + 仅数字键盘 + 11 位长度限制
- **自定义头像上传**：新增 `image_picker` 依赖，支持从相册选择图片，自动压缩（512×512、85% 质量）后复制到应用文档目录；头像选择器底部弹窗同时展示「从相册选择」和内置 emoji 头像；个人中心页和编辑页均支持显示自定义图片头像
- **个人中心手机号脱敏显示**：已登录状态下手机号中间四位隐藏为 `****`

### 阶段二：数据安全与课程成绩增强

- **备份恢复服务**：新增 `lib/utils/backup_service.dart`
  - 导出全量数据为 JSON（含 settings/users/courses/tasks/notes/habits/expenses/flashcard_decks/pomodoro_records）
  - 支持从 JSON 全量恢复
  - 个人中心接入备份入口：导出备份（弹窗展示 JSON，可一键复制到剪贴板）、导入恢复（粘贴 JSON 后恢复并刷新各模块 Provider）
- **课程成绩录入**：
  - 添加课程时可直接填写可选成绩（0~100 校验），`courseProvider` 支持 `addCourse(score: ...)`
  - 课程详情页增加「录入成绩/修改成绩」按钮并加强输入校验提示
  - `gpa_calculator_page.dart` 新增统计：平均分、最高分、最低分
  - 新增「成绩趋势（按录入顺序）」折线图（`fl_chart`）
  - GPA 点数换算统一走 Provider 的 `scoreToGpa`

### 阶段三：任务系统与番茄专注升级

- **任务系统增强**：新增子任务（Checklist）、重复任务（每天/每周）、智能逾期提醒、今日优先级建议
- **番茄专注升级**：新增专注中断记录、专注目标（每日分钟数设定）

### 阶段四：用户账户 SQLite 持久化

- **新增 `lib/utils/user_database.dart`**：SQLite 数据库帮助类
  - `users` 表存储所有用户账户（`id`, `username`, `password_hash`, `nickname`, `tags` 等）
  - `app_settings` 表存储登录会话（`current_user_id`）
  - 数据库文件位于 `Documents/studymate_db/studymate_users.db`
  - 桌面端 (Windows/Linux) 自动启用 FFI 初始化
- **`main.dart` 改动**：启动时初始化 SQLite → Hive 旧用户数据自动迁移到 SQLite（仅首次）→ 调用 `UserNotifier.init()` 预加载登录状态
- **`lib/providers/user_provider.dart` 重写**：全部 CRUD 方法改为 async，通过 `UserDatabase` 读写 SQLite
- **登录/编辑页适配**：`login_page.dart`、`profile_edit_page.dart` 所有操作适配 async 调用
- **备份服务适配**：用户导入导出改走 SQLite
- **核心机制**：启动恢复登录态 → 注册/登录写入 SQLite → 重启后读取 `current_user_id` 自动恢复，无需重新登录

### 阶段五：UI 商业化与大厂风格升级

- **新增依赖**：`flutter_animate`（声明式动画）、`animations`（Material 页面过渡 `FadeThroughTransition`）、`sqlite3: '>=2.0.0 <3.0.0'`（锁定 v2 避免 v3 build hook 下载超时）
- **主题系统重做 `lib/theme/app_theme.dart`**：
  - 配色：Notion/飞书风格靛蓝色系，亮/暗双主题
  - 排版：精调字重层级（`headlineLarge` w700、`bodyLarge` 1.6 行高等）
  - 组件：卡片微边框无阴影、精致输入框、`SegmentedButton`、`NavigationRail` 主题、SnackBar 浮动样式
- **ShellPage 自适应导航**：≥720px 宽使用左侧 `NavigationRail`（桌面端），<720px 宽使用底部 `NavigationBar`（移动端），页面切换 `FadeThroughTransition` 300ms 平滑过渡
- **Dashboard 重做**：渐变 Hero Header（用户问候 + 日期）、数据卡片（图标容器 + 大数字 + 单位分离）、工具箱横向等分布局 + 彩色背景、交错 `fadeIn` + `slideY`/`slideX` 入场动画
- **个人中心重做**：用户卡片横排头像+信息+箭头、标签药丸样式、3 列数据网格（图标+数值+标签）、`_SettingsGroup` 容器 + `_SettingsItem` 统一样式、主题切换 `SegmentedButton` 替代 `PopupMenu`

### 阶段六：关键 Bug 修复

- **闪卡翻转改为点击显示**：移除 `AnimationController`、`Matrix4.rotateY`、自定义 `AnimatedBuilder` 等 3D 翻转逻辑；问题始终显示在上方，点击「显示答案」按钮后答案从下方 fade + slide 展开；评分按钮改为等宽带色块卡片式按钮
- **编辑资料保存后不生效修复**：
  - 根因：`UserNotifier` 里更新方法使用 `state!.xxx = yyy; state = state;`，Riverpod `StateNotifier` 对比对象引用，同一对象不会触发 UI 刷新
  - 修复：给 `UserProfile` 添加 `copyWith()` 方法，7 个更新方法（`updateNickname`、`updateBio`、`updateAvatarIndex`、`updateAvatarPath`、`updateTags`、`addTag`、`removeTag`）全部改为 `final updated = state!.copyWith(...); state = updated;`，创建新对象触发通知

### 阶段七：闪卡 Anki 风格与掌握度统计

- **数据模型 `lib/models/flashcard.dart`**：
  - 新增 `CardStatus` 枚举：`isNew` / `learning` / `review` / `mastered` 四状态
  - 新增字段：`intervalDays`（当前间隔天数）、`learningStep`（学习步骤）
  - 重写 `updateReview`：Anki 风格 SM-2 算法（重来→10分钟后 / 困难→间隔×1.2 EF-0.15 / 良好→间隔×EF / 简单→间隔×EF×1.3 EF+0.15）
  - 新增 `intervalPreview`：每个卡片可预览四个评级对应的下次间隔时间
  - 新增 `masteryRate` 算法：`(复习中×0.6 + 已掌握×1.0) / 总数`
- **状态管理 `lib/providers/flashcard_provider.dart`**：
  - 新增 `StudySession` 会话统计：记录本轮重来/困难/良好/简单数量 + 正确率
  - 新增 `buildStudyQueue`：Anki 风格队列排序（学习中 → 新卡 → 复习卡）
  - 新增 `getDeckStats`：实时返回四状态数量 + 到期数
- **学习页 `flashcard_study_page.dart`**：顶部队列信息条（新/学中/复习数量）、卡片状态标签、Anki 风格评分按钮（重来/困难/良好/简单，每个按钮上方显示下次间隔时间）、完成总结弹窗（本轮耗时、各评级数量、正确率）
- **卡组列表页 `flashcard_list_page.dart`**：四状态迷你标签、四色掌握度条（蓝/橙/紫/绿）、到期数实时显示
- **卡片编辑页 `flashcard_edit_page.dart`**：状态徽标、间隔信息、顶部统计微标

### 阶段八：四大功能模块新增

- **日历课程表 `lib/pages/calendar/calendar_page.dart`**：
  - `table_calendar` 月/双周/周三种视图，支持中文 locale
  - 整合课程和待办：按 `weekday` 匹配课程，按 `dueDate` 匹配待办
  - 事件列表带类型徽标（课程/待办）和颜色标注
  - 「回到今天」快捷按钮
- **学习报告 `lib/pages/report/report_page.dart`**：
  - 本周/本月双 Tab 切换
  - 四大概览卡片：专注时长、完成待办、习惯打卡、闪卡掌握率
  - 每日专注柱状图（`fl_chart` BarChart）
  - 闪卡掌握度饼图（新/学习/复习/掌握四色）
  - 详细数据行：专注次数、完成率、最长连续打卡、待复习数等
- **成就/勋章系统**：
  - 模型层：`lib/models/achievement.dart` + Hive adapter，`typeId=20`
  - Provider：`lib/providers/achievement_provider.dart`，19 个内置成就定义（专注类 / 闪卡类 / 待办类 / 习惯类 / 综合类）
  - 自动检测：进入成就页时 `checkAll()` 扫描所有 Provider 数据
  - 展示页：`lib/pages/profile/achievement_page.dart`，分类展示 + 进度条 + 入场动画
- **OCR 拍照导入 `lib/pages/flashcard/ocr_import_page.dart`**：
  - 拍照/相册两种图片来源
  - `google_mlkit` 中英文混合 OCR 识别
  - 识别结果可选择导入为闪卡或导入为笔记
  - 闪卡导入支持三种分隔方式：每两行、Tab 分隔、短横线分隔
  - 导入前有实时预览
- **Dashboard 工具箱扩展**：4×2 网格，新增日历、报告、成就、OCR 四个入口
- **`main.dart` 注册**：`AchievementAdapter` 并打开 `achievements` Hive box

### 阶段九：日历上课时间联动

- **添加课程时设置上课时间 `lib/pages/course/course_list_page.dart`**：
  - 星期多选器：7 个 `FilterChip`（周一~周日），点击选中/取消，带课程颜色高亮
  - 开始/结束时间选择器：两个 `OutlinedButton` 点击弹出 `showTimePicker`（24小时制），默认 08:00-09:40
  - 添加课程时 `weekdays`、`startTime`、`endTime` 一并保存
- **课程详情页编辑时间 `lib/pages/course/course_detail_page.dart`**：
  - 信息卡新增上课日行，显示「周一、周三、周五」格式
  - 新增「编辑时间」按钮，弹出底部弹窗（星期+时间选择器）
  - 保存后通过 `updateCourse` 更新 Hive，日历页实时生效
- **课程列表卡片优化**：副标题显示「周一/周三 08:00-09:40 · 3学分」格式，带课程颜色
- **日历联动**：`CalendarPage` 已按 `course.weekdays` 匹配日期，设置了上课日的课程自动出现在对应日期的事件列表中

### 阶段十：构建与兼容性修复

- **App 图标设计与生成**：创建 `tools/generate_icon.py`（Pillow 绘制大脑+闪电+studymate 文字）
  - 生成 1024×1024 主图标 `assets/icon/app_icon.png`
  - 生成 Android 全密度 mipmap（mdpi~xxxhdpi）
  - 生成 Android Adaptive Icon 前景层 `ic_launcher_foreground.png`
  - 生成 Windows `.ico` 文件 `windows/runner/resources/app_icon.ico`
- **UTF-8 编码修复**：`tools/convert_words.ps1` 以 `utf-8-sig`（UTF-8 with BOM）重写，将 `[char]0x...` 转义序列改为正常中文字符，确保 PowerShell 正确读取
- **中文路径构建问题**：`E:\测试\studymate` 因含中文导致 `flutter clean` 后 Dart 编译器无法重建，解决方案为在纯英文路径 `E:\studymate_build` 构建，成功后复制 `.dart_tool` 和 APK 回原目录
- **OCR 识别修复**：
  - 根因：Google ML Kit 中文识别模型需联网下载，国内被墙导致初始化失败
  - 修复：识别器改为 `TextRecognitionScript.latin`（内置模型，完全离线），移除中文尝试+回退逻辑，更新提示文案为「支持英文和数字识别」
- **清理空目录**：确认 `E:\studymate_build` 仅剩空 `windows` 目录，可删除

## 10. 关键文件变更清单（续写汇总）

### 新增文件
- `lib/models/user_profile.dart`
- `lib/models/user_profile.g.dart`
- `lib/providers/user_provider.dart`
- `lib/pages/profile/login_page.dart`
- `lib/pages/profile/profile_edit_page.dart`
- `lib/utils/data_migration.dart`
- `lib/utils/backup_service.dart`
- `lib/utils/user_database.dart`
- `lib/models/achievement.dart`
- `lib/models/achievement.g.dart`
- `lib/providers/achievement_provider.dart`
- `lib/pages/profile/achievement_page.dart`
- `lib/pages/calendar/calendar_page.dart`
- `lib/pages/report/report_page.dart`
- `tools/generate_icon.py`
- `md1.md`

### 修改文件
- `lib/main.dart`
- `lib/theme/app_theme.dart`
- `lib/pages/profile/profile_page.dart`
- `lib/pages/flashcard/preset_decks_page.dart`
- `lib/pages/flashcard/flashcard_study_page.dart`
- `lib/pages/flashcard/flashcard_list_page.dart`
- `lib/pages/flashcard/flashcard_edit_page.dart`
- `lib/pages/flashcard/ocr_import_page.dart`
- `lib/providers/flashcard_provider.dart`
- `lib/models/flashcard.dart`
- `lib/models/flashcard.g.dart`
- `lib/providers/course_provider.dart`
- `lib/pages/course/course_list_page.dart`
- `lib/pages/course/course_detail_page.dart`
- `lib/pages/course/gpa_calculator_page.dart`
- `lib/models/course.dart`
- `lib/models/course.g.dart`
- `lib/models/task.dart`
- `lib/models/task.g.dart`
- `lib/models/note.dart`
- `lib/models/note.g.dart`
- `lib/models/habit.dart`
- `lib/models/habit.g.dart`
- `lib/models/expense.dart`
- `lib/models/expense.g.dart`
- `lib/models/pomodoro_record.dart`
- `lib/models/pomodoro_record.g.dart`
- `lib/providers/task_provider.dart`
- `lib/providers/note_provider.dart`
- `lib/providers/habit_provider.dart`
- `lib/providers/expense_provider.dart`
- `lib/providers/pomodoro_provider.dart`
- `pubspec.yaml`
- `tools/convert_words.ps1`
- `windows/runner/resources/app_icon.ico`
- `android/app/src/main/res/` 下各 mipmap/drawable 目录

---

## 11. 当前功能状态（截至 2026-05-17）

### 已完成
- 计算机专业课预设题库数量与文案已一致
- 个人中心：游客模式 + 本地账号登录体系 + 资料编辑（昵称/头像/标签/签名）+ 手机号注册 + 自定义头像上传 + 脱敏显示
- 用户会话可本地恢复（SQLite 持久化，重启自动登录）
- 多账号数据隔离：7 个业务模型均已按 `userId` 隔离读写
- 数据迁移与备份恢复：schema 版本化迁移 + 全量 JSON 导出/导入
- 课程成绩录入与 GPA 统计增强（含趋势图）
- 任务系统增强（子任务、重复任务、逾期提醒）
- 番茄专注升级（中断记录、每日目标）
- UI 商业化升级：自适应导航、主题系统、Dashboard、个人中心重做
- 闪卡 Anki 风格 SM-2 算法 + 掌握度统计
- 日历课程表 + 上课时间联动
- 学习报告 + 成就/勋章系统
- OCR 拍照导入（英文离线识别）
- App 图标设计与生成

### 建议下一步（优先级）
1. **稳定性/质量**：增加关键页面与 Provider 的单元测试/组件测试
2. **UX 细化**：登录成功提示、首次引导、各页面空状态设计
3. **性能优化**：大图压缩策略、Hive box 懒加载、长列表优化
4. **国际化**：当前为纯中文，如需出海可接入 `flutter_localizations`
