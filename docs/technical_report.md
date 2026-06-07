# StudyMate Pro 技术报告

> **项目名称**：StudyMate Pro — 全能学习效率伴侣
> **学生姓名**：[填写姓名]
> **学号**：[填写学号]
> **指导教师**：[填写教师]
> **完成日期**：2026 年 6 月

---

## 一、项目概述

### 1.1 选题背景

大学生在学习过程中需要同时管理课程、任务、复习、习惯等多方面事务，现有工具（如日历、备忘录）功能分散，缺乏学习场景的深度整合。StudyMate Pro 旨在打造一款一站式学习效率工具，将课程管理、智能任务、番茄专注、Anki 闪卡记忆、笔记、习惯打卡、记账、日历课表、学习报告、成就系统、OCR 识别等功能有机整合，帮助学生提升学习效率。

### 1.2 项目目标

- 基于 Flutter 3.x 开发一个可运行的跨平台移动应用，最低支持 Android API 21
- 遵循 Material Design 3 设计规范，支持亮色/深色/跟随系统三种主题模式
- 实现本地数据持久化（Hive + SQLite）和网络数据交互（HTTP + JSON 在线词库下载）
- 全程使用 AI 辅助编程工具开发，代码注释中标注 AI 生成与人工修改部分
- 使用 Git 进行版本控制，代码结构清晰，文档完整

### 1.3 技术指标

| 指标 | 数值 |
|------|------|
| 源码文件数 | 50+ Dart 文件 |
| 数据模型 | 9 个 Hive 数据模型 + 自动生成 TypeAdapter |
| 状态管理 | 10 个 Riverpod Provider |
| UI 页面 | 15+ 功能页面，14 个功能模块 |
| 代码行数 | 约 6,000+ 行 Dart |
| Hive Box | 8 个业务数据 Box |
| SQLite 表 | 2 张表（users + app_settings） |
| 支持平台 | Android 5.0+ / Windows / macOS / Linux |

---

## 二、技术方案

### 2.1 开发语言：Dart

Dart 是 Google 开发的面向对象编程语言，专为构建高性能客户端应用而设计。语法类似 Java/JavaScript 混合体，支持 JIT（热重载开发）和 AOT（预编译发布）两种编译模式。

| Dart 特性 | 本项目中的应用 |
|-----------|--------------|
| 强类型 + 类型推断 | 模型层用 `@HiveType` / `@HiveField` 注解自动生成序列化适配器 |
| async/await 异步模型 | 所有数据库读写（Hive/SQLite）均为异步操作，不阻塞 UI 线程 |
| 空安全 (Null Safety) | 所有可空字段显式声明 `?`，编译期杜绝空指针异常 |
| 声明式 UI | Flutter Widget 树即 Dart 嵌套表达式，代码即 UI 结构 |
| AOT 编译 | 发布时编译为 ARM 原生机器码，性能接近原生应用 |

### 2.2 跨平台框架：Flutter 3.x

Flutter 使用 Skia 渲染引擎自绘所有像素，不依赖系统原生控件，多平台视觉效果完全一致。Dart 代码通过 Platform Channel 调用原生相机、存储等系统能力。

### 2.3 技术选型

