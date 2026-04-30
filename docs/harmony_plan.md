# HarmonyOS NEXT 适配方案

## 一、适配背景

StudyMate Pro 当前基于 Flutter 3.x 开发，主要运行于 Android/Windows 平台。根据课程要求，需提供 HarmonyOS NEXT 适配方案。

## 二、适配策略

### 方案 A：Flutter 鸿蒙插件（推荐）

华为官方已推出 Flutter for HarmonyOS 适配层（`flutter_harmony`），可将现有 Flutter 项目以较低成本迁移至 HarmonyOS NEXT。

**迁移步骤：**

1. **安装 DevEco Studio 5.0+**（鸿蒙开发 IDE）
2. **配置 Flutter HarmonyOS 工具链**
   ```bash
   # 下载鸿蒙 Flutter SDK 分支
   git clone -b harmonyos https://gitee.com/aspect_aspect/flutter.git
   export FLUTTER_HOME=/path/to/harmonyos-flutter
   ```
3. **创建鸿蒙平台目录**
   ```bash
   flutter create --platforms harmonyos .
   ```
4. **插件兼容性检查**
   - ✅ `hive_flutter` — 纯 Dart 实现，天然兼容
   - ✅ `flutter_riverpod` — 纯 Dart，天然兼容
   - ✅ `fl_chart` — 纯 Dart Canvas 绘制，兼容
   - ✅ `table_calendar` — 纯 Dart，兼容
   - ✅ `flutter_animate` — 纯 Dart 动画，兼容
   - ⚠️ `sqflite` — 需替换为鸿蒙版 `@ohos.data.relationalStore`
   - ⚠️ `google_mlkit_text_recognition` — 需替换为华为 ML Kit
   - ⚠️ `image_picker` — 需适配鸿蒙相机/相册 API
   - ⚠️ `path_provider` — 需适配鸿蒙文件系统路径

5. **构建运行**
   ```bash
   flutter build hap --release  # 输出 .hap 安装包
   ```

### 方案 B：ArkTS 核心页面演示

使用 ArkTS（鸿蒙原生语言）重写 2-3 个核心页面，演示鸿蒙原生开发能力。

**选定演示页面：**

1. **Dashboard 首页** — 展示 ArkUI 布局、数据绑定
2. **课程日历页** — 展示鸿蒙日历组件
3. **闪卡复习页** — 展示交互与动画

**ArkTS Dashboard 首页示例代码：**

