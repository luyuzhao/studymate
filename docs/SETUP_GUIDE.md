# StudyMate Pro 完整环境搭建与实施指南

## 一、必须安装的软件和工具

### 1. Flutter SDK (核心开发框架)
- **下载地址**: https://docs.flutter.dev/get-started/install/windows/mobile
- **版本要求**: Flutter 3.x (建议 3.22+)
- **安装步骤**:
  1. 下载 Flutter SDK zip 包
  2. 解压到 `C:\flutter`（路径不要有中文和空格）
  3. 将 `C:\flutter\bin` 添加到系统环境变量 PATH
  4. 打开新终端验证: `flutter --version`
  5. 运行 `flutter doctor` 检查环境

### 2. Android Studio (Android 开发环境)
- **下载地址**: https://developer.android.com/studio
- **必须安装的组件**:
  - Android SDK (API 35, 最低支持 API 21)
  - Android SDK Build-Tools
  - Android SDK Command-line Tools
  - Android Emulator (模拟器)
- **配置步骤**:
  1. 安装 Android Studio
  2. 打开 SDK Manager → 勾选 Android 14 (API 35)
  3. 安装 Flutter 和 Dart 插件
  4. 创建 AVD 模拟器 (API 21+ 即可)

### 3. VS Code 或 Cursor/Trae (代码编辑器)
- 安装 Flutter 和 Dart 扩展
- 安装 Error Lens 扩展 (便于看错误)

### 4. Git (版本控制)
- **下载地址**: https://git-scm.com/downloads
- 用于代码版本管理，满足课程要求
- 推荐使用 GitHub 或 Gitee 托管

### 5. Java JDK (Android 构建需要)
- Android Studio 自带 JDK，通常不需单独安装
- 如果 `flutter doctor` 提示缺少 Java，安装 JDK 17

---

## 二、项目依赖包说明

以下是 `pubspec.yaml` 中所有依赖包的用途:

| 包名 | 版本 | 用途 | 用在哪个模块 |
|------|------|------|-------------|
| `flutter_riverpod` | ^2.5.1 | 状态管理框架 | **所有模块**的数据管理 |
| `hive` | ^2.2.3 | 本地 NoSQL 数据库 | **所有模块**的数据持久化 |
| `hive_flutter` | ^1.1.0 | Hive 的 Flutter 适配 | 初始化和数据存储 |
| `fl_chart` | ^0.68.0 | 图表绘制库 | **番茄钟**柱状图、**记账**饼图 |
| `google_fonts` | ^6.2.1 | Google 字体 | 全局使用 Noto Sans SC 中文字体 |
| `intl` | ^0.19.0 | 国际化/日期格式化 | 日期显示 (如 "2025年1月1日 周一") |
| `uuid` | ^4.4.2 | 生成唯一 ID | 所有数据模型的 ID 生成 |
| `percent_indicator` | ^4.2.3 | 进度指示器 | **GPA**圆环、**闪卡**进度条 |
| `table_calendar` | ^3.1.2 | 日历组件 | **任务**日历视图(可选扩展) |
| `flutter_staggered_animations` | ^1.1.1 | 列表动画 | 列表页面入场动画 |
| `shimmer` | ^3.0.0 | 骨架屏加载动画 | 加载状态 |
| `lottie` | ^3.1.2 | Lottie 动画播放 | 空状态/完成动画 |
| `path_provider` | ^2.1.4 | 获取系统路径 | 数据存储路径 |
| `collection` | ^1.18.0 | 集合工具类 | 数据排序筛选 |

**开发依赖** (不打包进 APK):
| 包名 | 用途 |
|------|------|
| `hive_generator` | Hive 适配器代码生成 (已手写,可选) |
| `build_runner` | 代码生成运行器 (已手写,可选) |
| `flutter_lints` | 代码规范检查 |

---

## 三、每个功能模块的实现详解

### 模块 1: Dashboard 首页 (dashboard_page.dart)

**实现方式**:
- 使用 `CustomScrollView` + `SliverAppBar.large` 实现折叠式顶栏
- 通过 Riverpod `ref.watch()` 实时监听所有模块数据
- 今日概览卡片: 读取番茄钟和任务 Provider 的统计数据
- 功能工具箱: `GridView` 网格布局，点击跳转到各子页面
- 今日待办: 从 TaskProvider 过滤出今日截止任务
- 习惯打卡: 从 HabitProvider 读取，展示为 ActionChip 列表
- 课程列表: 水平滚动 ListView