| 技术层 | 选型 | 版本 | 选型理由 |
|--------|------|------|---------|
| 框架 | Flutter | 3.x | 一套代码 Android/Windows/macOS 全平台运行 |
| 语言 | Dart | 3.5+ | 强类型、空安全、JIT 热重载 + AOT 高性能 |
| 状态管理 | Riverpod | 2.5.1 | 编译时安全、无需 BuildContext、Provider 间可组合依赖、支持 autoDispose |
| 业务存储 | Hive | 2.2.3 | 纯 Dart 实现、内存映射 NoSQL、零原生依赖、亚毫秒级读写 |
| 用户存储 | SQLite (sqflite) | 2.3.3 | 关系型数据、唯一约束、事务支持、适合账户认证与登录锁定 |
| 图表 | fl_chart | 0.68.0 | 纯 Dart 实现、无原生依赖、支持柱状图/饼图/折线图 |
| 日历 | table_calendar | 3.1.2 | 月/双周/周三种视图自由切换、支持中文 locale |
| OCR | Google ML Kit | 0.13.1 | Latin 模型内置离线可用、无需联网、拍照即识别 |
| 动画 | flutter_animate | 4.5.0 | 声明式语法、fadeIn/slideX/slideY 交错入场 |
| 页面过渡 | animations | 2.0.11 | Material 标准 FadeThroughTransition |
| 密码安全 | crypto | 3.0.3 | SHA-256 加盐哈希、随机 salt 生成 |
| 日期处理 | intl | 0.19.0 | 日期格式化 + 中文 locale 初始化 |
| 字体 | Google Fonts | 6.2.1 | Noto Sans SC 中文字体 |
| 头像 | image_picker | 1.0.7 | 相册选择 + 自动压缩 512×512 |
| 网络 | http / dart:io HttpClient | 1.2.1 | 在线词库下载、自动识别 JSON/TXT 格式 |
| 进度指示 | percent_indicator | 4.2.3 | 番茄钟圆环进度动画 |
| UUID | uuid | 4.4.2 | 全局唯一标识符生成 |
| 路径 | path_provider / path | 2.1.4 | 获取系统文档目录 |

### 2.4 系统架构

```
┌─────────────────────────────────────────────────────────────┐
│                      UI 层 (pages/)                          │
│  Dashboard / 课程 / 任务 / 番茄钟 / 闪卡 / 笔记 / 习惯 /       │
│  记账 / 日历 / 报告 / 成就 / OCR / 个人中心                    │
│  Material 3 + 自适应导航 (Rail/Bar) + flutter_animate 动画     │
└──────────────────────────┬──────────────────────────────────┘
                           │ ref.watch / ref.read
┌──────────────────────────▼──────────────────────────────────┐
│                状态管理层 (providers/)                        │
│  10 个 Riverpod Provider                                    │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ currentUserIdProvider (全局依赖源)                     │   │
│  │   → courseProvider   → taskProvider                   │   │
│  │   → noteProvider     → habitProvider                  │   │
│  │   → expenseProvider  → flashcardProvider              │   │
│  │   → pomodoroRecordProvider                            │   │
│  │   → userProvider     → themeProvider                  │   │
│  │   → achievementProvider                               │   │
│  │ copyWith() 不可变更新 → UI 自动刷新                     │   │
│  └─────────────────────────────────────────────────────┘   │
└──────────┬───────────────────────────────┬──────────────────┘
           │                               │
┌──────────▼──────────┐    ┌──────────────▼──────────────┐
│   Hive (业务数据)     │    │     SQLite (用户账户)        │
│   NoSQL 内存映射      │    │     关系型数据库              │
│                      │    │                             │
│  courses     课程     │    │  users 表:                  │
│  tasks       任务     │    │    id / username(手机号)     │
│  notes       笔记     │    │    password_hash / salt     │
│  habits      习惯     │    │    nickname / avatar        │
│  expenses    记账     │    │    tags / bio               │
│  flashcard_  闪卡     │    │    login_attempts           │
│    decks              │    │    last_attempt_time        │
│  pomodoro_   番茄     │    │                             │
│    records            │    │  app_settings 表:           │
│  settings    配置     │    │    current_user_id          │
│  achievements成就     │    │    hive_users_migrated      │
│                      │    │  ◄── SHA-256 加盐哈希       │
│  ◄── 按 userId 隔离   │    │  ◄── 登录失败锁定           │
└──────────────────────┘    └─────────────────────────────┘
           │                               │
           └───────────┬───────────────────┘
                       ▼
┌─────────────────────────────────────────────────────────────┐
│                    工具层 (utils/)                            │
│  data_migration  — Schema 版本化迁移 (V0→V1)                 │
│  backup_service  — JSON 全量备份/恢复                         │
│  user_database   — SQLite 数据库封装 (CRUD + 表管理)          │
└─────────────────────────────────────────────────────────────┘
```

### 2.5 多账号数据隔离机制

所有 7 个业务模型（Course / Task / Note / Habit / Expense / FlashcardDeck / PomodoroRecord）均包含 `@HiveField userId` 字段。

