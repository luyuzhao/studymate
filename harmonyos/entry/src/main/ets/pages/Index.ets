// AI生成 - ArkTS 版 StudyMate Pro：入口页面
import { router } from '@kit.ArkUI';

@Entry
@Component
struct Index {
  build() {
    Navigation() {
      DashboardPage()
    }
    .width('100%')
    .height('100%')
    .hideTitleBar(true)
  }
}
