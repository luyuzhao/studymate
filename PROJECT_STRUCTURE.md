# StudyMate Pro 项目结构说明

## 根目录文件

| 文件 | 目的和作用 |
|------|-----------|
| `README.md` | 项目介绍文档，包含功能概述、技术栈、安装运行说明、截图等对外展示内容 |
| `pubspec.yaml` | Flutter 项目的核心配置文件，定义：依赖包（dependencies/dev_dependencies）、Flutter 资源配置（assets/fonts）、SDK 版本约束、应用元数据（名称/版本/描述） |
| `md1.md` | **会话记忆文件**，记录开发过程中的所有功能迭代、架构决策、Bug 修复历史，作为后续开发的上下文参考 |
| `PROJECT_STRUCTURE.md` | 本文件，说明每个目录和文件的职责分工 |

---

## `lib/` — 核心业务代码目录

### `lib/main.dart`
- **作用**：应用唯一入口（`main()` 函数）
- **职责**：
  - 初始化 Flutter 绑定（`WidgetsFlutterBinding.ensureInitialized()`）
  - 初始化 `Hive`（注册所有 TypeAdapter、打开所有 box）
  - 初始化 `SQLite`（用户数据库，桌面端自动启用 FFI）
  - 执行数据迁移（`data_migration.dart`：旧数据无 `userId` 时回填）
  - Hive → SQLite 用户数据迁移（仅首次运行）
  - 调用 `UserNotifier.init()` 恢复登录会话
  - 挂载 `ProviderScope`（Riverpod 根节点）和 `MaterialApp`
  - 初始化中文日期格式（`initializeDateFormatting('zh_CN', null)`）

### `lib/app.dart`
- **作用**：`MaterialApp` 配置与主题动态切换
- **职责**：
  - 监听 `themeProvider` 状态，实时切换 亮色/深色/跟随系统 三种模式
  - 配置全局 `MaterialApp` 属性：主题色、字体、页面过渡动画、SnackBar 样式等
  - 定义 `home` 为 `ShellPage`（应用主框架）

---

## `lib/theme/` — 主题系统

### `lib/theme/app_theme.dart`
- **作用**：Material 3 设计系统的完整主题定义
- **职责**：
  - 定义亮/暗双主题 `ThemeData`（Notion/飞书风格靛蓝色系）
  - 精调字重层级：`headlineLarge` w700、`bodyLarge` 1.6 行高
  - 组件样式：卡片微边框无阴影（`CardThemeData`）、精致输入框、`SegmentedButton`、`NavigationRail`/`NavigationBar` 主题
  - SnackBar 浮动样式、`DialogThemeData` 等全局组件默认表现

---

## `lib/models/` — 数据模型层（Hive 持久化）

每个模型文件包含：数据类定义 + `@HiveType`/`@HiveField` 注解 + `part 'xxx.g.dart';`。`.g.dart` 文件由 `build_runner` 自动生成（TypeAdapter）。

| 文件 | 目的 | 关键字段 |
|------|------|---------|
| `course.dart` | 课程信息 | `name`, `teacher`, `location`, `credit`, `score`(0~100), `weekdays`(List<int>), `startTime`, `endTime`, `colorValue`, `userId` |
| `task.dart` | 待办任务 | `title`, `description`, `dueDate`, `priority`, `isCompleted`, `subTasks`(List<SubTask>), `repeatType`(none/daily/weekly), `userId` |
| `flashcard.dart` | 闪卡（Anki SM-2 核心） | `front`, `back`, `status`(CardStatus 枚举: isNew/learning/review/mastered), `intervalDays`, `learningStep`, `easeFactor`, `dueDate` |
| `note.dart` | 笔记 | `title`, `content`(Markdown 纯文本), `createdAt`, `updatedAt`, `userId` |
| `habit.dart` | 习惯打卡 | `name`, `colorValue`, `checkInLog`(List<DateTime>), `userId` |
| `expense.dart` | 记账条目 | `amount`, `category`, `note`, `date`, `userId` |
| `pomodoro_record.dart` | 番茄钟历史 | `startTime`, `endTime`, `duration`(分钟), `isInterrupted`, `goalMinutes`, `userId` |
| `achievement.dart` | 成就勋章 | `name`, `description`, `category`, `unlockedAt`, `progress`, `isUnlocked`, `typeId=20` |
| `user_profile.dart` | 用户账户（SQLite 为主，Hive 兼容） | `id`, `username`(手机号), `password_hash`, `salt`, `nickname`, `avatarIndex`/`avatarPath`, `tags`, `bio`, `loginAttempts`, `lastAttemptTime` |