```
currentUserIdProvider (从 SQLite 读取)
    │
    ├── taskProvider      ← userId → state.where((t) => t.userId == userId)
    ├── courseProvider    ← userId → state.where((c) => c.userId == userId)
    ├── noteProvider      ← userId → ...
    ├── habitProvider     ← userId → ...
    ├── expenseProvider   ← userId → ...
    ├── flashcardProvider ← userId → ...
    └── pomodoroRecordProvider ← userId → ...
```

- 未登录时 `userId = 'guest'`，游客可正常使用全部功能
- 登录后自动切换对应数据，无需手动刷新
- 新建数据自动写入当前 `userId`

### 2.6 核心算法：SM-2 间隔重复

闪卡模块实现了 Anki 核心的 SM-2（SuperMemo-2）科学记忆算法。

**数据结构**：

| 字段 | 类型 | 说明 |
|------|------|------|
| `status` | CardStatus 枚举 | isNew / learning / review / mastered 四状态流转 |
| `easeFactor` | double | 难易因子（默认 2.5，最低 1.3，最高 10.0）|
| `intervalDays` | int | 当前复习间隔天数 |
| `learningStep` | int | 学习步骤计数器 |
| `nextReviewDate` | DateTime | 下次复习日期 |

**四级评分规则**：

```
评分: Again(0) / Hard(2) / Good(3) / Easy(5)

if rating == 0 (重来):
    status → learning
    intervalDays = 0
    learningStep = 0
    nextReviewDate = now + 10 分钟
    easeFactor -= 0.2

if rating == 2 (困难):
    learningStep++
    intervalDays = max(1, intervalDays × 1.2)
    easeFactor -= 0.15

if rating == 3 (良好):
    intervalDays = intervalDays × easeFactor
    easeFactor 不变 (仅首次从 New→Review 时变化)

if rating == 5 (简单):
    intervalDays = intervalDays × easeFactor × 1.3
    easeFactor += 0.15

easeFactor = max(1.3, min(10.0, easeFactor))
```

**学习队列排序**（`buildStudyQueue`）：

1. 学习中（Learning）卡片，按到期时间升序
2. 新卡（New），每次取 20 张
3. 到期复习卡（Review / Mastered 且已到期）

**掌握度统计**（`getDeckStats`）：

实时返回各状态数量分布，UI 展示为四色进度条（蓝/橙/紫/绿），掌握率 = (复习中×0.6 + 已掌握×1.0) / 总数。

### 2.7 数据迁移与备份

**Schema 版本化迁移**（`data_migration.dart`）：

```
启动 → 读取 schema_version
  ├── version = 0 → 扫描旧数据 → 补填 userId 字段 → 写回 → 更新 version = 1
  └── version = 1 → 跳过迁移
```

**JSON 全量备份/恢复**（`backup_service.dart`）：

- 导出：序列化所有 Hive Box + SQLite 用户表 → 单一 JSON 字符串 → 一键复制到剪贴板
- 导入：解析 JSON → 清空各 Box → 逐表回写 → 刷新所有 Provider
- 覆盖数据范围：settings / users / courses / tasks / notes / habits / expenses / flashcard_decks / pomodoro_records

### 2.8 密码安全方案

| 环节 | 实现 |
|------|------|
| 注册 | 自动生成 32 字节随机 `salt`，SHA-256 加盐哈希后存储 |
| 登录 | 取出 salt + 存库 hash，对输入密码相同方式计算后比对 |
| 锁定 | 连续 5 次登录失败 → 锁定 5 分钟（`loginAttempts` / `lastAttemptTime`）|
| 兼容 | 旧用户 `salt` 为空时回退到旧哈希比对方式 |
| 会话 | `current_user_id` 存入 SQLite `app_settings`，重启自动恢复 |

---

## 三、功能模块实现详情

### 3.1 Dashboard 首页

**技术实现**：
- `ConsumerWidget` 通过 `ref.watch()` 监听 4 个核心 Provider（task / habit / course / user），数据变更自动重绘
- `ref.read()` 调用 `getTodayTasks()`、`getOverdueTasks()`、`todayMinutes` 等计算值
- 渐变 Hero Header 根据时间段自动切换问候语（5 种时段）
- 数据卡片：专注时长（红色，源自 pomodoroRecordProvider）+ 任务进度（橙色，源自 taskProvider）
- 工具箱 `GridView.count(crossAxisCount: 4)` 等分布局，8 个入口通过 `Navigator.push` 跳转
- 今日待办：Filter 过滤今日到期 + 逾期任务，`Checkbox` 直接调用 `updateStatus()`
- 习惯打卡：`ActionChip` 一键打卡，已打卡禁用重复点击
- 横向课程卡片：`ListView.separated(scrollDirection: Axis.horizontal)`
- 空状态：火箭图标 + 引导文案 + 入场动画
- 动画：`flutter_animate` 声明式 fadeIn + slideX/slideY，各区域独立延迟

