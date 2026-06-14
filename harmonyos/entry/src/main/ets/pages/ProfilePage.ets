// AI生成 - ArkTS 版 StudyMate Pro：个人中心
// 对应 Flutter 的 profile_page.dart

@Entry
@Component
struct ProfilePage {
  @State isLoggedIn: boolean = true;
  @State userName: string = '张同学';
  @State phoneNumber: string = '138****5678';
  @State isDarkMode: boolean = false;
  @State tags: string[] = ['计算机科学', '大三', '考研备考'];

  build() {
    Column() {
      // 顶部
      Text('个人中心')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .margin({ left: 20, top: 48, bottom: 12 });

      Scroll() {
        Column() {
          // ========== 用户信息卡片 ==========
          Row() {
            // 头像
            Stack() {
              Circle()
                .width(56).height(56)
                .fill('#E8F0FE');
              Text('👨‍🎓')
                .fontSize(28);
            }
            .width(56).height(56)
            .borderRadius(28);

            Column() {
              Text(this.userName)
                .fontSize(18)
                .fontWeight(FontWeight.Bold);
              Text(this.phoneNumber)
                .fontSize(13)
                .fontColor('#999999')
                .margin({ top: 2 });
            }
            .alignItems(HorizontalAlign.Start)
            .margin({ left: 12 });

            Blank();

            Text('>')
              .fontSize(18)
              .fontColor('#CCCCCC');
          }
          .width('100%')
          .padding(20)
          .borderRadius(16)
          .backgroundColor('#FFFFFF')
          .border({ width: 1, color: '#F0F0F0' })
          .margin({ left: 16, right: 16 })
          .onClick(() => { /* 跳转资料编辑 */ })

          // 标签
          Row() {
            ForEach(this.tags, (tag: string) => {
              Text(tag)
                .fontSize(12)
                .fontColor('#4A90D9')
                .backgroundColor('#E8F0FE')
                .borderRadius(12)
                .padding({ left: 10, right: 10, top: 4, bottom: 4 })
                .margin({ right: 8, top: 12 })
            })
          }
          .width('100%')
          .padding({ left: 20, right: 20 })

          // ========== 数据统计网格 ==========
          Row() {
            this.StatGrid('45', '专注(分钟)', '#EF4444');
            this.StatGrid('8', '待办任务', '#F59E0B');
            this.StatGrid('12', '打卡天数', '#4CAF50');
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 20 })
          .justifyContent(FlexAlign.SpaceEvenly)

          // ========== 设置分组 ==========
          Text('设置')
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .margin({ left: 20, top: 24, bottom: 10 });

          Column() {
            this.SettingsItem('深色模式', 'DarkMode')
            this.SettingsItem('数据备份与恢复', 'Backup')
            this.SettingsItem('成就勋章', 'Achievement')
            this.SettingsItem('关于 StudyMate Pro', 'About')
          }
          .borderRadius(16)
          .backgroundColor('#FFFFFF')
          .margin({ left: 16, right: 16 })
          .padding({ top: 4, bottom: 4 })

          // ========== 退出登录 ==========
          if (this.isLoggedIn) {
            Button('退出登录')
              .width('90%')
              .height(44)
              .fontSize(15)
              .fontColor('#EF4444')
              .backgroundColor('#FEF2F2')
              .borderRadius(12)
              .margin({ top: 24, bottom: 32 })
              .onClick(() => {
                this.isLoggedIn = false;
              })
          }

          // 游客模式
          if (!this.isLoggedIn) {
            Button('登录 / 注册')
              .width('90%')
              .height(44)
              .fontSize(15)
              .fontColor('#FFFFFF')
              .backgroundColor('#4A90D9')
              .borderRadius(12)
              .margin({ top: 24, bottom: 32 })
          }
        }
        .width('100%')
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F7FA')
  }

  @Builder StatGrid(value: string, label: string, color: string) {
    Column() {
      Text(value)
        .fontSize(28)
        .fontWeight(FontWeight.Bold)
        .fontColor(color);
      Text(label)
        .fontSize(12)
        .fontColor('#999999')
        .margin({ top: 4 });
    }
    .layoutWeight(1)
    .padding({ top: 12, bottom: 12 })
    .borderRadius(12)
    .backgroundColor('#FFFFFF')
    .border({ width: 1, color: '#F0F0F0' })
    .margin({ left: 4, right: 4 })
  }

  @Builder SettingsItem(title: string, type: string) {
    Row() {
      Text(title)
        .fontSize(15)
        .fontColor('#333333');
      Blank();
      if (type === 'DarkMode') {
        Toggle({ type: ToggleType.Switch, isOn: this.isDarkMode })
          .onChange((value: boolean) => { this.isDarkMode = value; })
      } else {
        Text('>')
          .fontSize(16)
          .fontColor('#CCCCCC');
      }
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 14, bottom: 14 })
    .border({ width: { bottom: 0.5 }, color: '#F0F0F0' })
  }
}
