// AI生成 - ArkTS 版 StudyMate Pro：EntryAbility
import { UIAbility, Want, AbilityConstant } from '@kit.AbilityKit';
import { window } from '@kit.ArkUI';

export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    console.info('StudyMate Pro EntryAbility onCreate');
  }

  onDestroy(): void {
    console.info('StudyMate Pro EntryAbility onDestroy');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    windowStage.loadContent('pages/Index', (err) => {
      if (err.code) {
        console.error(`Failed to load content: ${JSON.stringify(err)}`);
        return;
      }
      console.info('StudyMate Pro window loaded');
    });
  }

  onWindowStageDestroy(): void {
    console.info('StudyMate Pro onWindowStageDestroy');
  }

  onForeground(): void {
    console.info('StudyMate Pro onForeground');
  }

  onBackground(): void {
    console.info('StudyMate Pro onBackground');
  }
}