### 3.2 课程管理

**技术实现**：
- `CourseListPage`：ListView 课程列表 + GPA 渐变概览卡片
- 添加课程 BottomSheet：名称、教师、地点、学分、成绩（0~100 校验）、颜色选择
- `FilterChip` 星期多选器（周一~周日），带课程颜色高亮
- `showTimePicker` 24 小时制选择起止时间
- `CourseDetailPage`：渐变信息卡 + 关联任务/笔记列表 + 编辑上课时间弹窗 + 成绩录入弹窗 + 删除确认
- `GPACalculatorPage`：平均分/最高分/最低分统计 + `fl_chart` LineChart 成绩趋势折线图
- 数据处理：百分制 → GPA 点数换算表（≥90→4.0, ≥80→3.0, ≥70→2.0, ≥60→1.0）

### 3.3 任务看板

**技术实现**：
- `TabBarView` 四栏：建议 / 待做 / 进行中 / 已完成
- 智能排序算法（`getSuggestedTasks`）：逾期 > 今日到期 > 高优先级 > 有子任务进度
- 子任务 Checklist：`List<SubTask>` Hive 嵌入字段，`LinearProgressIndicator` 进度条
- 重复任务：每天/每周自动重复，`_generateNextRecurrence` 自动创建下一期
- 状态流转：`PopupMenuButton` 快速切换 todo ↔ inProgress ↔ done
- `Dismissible` 左滑删除 + 确认弹窗
- 任务详情 BottomSheet：编辑/删除工具按钮 + 子任务管理 + 底部红色删除按钮

### 3.4 番茄专注

**技术实现**：
- `Timer.periodic(Duration(seconds: 1))` 驱动秒级倒计时
- `CircularPercentIndicator` 圆环进度（radius: 120, lineWidth: 14），setState 驱动刷新
- `ChoiceChip` 时长选择：15/25/30/45/60 分钟
- 中断记录：`_recordInterrupt()` 累加计数 + SnackBar 提示
- 休息切换：专注完成 → 自动 5 分钟休息
- 每日目标：自定义分钟数 + `LinearProgressIndicator` 进度条 + 达成显示庆祝图标
- 专注模式：全屏纯黑极简 UI，双击退出
- 统计卡片：今日专注 / 今日番茄数 / 今日中断 / 本周总计
- `fl_chart` BarChart 本周分布柱状图（周一~周日，x 轴中文标签）

### 3.5 闪卡记忆

**技术实现**：

卡组列表：
- 四状态迷你标签（新/学习中/复习/掌握）
- 四色掌握度进度条（蓝/橙/紫/绿）
- 到期数 Badge 实时显示

学习页面：
- 顶部队列信息条（新 X / 学中 Y / 待复习 Z）
- 卡片状态标签（新 / 学习中 / 复习 / 掌握）
- 答案 `AnimatedSwitcher` fade + slide 展开（非 3D 翻转，避免部分设备旋转渲染问题）
- Anki 四级评分按钮（重来/困难/良好/简单），每个按钮上方显示 `intervalPreview` 下次间隔
- 完成总结弹窗：本轮耗时 + 各评级数量 + 正确率

词库商店：
- 7 套内置词库（CET-4/CET-6/考研/数据结构/计组/操作系统/计网），防重复导入检测
- 自定义导入：URL 下载（HttpClient 30 秒超时）或粘贴文本
- 自动识别格式：JSON（首字符 `{`）或 TXT（4 种分隔：词典正则 → Tab → 空格+中文 → 每行一词）
- 6 个推荐词库源（jsDelivr CDN 国内可访问）