---

## `lib/providers/` — 状态管理层（Riverpod）

所有 Provider 构造函数接收 `userId`，读写时自动按当前用户过滤。游客用户固定为 `'guest'`。

| 文件 | 目的 | 核心能力 |
|------|------|---------|
| `course_provider.dart` | 课程 CRUD + GPA 计算 | `addCourse(score: ...)`, `updateCourse`, `deleteCourse`, `scoreToGpa()` 换算表, 平均分/最高/最低统计 |
| `task_provider.dart` | 任务管理 + 智能排序 | 增删改查、子任务 Checklist、重复任务(daily/weekly)、逾期提醒、今日优先级建议 |
| `flashcard_provider.dart` | 闪卡核心 + Anki 算法 | `buildStudyQueue`(学习→新→复习排序), `updateReview`(SM-2 四级评分), `getDeckStats`, `StudySession` 会话统计 |
| `pomodoro_provider.dart` | 番茄钟计时 + 统计 | 专注计时控制、中断记录、每日目标(minutes)、历史数据聚合 |
| `habit_provider.dart` | 习惯打卡 | 打卡/取消打卡、连续天数计算、打卡热力图数据源 |
| `note_provider.dart` | 笔记管理 | 增删改查、按时间排序、内容搜索 |
| `expense_provider.dart` | 记账统计 | 增删改查、按类别汇总、月度统计、饼图数据源 |
| `achievement_provider.dart` | 成就检测 | 19 个内置成就定义，`checkAll()` 扫描所有 Provider 数据自动解锁 |
| `user_provider.dart` | 用户登录/注册/资料 | 注册(手机号+加盐SHA-256)、登录(失败5次锁定5分钟)、`copyWith()` 更新资料、SQLite CRUD |
| `theme_provider.dart` | 主题切换 | 亮/暗/跟随系统三种模式状态管理，持久化到 Hive settings |

---

## `lib/pages/` — UI 页面层

### 框架页面

| 文件 | 目的 |
|------|------|
| `shell_page.dart` | 应用主框架：自适应导航。≥720px 宽用左侧 `NavigationRail`，<720px 用底部 `NavigationBar`。页面切换 `FadeThroughTransition` 300ms |
| `home/dashboard_page.dart` | 首页 Dashboard：渐变 Hero Header(用户问候+日期)、数据概览卡片(大数字+单位)、工具箱 4×2 网格(课程/任务/番茄钟/闪卡/笔记/习惯/记账/日历/报告/成就/OCR)、交错入场动画 |

### 课程模块 `course/`

| 文件 | 目的 |
|------|------|
| `course_list_page.dart` | 课程列表：星期多选器(FilterChip)、起止时间选择器(showTimePicker 24h)、成绩输入(0~100)、卡片显示「周一/周三 08:00-09:40 · 3学分」 |
| `course_detail_page.dart` | 课程详情：信息卡(含上课日)、编辑时间按钮(底部弹窗)、成绩修改、删除确认 |
| `gpa_calculator_page.dart` | GPA 统计：平均分/最高/最低、成绩趋势折线图(fl_chart)、GPA 点数换算表可视化 |

### 任务模块 `task/`

| 文件 | 目的 |
|------|------|
| `task_list_page.dart` / `task_board_page.dart` | 任务看板：拖拽/列表视图、子任务 Checklist、重复任务标记、逾期高亮、优先级排序、今日建议 |

### 番茄钟模块 `pomodoro/`

| 文件 | 目的 |
|------|------|
| `pomodoro_page.dart` | 专注计时器：开始/暂停/放弃、圆形进度动画、中断记录、每日目标进度条、历史统计 |

### 闪卡模块 `flashcard/`

| 文件 | 目的 |
|------|------|
| `flashcard_list_page.dart` | 卡组列表：四状态迷你标签(新/学/复/掌)、四色掌握度条(蓝橙紫绿)、到期数Badge、导入/新建入口 |
| `flashcard_study_page.dart` | 学习页：顶部队列信息条(新X/学Y/复Z)、卡片状态标签、答案 fade+slide 展开(非翻转)、Anki 四级评分按钮(重来/困难/良好/简单，上方显示 intervalPreview)、完成总结弹窗 |
| `flashcard_edit_page.dart` | 卡片编辑：状态徽标、间隔信息、批量操作、顶部统计微标(AppBar) |
| `preset_decks_page.dart` | 内置题库：计算机专业课(数据结构51/操作系统49/计网45/计组40)、CET-4 词汇500+ |
| `word_store_page.dart` | 词库商店：自定义导入(TXT/JSON自动识别)、推荐 CDN 词典 URL(点击复制+SnackBar 40秒)、格式说明 |
| `ocr_import_page.dart` | OCR 拍照导入：`google_mlkit` Latin 离线识别(拍照/相册)、三种分隔方式(每两行/Tab/短横线)、导入为闪卡或笔记、实时预览 |