**技术点**: Riverpod 响应式数据联动、SliverAppBar 折叠效果

**满足课程要求**: ✅ 首页

---

### 模块 2: 课程管理 (course_list_page.dart + course_detail_page.dart + gpa_calculator_page.dart)

**实现方式**:
- **课程列表页**: ListView 展示所有课程，每个课程显示名称/教师/地点/时间
- **添加课程**: BottomSheet 弹出表单，填写名称/教师/地点/学分/颜色
- **课程详情页**: 展示课程完整信息 + 关联的任务和笔记列表
- **GPA 计算器**: CircularPercentIndicator 圆环展示 GPA，百分制→4.0制转换

**数据存储**: Hive Box<Course>，字段包括 id/name/teacher/location/credit/score/weekdays/time

**技术点**: 百分制→GPA 换算算法、加权平均计算

**满足课程要求**: ✅ 列表页 + 详情页

---

### 模块 3: 任务待办 (task_board_page.dart)

**实现方式**:
- 使用 `TabBar` + `TabBarView` 实现三栏看板 (待做/进行中/已完成)
- 每个任务卡片显示: 标题/描述/优先级标签/截止日期/课程关联
- `Dismissible` 组件实现滑动删除
- `PopupMenuButton` 切换任务状态
- 添加任务: BottomSheet 表单含优先级选择、日期选择器、课程关联下拉框
- 自动检测过期任务 (dueDate < now && status != done)

**数据存储**: Hive Box<Task>，状态枚举 TaskStatus (todo/inProgress/done)

**技术点**: 看板视图、滑动手势、日期选择器

**满足课程要求**: ✅ 核心功能页面

---

### 模块 4: 番茄钟专注 (pomodoro_page.dart)

**实现方式**:
- 核心: `Timer.periodic(Duration(seconds: 1))` 每秒倒计时
- 圆环进度: `CircularPercentIndicator` 实时显示进度
- 时长选择: `ChoiceChip` 组件选择 15/25/30/45/60 分钟
- 完成后自动切换到 5 分钟休息模式
- 完成记录存入 Hive，统计今日/本周专注时长
- 本周分布图: `fl_chart` 的 `BarChart` 绘制周一到周日柱状图

**数据存储**: Hive Box<PomodoroRecord>，记录开始/结束时间、时长、关联课程

**技术点**: Timer 计时器、fl_chart 柱状图、状态管理

**满足课程要求**: ✅ 核心功能页面 + 数据可视化

---

### 模块 5: 闪卡记忆 (flashcard_list_page.dart + flashcard_edit_page.dart + flashcard_study_page.dart)

**实现方式**:
- **卡组列表**: 显示每个卡组的名称/卡片数/待复习数/掌握度进度条
- **卡片管理**: 列表展示正反面内容，支持添加/删除
- **学习页面**: 翻转动画 + SM-2 间隔重复评分
  - 翻转: `AnimationController` + `Transform.rotateY` 实现 3D 翻转
  - SM-2 算法: 根据用户评分(0-5)调整复习间隔和难度因子
    - 评分 ≥ 3: 间隔递增 (1天 → 6天 → n*easeFactor天)
    - 评分 < 3: 重置为第1天重新学习
    - easeFactor 动态调整，最低 1.3
- 四个评分按钮: 忘了(0)/模糊(2)/记住(3)/轻松(5)

**数据存储**: Hive Box<FlashcardDeck>，内嵌 List<Flashcard>，每张卡片存储 repetitionLevel/easeFactor/nextReviewDate

**技术点**: SM-2 间隔重复算法(创新点!)、3D 翻转动画

**满足课程要求**: ✅ 核心功能 + 算法创新

---

### 模块 6: 笔记系统 (note_list_page.dart + note_edit_page.dart)

**实现方式**:
- **列表页**: 支持搜索(标题/内容/标签全文检索)、置顶、按课程标签筛选
- **编辑页**:
  - 标题输入 + 课程关联 FilterChip 横向滚动
  - 内容区: 全屏 TextField，支持 Markdown 语法
  - 底部 Markdown 快捷工具栏: H1/H2/加粗/斜体/列表/待办/代码/引用
  - 工具栏通过 `TextEditingController.selection` 操作光标位置插入标记

**数据存储**: Hive Box<Note>，content 字段存储原始 Markdown 文本