OCR 拍照导入：
- `google_mlkit_text_recognition` Latin 模型离线识别
- 拍照/从相册选择（`image_picker`）
- 三种分隔方式：每两行 / Tab 分隔 / 短横线分隔
- 导入为闪卡或笔记，导入前实时预览

### 3.6 笔记系统

**技术实现**：
- `NoteListPage`：卡片式预览 + AppBar 内嵌搜索栏全文检索
- `NoteEditPage`：标题 + 内容编辑器 + 课程关联 + Markdown 快捷工具栏
- PopupMenu 置顶切换 + 删除
- 按更新时间倒序排列

### 3.7 习惯打卡

**技术实现**：
- `HabitPage`：卡片列表 + 打卡按钮（去重判断 `isCheckedToday`）
- 35 天热力图：`GridView` 7×5 布局，`DateTime` 计算 35 天日期，打卡日着色
- 连续天数算法：从今天往前遍历 `checkInLog`，连续有记录则累加
- `LinearProgressIndicator` 目标进度条
- 新建习惯：名称 + 8 色选择 + 7 种目标天数（7/14/21/30/60/100）
- PopupMenu 删除

### 3.8 智能记账

**技术实现**：
- `ExpensePage`：月份切换（左右箭头）→ 筛选当月记录
- 收支概览：红色支出 + 绿色收入双卡片
- `fl_chart` PieChart 分类饼图 + 右侧颜色图例
- 7 个支出分类（餐饮/交通/购物/娱乐/学习/生活/其他）+ 收入
- `SegmentedButton` 支出/收入切换
- `Dismissible` 左滑删除明细
- 金额格式化 `¥XX.XX`

### 3.9 日历课表

**技术实现**：
- `CalendarPage`：`table_calendar` 月/双周/周三视图，`initializeDateFormatting('zh_CN')` 中文 locale
- 课程按 `course.weekdays` 匹配到对应星期日期
- 待办按 `task.dueDate` 聚合到对应日期
- 事件列表带类型徽标（课程/待办）和颜色标注
- 「回到今天」快捷按钮

### 3.10 学习报告

**技术实现**：
- `ReportPage`：本周/本月双 Tab 切换
- 四大概览卡片（专注时长 / 完成待办 / 习惯打卡 / 闪卡掌握率）
- `fl_chart` BarChart 每日专注柱状图
- `fl_chart` PieChart 闪卡掌握度饼图（新/学习/复习/掌握四色）
- 数据来源：聚合 pomodoro / task / habit / flashcard 四个 Provider 的实时数据

### 3.11 成就勋章系统

**技术实现**：
- `AchievementProvider`：19 个内置成就定义（专注类 5 个 / 闪卡类 4 个 / 待办类 4 个 / 习惯类 3 个 / 综合类 3 个）
- `checkAll()` 自动扫描所有 Provider 数据，比对阈值自动解锁
- 进入成就页触发检测，Hive 持久化解锁状态
- UI：分类展示 + 进度条 + 未解锁灰色遮罩 + 入场动画

### 3.12 个人中心

**技术实现**：
- `ProfilePage`：用户卡片（横排头像 + 昵称 + 脱敏手机号）+ 标签药丸样式
- 3 列数据网格（专注/待办/习惯统计）
- `SegmentedButton` 深色模式切换（亮/暗/跟随系统），持久化至 Hive settings
- 备份恢复入口：`BackupService.exportBackupJson()` 导出全量 JSON / 从剪贴板导入恢复
- `LoginPage`：Tab 切换登录/注册，手机号正则 `^1[3-9]\d{9}$` 校验，仅数字键盘 11 位限制
- `ProfileEditPage`：昵称（1-20 字符禁特殊字符）+ 签名（最多 50 字）+ 头像选择器（内置 emoji + 相册选择自动压缩 512×512）+ 标签管理（最多 10 个每个最多 10 字符）
- 会话恢复：SQLite 读取 `current_user_id`，重启自动登录

### 3.13 自适应响应式导航

**技术实现**（`ShellPage`）：
- `MediaQuery.sizeOf(context).width >= 720` → 左侧 `NavigationRail`（桌面端）
- `< 720` → 底部 `NavigationBar`（移动端）
- 页面切换：`PageTransitionSwitcher` + `FadeThroughTransition` 300ms 平滑过渡
- 5 个主导航项：首页 / 课程 / 待办 / 专注 / 我的

