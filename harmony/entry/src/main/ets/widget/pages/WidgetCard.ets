let storage = new LocalStorage();

@Entry(storage)
@Component
struct WidgetCard {
  @LocalStorageProp('formId') formId: string = '';
  @LocalStorageProp('siteName') siteName: string = '\u667a\u6167\u5de5\u5730';
  @LocalStorageProp('onlineMonitors') onlineMonitors: string = '12/13';
  @LocalStorageProp('temperature') temperature: string = '31.06 C';
  @LocalStorageProp('humidity') humidity: string = '48.03%';
  @LocalStorageProp('workers') workers: string = '86';
  @LocalStorageProp('alerts') alerts: string = '2';
  @LocalStorageProp('refreshTime') refreshTime: string = '--:--';
  @LocalStorageProp('updateSource') updateSource: string = '\u534e\u4e3a\u4e91';

  build() {
    Column() {
      Row() {
        Text(this.siteName)
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#172033')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Blank()
        Text(`${this.alerts} \u6761\u544a\u8b66`)
          .fontSize(12)
          .fontWeight(FontWeight.Bold)
          .fontColor('#C2410C')
      }
      .width('100%')

      Row() {
        this.WidgetMetric('Temp', this.temperature, '#E35D2F')
        this.WidgetMetric('Humi', this.humidity, '#1769E0')
      }
      .width('100%')
      .margin({ top: 14 })

      Row() {
        this.WidgetMetric('\u5de5\u4eba', this.workers, '#1769E0')
        this.WidgetMetric('\u76d1\u63a7', this.onlineMonitors, '#0E9F6E')
      }
      .width('100%')
      .margin({ top: 10 })

      Row() {
        Text(`${this.updateSource} ${this.refreshTime}`)
          .fontSize(10)
          .fontColor('#697386')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Blank()
        Text('\u5237\u65b0')
          .fontSize(12)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FFFFFF')
          .padding({ left: 12, right: 12, top: 5, bottom: 5 })
          .borderRadius(14)
          .backgroundColor('#1769E0')
          .onClick(() => {
            postCardAction(this, {
              action: 'message',
              params: {
                event: 'refresh',
                formId: this.formId
              }
            });
          })
      }
      .width('100%')
      .margin({ top: 14 })
      .alignItems(VerticalAlign.Center)
    }
    .width('100%')
    .height('100%')
    .padding(16)
    .borderRadius(18)
    .backgroundColor('#F5FAFF')
    .justifyContent(FlexAlign.SpaceBetween)
    .onClick(() => {
      postCardAction(this, {
        action: 'call',
        abilityName: 'EntryAbility',
        params: {
          source: 'smart_site_widget',
          formId: this.formId
        }
      });
    })
  }

  @Builder
  WidgetMetric(label: string, value: string, color: string) {
    Column() {
      Text(label)
        .fontSize(10)
        .fontColor('#697386')
      Text(value)
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor(color)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .margin({ top: 3 })
    }
    .layoutWeight(1)
    .alignItems(HorizontalAlign.Start)
  }
}
