# StudyMate Pro 鸿蒙版 — 部署指南

## 1. 安装 DevEco Studio

1. 下载 [DevEco Studio 5.0+](https://developer.huawei.com/consumer/cn/deveco-studio/)
2. 安装时勾选 HarmonyOS SDK (API 12+)
3. 打开 DevEco Studio → 欢迎页 → **Open** → 选择 `harmonyos/` 目录

## 2. 配置模拟器

1. DevEco Studio → Tools → Device Manager
2. 点 **New Emulator** → 选 Phone 或 Tablet → 选 API 12 镜像
3. 下载镜像后启动模拟器

## 3. 运行

1. DevEco Studio 顶部工具栏 → 选择模拟器设备
2. 点 ▶ Run / Shift+F10
3. 等待编译 → 应用自动安装到模拟器

## 4. 项目结构

```
harmonyos/
├── build-profile.json5        # 构建配置 (API 12)
├── oh-package.json5           # 项目级依赖
├── entry/
│   ├── oh-package.json5       # 模块依赖
│   ├── src/main/module.json5  # 模块声明
│   └── src/main/ets/
│       ├── entryability/
│       │   └── EntryAbility.ets  # 应用入口
│       └── pages/
│           ├── Index.ets          # 启动页
│           ├── DashboardPage.ets  # 首页 (数据概览+工具箱+待办+习惯)
│           ├── TaskPage.ets       # 任务看板 (四栏Tab+优先级+子任务)
│           ├── FlashcardPage.ets  # 闪卡学习 (SM-2四级评分+间隔预览)
│           └── ProfilePage.ets    # 个人中心 (登录/数据统计/深色模式)
```

## 5. 对应 Flutter 页面

| ArkTS 页面 | Flutter 来源 | 演示功能 |
|-----------|------------|---------|
| DashboardPage.ets | `dashboard_page.dart` | Hero Header + 统计卡片 + 工具箱网格 + 待办列表 + 习惯打卡 |
| TaskPage.ets | `task_board_page.dart` | 四栏 Tab + 优先级标签 + 子任务进度 + 逾期高亮 |
| FlashcardPage.ets | `flashcard_study_page.dart` | 点击显示答案 + SM-2 四级评分(Again/Hard/Good/Easy) + 间隔预览 + 完成总结 |
| ProfilePage.ets | `profile_page.dart` | 用户卡片 + 标签 + 数据统计网格 + 深色模式切换 + 登出 |

## 6. 关键技术对照

| Flutter | ArkTS/鸿蒙 |
|---------|-----------|
| `ConsumerWidget` + `ref.watch()` | `@State` / `@StorageLink` 响应式 |
| `ref.read(provider.notifier).updateStatus()` | `.onClick()` 直接修改 `@State` |
| `GridView.count()` | `Grid()` + `columnsTemplate()` |
| `ChoiceChip` | `Button` / `Toggle` |
| `fl_chart` BarChart | `Progress` 组件 |
| `AnimatedSwitcher` | `transition()` 内置过渡动画 |
| `Hive` 本地存储 | `@ohos.data.preferences` / `relationalStore` |
| `showModalBottomSheet` | `Navigation` + 子页面 |