---

## 四、开发过程

### 4.1 开发环境

| 项目 | 配置 |
|------|------|
| 操作系统 | Windows 11 |
| IDE | VS Code |
| AI 工具 | Windsurf Cascade / Trae / Cursor |
| Flutter SDK | 3.x |
| Dart SDK | 3.5+ |
| 版本控制 | Git + GitHub |
| 测试设备 | Android 手机/模拟器 + Windows 桌面 |

### 4.2 开发时间线

| 阶段 | 周次 | 工作内容 | 产出 |
|------|------|---------|------|
| 需求分析 | 第 1-2 周 | 确定功能模块、技术选型、项目初始化 | README / pubspec.yaml |
| 基础搭建 | 第 3-4 周 | 项目结构、主题系统、底部导航、9 个数据模型 | 模型层 + 主题 + shell_page |
| 核心开发 | 第 5-10 周 | 8 大基础模块实现（课程/任务/番茄/闪卡/笔记/习惯/记账/个人中心）| 15+ 页面 + 10 个 Provider |
| 功能增强 | 第 11-13 周 | SM-2 升级、日历、报告、成就、OCR、数据安全、UI 商业化重做 | 所有增强功能 |
| 测试完善 | 第 14-15 周 | Bug 修复、多账号隔离、数据迁移、备份恢复、文档撰写 | 工具类 + 迁移/备份 |
| 提交答辩 | 第 16 周 | APK 构建、演示视频录制、答辩 PPT 准备、项目同步 GitHub | APK + 视频 + 报告 |

### 4.3 AI 协作方式

本项目开发全程使用 AI 辅助编程工具，协作分工如下：

| 角色 | 职责 |
|------|------|
| AI | 代码框架搭建、UI 布局实现、算法编写（SM-2/排序/打卡/迁移）、代码规范性修复、Bug 排查 |
| 人工 | 需求定义与功能规划、交互设计与用户体验、多模块联调测试、代码审查与最终确认、文档撰写与答辩准备 |

所有源码文件头部均有标注：
- `// AI生成` — 该文件/代码段由 AI 辅助生成
- `// 人工修改` — 该部分经过人工审核与修改

Git 仓库累计提交 5+ 次，功能递增式迭代开发。

---

## 五、测试与问题解决

### 5.1 测试方法

| 测试类型 | 方法 | 覆盖范围 |
|----------|------|---------|
| 功能测试 | 逐模块手动验证所有 CRUD 操作流程 | 14 个模块全覆盖 |
| 兼容性测试 | Android 手机 + 平板 + Windows 桌面 + macOS 桌面 | 多尺寸屏幕 |
| 边界测试 | 空数据状态、大量数据滚动、极端输入值（成绩 0/100、金额 0） | 边界条件 |
| 用户测试 | 邀请同学安装 APK 进行实际使用反馈 | 真实场景 |

### 5.2 开发中遇到的关键问题与解决方案

| 问题 | 原因 | 解决方案 |
|------|------|---------|
| **闪卡翻转动画渲染异常** | 3D `rotateY` 在部分 Android 设备上有兼容性问题 | 改用 `AnimatedSwitcher` fade + slide 展开答案，稳定性显著提升 |
| **sqlite3 v3.x 构建超时** | v3 使用 Dart native assets build hooks，从 GitHub releases 下载 dll，国内超时 | 锁定 `sqlite3: '>=2.0.0 <3.0.0'`，v2 版本无此问题 |
| **编辑资料保存后不生效** | `StateNotifier` 对比对象引用，`state = state` 不触发 UI 刷新 | 为 `UserProfile` 添加 `copyWith()` 方法，更新时创建新对象 |
| **OCR 中文识别初始化失败** | Google ML Kit 中文模型需联网下载，国内被墙 | 改用 `TextRecognitionScript.latin` 离线模型，完全无需联网 |
| **中文路径导致 Dart 编译器失败** | `flutter clean` 后 `.dart_tool` 含中文绝对路径，编译器解析异常 | 在纯英文路径 `E:\studymate_build` 构建，产物复制回原目录 |
| **GitHub 推送超大文件警告** | `app-release.apk`（~90MB）超过 50MB 推荐上限 | `git rm --cached` + `.gitignore` 添加 `*.apk` 规则 |
| **PowerShell 脚本编码异常** | 中文路径 + Unicode 字符导致脚本执行报错 | 以 UTF-8 BOM 编码重写脚本，`[char]` 转义序列改为正常中文字符 |
| **多账号数据不隔离** | 旧版模型无 `userId` 字段 | 7 个业务模型统一添加 `userId` 字段（默认 `guest`），实现 data_migration 回填旧数据 |