### 笔记模块 `note/`

| 文件 | 目的 |
|------|------|
| `note_list_page.dart` | 笔记列表：卡片式预览、搜索框、按时间排序 |
| `note_edit_page.dart` | 笔记编辑：Markdown 编辑器(或纯文本)、标题+内容、保存/取消 |

### 习惯模块 `habit/`

| 文件 | 目的 |
|------|------|
| `habit_list_page.dart` | 习惯列表：打卡按钮(今日是否打卡)、连续天数显示、打卡热力图 |
| `habit_detail_page.dart` | 习惯详情：历史打卡记录、月度统计、编辑/删除 |

### 记账模块 `expense/`

| 文件 | 目的 |
|------|------|
| `expense_list_page.dart` | 记账列表：按日期分组、类别图标、金额正负显示 |
| `expense_chart_page.dart` | 统计图表：月度支出饼图(fl_chart)、趋势折线图、分类占比 |

### 日历模块 `calendar/`

| 文件 | 目的 |
|------|------|
| `calendar_page.dart` | 日历课表：`table_calendar` 月/双周/周三种视图，中文 locale。按 `course.weekdays` 显示课程，按 `task.dueDate` 显示待办。事件列表带类型徽标和颜色。「回到今天」快捷按钮 |

### 报告模块 `report/`

| 文件 | 目的 |
|------|------|
| `report_page.dart` | 学习报告：本周/本月 Tab 切换。四大概览卡片(专注时长/完成待办/习惯打卡/闪卡掌握率)、每日专注柱状图(fl_chart BarChart)、闪卡掌握度饼图(新/学/复/掌四色)、详细数据行 |

### 个人中心模块 `profile/`

| 文件 | 目的 |
|------|------|
| `profile_page.dart` | 个人中心：未登录时游客模式+登录/注册按钮；已登录时用户卡片(横排头像+昵称+脱敏手机号+箭头)、标签药丸样式、3列数据网格(专注/待办/习惯统计)、`_SettingsGroup` 分组设置项、主题切换 SegmentedButton、备份恢复入口 |
| `login_page.dart` | 登录/注册：Tab 切换、手机号输入框(仅数字键盘/11位限制/`^1[3-9]\d{9}$` 正则)、密码显示切换、错误提示、游客模式入口 |
| `profile_edit_page.dart` | 资料编辑：昵称(1-20字符/禁特殊字符)、个性签名(最多50字)、头像选择器(底部弹窗：内置 emoji + 从相册选择)、标签管理(最多10个/每个最多10字符) |
| `achievement_page.dart` | 成就展示：分类展示(专注/闪卡/待办/习惯/综合)、进度条、未解锁灰色遮罩、入场动画 |

---

## `lib/utils/` — 工具类

| 文件 | 目的 | 核心功能 |
|------|------|---------|
| `user_database.dart` | SQLite 用户数据库封装 | `users` 表(CRUD)、`app_settings` 表(存 `current_user_id`)、桌面端 FFI 自动初始化、数据库文件路径 `Documents/studymate_db/studymate_users.db` |
| `backup_service.dart` | JSON 全量备份/恢复 | 导出：序列化所有 box 数据为 JSON(含 settings/users/courses/tasks/notes/habits/expenses/flashcard_decks/pomodoro_records)。导入：解析 JSON 写回各 box，刷新所有 Provider |
| `data_migration.dart` | Hive 数据迁移引擎 | 版本化管理：读取各 box `schema_version`，V0→V1 将旧数据无 `userId` 字段的回填为当前用户或 `'guest'`，写回 `schema_version=1` |

---

## `android/` — Android 平台配置

