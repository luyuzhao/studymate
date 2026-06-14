// AI生成 - ArkTS 版 StudyMate Pro：任务看板页
// 对应 Flutter 的 task_board_page.dart

import { router } from '@kit.ArkUI';

@Entry
@Component
struct TaskPage {
  @State currentTab: number = 0;
  private tabs: string[] = ['建议', '待做', '进行中', '已完成'];

  // 模拟任务数据
  @State tasks: TaskItem[] = [
    { id: '1', title: '复习操作系统第四章', description: 'CPU调度算法', status: 0, priority: 2, dueDate: '2026-05-30', overdue: true, subtaskDone: 2, subtaskTotal: 5 },
    { id: '2', title: '完成数据结构作业', description: '二叉树遍历代码实现', status: 1, priority: 2, dueDate: '2026-05-30', overdue: false, subtaskDone: 0, subtaskTotal: 0 },
    { id: '3', title: '背英语单词 CET-6', description: '每天30个', status: 1, priority: 1, dueDate: '2026-05-31', overdue: false, subtaskDone: 1, subtaskTotal: 3 },
    { id: '4', title: '整理计组笔记', description: '', status: 2, priority: 1, dueDate: '2026-05-28', overdue: false, subtaskDone: 0, subtaskTotal: 0 },
    { id: '5', title: '提交实验报告', description: '实验3', status: 3, priority: 0, dueDate: '2026-05-25', overdue: false, subtaskDone: 0, subtaskTotal: 0 },
  ];

  build() {
    Column() {
      // 标题
      Row() {
        Text('任务待办')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .margin({ left: 20, top: 48, bottom: 12 });
      }

      // Tab 栏
      Row() {
        ForEach(this.tabs, (tab: string, index: number) => {
          Column() {
            Text(`${tab} (${this.getCount(index)})`)
              .fontSize(13)
              .fontWeight(this.currentTab === index ? FontWeight.Bold : FontWeight.Normal)
              .fontColor(this.currentTab === index ? '#4A90D9' : '#999999');
            if (this.currentTab === index) {
              Divider()
                .width('60%')
                .height(2)
                .color('#4A90D9')
                .strokeWidth(2);
            }
          }
          .layoutWeight(1)
          .padding({ top: 8, bottom: 4 })
          .onClick(() => { this.currentTab = index; })
        })
      }
      .padding({ left: 16, right: 16 })

      // 任务列表
      List() {
        ForEach(this.getFilteredTasks(), (task: TaskItem) => {
          ListItem() {
            this.TaskCard(task)
          }
        })
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF')
  }

  getCount(tabIndex: number): number {
    return this.tasks.filter(t => t.status === tabIndex).length;
  }

  getFilteredTasks(): TaskItem[] {
    if (this.currentTab === 3) return this.tasks; // 建议：显示全部
    return this.tasks.filter(t => t.status === this.currentTab);
  }

  @Builder TaskCard(task: TaskItem) {
    Column() {
      Row() {
        // 逾期警告
        if (task.overdue) {
          Text('⚠')
            .fontSize(14)
            .margin({ right: 4 });
        }
        // 标题
        Text(task.title)
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .fontColor('#333333')
          .layoutWeight(1);
        // 优先级标签
        Text(this.getPriorityLabel(task.priority))
          .fontSize(11)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.getPriorityColor(task.priority))
          .backgroundColor(this.getPriorityColor(task.priority) + '20')
          .borderRadius(6)
          .padding({ left: 8, right: 8, top: 3, bottom: 3 });
      }
      .width('100%')

      // 描述
      if (task.description !== '') {
        Text(task.description)
          .fontSize(13)
          .fontColor('#999999')
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .margin({ top: 6 })
          .width('100%');
      }

      // 子任务进度
      if (task.subtaskTotal > 0) {
        Row() {
          Progress({
            value: task.subtaskDone,
            total: task.subtaskTotal,
            type: ProgressType.Linear
          })
            .width('80%')
            .height(6)
            .style({ strokeRadius: 3 })
            .margin({ top: 8 });
          Text(`${task.subtaskDone}/${task.subtaskTotal}`)
            .fontSize(12)
            .fontColor('#999999')
            .margin({ left: 8, top: 8 });
        }
        .width('100%');
      }

      // 底部：日期 + 状态
      Row() {
        Text(task.dueDate)
          .fontSize(11)
          .fontColor(task.overdue ? '#EF4444' : '#999999')
          .margin({ left: 2 });
        if (task.overdue) {
          Text('已逾期')
            .fontSize(10)
            .fontColor('#EF4444')
            .backgroundColor('#FEE2E2')
            .borderRadius(4)
            .padding({ left: 6, right: 6, top: 1, bottom: 1 })
            .margin({ left: 8 });
        }
        Blank();
        Text(this.getStatusLabel(task.status))
          .fontSize(12)
          .backgroundColor('#E8F0FE')
          .fontColor('#4A90D9')
          .borderRadius(6)
          .padding({ left: 10, right: 10, top: 3, bottom: 3 });
      }
      .width('100%')
      .margin({ top: 8 });
    }
    .padding(16)
    .borderRadius(12)
    .backgroundColor('#FFFFFF')
    .border({ width: 1, color: '#F0F0F0' })
    .margin({ left: 16, right: 16, top: 8 })
  }

  getPriorityLabel(p: number): string {
    if (p === 2) return '高';
    if (p === 1) return '中';
    return '低';
  }

  getPriorityColor(p: number): string {
    if (p === 2) return '#EF4444';
    if (p === 1) return '#F59E0B';
    return '#4CAF50';
  }

  getStatusLabel(s: number): string {
    if (s === 0) return '建议';
    if (s === 1) return '待做';
    if (s === 2) return '进行中';
    return '已完成';
  }
}

interface TaskItem {
  id: string;
  title: string;
  description: string;
  status: number; // 0=建议 1=待做 2=进行中 3=已完成
  priority: number; // 0=低 1=中 2=高
  dueDate: string;
  overdue: boolean;
  subtaskDone: number;
  subtaskTotal: number;
}
