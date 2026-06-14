// AI生成 - ArkTS 版 StudyMate Pro：闪卡学习页
// 对应 Flutter 的 flashcard_study_page.dart，演示 Anki SM-2 四级评分

import { router } from '@kit.ArkUI';

@Entry
@Component
struct FlashcardPage {
  @State showAnswer: boolean = false;
  @State currentCard: number = 0;
  @State cardStatus: string = '新';
  @State cards: CardItem[] = [
    { front: '什么是二叉树？', back: '每个节点最多有两个子节点的树状数据结构，子节点分别称为左子节点和右子节点' },
    { front: '时间复杂度 O(n²) 的排序算法有哪些？', back: '冒泡排序、选择排序、插入排序。它们都是通过嵌套循环完成排序' },
    { front: '什么是虚拟内存？', back: '操作系统将磁盘空间作为内存扩展的技术，允许程序使用超过物理内存大小的地址空间' },
  ];
  @State studySession: SessionStats = { total: 0, again: 0, hard: 0, good: 0, easy: 0 };
  @State showSummary: boolean = false;
  // SM-2 参数
  @State easeFactor: number = 2.5;
  @State intervalDays: number = 1;

  build() {
    Column() {
      // 顶部导航
      Row() {
        Text('← 闪卡学习')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .onClick(() => { router.back(); });
        Blank();
        Text(`新 ${this.cards.length - this.currentCard} · 学中 0 · 待复习 0`)
          .fontSize(12)
          .fontColor('#999999');
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 48, bottom: 12 })
      .backgroundColor('#FFFFFF');

      // 卡片状态标签
      Row() {
        Text(this.cardStatus)
          .fontSize(11)
          .fontColor('#4A90D9')
          .backgroundColor('#E8F0FE')
          .borderRadius(6)
          .padding({ left: 10, right: 10, top: 3, bottom: 3 });
      }
      .width('100%')
      .padding({ left: 16, top: 12 });

      // 卡片区
      Column() {
        if (this.currentCard < this.cards.length) {
          // 问题面
          Column() {
            Text(this.cards[this.currentCard].front)
              .fontSize(22)
              .fontWeight(FontWeight.Bold)
              .fontColor('#1a1a1a')
              .textAlign(TextAlign.Center)
              .width('80%');

            if (this.showAnswer) {
              Divider()
                .width('60%')
                .color('#E0E0E0')
                .margin({ top: 20, bottom: 20 });
              // 答案面
              Text(this.cards[this.currentCard].back)
                .fontSize(16)
                .fontColor('#666666')
                .textAlign(TextAlign.Center)
                .width('85%')
                .lineHeight(24)
                .transition({
                  type: TransitionType.Insert,
                  opacity: 0, translate: { y: 20 }
                });
            }
          }
          .justifyContent(FlexAlign.Center)
          .height('55%')
          .padding(24)
        } else {
          // 完成总结
          this.SummaryView()
        }
      }
      .layoutWeight(1)

      // 按钮区
      if (this.currentCard < this.cards.length) {
        if (!this.showAnswer) {
          Button('显示答案')
            .width('80%')
            .height(48)
            .fontSize(16)
            .fontColor('#FFFFFF')
            .backgroundColor('#4A90D9')
            .borderRadius(12)
            .margin({ bottom: 12 })
            .onClick(() => { this.showAnswer = true; });
        } else {
          // Anki 四级评分按钮
          Row() {
            ForEach(this.ratingButtons, (btn: RatingBtn) => {
              Column() {
                Text(btn.nextInterval)
                  .fontSize(10)
                  .fontColor('#999999')
                  .margin({ bottom: 4 });
                Button(btn.label)
                  .fontSize(13)
                  .fontColor('#FFFFFF')
                  .backgroundColor(btn.color)
                  .borderRadius(8)
                  .width('100%')
                  .onClick(() => { this.handleRating(btn.value); });
              }
              .layoutWeight(1)
              .margin({ left: btn.value === 0 ? 0 : 6, right: btn.value === 5 ? 0 : 6 })
            })
          }
          .width('100%')
          .padding({ left: 16, right: 16, bottom: 12 });
        }
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF')
  }

  @Builder SummaryView() {
    Column() {
      Text('🎉 学习完成！').fontSize(24).fontWeight(FontWeight.Bold);
      Text(`本轮复习 ${this.studySession.total} 张卡片`).fontSize(14).fontColor('#999999').margin({ top: 8 });
      Row() {
        this.SummaryItem('重来', this.studySession.again, '#EF4444');
        this.SummaryItem('困难', this.studySession.hard, '#F59E0B');
        this.SummaryItem('良好', this.studySession.good, '#4A90D9');
        this.SummaryItem('简单', this.studySession.easy, '#4CAF50');
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceEvenly)
      .margin({ top: 20 });

      Text(`正确率: ${this.getAccuracy()}%`)
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor('#4CAF50')
        .margin({ top: 16 });
    }
    .justifyContent(FlexAlign.Center)
    .height('100%')
    .padding(24)
  }

  @Builder SummaryItem(label: string, count: number, color: string) {
    Column() {
      Text(`${count}`).fontSize(24).fontWeight(FontWeight.Bold).fontColor(color);
      Text(label).fontSize(12).fontColor('#999999').margin({ top: 2 });
    }
  }

  ratingButtons: RatingBtn[] = [
    { value: 0, label: '重来\nAgain', color: '#EF4444', nextInterval: '10分钟' },
    { value: 2, label: '困难\nHard', color: '#F59E0B', nextInterval: this.getIntervalPreview(2) },
    { value: 3, label: '良好\nGood', color: '#4A90D9', nextInterval: this.getIntervalPreview(3) },
    { value: 5, label: '简单\nEasy', color: '#4CAF50', nextInterval: this.getIntervalPreview(5) },
  ];

  handleRating(quality: number) {
    this.studySession.total++;
    if (quality === 0) this.studySession.again++;
    else if (quality === 2) this.studySession.hard++;
    else if (quality === 3) this.studySession.good++;
    else if (quality === 5) this.studySession.easy++;

    // SM-2 算法
    if (quality === 0) {
      this.easeFactor = Math.max(1.3, this.easeFactor - 0.2);
      this.intervalDays = 0;
      this.cardStatus = '学习中';
    } else if (quality === 2) {
      this.easeFactor = Math.max(1.3, this.easeFactor - 0.15);
      this.intervalDays = Math.max(1, this.intervalDays * 1.2);
      this.cardStatus = '学习中';
    } else if (quality === 3) {
      this.intervalDays = Math.round(this.intervalDays * this.easeFactor);
      this.cardStatus = '复习中';
    } else if (quality === 5) {
      this.intervalDays = Math.round(this.intervalDays * this.easeFactor * 1.3);
      this.easeFactor = Math.min(10.0, this.easeFactor + 0.15);
      this.cardStatus = '已掌握';
    }

    this.showAnswer = false;
    this.currentCard++;
  }

  getIntervalPreview(rating: number): string {
    let days = this.intervalDays;
    if (rating === 3) days = Math.round(days * this.easeFactor);
    if (rating === 5) days = Math.round(days * this.easeFactor * 1.3);
    if (days < 1) return '10分钟';
    if (days === 1) return '1天';
    if (days < 30) return `${days}天`;
    return `${Math.round(days / 30)}月`;
  }

  getAccuracy(): number {
    if (this.studySession.total === 0) return 0;
    return Math.round((this.studySession.good + this.studySession.easy) / this.studySession.total * 100);
  }
}

interface CardItem {
  front: string;
  back: string;
}

interface RatingBtn {
  value: number;
  label: string;
  color: string;
  nextInterval: string;
}

interface SessionStats {
  total: number;
  again: number;
  hard: number;
  good: number;
  easy: number;
}