| 目录/文件 | 目的 |
|-----------|------|
| `app/src/main/AndroidManifest.xml` | 应用清单：包名、权限(相机/存储/网络)、Activity 声明、Flutter 嵌入模式 |
| `app/src/main/res/mipmap-*/ic_launcher.png` | 各密度应用图标(mdpi~xxxhdpi)，由 `tools/generate_icon.py` 生成 |
| `app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml` | 自适应图标定义：背景色 + 前景 drawable |
| `app/src/main/res/drawable-*/ic_launcher_foreground.png` | 自适应图标前景层（大脑+闪电，无文字），`generate_icon.py` 生成 |
| `app/src/main/res/values/colors.xml` | 资源颜色：`ic_launcher_background` = `#FFFFFF` |
| `app/build.gradle.kts` | Android 构建配置：compileSdk、minSdk、targetSdk、proguard 规则(保留 ML Kit 模型) |
| `app/proguard-rules.pro` | ProGuard 混淆规则：Google ML Kit 相关类不混淆 |

---

## `docs/` — 文档目录

| 文件 | 目的 |
|------|------|
| `SETUP_GUIDE.md` | 环境搭建指南：Flutter SDK 安装、IDE 配置、依赖安装、运行命令 |
| `harmony_plan.md` | 鸿蒙(HarmonyOS)适配方案：未来跨平台扩展的技术规划 |
| `technical_report.md` | 技术报告模板：架构说明、性能指标、测试结果等 |

---

## `assets/` — 静态资源

| 目录 | 内容 |
|------|------|
| `assets/data/` | 内置数据文件：`cet4_words.json`(CET-4 词汇)、`data_structure.json` 等计算机专业课 JSON 词库 |
| `assets/icon/` | 应用图标源文件：`app_icon.png`(1024×1024 主图标，由 `generate_icon.py` 生成) |

---

## `tools/` — 开发工具脚本

| 文件 | 目的 |
|------|------|
| `generate_icon.py` | 图标生成器：Pillow 绘制大脑+闪电+studymate 文字图标，生成 Android 全密度 mipmap、Adaptive Icon 前景、Windows `.ico` |
| `convert_words.ps1` | 词库转换脚本：从开源数据下载并转换为应用内 JSON 格式（UTF-8 BOM 编码） |
| `merge_words.ps1` | 词库合并脚本：合并多个词源为一个 JSON 文件 |
| `fix_encoding.py` | 编码修复工具：处理 PowerShell 脚本的中文编码问题 |

---

## 数据流与架构关系图

```
┌─────────────────────────────────────────────────────────────┐
│                        UI 层 (pages/)                        │
│  Dashboard → 课程/任务/番茄/闪卡/笔记/习惯/记账/日历/报告/个人  │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    状态管理层 (providers/)                   │
│  Riverpod StateNotifier: 按 userId 过滤，copyWith() 触发刷新   │
└─────────────────────────────────────────────────────────────┘
                              │
              ┌───────────────┴───────────────┐
              ▼                               ▼
┌─────────────────────────┐    ┌──────────────────────────────┐
│    业务数据 (Hive)        │    │      用户数据 (SQLite)        │
│  courses/tasks/notes/... │    │  users 表 / app_settings 表   │
│  按 userId 隔离读写      │    │  加盐 SHA-256 / 登录会话恢复   │
└─────────────────────────┘    └──────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                      工具层 (utils/)                         │
│  data_migration (schema版本迁移) → backup_service (JSON备份) │
└─────────────────────────────────────────────────────────────┘
```

---

## 关键设计决策速查

| 决策 | 说明 |
|------|------|
| 为什么 Hive + SQLite 双存储？ | Hive 适合高频读写的业务数据（课程/任务等结构化小对象），SQLite 适合关系型用户账户数据（登录/注册/查询） |
| 为什么 userId 默认 `'guest'`？ | 确保未登录游客也能正常使用所有功能，登录后数据自动归属到真实用户 |
| 为什么闪卡不用翻转动画？ | 3D rotateY 在部分设备上有渲染问题，改为 fade+slide 展开答案更稳定 |
| 为什么 OCR 只用 Latin 模型？ | Google ML Kit 中文模型需联网下载，国内网络不稳定；Latin 模型内置离线可用 |
| 为什么 SQLite 锁定 `sqlite3: '>=2.0.0 <3.0.0'`？ | sqlite3 v3.x 使用 Dart native assets build hooks，会从 GitHub releases 下载 dll，国内超时失败；v2.x 无此问题 |
| 为什么 `copyWith()` 是必须的？ | Riverpod `StateNotifier` 对比对象引用，`state = state` 不会触发 UI 刷新；必须创建新对象 |