---

## 六、鸿蒙适配方案

详见 `docs/harmony_plan.md`，核心策略：

**方案 A（推荐）：Flutter for HarmonyOS**
- 华为已推出 Flutter 鸿蒙适配层，核心纯 Dart 代码天然兼容
- 需替换的插件仅 3 个：sqflite → `@ohos.data.relationalStore`、google_mlkit → 华为 ML Kit、image_picker → `@ohos.multimedia.camera`
- 适配工作量预估：5-8 天

**方案 B（演示）：ArkTS 核心页面**
- harmony_plan.md 已提供 ArkTS Dashboard 首页完整示例代码（约 160 行）
- 覆盖 ArkUI 布局、数据绑定、路由跳转、组件化开发

**鸿蒙特有能力利用**：
- 本地通知 `@ohos.notificationManager` → 课程/任务提醒
- 桌面服务卡片 `FormAbility` → 今日待办/专注时长小组件
- 华为 ML Kit → OCR 与闪卡智能导入

---

## 七、总结与展望

### 7.1 项目总结

StudyMate Pro 基于 Flutter 3.x 开发，采用 **Hive + SQLite 双存储架构** 和 **Riverpod 响应式状态管理**，实现了 **14 个功能模块、15+ UI 页面**，覆盖学生从课程管理到科学复习的全流程需求。全程使用 AI 辅助编程工具，约 16 周完成从需求到交付的全流程。

### 7.2 核心技术亮点

1. **SM-2 间隔重复算法**：实现 Anki 科学记忆曲线，四级评分动态调整 easeFactor 和复习间隔
2. **Hive + SQLite 双存储**：业务数据 NoSQL 高频读写 + 用户账户 SQL 约束与事务，各取所长
3. **Riverpod 响应式状态管理**：10 个 Provider 实现 14 个模块间数据实时联动，多账号自动隔离
4. **Schema 版本化数据迁移**：检测版本号自动补填旧数据字段，用户升级零感知
5. **沙盒级隐私安全**：完全本地存储 + SHA-256 加盐哈希 + JSON 全量备份恢复
6. **Material 3 自适应 UI**：亮暗双主题 + 响应式导航（移动端 Bar / 桌面端 Rail）

### 7.3 收获

- 掌握了 Flutter 跨平台开发全流程，从模型设计到 APK 构建
- 深入理解了 Riverpod 状态管理的组合依赖与不可变更新模式
- 实践了 Hive NoSQL + SQLite 双存储架构的设计与协同
- 体验了 AI 辅助编程的工作模式，理解了人机协作的效率边界
- 实践了 Material Design 3 设计规范与自适应布局

### 7.4 未来展望

- 接入 AI 大模型，实现智能答疑和自动生成闪卡
- 增加学习小组与社交激励功能
- 完善单元测试与集成测试，提升代码质量
- 适配 HarmonyOS NEXT，发布到华为应用市场
- 接入在线同步服务，实现多设备数据同步

---

## 附录

### A. 项目仓库地址

https://github.com/luyuzhao/studymate

### B. APK 文件说明

项目根目录包含编译好的 `app-release.apk`，支持 Android 5.0+（API 21）直接安装运行。

### C. 演示视频

[填写视频链接]

### D. 参考资料

1. Flutter 官方文档 — https://docs.flutter.dev
2. Riverpod 文档 — https://riverpod.dev
3. Hive 文档 — https://docs.hivedb.dev
4. Material Design 3 — https://m3.material.io
5. SuperMemo SM-2 算法 — https://www.supermemo.com
6. table_calendar — https://pub.dev/packages/table_calendar
7. fl_chart — https://pub.dev/packages/fl_chart
8. Google ML Kit — https://developers.google.com/ml-kit
