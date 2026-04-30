# StudyMate Pro — 全能学习效率伴侣

> 基于 Flutter 3.x 开发的跨平台学习效率应用，集课程管理、智能任务、番茄专注、闪卡记忆（SM-2）、笔记、习惯打卡、记账、日历课表、学习报告、成就系统、OCR 拍照导入等 14 大模块于一体。

## 📱 项目概述

StudyMate Pro 是一款面向学生群体的一站式学习效率工具。使用 Flutter 3.x 跨平台框架开发，支持 Android（最低 API 21）手机和平板设备运行，遵循 Material Design 3 设计规范，支持亮色 / 深色 / 跟随系统三种主题模式。

## ✨ 核心功能（14 大模块）

| 模块 | 功能描述 |
|------|----------|
| 📊 **Dashboard 首页** | 数据概览卡片、8 宫格工具箱、今日待办/习惯/课程摘要、入场动画 |
| 📚 **课程管理** | 课程 CRUD、上课时间（星期+时间段）、教师/地点/学分、GPA 计算器、成绩录入 |
| ✅ **任务看板** | 三栏看板（待做/进行中/已完成）、智能优先级排序、子任务、重复任务、课程关联 |
| 🍅 **番茄专注** | 自定义时长（15/25/30/45/60 min）、休息切换、专注记录、本周分布柱状图 |
| 🧠 **闪卡记忆** | Anki 风格 SM-2 间隔重复、四级评分（Again/Hard/Good/Easy）、卡组掌握度统计 |
| 📝 **Markdown 笔记** | 富文本编辑、快捷工具栏、课程关联、全文搜索、置顶 |
| 💪 **习惯打卡** | 每日打卡、连续天数追踪、35 天热力图、目标进度 |
| 💰 **智能记账** | 收支记录、分类饼图统计、月度趋势、滑动删除 |
| 📅 **日历课表** | 月/双周/周三种视图、课程按星期自动显示、待办按日期聚合 |
| 📈 **学习报告** | 本周/本月数据汇总、专注柱状图、闪卡掌握度饼图、详细数据表 |
| 🏆 **成就勋章** | 19 项成就（专注/闪卡/待办/习惯/综合）、自动里程碑检测、进度追踪 |
| 📸 **OCR 拍照导入** | 拍照/相册 → 中英文 OCR 识别 → 一键转闪卡或笔记 |
| 👤 **个人中心** | 注册登录、数据备份/恢复（JSON 导出导入）、深色模式切换 |
| 🔐 **数据安全** | 用户密码 SHA-256 加盐哈希、SQLite 持久化用户账户、Hive→SQLite 自动迁移 |

## 🛠 技术栈

| 类别 | 技术 |
|------|------|
| **框架** | Flutter 3.x + Dart 3.5+ |
| **状态管理** | Riverpod (flutter_riverpod) |
| **本地存储** | Hive (业务数据 NoSQL) + SQLite (用户账户) |
| **图表可视化** | fl_chart (柱状图/饼图/折线图) |
| **日历** | table_calendar |
| **OCR** | google_mlkit_text_recognition (中英文) |
| **动画** | flutter_animate |
| **UI** | Material Design 3、Google Fonts (Noto Sans SC) |
| **工具** | uuid、intl、image_picker、crypto、path_provider |

## 📂 项目结构