**技术点**: Markdown 编辑、TextEditingController 光标操作、全文搜索

**满足课程要求**: ✅ 详情页 + 编辑功能

---

### 模块 7: 习惯打卡 (habit_page.dart)

**实现方式**:
- 每个习惯卡片包含: 名称/连续天数/打卡按钮/热力图/目标进度条
- **热力图**: `GridView` 7列×5行 = 35天，已打卡日填充颜色
- **打卡逻辑**: 检查今日是否已打卡(去重)，打卡后记录存入 records 列表
- **连续天数算法**: 从今天往前遍历 records，连续有记录则累加
- **目标进度**: LinearProgressIndicator 显示 totalCheckins/targetDays

**数据存储**: Hive Box<Habit>，内嵌 List<HabitRecord>，每条记录存储日期和备注

**技术点**: 热力图可视化、连续天数算法、日期去重

**满足课程要求**: ✅ 核心功能 + 数据可视化

---

### 模块 8: 智能记账 (expense_page.dart)

**实现方式**:
- **月份切换**: 左右箭头切换年月，筛选当月记录
- **收支概览**: 两个彩色卡片分别显示月支出和月收入
- **分类饼图**: `fl_chart` 的 `PieChart`，按类别统计占比
- **明细列表**: 按时间倒序排列，Dismissible 滑动删除
- **快速记账 BottomSheet**: 
  - 支出/收入切换 (SegmentedButton)
  - 金额输入 (大字号)
  - 分类选择 (ChoiceChip): 餐饮🍜/交通🚌/购物🛍️/娱乐🎮/学习📚/生活🏠/其他📦
  - 备注输入

**数据存储**: Hive Box<Expense>，枚举 ExpenseCategory + isIncome 区分收支

**技术点**: PieChart 饼图、分类统计、月度筛选

**满足课程要求**: ✅ 核心功能 + 图表可视化

---

### 模块 9: 个人中心 (profile_page.dart)

**实现方式**:
- 用户头像和名称展示
- **数据统计网格**: 2×3 GridView 显示课程数/任务完成数/笔记数/闪卡数/专注总时长/习惯数
- **深色模式切换**: PopupMenuButton 选择 系统/亮色/深色，存入 Hive settings box
- **清除数据**: 调用所有 Hive box 的 clear() 方法，然后 invalidate 所有 Provider
- **关于信息**: AboutDialog 展示版本和技术栈

**技术点**: 主题持久化、全局状态刷新

**满足课程要求**: ✅ 个人中心 + 深色模式切换

---

## 四、项目如何满足课程要求对照表

| 课程要求 | 本项目实现 | 状态 |
|---------|-----------|------|
| Flutter 3.x 开发 | 使用 Flutter 3.x + Dart | ✅ |
| 支持 Android (API 21+) | minSdkVersion 设为 21 | ✅ |
| 鸿蒙适配方案 | 可在技术报告中说明 ArkTS 适配方案 | ⬜ 文档补充 |
| AI 辅助开发标注 | 每个文件头部 `// AI生成` 注释 | ✅ |
| Git 版本控制 | .gitignore 已配置 | ✅ |
| README 完整 | 详细 README.md | ✅ |
| 3-5 个核心功能页面 | **9 个功能模块，13+ 页面** | ✅ 超额完成 |
| 本地数据持久化 | Hive NoSQL 数据库 | ✅ |
| Material Design 3 | 完整 MD3 主题配置 | ✅ |
| 深色模式切换 | 支持 亮色/深色/跟随系统 | ✅ |
| 可安装 APK | `flutter build apk --release` | ✅ |

---

## 五、运行项目的完整步骤

```bash
# 1. 安装 Flutter 后，进入项目目录
cd E:\测试\studymate

# 2. 生成 Android 平台文件 (因为项目是手动创建的)
flutter create .

# 3. 获取所有依赖包
flutter pub get

# 4. 连接 Android 设备或启动模拟器
flutter devices

# 5. 运行项目
flutter run

# 6. 构建发布 APK
flutter build apk --release
# APK 路径: build/app/outputs/flutter-apk/app-release.apk
```

## 六、Git 初始化

```bash
cd E:\测试\studymate
git init
git add .
git commit -m "feat: 初始化 StudyMate Pro 项目"
# 推送到 GitHub/Gitee
git remote add origin <你的仓库地址>
git push -u origin main
```
