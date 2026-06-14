// AI生成 - ArkTS 版 StudyMate Pro：Dashboard 首页
// 对应 Flutter 的 dashboard_page.dart

import { router } from '@kit.ArkUI';

@Entry
@Component
struct DashboardPage {
  @StorageLink('currentTheme') currentTheme: number = 0; // 0=亮色 1=深色
  @State greeting: string = '';
  @State userName: string = '同学';
  @State todayMinutes: number = 45;
  @State completedTasks: number = 5;
  @State pendingTasks: number = 8;
  @State todaySessions: number = 3;
  @State habitsToday: HabitItem[] = [
    { name: '每日阅读', checked: true, color: '#16A085' },
    { name: '背单词', checked: false, color: '#4A90D9' },
    { name: '运动', checked: false, color: '#E67E22' },
  ];

  aboutToAppear() {
    const hour = new Date().getHours();
    if (hour < 6) this.greeting = '夜深了 🌙';
    else if (hour < 12) this.greeting = '早上好 ☀️';
    else if (hour < 14) this.greeting = '中午好 🌤️';
    else if (hour < 18) this.greeting = '下午好 ⛅';
    else this.greeting = '晚上好 🌆';
  }

  build() {
    Column() {
      // ========== Hero Header ==========
      Column() {
        Text(this.getDateStr())
          .fontSize(13)
          .fontColor('#999999')
          .margin({ bottom: 4 });
        Row() {
          Text(this.greeting)
            .fontSize(28)
            .fontWeight(FontWeight.Bold)
            .fontColor('#1a1a1a');
          Text(this.userName)
            .fontSize(20)
            .fontColor('#666666')
            .margin({ left: 6, bottom: 2 });
        }
      }
      .width('100%')
      .padding({ left: 20, right: 20, top: 48, bottom: 20 })
      .linearGradient({
        direction: GradientDirection.RightBottom,
        colors: [['#F0F4FF', 0], ['#FFFFFF', 1]]
      })

      Scroll() {
        Column() {
          // ========== 数据概览卡片 ==========
          Row() {
            this.StatCard('专注时长', `${this.todayMinutes}`, '分钟',
              `${this.todaySessions} 个番茄`, '#EF4444', $r('app.media.timer_icon'))
            this.StatCard('任务进度', `${this.completedTasks}`, '完成',
              `${this.pendingTasks} 项待做`, '#F59E0B', $r('app.media.task_icon'))
          }
          .width('100%')
          .padding({ left: 20, right: 20 })
          .justifyContent(FlexAlign.SpaceBetween)

          // ========== 工具箱 ==========
          Text('工具箱')
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .margin({ left: 20, top: 24, bottom: 12 });

          Grid() {
            GridItem() { this.ToolItem('📚', '课程', '#4A90D9', () => {}) }
            GridItem() { this.ToolItem('✅', '待办', '#F59E0B', () => router.pushUrl({ url: 'pages/TaskPage' })) }
            GridItem() { this.ToolItem('🍅', '专注', '#EF4444', () => {}) }
            GridItem() { this.ToolItem('🧠', '闪卡', '#26A69A', () => router.pushUrl({ url: 'pages/FlashcardPage' })) }
            GridItem() { this.ToolItem('📝', '笔记', '#2196F3', () => {}) }
            GridItem() { this.ToolItem('💪', '习惯', '#4CAF50', () => {}) }
            GridItem() { this.ToolItem('💰', '记账', '#795548', () => {}) }
            GridItem() { this.ToolItem('👤', '我的', '#6366F1', () => router.pushUrl({ url: 'pages/ProfilePage' })) }
          }
          .columnsTemplate('1fr 1fr 1fr 1fr')
          .rowsGap(10)
          .columnsGap(10)
          .padding({ left: 20, right: 20 })
          .height(170)

          // ========== 今日待办 ==========
          Row() {
            Text('今日待办')
              .fontSize(16)
              .fontWeight(FontWeight.Medium);
            Blank();
            Text('3 项过期')
              .fontSize(12)
              .fontColor('#EF4444')
              .backgroundColor('#FEE2E2')
              .borderRadius(12)
              .padding({ left: 10, right: 10, top: 3, bottom: 3 });
          }
          .width('100%')
          .padding({ left: 20, right: 20, top: 20, bottom: 10 });

          Column() {
            this.TaskItem('复习操作系统', true, '5/30 23:59', '#EF4444');
            this.TaskItem('完成数据结构作业', false, '5/30 18:00', '#F59E0B');
            this.TaskItem('背英语单词 30 个', false, '5/30 20:00', '#4CAF50');
          }
          .padding({ left: 20, right: 20 })

          // ========== 今日习惯 ==========
          Text('今日习惯')
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .margin({ left: 20, top: 20, bottom: 10 });

          Row() {
            ForEach(this.habitsToday, (habit: HabitItem, index: number) => {
              this.HabitChip(habit)
            })
          }
          .width('100%')
          .padding({ left: 20, right: 20 })

          // ========== 空状态 ==========
          if (this.completedTasks === 0 && this.pendingTasks === 0) {
            Column() {
              Text('🚀').fontSize(48);
              Text('欢迎使用 StudyMate Pro')
                .fontSize(20).fontWeight(FontWeight.Bold).margin({ top: 12 });
              Text('从添加课程或创建待办开始你的学习之旅')
                .fontSize(14).fontColor('#999999').margin({ top: 6 });
            }
            .width('100%')
            .padding({ top: 40, bottom: 40 })
            .justifyContent(FlexAlign.Center)
          }
        }
        .width('100%')
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF')
  }

  getDateStr(): string {
    const now = new Date();
    const weekdays = ['日', '一', '二', '三', '四', '五', '六'];
    return `${now.getFullYear()}年${now.getMonth() + 1}月${now.getDate()}日 周${weekdays[now.getDay()]}`;
  }

  @Builder StatCard(label: string, value: string, unit: string, subtitle: string, color: string, icon: Resource) {
    Column() {
      Row() {
        Image(icon).width(18).height(18).fillColor(color);
        Text(label).fontSize(12).fontColor('#999999').margin({ left: 6 });
      }
      Row() {
        Text(value).fontSize(28).fontWeight(FontWeight.Bold).fontColor('#1a1a1a');
        Text(unit).fontSize(12).fontColor('#999999').margin({ left: 3, bottom: 5 });
      }
      .alignItems(VerticalAlign.Bottom)
      .margin({ top: 8 });
      Text(subtitle).fontSize(11).fontColor('#CCCCCC').margin({ top: 2 });
    }
    .padding(16)
    .borderRadius(14)
    .border({ width: 1, color: '#F0F0F0' })
    .layoutWeight(1)
    .margin({ right: 6 })
  }

  @Builder ToolItem(icon: string, label: string, color: string, action: () => void) {
    Column() {
      Text(icon).fontSize(24);
      Text(label).fontSize(12).margin({ top: 4 });
    }
    .justifyContent(FlexAlign.Center)
    .width('100%')
    .height('100%')
    .borderRadius(12)
    .backgroundColor('#F8F9FA')
    .border({ width: 1, color: '#F0F0F0' })
    .onClick(action)
  }

  @Builder TaskItem(title: string, done: boolean, dueDate: string, priorityColor: string) {
    Row() {
      Checkbox({ name: title, group: 'tasks' })
        .select(done)
        .width(20).height(20)
        .shape(CheckBoxShape.ROUNDED_SQUARE)
        .borderRadius(4);
      Column() {
        Text(title)
          .fontSize(14).fontColor('#333333')
          .decoration(done ? { type: TextDecorationType.LineThrough } : undefined);
        Text(dueDate).fontSize(11).fontColor('#999999').margin({ top: 2 });
      }
      .alignItems(HorizontalAlign.Start)
      .margin({ left: 10 });
      Blank();
      Circle()
        .width(8).height(8)
        .fill(priorityColor);
    }
    .width('100%')
    .padding({ top: 8, bottom: 8 })
  }

  @Builder HabitChip(habit: HabitItem) {
    Row() {
      Text(habit.checked ? '✓' : '○')
        .fontSize(16)
        .fontColor(habit.checked ? habit.color : '#CCCCCC');
      Text(habit.name)
        .fontSize(13)
        .fontWeight(habit.checked ? FontWeight.Bold : FontWeight.Normal)
        .fontColor(habit.checked ? habit.color : '#666666')
        .margin({ left: 4 });
    }
    .padding({ left: 12, right: 12, top: 6, bottom: 6 })
    .borderRadius(20)
    .backgroundColor(habit.checked ? this.hexToRgba(habit.color, 0.1) : '#F5F5F5')
    .border({ width: habit.checked ? 1 : 0, color: habit.checked ? this.hexToRgba(habit.color, 0.3) : '' })
    .margin({ right: 8, bottom: 8 })
  }

  hexToRgba(hex: string, alpha: number): string {
    const r = parseInt(hex.slice(1, 3), 16);
    const g = parseInt(hex.slice(3, 5), 16);
    const b = parseInt(hex.slice(5, 7), 16);
    return `rgba(${r},${g},${b},${alpha})`;
  }
}

interface HabitItem {
  name: string;
  checked: boolean;
  color: string;
}