```
studymate/
├── lib/
│   ├── main.dart                     # 应用入口，Hive/SQLite 初始化
│   ├── app.dart                      # MaterialApp 配置，亮色/深色主题
│   ├── theme/
│   │   └── app_theme.dart            # Material 3 主题定义
│   ├── models/                       # 数据模型 (Hive TypeAdapter)
│   │   ├── course.dart               # 课程 (含上课星期/时间)
│   │   ├── task.dart                 # 任务 (含子任务/重复规则)
│   │   ├── flashcard.dart            # 闪卡 (SM-2 算法字段)
│   │   ├── note.dart                 # 笔记
│   │   ├── habit.dart                # 习惯 (含打卡记录)
│   │   ├── expense.dart              # 记账
│   │   ├── pomodoro_record.dart      # 番茄钟记录
│   │   ├── achievement.dart          # 成就勋章
│   │   └── user_profile.dart         # 用户
│   ├── providers/                    # Riverpod 状态管理
│   │   ├── course_provider.dart      # 课程 CRUD + GPA
│   │   ├── task_provider.dart        # 任务 + 智能排序
│   │   ├── flashcard_provider.dart   # 闪卡 + Anki 队列
│   │   ├── pomodoro_provider.dart    # 番茄钟统计
│   │   ├── habit_provider.dart       # 习惯打卡
│   │   ├── note_provider.dart        # 笔记搜索
│   │   ├── expense_provider.dart     # 记账统计
│   │   ├── achievement_provider.dart # 成就检测
│   │   ├── user_provider.dart        # 用户登录/注册
│   │   └── theme_provider.dart       # 主题切换
│   ├── pages/                        # UI 页面
│   │   ├── shell_page.dart           # 底部导航主框架
│   │   ├── home/dashboard_page.dart  # Dashboard 首页
│   │   ├── course/                   # 课程列表/详情/GPA
│   │   ├── task/                     # 任务看板
│   │   ├── pomodoro/                 # 番茄专注
│   │   ├── flashcard/                # 闪卡列表/编辑/复习/OCR导入
│   │   ├── note/                     # 笔记列表/编辑
│   │   ├── habit/                    # 习惯打卡
│   │   ├── expense/                  # 记账
│   │   ├── calendar/                 # 日历课表
│   │   ├── report/                   # 学习报告
│   │   └── profile/                  # 个人中心/成就/登录
│   └── utils/                        # 工具类
│       ├── user_database.dart        # SQLite 用户数据库
│       ├── backup_service.dart       # JSON 备份/恢复
│       └── data_migration.dart       # 数据迁移
├── android/                          # Android 平台配置
├── docs/
│   ├── SETUP_GUIDE.md                # 环境搭建指南
│   ├── harmony_plan.md               # 鸿蒙适配方案
│   └── technical_report.md           # 技术报告模板
├── pubspec.yaml
└── README.md
```

## 🚀 快速开始

### 环境要求

- Flutter SDK >= 3.5.0
- Dart SDK >= 3.5.0
- Android Studio / VS Code
- Android 设备或模拟器 (API 21+)

### 安装运行

```bash
# 1. 克隆仓库
git clone <repo-url>
cd studymate

# 2. 获取依赖
flutter pub get

# 3. 连接设备后运行
flutter run

# 4. 构建发布 APK（给朋友安装）
flutter build apk --release
# 输出位置: build/app/outputs/flutter-apk/app-release.apk
```

### 给朋友安装测试

1. 将 `app-release.apk` 发送给朋友（微信/QQ/网盘）
2. 朋友手机上打开 APK → 允许「安装未知来源应用」→ 安装
3. 支持 Android 5.0+ 手机和平板

## 📝 AI 协作说明

本项目开发全程使用 AI 辅助编程工具（Windsurf Cascade）：

- `// AI生成` — 该文件/代码段由 AI 辅助生成
- `// 人工修改` — 该部分经过人工审核修改
- **AI 主要负责**：代码框架搭建、UI 布局实现、算法编写、Bug 修复
- **人工主要负责**：需求定义、功能规划、交互设计、测试验证、最终审查

## 🎨 设计规范

- 遵循 Material Design 3 设计语言
- 使用 Dynamic Color 动态颜色方案
- 支持亮色 / 深色 / 跟随系统三种主题模式
- 各功能模块使用专属品牌色区分
- 入场动画、微交互提升用户体验

## 📊 技术亮点

1. **SM-2 间隔重复算法** — 闪卡模块实现 Anki 风格科学记忆曲线
2. **Hive + SQLite 双存储** — 业务数据用 Hive NoSQL，用户账户用 SQLite
3. **Riverpod 响应式状态管理** — 14 个 Provider 实现模块间数据实时联动
4. **图表可视化** — 专注柱状图、记账饼图、习惯热力图、闪卡掌握度饼图
5. **OCR 文字识别** — Google ML Kit 中英文混合识别，拍照即可转闪卡
6. **成就系统** — 19 项成就自动检测解锁，游戏化激励学习
7. **数据安全** — 密码加盐哈希、JSON 备份恢复、自动数据迁移

## � 鸿蒙适配方案

详见 [`docs/harmony_plan.md`](docs/harmony_plan.md)

## 📄 License

本项目为课程期末作品，仅用于学习交流。