```typescript
// pages/DashboardPage.ets
// AI生成 — 鸿蒙 ArkTS 版 Dashboard 首页演示

import router from '@ohos.router'

@Entry
@Component
struct DashboardPage {
  @State todayMinutes: number = 45
  @State completedTasks: number = 3
  @State pendingTasks: number = 5
  @State greeting: string = '早上好 ☀️'

  aboutToAppear() {
    const hour = new Date().getHours()
    if (hour < 6) this.greeting = '夜深了 🌙'
    else if (hour < 12) this.greeting = '早上好 ☀️'
    else if (hour < 14) this.greeting = '中午好 🌤️'
    else if (hour < 18) this.greeting = '下午好 ⛅'
    else this.greeting = '晚上好 🌆'
  }

  build() {
    Column() {
      // Hero Header
      Column() {
        Text(this.greeting)
          .fontSize(28)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')
        Text(new Date().toLocaleDateString('zh-CN', {
          year: 'numeric', month: 'long', day: 'numeric', weekday: 'long'
        }))
          .fontSize(13)
          .fontColor('#999999')
          .margin({ top: 4 })
      }
      .width('100%')
      .padding({ left: 20, right: 20, top: 48, bottom: 20 })
      .linearGradient({
        direction: GradientDirection.RightBottom,
        colors: [['#F0F4FF', 0], ['#FFFFFF', 1]]
      })

      // 数据概览
      Row() {
        this.StatCard('专注时长', `${this.todayMinutes}`, '分钟', '#4A90D9')
        this.StatCard('完成待办', `${this.completedTasks}`, '项', '#27AE60')
      }
      .width('100%')
      .padding({ left: 20, right: 20 })
      .justifyContent(FlexAlign.SpaceBetween)

      // 工具箱
      Text('工具箱')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .margin({ left: 20, top: 24, bottom: 12 })

      Grid() {
        this.ToolItem('📚', '课程', () => router.pushUrl({ url: 'pages/CoursePage' }))
        this.ToolItem('✅', '待办', () => router.pushUrl({ url: 'pages/TaskPage' }))
        this.ToolItem('🍅', '专注', () => router.pushUrl({ url: 'pages/PomodoroPage' }))
        this.ToolItem('🧠', '闪卡', () => router.pushUrl({ url: 'pages/FlashcardPage' }))
        this.ToolItem('📅', '日历', () => router.pushUrl({ url: 'pages/CalendarPage' }))
        this.ToolItem('📈', '报告', () => router.pushUrl({ url: 'pages/ReportPage' }))
        this.ToolItem('🏆', '成就', () => router.pushUrl({ url: 'pages/AchievementPage' }))
        this.ToolItem('📸', 'OCR', () => router.pushUrl({ url: 'pages/OcrPage' }))
      }
      .columnsTemplate('1fr 1fr 1fr 1fr')
      .rowsGap(10)
      .columnsGap(10)
      .padding({ left: 20, right: 20 })
      .height(180)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF')
  }

  @Builder StatCard(label: string, value: string, unit: string, color: string) {
    Column() {
      Text(label).fontSize(12).fontColor('#999999')
      Row() {
        Text(value).fontSize(28).fontWeight(FontWeight.Bold)
        Text(unit).fontSize(12).fontColor('#999999').margin({ left: 2, bottom: 4 })
      }.alignItems(VerticalAlign.Bottom)
    }
    .padding(16)
    .borderRadius(14)
    .border({ width: 1, color: '#F0F0F0' })
    .layoutWeight(1)
    .margin({ right: 6 })
  }

  @Builder ToolItem(icon: string, label: string, action: () => void) {
    GridItem() {
      Column() {
        Text(icon).fontSize(24)
        Text(label).fontSize(12).margin({ top: 6 })
      }
      .justifyContent(FlexAlign.Center)
      .width('100%')
      .height('100%')
      .borderRadius(12)
      .backgroundColor('#F8F9FA')
      .onClick(action)
    }
  }
}
```

## 三、鸿蒙特有能力利用

| Flutter 功能 | 鸿蒙对应 API | 说明 |
|-------------|-------------|------|
| 本地通知 | `@ohos.notificationManager` | 课程/任务提醒 |
| 桌面小组件 | `FormAbility` (服务卡片) | 今日待办/专注时长卡片 |
| OCR 识别 | `@ohos.ai.textRecognition` | 替代 Google ML Kit |
| 数据库 | `@ohos.data.relationalStore` | 替代 SQLite |
| 文件存储 | `@ohos.file.fs` | 替代 path_provider |
| 相机 | `@ohos.multimedia.camera` | 替代 image_picker |

## 四、适配工作量评估

| 任务 | 预估工时 | 优先级 |
|------|---------|--------|
| Flutter HarmonyOS 环境搭建 | 1 天 | P0 |
| 纯 Dart 插件验证 | 0.5 天 | P0 |
| 平台相关插件替换（SQLite/相机/OCR） | 2-3 天 | P1 |
| UI 适配与测试 | 1-2 天 | P1 |
| ArkTS 演示页面开发 | 1-2 天 | P2 |
| **合计** | **5-8 天** | — |

## 五、结论

StudyMate Pro 的核心业务逻辑（模型、Provider、算法）均为纯 Dart 实现，天然兼容鸿蒙平台。主要适配工作集中在 3 个平台相关插件的替换上。推荐采用**方案 A（Flutter for HarmonyOS）为主 + 方案 B（ArkTS 演示）为辅**的混合策略。
