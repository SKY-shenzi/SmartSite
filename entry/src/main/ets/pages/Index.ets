import { http } from '@kit.NetworkKit';
import socket from '@ohos.net.socket';
import image from '@ohos.multimedia.image';
import webview from '@ohos.web.webview';
import { CEMENT_IOTDA_CONFIG, WOOD_IOTDA_CONFIG, buildDeviceShadowPath, IotdaConfig } from '../common/IotdaConfig';
import { SUPABASE_CONFIG } from '../common/SupabaseConfig';
import { DIFY_CONFIG } from '../common/DifyConfig';
import { MATERIAL_DATABASE_CONFIG, buildMaterialRecordsPath } from '../common/MaterialDatabaseConfig';

interface ShadowData {
  properties: Record<string, Object>;
  eventTime: string;
  version: string;
}

interface SocketMessage {
  message: ArrayBuffer;
  remoteInfo: socket.SocketRemoteInfo;
}

interface SupabaseUserRow {
  id: number;
  username: string;
  password: string;
  real_name: string;
  role: string;
  team_name: string;
  phone: string;
}

interface AttendanceTaskRow {
  id: number;
  title: string;
  work_date: string;
  checkin_start: string;
  checkin_end: string;
  checkout_start: string;
  checkout_end: string;
  target_team: string;
  status: string;
  created_by: number;
  created_at: string;
}

interface AttendanceRecordRow {
  id: number;
  task_id: number;
  worker_id: number;
  checkin_time: string;
  checkout_time: string;
  checkin_status: string;
  checkout_status: string;
  work_minutes: number;
}

interface DifyChatResponse {
  answer: string;
  conversation_id: string;
}

interface DifyChatRequest {
  inputs: Record<string, Object>;
  query: string;
  response_mode: string;
  conversation_id: string;
  user: string;
}

interface MaterialSensorRecord {
  id: number;
  zone_code: string;
  zone_name: string;
  device_id: string;
  temp: number;
  humi: number;
  dist: number;
  lumi: number;
  lamp_status: string;
  shadow_version: string;
  created_at: string;
}

interface MaterialHistoryResponse {
  records: Array<MaterialSensorRecord>;
  count: number;
}

interface MaterialZone {
  id: string;
  zone_code: string;
  zone_name: string;
  material_type: string;
  manager_name: string;
  manager_phone: string;
  temp_min: number;
  temp_max: number;
  humi_min: number;
  humi_max: number;
  fan_auto_enabled: boolean;
  alarm_enabled: boolean;
}

interface MaterialZonesResponse {
  zones: Array<MaterialZone>;
  count: number;
}

interface MaterialAlertEvent {
  id: string;
  zone_code: string;
  metric_code: string;
  metric_name: string;
  actual_value: number;
  min_value: number;
  max_value: number;
  severity: string;
  status: string;
  message: string;
  created_at: string;
}

interface MaterialAlertsResponse {
  alerts: Array<MaterialAlertEvent>;
  count: number;
}

interface DigitalTwinAsset {
  id: string;
  asset_code: string;
  asset_name: string;
  asset_type: string;
  zone_code: string;
  model_type: string;
  status: string;
  data_source: string;
}

interface DigitalTwinAssetsResponse {
  assets: Array<DigitalTwinAsset>;
  count: number;
}

interface CommandParas {
  FanSt?: string;
  fan?: string;
}

@Entry
@Component
struct Index {
  @State isLoggedIn: boolean = false;
  @State loginRole: string = 'admin';
  @State currentRole: string = 'admin';
  @State username: string = '';
  @State password: string = '';
  @State loginError: string = '';
  @State activeTab: string = 'home';
  @State uiPulse: boolean = false;
  @State navTouchKey: string = '';
  @State aiPressed: boolean = false;

  @State syncing: boolean = false;
  @State cloudStatus: string = '\u534e\u4e3a\u4e91\u5f85\u540c\u6b65';
  @State lastSync: string = '--:--';
  @State shadowVersion: string = '--';
  @State refreshTick: number = 0;
  @State tempValue: string = '--';
  @State humiValue: string = '--';
  @State distValue: string = '--';
  @State lumiValue: string = '--';
  @State lampValue: string = '--';
  @State cementFanSt: string = '--';
  @State commandStatus: string = '';
  @State commandSending: boolean = false;
  @State woodTempValue: string = '--';
  @State woodHumiValue: string = '--';
  @State woodLumiValue: string = '--';
  @State woodSmokeValue: string = '--';
  @State woodFanSt: string = '--';
  @State woodCommandStatus: string = '';
  @State woodCommandSending: boolean = false;
  @State woodBuzzerSt: string = '--';
  @State woodCo2Value: string = '--';
  @State woodShadowVersion: string = '--';
  @State woodCloudStatus: string = '\u6728\u6750\u533a\u5f85\u540c\u6b65';

  @State workerHasTask: boolean = false;
  @State workerCheckInTime: string = '';
  @State workerCheckOutTime: string = '';
  @State workerWorkDuration: string = '0h 0m 0s';
  @State workerCheckInTimestamp: string = '';
  @State workerCheckOutTimestamp: string = '';
  @State currentUserName: string = '';
  @State attendanceRecordSummary: string = '\u6682\u65e0\u6253\u5361\u8bb0\u5f55';
  @State attendanceRecordCount: number = 0;
  @State attendanceTaskName: string = '\u667a\u6167\u5de5\u5730\u9879\u76ee';
  @State attendanceTaskWindow: string = '07:30 - 09:00';
  @State attendancePublishedAt: string = '--:--';
  @State attendanceCloudStatus: string = '\u6253\u5361\u5f85\u540c\u6b65';

  @State cameraIpAddress: string = '192.168.43.137';
  @State cameraPort: string = '8080';
  @State cameraConnected: boolean = false;
  @State cameraStatus: string = '\u6444\u50cf\u5934\u5f85\u8fde\u63a5';
  @State cameraFrame: PixelMap | null = null;
  @State cloudVideoHost: string = '39.107.224.246';
  @State cloudVideoRtspPort: string = '8554';
  @State cloudVideoHlsPort: string = '8888';
  @State cloudVideoStreamName: string = 'livecam';
  @State cloudVideoStatus: string = '\u4e91\u89c6\u9891\u5f85\u8fde\u63a5';
  @State assistantOpen: boolean = false;
  @State assistantInput: string = '';
  @State assistantSending: boolean = false;
  @State assistantChatLog: string = '\u667a\u6167\u5de5\u5730\u52a9\u624b: \u4f60\u597d\uff0c\u6211\u53ef\u4ee5\u5e2e\u4f60\u67e5\u8be2\u6253\u5361\u3001\u6750\u6599\u76d1\u6d4b\u3001\u6444\u50cf\u5934\u548c\u8fd0\u7ef4\u95ee\u9898\u3002';
  @State assistantConversationId: string = '';
  @State materialHistoryOpen: boolean = false;
  @State materialHistoryLoading: boolean = false;
  @State materialHistoryStatus: string = '\u91d1\u4ed3\u5386\u53f2\u5f85\u52a0\u8f7d';
  @State materialHistoryZoneCode: string = 'cement_zone';
  @State materialHistoryZoneName: string = '\u6c34\u6ce5\u533a';
  @State materialHistoryRecords: Array<MaterialSensorRecord> = [];
  @State materialRecordCount: number = 0;
  @State materialTwinOpen: boolean = false;
  @State materialTwinLoading: boolean = false;
  @State materialTwinStatus: string = '\u6570\u5b57\u5b6a\u751f\u5f85\u540c\u6b65';
  @State materialZones: Array<MaterialZone> = [];
  @State materialAlerts: Array<MaterialAlertEvent> = [];
  @State twinAssets: Array<DigitalTwinAsset> = [];
  @State materialTwinLatestRecords: Array<MaterialSensorRecord> = [];
  @State materialTwinLatestRecord: MaterialSensorRecord | null = null;

  private refreshTimer: number = -1;
  private workTimer: number = -1;
  private lastMaterialSaveTime: number = 0;
  private chartSettings: RenderingContextSettings = new RenderingContextSettings(true);
  private materialChartContext: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.chartSettings);
  private tcpSocket: socket.TCPSocket | null = null;
  private cameraBuffer: Uint8Array = new Uint8Array(0);
  private cloudVideoController: webview.WebviewController = new webview.WebviewController();
  private thingjsController: webview.WebviewController = new webview.WebviewController();
  private currentUserId: number = -1;
  private currentUserTeam: string = '';
  private workerCloudId: number = 2;
  private currentAttendanceTaskId: number = -1;
  private attendanceSyncing: boolean = false;

  aboutToAppear(): void {
    this.uiPulse = true;
    this.startAutoRefresh();
    this.startWorkTimer();
  }

  aboutToDisappear(): void {
    this.stopAutoRefresh();
    this.stopWorkTimer();
    this.disconnectCamera();
  }

  build() {
    if (!this.isLoggedIn) {
      this.PixelLoginPage()
    } else {
      Stack({ alignContent: Alignment.BottomEnd }) {
        Column() {
          this.PixelAppHeader()

          if (this.assistantOpen) {
            this.AssistantPage()
          } else if (this.currentRole === 'worker') {
            this.WorkerPage()
          } else {
            Column() {
              if (this.activeTab === 'home') {
                this.AdminHomePage()
              } else if (this.activeTab === 'env') {
                this.EnvironmentPage()
              } else if (this.activeTab === 'monitor') {
                this.MonitorPage()
              } else if (this.activeTab === 'attendance') {
                this.AttendancePage()
              } else {
                this.WorkHourPage()
              }
            }
            .layoutWeight(1)
            .width('100%')
            .animation({ duration: 220, curve: Curve.EaseOut })

            this.PixelBottomNavigation()
          }
        }
        .width('100%')
        .height('100%')
        .backgroundColor('#F7E7B7')

        if (!this.assistantOpen) {
          this.AssistantFloatButton()
        }
      }
      .width('100%')
      .height('100%')
    }
  }

  @Builder
  PixelLoginPage() {
    Stack() {
      Column() {
        this.PixelGroundBand('#F8C02E', 0)
        this.PixelGroundBand('#343434', 18)
        Blank()
      }
      .width('100%')
      .height('100%')
      .alignItems(HorizontalAlign.Start)

      Column() {
        Image($r('app.media.smart_site_pixel_icon'))
          .width(92)
          .height(92)
          .borderRadius(18)
          .border({ width: 3, color: '#1F1F1F' })
          .shadow({ radius: 0, color: '#1F1F1F', offsetX: 5, offsetY: 5 })
          .margin({ bottom: 16 })
          .scale({ x: this.uiPulse ? 1 : 0.96, y: this.uiPulse ? 1 : 0.96 })
          .animation({ duration: 260, curve: Curve.EaseOut })

        Text('\u667a\u6167\u5de5\u5730')
          .fontSize(32)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1F1F1F')
        Text('\u50cf\u7d20\u5de5\u5730 - \u5b9e\u65f6\u6570\u636e - \u73b0\u573a\u7ba1\u63a7')
          .fontSize(13)
          .fontColor('#6B4B16')
          .margin({ top: 8 })

        Row() {
          this.PixelRoleButton('worker', '\u5de5\u4eba')
          this.PixelRoleButton('admin', '\u7ba1\u7406')
        }
        .alignItems(VerticalAlign.Center)
        .width('100%')
        .height(44)
        .padding(4)
        .borderRadius(6)
        .border({ width: 2, color: '#1F1F1F' })
        .backgroundColor('#F9D36A')
        .margin({ top: 26 })

        TextInput({ placeholder: 'Password' })
          .width('100%')
          .height(48)
          .fontSize(15)
          .backgroundColor('#FFF8E1')
          .borderRadius(6)
          .border({ width: 2, color: '#2D2D2D' })
          .margin({ top: 22 })
          .onChange((value: string) => {
            this.username = value;
            this.loginError = '';
          })

        TextInput({ placeholder: 'Password' })
          .type(InputType.Password)
          .width('100%')
          .height(48)
          .fontSize(15)
          .backgroundColor('#FFF8E1')
          .borderRadius(6)
          .border({ width: 2, color: '#2D2D2D' })
          .margin({ top: 12 })
          .onChange((value: string) => {
            this.password = value;
            this.loginError = '';
          })

        if (this.loginError !== '') {
          Text(this.loginError)
            .fontSize(12)
            .fontColor('#B42318')
            .margin({ top: 10 })
            .width('100%')
        }

        Button('\u8fdb\u5165')
          .width('100%')
          .height(50)
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1F1F1F')
          .backgroundColor('#F8C02E')
          .borderRadius(6)
          .border({ width: 3, color: '#1F1F1F' })
          .shadow({ radius: 0, color: '#1F1F1F', offsetX: 4, offsetY: 4 })
          .margin({ top: 22 })
          .hoverEffect(HoverEffect.Scale)
          .onClick(() => {
            animateTo({ duration: 180, curve: Curve.EaseOut }, () => {
              this.login();
            });
          })

        Text('\u6d4b\u8bd5\u8d26\u53f7: worker / 123456, admin / 123456')
          .fontSize(12)
          .fontColor('#72531B')
          .textAlign(TextAlign.Center)
          .lineHeight(18)
          .margin({ top: 16 })
      }
      .width('88%')
      .padding(22)
      .borderRadius(8)
      .border({ width: 3, color: '#1F1F1F' })
      .backgroundColor('#FFF2C5')
      .shadow({ radius: 0, color: '#1F1F1F', offsetX: 6, offsetY: 6 })
      .alignItems(HorizontalAlign.Center)
    }
    .width('100%')
    .height('100%')
    .alignContent(Alignment.Center)
    .backgroundColor('#F7E7B7')
  }

  @Builder
  PixelGroundBand(color: string, top: number) {
    Row() {}
      .width('100%')
      .height(16)
      .backgroundColor(color)
      .margin({ top: top })
  }

  @Builder
  PixelRoleButton(role: string, label: string) {
    Text(label)
      .fontSize(14)
      .fontWeight(FontWeight.Bold)
      .fontColor('#1F1F1F')
      .textAlign(TextAlign.Center)
      .layoutWeight(1)
      .height(34)
      .borderRadius(4)
      .border({ width: this.loginRole === role ? 2 : 0, color: '#1F1F1F' })
      .backgroundColor(this.loginRole === role ? '#FFFFFF' : '#F9D36A')
      .hoverEffect(HoverEffect.Scale)
      .onClick(() => {
        animateTo({ duration: 160, curve: Curve.EaseOut }, () => {
          this.loginRole = role;
          this.loginError = '';
        });
      })
  }

  @Builder
  LoginPage() {
    Column() {
      Blank()
      Column() {
        Text('\u667a\u6167\u5de5\u5730')
          .fontSize(32)
          .fontWeight(FontWeight.Bold)
          .fontColor('#172033')
        Text('\u5de5\u5730\u5b89\u5168\u4e0e\u6750\u6599\u73af\u5883\u7ba1\u7406')
          .fontSize(14)
          .fontColor('#697386')
          .margin({ top: 8 })

        Row() {
          this.RoleButton('worker', '\u5de5\u4eba')
          this.RoleButton('admin', '\u7ba1\u7406')
        }
        .alignItems(VerticalAlign.Center)
        .width('100%')
        .height(42)
        .padding(4)
        .borderRadius(10)
        .backgroundColor('#EEF3F8')
        .margin({ top: 28 })

        TextInput({ placeholder: 'Password' })
          .width('100%')
          .height(48)
          .fontSize(15)
          .backgroundColor('#F4F7FB')
          .margin({ top: 22 })
          .onChange((value: string) => {
            this.username = value;
            this.loginError = '';
          })

        TextInput({ placeholder: 'Password' })
          .type(InputType.Password)
          .width('100%')
          .height(48)
          .fontSize(15)
          .backgroundColor('#F4F7FB')
          .margin({ top: 12 })
          .onChange((value: string) => {
            this.password = value;
            this.loginError = '';
          })

        if (this.loginError !== '') {
          Text(this.loginError)
            .fontSize(12)
            .fontColor('#C2410C')
            .margin({ top: 10 })
            .width('100%')
        }

        Button('\u767b\u5f55')
          .width('100%')
          .height(48)
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .backgroundColor('#1769E0')
          .margin({ top: 22 })
          .onClick(() => {
            this.login();
          })

        Text('\u6d4b\u8bd5\u8d26\u53f7: worker / 123456, admin / 123456')
          .fontSize(12)
          .fontColor('#697386')
          .textAlign(TextAlign.Center)
          .lineHeight(18)
          .margin({ top: 16 })
      }
      .width('88%')
      .padding(22)
      .borderRadius(14)
      .backgroundColor('#FFFFFF')
      .alignItems(HorizontalAlign.Center)
      Blank()
    }
    .width('100%')
    .height('100%')
    .alignItems(HorizontalAlign.Center)
    .backgroundColor('#F4F7FB')
  }

  @Builder
  RoleButton(role: string, label: string) {
    Text(label)
      .fontSize(14)
      .fontWeight(this.loginRole === role ? FontWeight.Bold : FontWeight.Regular)
      .fontColor(this.loginRole === role ? '#1769E0' : '#697386')
      .textAlign(TextAlign.Center)
      .layoutWeight(1)
      .height(34)
      .borderRadius(8)
      .backgroundColor(this.loginRole === role ? '#FFFFFF' : '#EEF3F8')
      .onClick(() => {
        this.loginRole = role;
        this.loginError = '';
      })
  }

  @Builder
  AssistantFloatButton() {
    Button('AI')
      .width(62)
      .height(62)
      .borderRadius(8)
      .fontSize(18)
      .fontWeight(FontWeight.Bold)
      .fontColor('#1F1F1F')
      .backgroundColor('#F8C02E')
      .border({ width: 3, color: '#1F1F1F' })
      .margin({ right: 18, bottom: this.currentRole === 'worker' ? 24 : 82 })
      .shadow({ radius: 0, color: '#1F1F1F', offsetX: this.aiPressed ? 2 : 5, offsetY: this.aiPressed ? 2 : 5 })
      .scale({ x: this.aiPressed ? 0.95 : 1, y: this.aiPressed ? 0.95 : 1 })
      .hoverEffect(HoverEffect.Scale)
      .animation({ duration: 140, curve: Curve.EaseOut })
      .onTouch((event: TouchEvent) => {
        if (event.type === TouchType.Down) {
          this.aiPressed = true;
        }
        if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
          this.aiPressed = false;
        }
      })
      .onClick(() => {
        animateTo({ duration: 180, curve: Curve.EaseOut }, () => {
          this.assistantOpen = true;
        });
      })
  }

  @Builder
  AssistantPage() {
    Column() {
      Row() {
        Column() {
          Text('\u667a\u6167\u5de5\u5730\u52a9\u624b')
            .fontSize(22)
            .fontWeight(FontWeight.Bold)
            .fontColor('#172033')
          Text('Dify \u52a9\u624b')
            .fontSize(13)
            .fontColor('#697386')
            .margin({ top: 4 })
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        Button('\u8fd4\u56de')
          .height(34)
          .fontSize(13)
          .fontColor('#1769E0')
          .backgroundColor('#EAF2FF')
          .onClick(() => {
            this.assistantOpen = false;
          })
      }
      .width('100%')

      Scroll() {
        Text(this.assistantChatLog)
          .fontSize(14)
          .fontColor('#172033')
          .lineHeight(24)
          .width('100%')
          .padding(16)
          .borderRadius(10)
          .backgroundColor('#FFFFFF')
      }
      .layoutWeight(1)
      .width('100%')
      .margin({ top: 16 })

      Row() {
        TextInput({ placeholder: 'Type a question', text: this.assistantInput })
          .layoutWeight(1)
          .height(46)
          .fontSize(14)
          .backgroundColor('#FFFFFF')
          .onChange((value: string) => {
            this.assistantInput = value;
          })
        Button(this.assistantSending ? '\u53d1\u9001\u4e2d' : '\u53d1\u9001')
          .height(46)
          .fontSize(15)
          .fontWeight(FontWeight.Bold)
          .backgroundColor(this.assistantSending ? '#94A3B8' : '#1769E0')
          .margin({ left: 10 })
          .enabled(!this.assistantSending)
          .onClick(() => {
            this.sendAssistantMessage();
          })
      }
      .width('100%')
      .margin({ top: 14 })
    }
    .layoutWeight(1)
    .width('100%')
    .padding({ left: 16, right: 16, top: 18, bottom: 18 })
    .backgroundColor('#F4F7FB')
  }

  @Builder
  PixelAppHeader() {
    Column() {
      Row() {
        Image($r('app.media.smart_site_pixel_icon'))
          .width(44)
          .height(44)
          .borderRadius(8)
          .border({ width: 2, color: '#1F1F1F' })
          .shadow({ radius: 0, color: '#1F1F1F', offsetX: 3, offsetY: 3 })
          .margin({ right: 12 })

        Column() {
          Text('\u667a\u6167\u5de5\u5730')
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
            .fontColor('#1F1F1F')
          Text(this.currentRole === 'worker' ? '\u5de5\u4eba' : '\u7ba1\u7406')
            .fontSize(12)
            .fontColor('#6B4B16')
            .margin({ top: 4 })
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        Text(this.currentRole === 'worker' ? '\u5de5\u4eba' : '\u7ba1\u7406')
          .fontSize(11)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1F1F1F')
          .padding({ left: 10, right: 10, top: 6, bottom: 6 })
          .borderRadius(4)
          .border({ width: 2, color: '#1F1F1F' })
          .backgroundColor('#F8C02E')

        Button('\u9000\u51fa')
          .height(32)
          .fontSize(12)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1F1F1F')
          .backgroundColor('#FFE1D6')
          .borderRadius(4)
          .border({ width: 2, color: '#1F1F1F' })
          .margin({ left: 8 })
          .hoverEffect(HoverEffect.Scale)
          .onClick(() => {
            animateTo({ duration: 160, curve: Curve.EaseOut }, () => {
              this.logout();
            });
          })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 16, bottom: 12 })

      Row() {
        ForEach([0, 1, 2, 3, 4, 5], (item: number) => {
          Row() {}
            .width(26)
            .height(8)
            .backgroundColor(item % 2 === 0 ? '#1F1F1F' : '#F8C02E')
        })
      }
      .width('100%')
      .height(8)
      .clip(true)
    }
    .width('100%')
    .backgroundColor('#FFF2C5')
    .border({ width: { bottom: 3 }, color: '#1F1F1F' })
  }

  @Builder
  AppHeader() {
    Row() {
      Column() {
        Text('\u667a\u6167\u5de5\u5730')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor('#172033')
        Text(this.currentRole === 'worker' ? '\u5de5\u4eba\u7aef - \u6253\u5361' : '\u7ba1\u7406\u7aef - \u5de5\u5730\u7ba1\u63a7')
          .fontSize(13)
          .fontColor('#697386')
          .margin({ top: 5 })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      Text(this.currentRole === 'worker' ? '\u5de5\u4eba' : '\u7ba1\u7406')
        .fontSize(12)
        .fontWeight(FontWeight.Bold)
        .fontColor('#1769E0')
        .padding({ left: 12, right: 12, top: 6, bottom: 6 })
        .borderRadius(14)
        .backgroundColor('#EAF2FF')

      Button('\u9000\u51fa')
        .height(30)
        .fontSize(12)
        .fontColor('#C2410C')
        .backgroundColor('#FEEDE8')
        .margin({ left: 8 })
        .onClick(() => {
          this.logout();
        })
    }
    .width('100%')
    .padding({ left: 18, right: 18, top: 20, bottom: 14 })
    .backgroundColor('#FFFFFF')
  }

  @Builder
  AdminHomePage() {
    Scroll() {
      Column() {
        this.CloudStatusCard()
        this.TodayBoard()
        this.CementZoneCard()
        this.WoodZoneLiveCard()
        this.MonitorSummaryCard()
        this.AttendanceOverviewCard()
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 16, bottom: 24 })
    }
    .layoutWeight(1)
    .width('100%')
  }

  @Builder
  CloudStatusCard() {
    Column() {
      Row() {
        Column() {
          Text('\u534e\u4e3a\u4e91 IoTDA')
            .fontSize(17)
            .fontWeight(FontWeight.Bold)
            .fontColor('#172033')
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        Text(this.cloudStatus)
          .fontSize(12)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.getCloudColor())
          .padding({ left: 10, right: 10, top: 5, bottom: 5 })
          .borderRadius(14)
          .backgroundColor(this.getCloudBg())
      }
      .width('100%')

      Row() {
        Text('\u540c\u6b65 ' + this.lastSync)
          .fontSize(12)
          .fontColor('#4B5563')
        Blank()
        Text(this.cloudStatus)
          .fontSize(12)
          .fontColor('#4B5563')
      }
      .width('100%')
      .margin({ top: 12 })
    }
    .width('100%')
    .padding(16)
    .borderRadius(10)
    .backgroundColor('#FFFFFF')
  }

  @Builder
  TodayBoard() {
    Column() {
      Row() {
        Text('\u4eca\u65e5\u770b\u677f')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor('#172033')
        Blank()
        Text(this.getCementStatus())
          .fontSize(12)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.getCementColor())
      }
      .width('100%')
      .margin({ bottom: 12 })

      Grid() {
        GridItem() {
          this.MetricCard('\u6c34\u6ce5\u533a\u6e29\u5ea6', this.withUnit(this.tempValue, 'C'), '#E35D2F')
        }
        GridItem() {
          this.MetricCard('\u6c34\u6ce5\u533a\u6e7f\u5ea6', this.withUnit(this.humiValue, '%'), '#1769E0')
        }
        GridItem() {
          this.MetricCard('\u6c34\u6ce5\u533a\u98ce\u6247', this.getCementFanPlan(), '#4B5563')
        }
        GridItem() {
          this.MetricCard('\u6728\u6750\u533a\u6e29\u5ea6', this.withUnit(this.woodTempValue, 'C'), '#D97706')
        }
      }
      .columnsTemplate('1fr 1fr')
      .rowsGap(12)
      .columnsGap(12)
      .width('100%')
    }
    .width('100%')
    .margin({ top: 16 })
  }

  @Builder
  MetricCard(title: string, value: string, color: string) {
    Column() {
      Row() {
        Row() {}
          .width(18)
          .height(8)
          .backgroundColor('#F8C02E')
        Row() {}
          .width(18)
          .height(8)
          .backgroundColor('#1F1F1F')
        Row() {}
          .width(18)
          .height(8)
          .backgroundColor('#F8C02E')
      }
      .height(8)
      .margin({ bottom: 10 })

      Text(title)
        .fontSize(13)
        .fontWeight(FontWeight.Bold)
        .fontColor('#4B5563')
        .maxLines(1)
      Text(value)
        .fontSize(26)
        .fontWeight(FontWeight.Bold)
        .fontColor(color)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .margin({ top: 10 })
    }
    .width('100%')
    .height(104)
    .padding(14)
    .borderRadius(6)
    .border({ width: 2, color: '#1F1F1F' })
    .backgroundColor('#FFF8E1')
    .shadow({ radius: 0, color: '#1F1F1F', offsetX: 3, offsetY: 3 })
    .hoverEffect(HoverEffect.Scale)
    .animation({ duration: 160, curve: Curve.EaseOut })
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  CementZoneCard() {
    Column() {
      Row() {
        Column() {
          Text('\u6c34\u6ce5\u533a')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor('#172033')
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        Text(this.getCementStatus())
          .fontSize(12)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.getCementColor())
      }
      .width('100%')

      Row() {
        this.SensorBlock('Temp', '\u6e29\u5ea6', this.withUnit(this.tempValue, 'C'), '#E35D2F')
        this.SensorBlock('Humi', '\u6e7f\u5ea6', this.withUnit(this.humiValue, '%'), '#1769E0')
      }
      .width('100%')
      .margin({ top: 16 })

      Row() {
        this.SensorBlock('Fan', '\u98ce\u6247\u7b56\u7565', this.getCementFanPlan(), '#4B5563')
        this.SensorBlock('Alarm', '\u6e7f\u5ea6\u62a5\u8b66', this.getCementAlarmPlan(), '#C2410C')
        this.SensorBlock('LampST', '\u706f\u5149', this.lampValue, '#0E9F6E')
      }
      .width('100%')
      .margin({ top: 12 })

      this.FanCommandPanel()

    }
    .width('100%')
    .padding(16)
    .borderRadius(10)
    .backgroundColor('#FFFFFF')
    .margin({ top: 16 })
    .onClick(() => {
      this.openMaterialHistory('cement_zone');
    })
  }

  @Builder
  FanCommandPanel() {
    Row() {
      Column() {
        Text('\u98ce\u6247\u63a7\u5236')
          .fontSize(12)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1F1F1F')
        Text('\u5f53\u524d: ' + (this.cementFanSt === '--' ? '\u672a\u77e5' : this.cementFanSt))
          .fontSize(11)
          .fontColor(this.cementFanSt === 'ON' ? '#E35D2F' : '#4B5563')
          .margin({ top: 4 })
        if (this.commandStatus !== '') {
          Text(this.commandStatus)
            .fontSize(10)
            .fontColor(this.commandStatus.toLowerCase().includes('failed') || this.commandStatus.includes('\u5931\u8d25') ? '#C2410C' : '#0E9F6E')
            .margin({ top: 4 })
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      this.FanCommandButton('ON', '#E35D2F', '#FEEDE8')
      this.FanCommandButton('OFF', '#4B5563', '#EEF3F8')
    }
    .width('100%')
    .padding({ left: 12, right: 12, top: 10, bottom: 10 })
    .margin({ top: 12 })
    .borderRadius(6)
    .border({ width: 2, color: '#1F1F1F' })
    .backgroundColor('#FFF8E1')
    .alignItems(VerticalAlign.Center)
  }

  @Builder
  FanCommandButton(state: string, color: string, bgColor: string) {
    Button(state)
      .height(32)
      .fontSize(12)
      .fontWeight(FontWeight.Bold)
      .fontColor(color)
      .backgroundColor(bgColor)
      .borderRadius(4)
      .border({ width: 2, color: '#1F1F1F' })
      .margin({ left: 8 })
      .enabled(!this.commandSending)
      .hoverEffect(HoverEffect.Scale)
      .onClick(() => {
        const params: CommandParas = { FanSt: state };
        this.sendCementFanCommand(state, params);
      })
  }

  @Builder
  WoodZoneLiveCard() {
    Column() {
      Row() {
        Column() {
          Text('\u6728\u6750\u533a')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor('#172033')
          Text('IoTDA \u5b9e\u65f6\u5f71\u5b50\u6570\u636e')
            .fontSize(12)
            .fontColor('#697386')
            .margin({ top: 5 })
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        Text(this.woodCloudStatus)
          .fontSize(12)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.woodCloudStatus.toLowerCase().includes('failed') || this.woodCloudStatus.includes('\u5931\u8d25') ? '#C2410C' : '#0E9F6E')
          .padding({ left: 10, right: 10, top: 5, bottom: 5 })
          .borderRadius(14)
          .backgroundColor(this.woodCloudStatus.toLowerCase().includes('failed') || this.woodCloudStatus.includes('\u5931\u8d25') ? '#FEEDE8' : '#E8F7EF')
      }
      .width('100%')

      Row() {
        this.SensorBlock('Temp', '\u6e29\u5ea6', this.withUnit(this.woodTempValue, 'C'), '#E35D2F')
        this.SensorBlock('Humi', '\u6e7f\u5ea6', this.withUnit(this.woodHumiValue, '%'), '#1769E0')
      }
      .width('100%')
      .margin({ top: 16 })

      Row() {
        this.SensorBlock('Lumi', '\u4eae\u5ea6', this.woodLumiValue, '#D97706')
        this.SensorBlock('CO2', '\u4e8c\u6c27\u5316\u78b3', this.woodCo2Value, '#8B5CF6')
        this.SensorBlock('Smoke', '\u70df\u96fe', this.woodSmokeValue, '#C2410C')
      }
      .width('100%')
      .margin({ top: 12 })

      Row() {
        this.SensorBlock('Fan', '\u98ce\u6247', this.woodFanSt, '#4B5563')
        this.SensorBlock('\u8702\u9e23\u5668', '\u8702\u9e23\u5668', this.woodBuzzerSt, '#C2410C')
        Column().layoutWeight(1)
      }
      .width('100%')
      .margin({ top: 12 })

      Row() {
        Column() {
          Text('\u98ce\u6247\u63a7\u5236')
            .fontSize(12)
            .fontWeight(FontWeight.Bold)
            .fontColor('#172033')
          Text('\u5f53\u524d: ' + (this.woodFanSt === '--' ? '\u672a\u77e5' : this.woodFanSt))
            .fontSize(11)
            .fontColor(this.woodFanSt === 'ON' ? '#E35D2F' : '#4B5563')
            .margin({ top: 4 })
          if (this.woodCommandStatus !== '') {
            Text(this.woodCommandStatus)
              .fontSize(10)
              .fontColor(this.woodCommandStatus.toLowerCase().includes('failed') || this.woodCommandStatus.includes('\u5931\u8d25') ? '#C2410C' : '#0E9F6E')
              .margin({ top: 4 })
          }
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        this.WoodFanCommandButton('ON', '#E35D2F', '#FEEDE8')
        this.WoodFanCommandButton('OFF', '#4B5563', '#EEF3F8')
      }
      .width('100%')
      .margin({ top: 14 })
      .padding(12)
      .borderRadius(8)
      .backgroundColor('#FFF8E1')
      .alignItems(VerticalAlign.Center)
    }
    .width('100%')
    .padding(16)
    .borderRadius(10)
    .backgroundColor('#FFFFFF')
    .margin({ top: 16 })
    .onClick(() => {
      this.openMaterialHistory('timber_zone');
    })
  }

  @Builder
  WoodFanCommandButton(state: string, color: string, bgColor: string) {
    Button(state)
      .height(32)
      .fontSize(12)
      .fontWeight(FontWeight.Bold)
      .fontColor(color)
      .backgroundColor(bgColor)
      .borderRadius(4)
      .border({ width: 2, color: '#1F1F1F' })
      .margin({ left: 8 })
      .enabled(!this.woodCommandSending)
      .hoverEffect(HoverEffect.Scale)
      .onClick(() => {
        const params: CommandParas = { fan: state };
        this.sendWoodFanCommand(state, params);
      })
  }

  @Builder
  WoodZonePlanCard() {
    Column() {
      Row() {
        Column() {
          Text('\u6728\u6750\u533a')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor('#172033')
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        Text(this.woodCloudStatus)
          .fontSize(12)
          .fontWeight(FontWeight.Bold)
          .fontColor('#D97706')
          .padding({ left: 10, right: 10, top: 5, bottom: 5 })
          .borderRadius(14)
          .backgroundColor('#FFF7E6')
      }
      .width('100%')

      Row() {
        this.SensorBlock('Temp', '\u6e29\u5ea6', this.withUnit(this.woodTempValue, 'C'), '#E35D2F')
        this.SensorBlock('Humi', '\u6e7f\u5ea6', this.withUnit(this.woodHumiValue, '%'), '#1769E0')
      }
      .width('100%')
      .margin({ top: 16 })

      Row() {
        this.SensorBlock('Fan', '\u98ce\u6247\u7b56\u7565', '\u5f85\u5904\u7406', '#4B5563')
        this.SensorBlock('Alarm', '\u706b\u707e\u62a5\u8b66', '\u5f85\u5904\u7406', '#C2410C')
        this.SensorBlock('Smoke', 'Smoke', '\u5f85\u5904\u7406', '#D97706')
      }
      .width('100%')
      .margin({ top: 12 })

    }
    .width('100%')
    .padding(16)
    .borderRadius(10)
    .backgroundColor('#FFFFFF')
    .margin({ top: 16 })
    .onClick(() => {
      this.openMaterialHistory('timber_zone');
    })
  }

  @Builder
  SensorBlock(key: string, label: string, value: string, color: string) {
    Column() {
      Text(key)
        .fontSize(11)
        .fontColor('#94A3B8')
      Text(value)
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor(color)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .margin({ top: 5 })
      Text(label)
        .fontSize(11)
        .fontColor('#697386')
        .margin({ top: 4 })
    }
    .layoutWeight(1)
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  MonitorSummaryCard() {
    Column() {
      Row() {
        Text('\u73b0\u573a\u6444\u50cf\u5934')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#172033')
        Blank()
        Text(this.cameraStatus)
          .fontSize(12)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.cameraConnected ? '#0E9F6E' : '#697386')
      }
      .width('100%')

    }
    .width('100%')
    .padding(16)
    .borderRadius(10)
    .backgroundColor('#FFFFFF')
    .margin({ top: 16 })
  }

  @Builder
  UnfinishedCard(title: string, desc: string) {
    Column() {
      Row() {
        Text(title)
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#172033')
        Blank()
        Text('\u5f85\u5904\u7406')
          .fontSize(12)
          .fontWeight(FontWeight.Bold)
          .fontColor('#D97706')
          .padding({ left: 10, right: 10, top: 5, bottom: 5 })
          .borderRadius(14)
          .backgroundColor('#FFF7E6')
      }
      .width('100%')
      Text(desc)
        .fontSize(13)
        .fontColor('#697386')
        .lineHeight(20)
        .margin({ top: 10 })
    }
    .width('100%')
    .padding(16)
    .borderRadius(10)
    .backgroundColor('#FFFFFF')
    .margin({ top: 16 })
  }

  @Builder
  AttendanceOverviewCard() {
    Column() {
      Row() {
        Text('\u6253\u5361\u4efb\u52a1')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#172033')
        Blank()
        Text(this.workerHasTask ? '\u5df2\u53d1\u5e03' : '\u672a\u53d1\u5e03')
          .fontSize(12)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.workerHasTask ? '#0E9F6E' : '#D97706')
          .padding({ left: 10, right: 10, top: 5, bottom: 5 })
          .borderRadius(14)
          .backgroundColor(this.workerHasTask ? '#E8F7EF' : '#FFF7E6')
      }
      .width('100%')

      Row() {
        this.AttendanceStat('\u7b7e\u5230', this.workerCheckInTime === '' ? '--:--' : this.workerCheckInTime)
        this.AttendanceStat('\u7b7e\u9000', this.workerCheckOutTime === '' ? '--:--' : this.workerCheckOutTime)
        this.AttendanceStat('\u5de5\u65f6', this.workerWorkDuration)
      }
      .width('100%')
      .margin({ top: 14 })

      Text(this.workerHasTask ? '\u6253\u5361\u65f6\u95f4 ' + this.attendanceTaskWindow : '\u6682\u65e0\u6253\u5361\u4efb\u52a1\u3002')
        .fontSize(12)
        .fontColor('#697386')
        .lineHeight(18)
        .margin({ top: 10 })
    }
    .width('100%')
    .padding(16)
    .borderRadius(10)
    .backgroundColor('#FFFFFF')
    .margin({ top: 16 })
  }

  @Builder
  AttendanceStat(label: string, value: string) {
    Column() {
      Text(value)
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor('#1769E0')
        .maxLines(1)
      Text(label)
        .fontSize(11)
        .fontColor('#697386')
        .margin({ top: 4 })
    }
    .layoutWeight(1)
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  EnvironmentPage() {
    if (this.materialHistoryOpen) {
      this.MaterialHistoryPage()
    } else if (this.materialTwinOpen) {
      this.MaterialTwinPage()
    } else {
    Scroll() {
      Column() {
        this.EnvironmentHeader()
        this.CementZoneCard()
        this.WoodZoneLiveCard()
        this.UnfinishedCard('Other Areas', 'No board parameters yet, so demo data is hidden.')
      }
      .width('100%')
      .padding({ left: 16, right: 16, bottom: 24 })
    }
    .layoutWeight(1)
    }
  }

  @Builder
  EnvironmentHeader() {
    Row() {
      Column() {
        Text('\u6750\u6599\u5206\u533a')
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .fontColor('#172033')
      }
      .alignItems(HorizontalAlign.Start)
        this.ZonePill('\u6c34\u6ce5', 'cement_zone', this.materialHistoryZoneCode)
        this.ZonePill('\u6728\u6750', 'timber_zone', this.materialHistoryZoneCode)
      Button('3D')
        .width(46)
        .height(34)
        .fontSize(14)
        .fontWeight(FontWeight.Bold)
        .fontColor('#1769E0')
        .backgroundColor('#EAF2FF')
        .borderRadius(17)
        .onClick(() => {
          this.materialTwinOpen = true;
          this.loadMaterialTwin();
        })
    }
    .width('100%')
    .margin({ top: 18, bottom: 12 })
  }

  @Builder
  MaterialTwinEntryCard() {
    Column() {
      Row() {
        Column() {
          Text(this.materialHistoryZoneName + ' \u5386\u53f2\u8d8b\u52bf')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor('#172033')
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        Button('\u5b6a\u751f\u89c6\u56fe')
          .height(38)
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .backgroundColor('#0F766E')
          .onClick(() => {
            this.materialTwinOpen = true;
            this.loadMaterialTwin();
          })
      }
      .width('100%')
    }
    .width('100%')
    .padding(16)
    .borderRadius(10)
    .backgroundColor('#FFFFFF')
    .margin({ top: 12 })
  }

  @Builder
  MaterialHistoryEntryCard() {
    Column() {
      Row() {
        Column() {
          Text('\u91d1\u4ed3\u6750\u6599\u6570\u636e\u5e93')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor('#172033')
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        Button('\u5386\u53f2\u8d8b\u52bf')
          .height(38)
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .backgroundColor('#1769E0')
          .onClick(() => {
            this.materialHistoryOpen = true;
            this.loadMaterialHistory();
          })
      }
      .width('100%')
    }
    .width('100%')
    .padding(16)
    .borderRadius(10)
    .backgroundColor('#FFFFFF')
    .margin({ top: 12 })
  }

  @Builder
  MaterialTwinPage() {
    Scroll() {
      Column() {
        Row() {
          Column() {
            Text('3D \u89c6\u56fe')
              .fontSize(22)
              .fontWeight(FontWeight.Bold)
              .fontColor('#172033')
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)

          Button('\u8fd4\u56de')
            .height(34)
            .fontSize(13)
            .fontColor('#1769E0')
            .backgroundColor('#EAF2FF')
            .onClick(() => {
              this.materialTwinOpen = false;
            })
        }
        .width('100%')

        this.ThingjsTwinCard()
        this.MaterialTwinAlertCard()
      }
      .width('100%')
      .padding({ left: 16, right: 16, bottom: 24 })
    }
    .layoutWeight(1)
    .onAppear(() => {
      this.loadMaterialTwin();
    })
  }

  @Builder
  ThingjsTwinCard() {
    Column() {
      Row() {
        Text('\u6750\u6599')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#172033')
        Blank()
        Button('\u5237\u65b0')
          .height(34)
          .fontSize(13)
          .fontColor('#1769E0')
          .backgroundColor('#EAF2FF')
          .onClick(() => {
            this.thingjsController.refresh();
            this.loadMaterialTwin();
          })
      }
      .width('100%')

      Web({ src: 'https://www.thingjs.com/s/9f06f979bd2f32f296721080', controller: this.thingjsController })
        .width('100%')
        .height(500)
        .borderRadius(10)
        .javaScriptAccess(true)
        .domStorageAccess(true)
        .onlineImageAccess(true)
        .onPageEnd(() => {
          this.loadMaterialTwin();
        })
      .width('100%')
      .height(500)
      .borderRadius(10)
      .clip(true)
      .backgroundColor('#0D1726')
      .margin({ top: 12 })
    }
    .width('100%')
    .padding(14)
    .backgroundColor('#FFFFFF')
    .margin({ top: 16 })
  }

  @Builder
  TwinOverlayCard(zoneCode: string, title: string, color: string) {
    Column() {
      Row() {
        Text(title)
          .fontSize(13)
          .fontWeight(FontWeight.Bold)
          .fontColor('#172033')
        Blank()
        Text(this.getTwinRiskTextFor(zoneCode))
          .fontSize(10)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.getTwinRiskColorFor(zoneCode))
          .padding({ left: 6, right: 6, top: 3, bottom: 3 })
          .borderRadius(10)
          .backgroundColor(this.getTwinRiskBgFor(zoneCode))
      }
      .width('100%')

      Row() {
        this.TwinOverlayMetric('Temp', this.getTwinMetricValue(zoneCode, 'temp'), 'C', '#FCA5A5')
        this.TwinOverlayMetric('Humi', this.getTwinMetricValue(zoneCode, 'humi'), '%', '#1769E0')
      }
      .width('100%')
      .margin({ top: 6 })

      Row() {
        Text('Fan ' + this.getTwinFanStateFor(zoneCode))
          .fontSize(11)
          .fontColor('#475569')
        Blank()
        Text('\u544a\u8b66 ' + this.getTwinAlarmStateFor(zoneCode))
          .fontSize(11)
          .fontColor('#475569')
      }
      .width('100%')
      .margin({ top: 6 })
    }
    .layoutWeight(1)
    .height(108)
    .padding(10)
    .borderRadius(8)
    .backgroundColor('#EFFFFFFF')
    .border({ width: 1, color: '#D7DEE8' })
    .margin({ left: zoneCode === 'timber_zone' ? 8 : 0 })
  }

  @Builder
  TwinOverlayMetric(label: string, value: string, unit: string, color: string) {
    Column() {
      Text(label)
        .fontSize(10)
        .fontColor('#697386')
      Text(value === '--' ? '--' : value + unit)
        .fontSize(15)
        .fontWeight(FontWeight.Bold)
        .fontColor(color)
        .margin({ top: 3 })
    }
    .layoutWeight(1)
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  MaterialTwinFlowCard() {
    Column() {
      Row() {
        Text('\u6570\u636e\u6d41\u8f6c')
          .fontWeight(FontWeight.Bold)
          .fontColor('#172033')
        Blank()
        Button(this.materialTwinLoading ? '\u540c\u6b65\u4e2d' : '\u5237\u65b0')
          .fontSize(12)
          .fontColor('#1769E0')
          .backgroundColor('#EAF2FF')
          .enabled(!this.materialTwinLoading)
          .onClick(() => {
            this.loadMaterialTwin();
          })
      }
      .width('100%')

      Row() {
        this.TwinFlowNode('IoTDA', 'Device Shadow')
        Text('>')
          .fontSize(18)
          .fontColor('#94A3B8')
          .margin({ left: 8, right: 8 })
        this.TwinFlowNode('Kingbase', 'History')
        Text('>')
          .fontSize(18)
          .fontColor('#94A3B8')
          .margin({ left: 8, right: 8 })
        this.TwinFlowNode('App', 'Twin Panel')
      }
      .width('100%')
      .margin({ top: 14 })

      Text('\u8be5\u89c6\u56fe\u5173\u8054\u771f\u5b9e\u8bbe\u5907\u3001\u6570\u636e\u5e93\u8bb0\u5f55\u3001\u89c4\u5219\u548c\u533a\u57df\u72b6\u6001\u3002')
        .lineHeight(18)
        .margin({ top: 12 })
        .width('100%')
    }
    .width('100%')
    .padding(16)
    .borderRadius(10)
    .backgroundColor('#FFFFFF')
    .margin({ top: 16 })
  }

  @Builder
  TwinFlowNode(title: string, desc: string) {
    Column() {
      Text(title)
        .fontSize(14)
        .fontWeight(FontWeight.Bold)
        .fontColor('#172033')
      Text(desc)
        .fontSize(11)
        .fontColor('#697386')
        .margin({ top: 4 })
    }
    .layoutWeight(1)
    .height(64)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .borderRadius(8)
    .backgroundColor('#F4F7FB')
  }

  @Builder
  MaterialTwinZoneTwinCard(zoneCode: string, title: string, desc: string, themeColor: string) {
    Column() {
      Row() {
        Column() {
          Text(title)
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor('#172033')
          Text(desc)
            .fontSize(12)
            .fontColor('#697386')
            .lineHeight(18)
            .margin({ top: 5 })
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        Text(this.getTwinRiskTextFor(zoneCode))
          .fontSize(12)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.getTwinRiskColorFor(zoneCode))
          .padding({ left: 10, right: 10, top: 5, bottom: 5 })
          .borderRadius(14)
          .backgroundColor(this.getTwinRiskBgFor(zoneCode))
      }
      .width('100%')

      Stack({ alignContent: Alignment.Center }) {
        Column() {
          Row() {
            this.TwinStorageBlock('\u6750\u6599\u5806\u653e', this.getTwinZoneMaterialType(zoneCode), themeColor)
            this.TwinStorageBlock('Sensor', this.getTwinSensorSummary(zoneCode), '#1769E0')
          }
          .width('100%')

          Row() {
            this.TwinStorageBlock('Fan', this.getTwinFanStateFor(zoneCode), '#4B5563')
            this.TwinStorageBlock('Alarm', this.getTwinAlarmStateFor(zoneCode), this.getTwinRiskColorFor(zoneCode))
          }
          .width('100%')
          .margin({ top: 10 })
        }
        .width('100%')
      }
      .width('100%')
      .padding(12)
      .borderRadius(10)
      .backgroundColor('#F8FAFC')
      .border({ width: 1, color: '#D7DEE8' })
      .margin({ top: 14 })

      Row() {
        this.TwinMetricPill('Temp', this.getTwinMetricValue(zoneCode, 'temp'), 'C', '#E35D2F')
        this.TwinMetricPill('Humidity', this.getTwinMetricValue(zoneCode, 'humi'), '%', '#1769E0')
        this.TwinMetricPill('Lumi', this.getTwinMetricValue(zoneCode, 'lumi'), '', '#0E9F6E')
      }
      .width('100%')
      .margin({ top: 12 })

      Text(this.getTwinZoneSummaryFor(zoneCode))
        .fontSize(12)
        .fontColor('#697386')
        .lineHeight(18)
        .margin({ top: 10 })
        .width('100%')
    }
    .width('100%')
    .padding(16)
    .borderRadius(10)
    .backgroundColor('#FFFFFF')
    .margin({ top: 16 })
    .onClick(() => {
      this.openMaterialHistory(zoneCode);
    })
  }

  @Builder
  TwinStorageBlock(title: string, value: string, color: string) {
    Column() {
      Text(title)
        .fontSize(11)
        .fontColor('#697386')
      Text(value)
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor(color)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .margin({ top: 6 })
    }
    .layoutWeight(1)
    .height(74)
    .padding(10)
    .alignItems(HorizontalAlign.Start)
    .justifyContent(FlexAlign.Center)
    .borderRadius(8)
    .backgroundColor('#FFFFFF')
    .margin({ right: 8 })
  }

  @Builder
  TwinMetricPill(label: string, value: string, unit: string, color: string) {
    Column() {
      Text(value === '--' ? '--' : value + unit)
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
      Text('\u5b6a\u751f\u8d44\u4ea7\u5217\u8868')
      Text(label)
        .fontSize(11)
        .fontColor('#697386')
        .margin({ top: 4 })
    }
    .layoutWeight(1)
    .height(66)
    .alignItems(HorizontalAlign.Center)
    .justifyContent(FlexAlign.Center)
      Text('\u5b9e\u65f6\u6570\u636e')
    .backgroundColor('#F4F7FB')
    .margin({ right: 8 })
  }

  @Builder
  MaterialTwinAssetMapCard() {
    Column() {
      Text('\u5b6a\u751f\u8d44\u4ea7\u5217\u8868')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor('#172033')
        .width('100%')

      ForEach(this.twinAssets, (asset: DigitalTwinAsset) => {
        Row() {
          Column() {
            Text(asset.asset_name)
              .fontSize(14)
              .fontWeight(FontWeight.Bold)
              .fontColor('#172033')
            Text(String(asset.zone_code) + ' / ' + String(asset.asset_type) + ' / ' + String(asset.data_source))
              .fontSize(11)
              .fontColor('#697386')
              .margin({ top: 4 })
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)

          Text(asset.status)
            .fontSize(11)
            .fontColor(asset.status === 'online' ? '#0F766E' : '#B54708')
        }
        .width('100%')
        .padding({ top: 12, bottom: 12 })
        .border({ width: { bottom: 1 }, color: '#EEF2F7' })
      }, (asset: DigitalTwinAsset) => asset.asset_code)

      if (this.twinAssets.length === 0) {
        Text('\u6682\u65e0\u5b6a\u751f\u8d44\u4ea7\uff0c\u8bf7\u5148\u5728\u91d1\u4ed3\u521d\u59cb\u5316 digital_twin_assets\u3002')
          .fontSize(12)
          .fontColor('#697386')
          .margin({ top: 12 })
          .width('100%')
      }
    }
    .width('100%')
    .padding(16)
    .borderRadius(10)
    .backgroundColor('#FFFFFF')
    .margin({ top: 16 })
  }

  @Builder
  MaterialTwinAlertCard() {
    Column() {
      Text('\u544a\u8b66\u4e8b\u4ef6')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor('#172033')
        .width('100%')

      ForEach(this.materialAlerts, (alert: MaterialAlertEvent) => {
        Column() {
          Row() {
            Text(alert.message)
              .fontSize(13)
              .fontWeight(FontWeight.Bold)
              .fontColor(alert.severity === 'critical' ? '#B42318' : '#B54708')
              .layoutWeight(1)
            Text(alert.status)
              .fontSize(11)
              .fontColor('#697386')
          }
          .width('100%')

          Text(String(alert.zone_code) + ' ' + String(alert.metric_name) + ' ' + String(alert.actual_value) + ', range ' + String(alert.min_value) + ' - ' + String(alert.max_value))
            .fontSize(12)
            .fontColor('#697386')
            .margin({ top: 5 })
            .width('100%')
        }
        .width('100%')
        .padding({ top: 12, bottom: 12 })
        .border({ width: { bottom: 1 }, color: '#EEF2F7' })
      }, (alert: MaterialAlertEvent) => alert.id)

      if (this.materialAlerts.length === 0) {
        Text('\u6682\u65e0\u544a\u8b66\uff0c\u6750\u6599\u6307\u6807\u8d85\u9650\u540e\u4f1a\u663e\u793a\u5728\u8fd9\u91cc\u3002')
          .fontSize(12)
          .fontColor('#697386')
          .margin({ top: 12 })
          .width('100%')
      }
    }
    .width('100%')
    .padding(16)
    .borderRadius(10)
    .backgroundColor('#FFFFFF')
    .margin({ top: 16 })
  }

  @Builder
  PageTitle(title: string, subtitle: string) {
    Column() {
      Text(title)
        .fontSize(22)
        .fontWeight(FontWeight.Bold)
        .fontColor('#172033')
      Text(subtitle)
        .fontSize(12)
        .fontColor('#697386')
        .margin({ top: 6 })
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
    .margin({ top: 18, bottom: 14 })
  }

  @Builder
  ZonePill(label: string, zoneCode: string, activeZoneCode: string) {
    Button(label)
      .height(34)
      .fontSize(13)
      .fontWeight(FontWeight.Bold)
      .fontColor(activeZoneCode === zoneCode ? '#FFFFFF' : '#1769E0')
      .backgroundColor(activeZoneCode === zoneCode ? '#1769E0' : '#EAF2FF')
      .borderRadius(17)
      .margin({ right: 8 })
      .onClick(() => {
        this.openMaterialHistory(zoneCode);
      })
  }

  @Builder
  MaterialHistoryPage() {
    Scroll() {
      Column() {
        Row() {
          Column() {
            Text(this.materialHistoryZoneName + ' \u5386\u53f2\u8d8b\u52bf')
              .fontSize(22)
              .fontWeight(FontWeight.Bold)
              .fontColor('#172033')
            Text(this.materialHistoryStatus)
              .fontSize(12)
              .fontColor('#697386')
              .margin({ top: 5 })
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)

          Button('\u8fd4\u56de')
            .height(34)
            .fontSize(13)
            .fontColor('#1769E0')
            .backgroundColor('#EAF2FF')
            .onClick(() => {
              this.materialHistoryOpen = false;
            })
        }
        .width('100%')

        this.MaterialTrendChartCard()
        this.MaterialHistoryListCard()
      }
      .width('100%')
      .padding({ left: 16, right: 16, bottom: 24 })
    }
    .layoutWeight(1)
  }

  @Builder
  MaterialTrendChartCard() {
    Column() {
      Row() {
        Text('\u6e29\u6e7f\u5ea6\u8d8b\u52bf')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#172033')
        Blank()
        Button(this.materialHistoryLoading ? '\u52a0\u8f7d\u4e2d' : '\u5237\u65b0')
          .height(32)
          .fontSize(12)
          .backgroundColor('#1769E0')
          .onClick(() => {
            this.loadMaterialHistory();
          })
      }
      .width('100%')

      Canvas(this.materialChartContext)
        .width('100%')
        .height(220)
        .margin({ top: 12 })
        .onReady(() => {
          this.drawMaterialTrendChart();
        })
    }
    .width('100%')
    .padding(16)
    .borderRadius(10)
    .backgroundColor('#FFFFFF')
    .margin({ top: 16 })
  }

  @Builder
  MaterialHistoryListCard() {
    Column() {
      Row() {
        Text('\u6700\u8fd1\u8bb0\u5f55')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#172033')
        Blank()
        Text(this.materialRecordCount + ' \u6761')
          .fontSize(12)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1769E0')
      }
      .width('100%')

      Text(this.getMaterialHistorySummary())
        .fontSize(12)
        .fontColor('#697386')
        .lineHeight(20)
        .margin({ top: 12 })
        .width('100%')
    }
    .width('100%')
    .padding(16)
    .borderRadius(10)
    .backgroundColor('#FFFFFF')
    .margin({ top: 16 })
  }

  @Builder
  MonitorPage() {
    Scroll() {
      Column() {
        this.PageTitle('\u89c6\u9891\u76d1\u63a7', 'ESP32 \u4e0e RTSP \u6444\u50cf\u5934\u63a5\u5165')
        this.CameraConfigCard()
        this.CameraPreviewCard()
        this.CloudVideoConfigCard()
        this.CloudVideoPreviewCard()
      }
      .width('100%')
      .padding({ left: 16, right: 16, bottom: 24 })
    }
    .layoutWeight(1)
  }

  @Builder
  CameraConfigCard() {
    Column() {
      Text('\u6444\u50cf\u5934\u8fde\u63a5')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor('#172033')
        .width('100%')
      TextInput({ placeholder: '\u76d1\u63a7 IP Address', text: this.cameraIpAddress })
        .height(44)
        .margin({ top: 12 })
        .onChange((value: string) => {
          this.cameraIpAddress = value;
        })
      TextInput({ placeholder: 'Port', text: this.cameraPort })
        .height(44)
        .margin({ top: 10 })
        .onChange((value: string) => {
          this.cameraPort = value;
        })
      Row() {
        Button(this.cameraConnected ? '\u65ad\u5f00' : '\u8fde\u63a5')
          .layoutWeight(1)
          .height(44)
          .backgroundColor(this.cameraConnected ? '#C2410C' : '#1769E0')
          .onClick(() => {
            if (this.cameraConnected) {
              this.disconnectCamera();
            } else {
              this.connectCamera();
            }
          })
        Button('\u6e05\u9664\u753b\u9762')
          .height(44)
          .margin({ left: 10 })
          .backgroundColor('#EAF2FF')
          .fontColor('#1769E0')
          .onClick(() => {
            this.cameraFrame = null;
          })
      }
      .width('100%')
      .margin({ top: 12 })
      Text(this.cameraStatus)
        .fontSize(12)
        .fontColor('#697386')
        .margin({ top: 10 })
        .width('100%')
    }
    .width('100%')
    .padding(16)
    .borderRadius(10)
    .backgroundColor('#FFFFFF')
    .margin({ top: 16 })
  }

  @Builder
  CameraPreviewCard() {
    Column() {
      Text('\u672c\u5730\u6444\u50cf\u5934')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor('#172033')
        .width('100%')
      if (this.cameraFrame !== null) {
        Image(this.cameraFrame)
          .width('100%')
          .height(220)
          .objectFit(ImageFit.Contain)
          .margin({ top: 12 })
      } else {
        Column() {
          Text('\u7b49\u5f85\u6444\u50cf\u5934\u753b\u9762')
            .fontSize(14)
            .fontColor('#697386')
        }
        .width('100%')
        .height(180)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .backgroundColor('#F4F7FB')
        .borderRadius(8)
        .margin({ top: 12 })
      }
    }
    .width('100%')
    .padding(16)
    .borderRadius(10)
    .backgroundColor('#FFFFFF')
    .margin({ top: 16 })
  }

  @Builder
  CloudVideoConfigCard() {
    Column() {
      Text('\u4e91\u7aef\u89c6\u9891\u7aef\u53e3')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor('#172033')
        .width('100%')
      TextInput({ placeholder: 'Server IP', text: this.cloudVideoHost })
        .height(44)
        .margin({ top: 12 })
        .onChange((value: string) => {
          this.cloudVideoHost = value;
        })
      TextInput({ placeholder: 'HLS Port', text: this.cloudVideoHlsPort })
        .height(44)
        .margin({ top: 10 })
        .onChange((value: string) => {
          this.cloudVideoHlsPort = value;
        })
      TextInput({ placeholder: 'RTSP Push Port', text: this.cloudVideoRtspPort })
        .height(44)
        .margin({ top: 10 })
        .onChange((value: string) => {
          this.cloudVideoRtspPort = value;
        })
      TextInput({ placeholder: 'Stream name', text: this.cloudVideoStreamName })
        .height(44)
        .margin({ top: 10 })
        .onChange((value: string) => {
          this.cloudVideoStreamName = value;
        })
      Button('\u91cd\u65b0\u52a0\u8f7d')
        .height(40)
        .margin({ top: 12 })
        .backgroundColor('#1769E0')
        .onClick(() => {
          this.reloadCloudVideo();
        })
    }
    .width('100%')
    .padding(16)
    .borderRadius(10)
    .backgroundColor('#FFFFFF')
    .margin({ top: 16 })
  }

  @Builder
  CloudVideoPreviewCard() {
    Column() {
      Text('\u4e91\u7aef\u89c6\u9891\u753b\u9762')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor('#172033')
        .width('100%')
      Text(this.getCloudVideoUrl())
        .fontSize(12)
        .fontColor('#697386')
        .margin({ top: 8 })
        .width('100%')
      Web({ src: this.getCloudVideoUrl(), controller: this.cloudVideoController })
        .width('100%')
        .height(220)
        .margin({ top: 12 })
      Text(this.cloudVideoStatus)
        .fontSize(12)
        .fontColor('#697386')
        .margin({ top: 10 })
    }
    .width('100%')
    .padding(16)
    .borderRadius(10)
    .backgroundColor('#FFFFFF')
    .margin({ top: 16 })
  }

  @Builder
  AttendancePage() {
    Scroll() {
      Column() {
        this.PageTitle('\u6253\u5361\u7ba1\u7406', '\u53d1\u5e03\u6253\u5361\u4efb\u52a1\u5e76\u67e5\u770b\u5de5\u4eba\u8bb0\u5f55')
        this.AttendanceTaskManager()
        this.AttendanceCloudRecordCard()
      }
      .width('100%')
      .padding({ left: 16, right: 16, bottom: 24 })
    }
    .layoutWeight(1)
  }

  @Builder
  AttendanceTaskManager() {
    Column() {
      Row() {
        Column() {
          Text(this.attendanceTaskName)
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor('#172033')
          Text('\u7b7e\u5230\u7a97\u53e3 ' + this.attendanceTaskWindow)
            .fontSize(12)
            .fontColor('#697386')
            .margin({ top: 5 })
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
        Text(this.workerHasTask ? '\u5df2\u53d1\u5e03' : '\u672a\u53d1\u5e03')
          .fontSize(12)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.workerHasTask ? '#0E9F6E' : '#C2410C')
      }
      .width('100%')

      Text('\u53d1\u5e03\u4e8e ' + this.attendancePublishedAt)
        .fontSize(12)
        .fontColor('#697386')
        .margin({ top: 10 })

      Row() {
        Button(this.workerHasTask ? '\u5173\u95ed\u4efb\u52a1' : '\u53d1\u5e03\u4efb\u52a1')
          .layoutWeight(1)
          .height(44)
          .fontSize(15)
          .fontWeight(FontWeight.Bold)
          .backgroundColor(this.workerHasTask ? '#C2410C' : '#1769E0')
          .onClick(() => {
            if (this.workerHasTask) {
              this.closeAttendanceTask();
            } else {
              this.publishAttendanceTask();
            }
          })
        Button('\u91cd\u7f6e\u8bb0\u5f55')
          .height(44)
          .fontSize(15)
          .fontColor('#1769E0')
          .backgroundColor('#EAF2FF')
          .margin({ left: 10 })
          .onClick(() => {
            this.resetAttendanceRecordsOnCloud();
          })
      }
      .width('100%')
      .margin({ top: 16 })
    }
    .width('100%')
    .padding(16)
    .borderRadius(10)
    .backgroundColor('#FFFFFF')
    .margin({ top: 16 })
  }

  @Builder
  AttendanceRecordCard() {
    Column() {
      Text('\u5f53\u524d\u5de5\u4eba\u8bb0\u5f55')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor('#172033')
        .width('100%')
      Row() {
        this.AttendanceStat('\u7b7e\u5230', this.workerCheckInTime === '' ? '--:--' : this.workerCheckInTime)
        this.AttendanceStat('\u7b7e\u9000', this.workerCheckOutTime === '' ? '--:--' : this.workerCheckOutTime)
        this.AttendanceStat('\u5de5\u65f6', this.workerWorkDuration)
      }
      .width('100%')
      .margin({ top: 14 })
    }
    .width('100%')
    .padding(16)
    .borderRadius(10)
    .backgroundColor('#FFFFFF')
    .margin({ top: 16 })
  }

  @Builder
  AttendanceCloudRecordCard() {
    Column() {
      Text('\u4e91\u7aef\u6253\u5361\u5217\u8868')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor('#172033')
        .width('100%')
      Text(this.attendanceRecordSummary)
        .fontSize(12)
        .fontColor('#697386')
        .lineHeight(20)
        .margin({ top: 12 })
        .width('100%')
    }
    .width('100%')
    .padding(16)
    .borderRadius(10)
    .backgroundColor('#FFFFFF')
    .margin({ top: 16 })
  }

  @Builder
  WorkHourPage() {
    Scroll() {
      Column() {
        this.PageTitle('\u5de5\u65f6\u7edf\u8ba1', '\u6839\u636e\u7b7e\u5230\u548c\u7b7e\u9000\u65f6\u95f4\u8ba1\u7b97')
        this.WorkHourCurrentCard()
      }
      .width('100%')
      .padding({ left: 16, right: 16, bottom: 24 })
    }
    .layoutWeight(1)
  }

  @Builder
  WorkHourCurrentCard() {
    Column() {
      Text('\u5f53\u524d\u5de5\u4eba')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor('#172033')
        .width('100%')
      Text(this.workerWorkDuration)
        .fontSize(32)
        .fontWeight(FontWeight.Bold)
        .fontColor('#1769E0')
        .margin({ top: 14 })
      Text('\u7b7e\u5230 ' + (this.workerCheckInTime === '' ? '--:--' : this.workerCheckInTime) + '  \u7b7e\u9000 ' + (this.workerCheckOutTime === '' ? '--:--' : this.workerCheckOutTime))
        .fontSize(12)
        .fontColor('#697386')
        .margin({ top: 10 })
    }
    .width('100%')
    .padding(16)
    .borderRadius(10)
    .backgroundColor('#FFFFFF')
    .margin({ top: 16 })
  }

  @Builder
  WorkerPage() {
    Column() {
      Text('\u4eca\u65e5\u6253\u5361\u4efb\u52a1')
        .fontSize(22)
        .fontWeight(FontWeight.Bold)
        .fontColor('#172033')
        .width('100%')
        .margin({ top: 24 })

      if (this.workerHasTask) {
        Column() {
          Text('\u5f00\u59cb\u6253\u5361')
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor('#172033')
          Text('\u7b7e\u5230\u7a97\u53e3 07:30 - 09:00')
            .fontSize(14)
            .fontColor('#697386')
            .margin({ top: 8 })
          Text(this.workerWorkDuration)
            .fontSize(30)
            .fontWeight(FontWeight.Bold)
            .fontColor('#1769E0')
            .textAlign(TextAlign.Center)
            .width('100%')
            .margin({ top: 28 })
          Button(this.getWorkerActionText())
            .width(156)
            .height(156)
            .borderRadius(78)
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FFFFFF')
            .backgroundColor(this.getWorkerActionColor())
            .margin({ top: 28 })
            .enabled(this.workerCheckOutTime === '')
            .onClick(() => {
              this.handleWorkerAttendanceAction();
            })
          this.WorkerTaskStatus()
        }
        .width('100%')
        .alignItems(HorizontalAlign.Center)
        .padding(18)
        .borderRadius(10)
        .backgroundColor('#FFFFFF')
        .margin({ top: 14 })
      } else {
        Column() {
          Text('\u6682\u65e0\u6253\u5361\u4efb\u52a1')
            .fontSize(22)
            .fontWeight(FontWeight.Bold)
            .fontColor('#172033')
          Text('\u7ba1\u7406\u5458\u53d1\u5e03\u4efb\u52a1\u540e\u624d\u4f1a\u663e\u793a\u6253\u5361\u5165\u53e3\u3002')
            .fontSize(14)
            .fontColor('#697386')
            .textAlign(TextAlign.Center)
            .lineHeight(22)
            .margin({ top: 10 })
        }
        .width('100%')
        .height(260)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .padding(20)
        .borderRadius(10)
        .backgroundColor('#FFFFFF')
        .margin({ top: 14 })
      }
    }
    .width('100%')
    .padding({ left: 16, right: 16 })
  }

  @Builder
  WorkerTaskStatus() {
    Column() {
      this.StatusLine('\u7b7e\u5230', this.workerCheckInTime === '' ? '\u672a\u6253\u5361' : this.workerCheckInTime, this.workerCheckInTime === '' ? '#C2410C' : '#0E9F6E')
      this.StatusLine('\u7b7e\u9000', this.workerCheckOutTime === '' ? '\u672a\u6253\u5361' : this.workerCheckOutTime, this.workerCheckOutTime === '' ? '#C2410C' : '#0E9F6E')
      this.StatusLine('\u5de5\u65f6', this.workerWorkDuration, '#1769E0')
    }
    .width('100%')
    .padding(14)
    .borderRadius(8)
    .backgroundColor('#F4F7FB')
    .margin({ top: 16 })
  }

  @Builder
  StatusLine(label: string, value: string, color: string) {
    Row() {
      Text(label)
        .fontSize(13)
        .fontColor('#697386')
      Blank()
      Text(value)
        .fontSize(13)
        .fontWeight(FontWeight.Bold)
        .fontColor(color)
    }
    .width('100%')
    .margin({ top: 6 })
  }

  @Builder
  BottomNavigation() {
    Row() {
      this.NavItem('home', '\u9996\u9875')
      this.NavItem('env', '\u6750\u6599')
      this.NavItem('monitor', '\u76d1\u63a7')
      this.NavItem('attendance', '\u6253\u5361')
      this.NavItem('hours', '\u5de5\u65f6')
    }
    .width('100%')
    .height(64)
    .padding({ left: 8, right: 8 })
    .backgroundColor('#FFFFFF')
  }

  @Builder
  NavItem(key: string, label: string) {
    Column() {
      Text(label)
        .fontSize(13)
        .fontWeight(this.activeTab === key ? FontWeight.Bold : FontWeight.Regular)
        .fontColor(this.activeTab === key ? '#1769E0' : '#697386')
    }
    .layoutWeight(1)
    .height(54)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .onClick(() => {
      this.activeTab = key;
    })
  }

  @Builder
  PixelBottomNavigation() {
    Row() {
      this.PixelNavItem('home', '\u9996\u9875', '*')
      this.PixelNavItem('env', '\u6750\u6599', '*')
      this.PixelNavItem('monitor', '\u76d1\u63a7', '*')
      this.PixelNavItem('attendance', '\u6253\u5361', 'o')
      this.PixelNavItem('hours', '\u5de5\u65f6', 'o')
    }
    .width('100%')
    .height(70)
    .padding({ left: 10, right: 10, top: 8, bottom: 8 })
    .backgroundColor('#2F2F2F')
    .border({ width: 3, color: '#1F1F1F' })
  }

  @Builder
  PixelNavItem(key: string, label: string, mark: string) {
    Column() {
      Text(mark)
        .fontSize(13)
        .fontColor(this.activeTab === key ? '#F8C02E' : '#C7BDA4')
      Text(label)
        .fontSize(12)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.activeTab === key ? '#F8C02E' : '#C7BDA4')
        .margin({ top: 3 })
    }
    .layoutWeight(1)
    .height(54)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .onClick(() => {
      animateTo({ duration: 180, curve: Curve.EaseOut }, () => {
        this.activeTab = key;
      });
    })
  }
  private loginWithSupabase(): void {
    const account = this.username.trim();
    const pwd = this.password.trim();
    if (account === '' || pwd === '') {
      this.loginError = 'Account and password cannot be empty';
      return;
    }
    this.loginError = '\u6b63\u5728\u8fde\u63a5\u4e91\u6570\u636e\u5e93...';
    this.loginWithSupabaseAsync(account, pwd, this.loginRole);
  }

  private sendAssistantMessage(): void {
    const query = this.assistantInput.trim();
    if (query === '') {
      return;
    }
    if (DIFY_CONFIG.apiKey === '' || DIFY_CONFIG.apiKey === 'app-your-api-key') {
      this.assistantChatLog += '\n\n\u6211: ' + query + '\n\u667a\u6167\u5de5\u5730\u52a9\u624b: \u8bf7\u5148\u5728 DifyConfig.ets \u914d\u7f6e API Key\u3002';
      this.assistantInput = '';
      return;
    }
    this.assistantInput = '';
    this.assistantSending = true;
    this.assistantChatLog += '\n\n\u6211: ' + query;
    this.requestDifyAnswer(query);
  }

  private async requestDifyAnswer(query: string): Promise<void> {
    const request = http.createHttp();
    try {
      const chatRequest: DifyChatRequest = {
        inputs: {},
        query: query,
        response_mode: 'blocking',
        conversation_id: this.assistantConversationId,
        user: DIFY_CONFIG.user
      };
      const body = JSON.stringify(chatRequest);
      const response = await request.request(DIFY_CONFIG.apiUrl, {
        method: http.RequestMethod.POST,
        expectDataType: http.HttpDataType.STRING,
        connectTimeout: 15000,
        readTimeout: 30000,
        header: {
          'Authorization': 'Bearer ' + DIFY_CONFIG.apiKey,
          'Content-Type': 'application/json'
        },
        extraData: body
      });
      if (response.responseCode < 200 || response.responseCode >= 300) {
        this.assistantChatLog += '\n\u667a\u6167\u5de5\u5730\u52a9\u624b: \u8bf7\u6c42\u5931\u8d25\uff0cHTTP ' + response.responseCode + '.';
        return;
      }
      const result = JSON.parse(typeof response.result === 'string' ? response.result : JSON.stringify(response.result)) as DifyChatResponse;
      if (result.conversation_id !== '') {
        this.assistantConversationId = result.conversation_id;
      }
      this.assistantChatLog += '\n' + '\u667a\u6167\u5de5\u5730\u52a9\u624b: ' + this.cleanAssistantAnswer(result.answer);
    } catch (error) {
      this.assistantChatLog += '\n\u667a\u6167\u5de5\u5730\u52a9\u624b: Dify \u8fde\u63a5\u5931\u8d25\uff0c\u8bf7\u68c0\u67e5\u63a5\u53e3\u5730\u5740\u3001API Key \u548c\u7f51\u7edc\u3002';
    } finally {
      this.assistantSending = false;
      request.destroy();
    }
  }

  private cleanAssistantAnswer(answer: string): string {
    const start = answer.indexOf('<think>');
    const end = answer.indexOf('</think>');
    if (start >= 0 && end >= start) {
      return answer.substring(end + 8).trim();
    }
    return answer.trim();
  }

  private logout(): void {
    this.isLoggedIn = false;
    this.currentRole = 'admin';
    this.loginRole = 'admin';
    this.username = '';
    this.password = '';
    this.loginError = '';
    this.activeTab = 'home';
    this.assistantOpen = false;
    this.assistantInput = '';
    this.assistantSending = false;
    this.currentUserId = -1;
    this.currentUserName = '';
    this.currentUserTeam = '';
    this.workerCloudId = 2;
    this.currentAttendanceTaskId = -1;
    this.workerHasTask = false;
    this.attendanceRecordSummary = '\u6682\u65e0\u6253\u5361\u8bb0\u5f55';
    this.attendanceRecordCount = 0;
    this.resetAttendanceRecord();
  }

  private async loginWithSupabaseAsync(account: string, pwd: string, role: string): Promise<void> {
    try {
      const users = await this.querySupabaseUsers(account, pwd, role);
      if (users.length === 0) {
        this.loginError = 'Account, password or role does not match';
        return;
      }
      const user = users[0];
      this.currentUserId = user.id;
      this.currentUserName = user.real_name;
      this.currentUserTeam = user.team_name;
      if (user.role === 'worker') {
        this.workerCloudId = user.id;
      }
      this.currentRole = user.role;
      this.activeTab = 'home';
      this.isLoggedIn = true;
      this.loginError = '';
      await this.refreshAttendanceData();
    } catch (error) {
      const workerValid = role === 'worker' && account === 'worker' && pwd === '123456';
      const adminValid = role === 'admin' && account === 'admin' && pwd === '123456';
      if (!workerValid && !adminValid) {
        this.loginError = '\u4e91\u6570\u636e\u5e93\u8fde\u63a5\u5931\u8d25\uff0c\u672c\u5730\u8d26\u53f7\u6821\u9a8c\u4e5f\u672a\u901a\u8fc7';
        return;
      }
      this.currentRole = role;
      this.currentUserId = role === 'admin' ? 1 : 2;
      this.currentUserName = role === 'admin' ? '\u7ba1\u7406' : '\u5de5\u4eba\u4e00';
      this.currentUserTeam = role === 'admin' ? '\u7ba1\u7406\u7ec4' : '\u4e00\u73ed\u7ec4';
      this.workerCloudId = 2;
      this.activeTab = 'home';
      this.isLoggedIn = true;
      this.loginError = '';
    }
  }

  private async querySupabaseUsers(account: string, pwd: string, role: string): Promise<Array<SupabaseUserRow>> {
    const path = '/rest/v1/users?select=id,username,password,real_name,role,team_name,phone&username=eq.' + encodeURIComponent(account) + '&password=eq.' + encodeURIComponent(pwd) + '&role=eq.' + encodeURIComponent(role) + '&limit=1';
    const body = await this.supabaseRequest(path, http.RequestMethod.GET);
    return JSON.parse(body) as Array<SupabaseUserRow>;
  }

  private async refreshAttendanceData(): Promise<void> {
    if (this.attendanceSyncing) {
      return;
    }
    this.attendanceSyncing = true;
    try {
      const tasks = await this.queryActiveAttendanceTasks();
      if (tasks.length === 0) {
        this.currentAttendanceTaskId = -1;
        this.workerHasTask = false;
        this.resetAttendanceRecord();
        this.clearAttendanceRecordSummary('\u6682\u65e0\u6253\u5361\u4efb\u52a1');
        this.attendanceCloudStatus = 'No cloud attendance task';
        this.attendanceSyncing = false;
        return;
      }
      this.applyAttendanceTask(tasks[0]);
      if (this.currentRole === 'admin') {
        await this.refreshAdminAttendanceRecords();
      } else {
        await this.refreshAttendanceRecord();
      }
      this.attendanceCloudStatus = '\u6253\u5361\u5df2\u540c\u6b65';
    } catch (error) {
      this.attendanceCloudStatus = '\u6253\u5361\u540c\u6b65\u5931\u8d25';
    }
    this.attendanceSyncing = false;
  }

  private async queryActiveAttendanceTasks(): Promise<Array<AttendanceTaskRow>> {
    const path = '/rest/v1/attendance_tasks?select=*&status=eq.active&order=created_at.desc&limit=1';
    const body = await this.supabaseRequest(path, http.RequestMethod.GET);
    return JSON.parse(body) as Array<AttendanceTaskRow>;
  }

  private async refreshAttendanceRecord(): Promise<void> {
    if (this.currentAttendanceTaskId < 0) {
      this.resetAttendanceRecord();
      return;
    }
    const records = await this.queryAttendanceRecords(this.currentAttendanceTaskId, this.workerCloudId);
    if (records.length === 0) {
      this.resetAttendanceRecord();
      return;
    }
    this.applyAttendanceRecord(records[0]);
  }

  private async queryAttendanceRecords(taskId: number, workerId: number): Promise<Array<Record<string, Object>>> {
    const path = '/rest/v1/attendance_records?select=*&task_id=eq.' + taskId + '&worker_id=eq.' + workerId + '&limit=1';
    const body = await this.supabaseRequest(path, http.RequestMethod.GET);
    return JSON.parse(body) as Array<Record<string, Object>>;
  }

  private async queryTaskAttendanceRecords(taskId: number): Promise<Array<Record<string, Object>>> {
    const path = '/rest/v1/attendance_records?select=*&task_id=eq.' + taskId + '&order=updated_at.desc';
    const body = await this.supabaseRequest(path, http.RequestMethod.GET);
    return JSON.parse(body) as Array<Record<string, Object>>;
  }

  private async queryAllWorkers(): Promise<Array<SupabaseUserRow>> {
    const path = '/rest/v1/users?select=id,username,password,real_name,role,team_name,phone&role=eq.worker&order=id.asc';
    const body = await this.supabaseRequest(path, http.RequestMethod.GET);
    return JSON.parse(body) as Array<SupabaseUserRow>;
  }

  private async refreshAdminAttendanceRecords(): Promise<void> {
    if (this.currentAttendanceTaskId < 0) {
      this.attendanceRecordSummary = '\u6682\u65e0\u6253\u5361\u4efb\u52a1';
      this.attendanceRecordCount = 0;
      return;
    }
    const workers = await this.queryAllWorkers();
    const records = await this.queryTaskAttendanceRecords(this.currentAttendanceTaskId);
    this.attendanceRecordCount = records.length;
    if (records.length === 0) {
      this.attendanceRecordSummary = 'No worker check records';
      return;
    }
    let summary = '';
    for (let index = 0; index < records.length; index++) {
      const record = records[index];
      const workerId = Number(record['worker_id']);
      const workerName = this.findWorkerName(workers, workerId);
      const checkIn = this.timeFromIso(this.objectToString(record['checkin_time']));
      const checkOut = this.timeFromIso(this.objectToString(record['checkout_time']));
      const duration = this.durationFromRecord(record);
      summary += workerName + '  \u7b7e\u5230 ' + (checkIn === '' ? '--:--' : checkIn) + '  \u7b7e\u9000 ' + (checkOut === '' ? '--:--' : checkOut) + '  \u5de5\u65f6 ' + duration;
      if (index < records.length - 1) {
        summary += '\n';
      }
    }
    this.attendanceRecordSummary = summary;
  }

  private findWorkerName(workers: Array<SupabaseUserRow>, workerId: number): string {
    for (let index = 0; index < workers.length; index++) {
      if (workers[index].id === workerId) {
        return workers[index].real_name;
      }
    }
    return '\u5de5\u4eba ' + workerId;
  }

  private applyAttendanceTask(task: AttendanceTaskRow): void {
    this.currentAttendanceTaskId = task.id;
    this.workerHasTask = true;
    this.attendanceTaskName = task.title;
    this.attendanceTaskWindow = this.timePart(task.checkin_start) + ' - ' + this.timePart(task.checkin_end);
    this.attendancePublishedAt = this.timeFromIso(task.created_at);
  }

  private applyAttendanceRecord(row: Record<string, Object>): void {
    this.workerCheckInTimestamp = this.objectToString(row['checkin_time']);
    this.workerCheckOutTimestamp = this.objectToString(row['checkout_time']);
    this.workerCheckInTime = this.timeFromIso(this.workerCheckInTimestamp);
    this.workerCheckOutTime = this.timeFromIso(this.workerCheckOutTimestamp);
    this.workerWorkDuration = this.durationFromRecord(row);
    this.updateLiveWorkDuration();
  }

  private async supabaseRequest(path: string, method: http.RequestMethod, data: string = ''): Promise<string> {
    const request = http.createHttp();
    try {
      const header: Record<string, string> = {
        'Content-Type': 'application/json; charset=utf-8',
        'apikey': SUPABASE_CONFIG.publishableKey,
        'Authorization': 'Bearer ' + SUPABASE_CONFIG.publishableKey,
        'Prefer': 'return=representation'
      };
      const options: http.HttpRequestOptions = {
        method: method,
        expectDataType: http.HttpDataType.STRING,
        connectTimeout: 10000,
        readTimeout: 10000,
        header: header
      };
      if (data !== '') {
        options.extraData = data;
      }
      const response = await request.request(SUPABASE_CONFIG.projectUrl + path, options);
      if (response.responseCode < 200 || response.responseCode >= 300) {
        throw new Error('Supabase HTTP ' + response.responseCode);
      }
      return typeof response.result === 'string' ? response.result : JSON.stringify(response.result);
    } finally {
      request.destroy();
    }
  }

  private async materialDatabaseRequest(path: string, method: http.RequestMethod, data: string = ''): Promise<string> {
    const request = http.createHttp();
    try {
      const options: http.HttpRequestOptions = {
        method: method,
        expectDataType: http.HttpDataType.STRING,
        connectTimeout: MATERIAL_DATABASE_CONFIG.requestTimeoutMs,
        readTimeout: MATERIAL_DATABASE_CONFIG.requestTimeoutMs,
        header: {
          'Content-Type': 'application/json; charset=utf-8'
        }
      };
      if (data !== '') {
        options.extraData = data;
      }
      const response = await request.request(MATERIAL_DATABASE_CONFIG.apiBaseUrl + path, options);
      if (response.responseCode < 200 || response.responseCode >= 300) {
        throw new Error('Kingbase API HTTP ' + response.responseCode);
      }
      return typeof response.result === 'string' ? response.result : JSON.stringify(response.result);
    } finally {
      request.destroy();
    }
  }

  private saveMaterialSensorRecord(): void {
    const now = new Date().getTime();
    if (now - this.lastMaterialSaveTime < 5000) {
      return;
    }
    if (this.tempValue === '--' && this.humiValue === '--' && this.woodTempValue === '--' && this.woodHumiValue === '--') {
      return;
    }
    this.lastMaterialSaveTime = now;
    if (this.tempValue !== '--' || this.humiValue !== '--') {
      this.saveMaterialSensorRecordAsync('cement_zone', '\u6c34\u6ce5\u533a', CEMENT_IOTDA_CONFIG.deviceId,
        this.tempValue, this.humiValue, this.distValue, this.lumiValue, this.lampValue, this.shadowVersion);
    }
    if (this.woodTempValue !== '--' || this.woodHumiValue !== '--') {
      this.saveMaterialSensorRecordAsync('timber_zone', 'Timber Zone', WOOD_IOTDA_CONFIG.deviceId,
        this.woodTempValue, this.woodHumiValue, '--', '--', '--', this.woodShadowVersion);
    }
  }

  private async saveMaterialSensorRecordAsync(zoneCode: string, zoneName: string, deviceId: string,
    tempValue: string, humiValue: string, distValue: string, lumiValue: string,
    lampValue: string, shadowVersion: string): Promise<void> {
    try {
      const body = JSON.stringify({
        zone_code: zoneCode,
        zone_name: zoneName,
        device_id: deviceId,
        temp: this.toNullableNumber(tempValue),
        humi: this.toNullableNumber(humiValue),
        dist: this.toNullableNumber(distValue),
        lumi: this.toNullableNumber(lumiValue),
        lamp_status: lampValue,
        shadow_version: shadowVersion
      });
      await this.materialDatabaseRequest('/api/material-records', http.RequestMethod.POST, body);
    } catch (error) {
      this.materialHistoryStatus = '\u91d1\u4ed3\u5199\u5165\u5931\u8d25\uff0c\u8bf7\u68c0\u67e5\u6750\u6599 API \u548c\u6570\u636e\u5e93';
    }
  }

  private openMaterialHistory(zoneCode: string): void {
    this.materialHistoryZoneCode = zoneCode;
    this.materialHistoryZoneName = this.getMaterialZoneDisplayName(zoneCode);
    this.materialHistoryOpen = true;
    this.loadMaterialHistory();
  }

  private getMaterialZoneDisplayName(zoneCode: string): string {
    if (zoneCode === 'timber_zone') {
      return '\u6728\u6750\u533a';
    }
    return '\u6c34\u6ce5\u533a';
  }

  private loadMaterialHistory(): void {
    if (this.materialHistoryLoading) {
      return;
    }
    this.materialHistoryLoading = true;
    this.materialHistoryStatus = '\u6b63\u5728\u52a0\u8f7d\u91d1\u4ed3\u6570\u636e...';
    this.loadMaterialHistoryAsync();
  }

  private async loadMaterialHistoryAsync(): Promise<void> {
    try {
      const body = await this.materialDatabaseRequest(buildMaterialRecordsPath(24, this.materialHistoryZoneCode), http.RequestMethod.GET);
      const payload = JSON.parse(body) as MaterialHistoryResponse;
      this.materialHistoryRecords = payload.records.reverse();
      this.materialRecordCount = this.materialHistoryRecords.length;
      this.materialHistoryStatus = this.materialRecordCount > 0 ? 'Kingbase history loaded' : 'No Kingbase history';
      this.drawMaterialTrendChart();
    } catch (error) {
      this.materialHistoryRecords = [];
      this.materialRecordCount = 0;
      this.materialHistoryStatus = '\u52a0\u8f7d\u5931\u8d25\uff0c\u8bf7\u542f\u52a8\u91d1\u4ed3\u6750\u6599 API \u5e76\u521b\u5efa\u8868';
      this.drawMaterialTrendChart();
    }
    this.materialHistoryLoading = false;
  }

  private loadMaterialTwin(): void {
    if (this.materialTwinLoading) {
      return;
    }
    this.materialTwinLoading = true;
    this.materialTwinStatus = '\u6b63\u5728\u52a0\u8f7d\u91d1\u4ed3\u5b6a\u751f\u6570\u636e...';
    this.loadMaterialTwinAsync();
  }

  private async loadMaterialTwinAsync(): Promise<void> {
    try {
      const zonesBody = await this.materialDatabaseRequest('/api/material-zones', http.RequestMethod.GET);
      const assetsBody = await this.materialDatabaseRequest('/api/twin-assets', http.RequestMethod.GET);
      const cementAlertsBody = await this.materialDatabaseRequest('/api/material-alerts?zoneCode=cement_zone&limit=4', http.RequestMethod.GET);
      const timberAlertsBody = await this.materialDatabaseRequest('/api/material-alerts?zoneCode=timber_zone&limit=4', http.RequestMethod.GET);
      const cementRecordsBody = await this.materialDatabaseRequest(buildMaterialRecordsPath(1, 'cement_zone'), http.RequestMethod.GET);
      const timberRecordsBody = await this.materialDatabaseRequest(buildMaterialRecordsPath(1, 'timber_zone'), http.RequestMethod.GET);
      const zonesPayload = JSON.parse(zonesBody) as MaterialZonesResponse;
      const assetsPayload = JSON.parse(assetsBody) as DigitalTwinAssetsResponse;
      const cementAlertsPayload = JSON.parse(cementAlertsBody) as MaterialAlertsResponse;
      const timberAlertsPayload = JSON.parse(timberAlertsBody) as MaterialAlertsResponse;
      const cementRecordsPayload = JSON.parse(cementRecordsBody) as MaterialHistoryResponse;
      const timberRecordsPayload = JSON.parse(timberRecordsBody) as MaterialHistoryResponse;
      this.materialZones = zonesPayload.zones;
      this.twinAssets = assetsPayload.assets;
      this.materialAlerts = cementAlertsPayload.alerts.concat(timberAlertsPayload.alerts);
      this.materialTwinLatestRecords = [];
      if (cementRecordsPayload.records.length > 0) {
        this.materialTwinLatestRecords.push(cementRecordsPayload.records[0]);
      }
      if (timberRecordsPayload.records.length > 0) {
        this.materialTwinLatestRecords.push(timberRecordsPayload.records[0]);
      }
      this.materialTwinLatestRecord = this.materialTwinLatestRecords.length > 0 ? this.materialTwinLatestRecords[0] : null;
      this.materialTwinStatus = '\u5df2\u540c\u6b65 ' + this.twinAssets.length + ' \u4e2a\u5b6a\u751f\u8d44\u4ea7\uff0c' + this.materialAlerts.length + ' \u6761\u544a\u8b66';
    } catch (error) {
      this.materialZones = [];
      this.twinAssets = [];
      this.materialAlerts = [];
      this.materialTwinLatestRecords = [];
      this.materialTwinLatestRecord = null;
      this.materialTwinStatus = '\u52a0\u8f7d\u5931\u8d25\uff0c\u8bf7\u68c0\u67e5\u91d1\u4ed3\u6750\u6599 API';
    }
    this.materialTwinLoading = false;
  }

  private getTwinZoneConfig(zoneCode: string): MaterialZone | null {
    for (let index = 0; index < this.materialZones.length; index++) {
      if (this.materialZones[index].zone_code === zoneCode) {
        return this.materialZones[index];
      }
    }
    return null;
  }

  private getTwinLatestRecord(zoneCode: string): MaterialSensorRecord | null {
    for (let index = 0; index < this.materialTwinLatestRecords.length; index++) {
      if (this.materialTwinLatestRecords[index].zone_code === zoneCode) {
        return this.materialTwinLatestRecords[index];
      }
    }
    return null;
  }

  private getTwinMetricValue(zoneCode: string, field: string): string {
    const record = this.getTwinLatestRecord(zoneCode);
    if (record === null) {
      return '--';
    }
    if (field === 'temp') {
      return String(record.temp);
    }
    if (field === 'humi') {
      return String(record.humi);
    }
    if (field === 'lumi') {
      return String(record.lumi);
    }
    return '--';
  }

  private getTwinSensorSummary(zoneCode: string): string {
    const record = this.getTwinLatestRecord(zoneCode);
    if (record === null) {
      return '\u7b49\u5f85\u6570\u636e';
    }
    return 'v' + String(record.shadow_version);
  }

  private getTwinZoneMaterialType(zoneCode: string): string {
    const zone = this.getTwinZoneConfig(zoneCode);
    if (zone !== null && zone.material_type !== '') {
      return zone.material_type;
    }
    return zoneCode === 'timber_zone' ? 'timber' : 'cement';
  }

  private getTwinRiskTextFor(zoneCode: string): string {
    const record = this.getTwinLatestRecord(zoneCode);
    const zone = this.getTwinZoneConfig(zoneCode);
    if (record === null || zone === null) {
      return '\u7b49\u5f85\u6570\u636e';
    }
    if (record.humi > zone.humi_max || record.humi < zone.humi_min) {
      return '\u6e7f\u5ea6\u8d85\u9650';
    }
    if (record.temp > zone.temp_max || record.temp < zone.temp_min) {
      return '\u6e29\u5ea6\u8d85\u9650';
    }
    return '\u6b63\u5e38';
  }

  private getTwinRiskColorFor(zoneCode: string): string {
    const risk = this.getTwinRiskTextFor(zoneCode);
    if (risk === '\u6e7f\u5ea6\u8d85\u9650') {
      return '#B42318';
    }
    if (risk === '\u6e29\u5ea6\u8d85\u9650') {
      return '#B54708';
    }
    if (risk === '\u6b63\u5e38') {
      return '#0F766E';
    }
    return '#697386';
  }

  private getTwinRiskBgFor(zoneCode: string): string {
    const color = this.getTwinRiskColorFor(zoneCode);
    if (color === '#B42318') {
      return '#FEE4E2';
    }
    if (color === '#B54708') {
      return '#FEF0C7';
    }
    if (color === '#0F766E') {
      return '#E7F7F3';
    }
    return '#F4F7FB';
  }

  private getTwinFanStateFor(zoneCode: string): string {
    const record = this.getTwinLatestRecord(zoneCode);
    const zone = this.getTwinZoneConfig(zoneCode);
    if (record === null || zone === null) {
      return '\u5f85\u5904\u7406';
    }
    if (!zone.fan_auto_enabled) {
      return '\u5173\u95ed';
    }
    if (record.temp > zone.temp_max || record.humi > zone.humi_max) {
      return '\u5efa\u8bae\u542f\u52a8';
    }
    return '\u7a7a\u95f2';
  }

  private getTwinAlarmStateFor(zoneCode: string): string {
    const record = this.getTwinLatestRecord(zoneCode);
    const zone = this.getTwinZoneConfig(zoneCode);
    if (record === null || zone === null) {
      return '\u5f85\u5904\u7406';
    }
    if (!zone.alarm_enabled) {
      return '\u5173\u95ed';
    }
    if (record.temp > zone.temp_max || record.temp < zone.temp_min ||
      record.humi > zone.humi_max || record.humi < zone.humi_min) {
      return '\u5efa\u8bae\u544a\u8b66';
    }
    return '\u6b63\u5e38';
  }

  private getTwinZoneSummaryFor(zoneCode: string): string {
    const record = this.getTwinLatestRecord(zoneCode);
    const zone = this.getTwinZoneConfig(zoneCode);
    if (record === null) {
      return '\u8be5\u533a\u57df\u6682\u65e0\u91d1\u4ed3\u8bb0\u5f55\u3002';
    }
    if (zone === null) {
      return '\u5b9e\u65f6\u6e29\u5ea6 ' + record.temp + 'C\uff0c\u6e7f\u5ea6 ' + record.humi + '%\uff0c\u4eae\u5ea6 ' + record.lumi;
    }
    return '\u6e29\u5ea6\u8303\u56f4 ' + zone.temp_min + '-' + zone.temp_max + 'C\uff0c\u6e7f\u5ea6 ' + zone.humi_min + '-' + zone.humi_max + '%\u3002\u5f53\u524d\u6e29\u5ea6 ' + record.temp + 'C\uff0c\u6e7f\u5ea6 ' + record.humi + '%.';
  }

  private getCementZoneConfig(): MaterialZone | null {
    for (let index = 0; index < this.materialZones.length; index++) {
      if (this.materialZones[index].zone_code === 'cement_zone') {
        return this.materialZones[index];
      }
    }
    return null;
  }

  private getTwinRiskText(): string {
    const record = this.materialTwinLatestRecord;
    const zone = this.getCementZoneConfig();
    if (record === null || zone === null) {
      return '\u5b6a\u751f\u72b6\u6001\uff1a\u7b49\u5f85\u91d1\u4ed3\u6570\u636e';
    }
    if (record.humi > zone.humi_max) {
      return '\u5b6a\u751f\u72b6\u6001\uff1a\u6e7f\u5ea6\u8d85\u9650';
    }
    if (record.temp > zone.temp_max) {
      return '\u5b6a\u751f\u72b6\u6001\uff1a\u6e29\u5ea6\u504f\u9ad8';
    }
    return '\u5b6a\u751f\u72b6\u6001\uff1a\u6b63\u5e38';
  }

  private getTwinRiskColor(): string {
    const record = this.materialTwinLatestRecord;
    const zone = this.getCementZoneConfig();
    if (record === null || zone === null) {
      return '#697386';
    }
    if (record.humi > zone.humi_max) {
      return '#B42318';
    }
    if (record.temp > zone.temp_max) {
      return '#B54708';
    }
    return '#0F766E';
  }

  private getTwinZoneBg(): string {
    const color = this.getTwinRiskColor();
    if (color === '#B42318') {
      return '#FEE4E2';
    }
    if (color === '#B54708') {
      return '#FEF0C7';
    }
    if (color === '#0F766E') {
      return '#E7F7F3';
    }
    return '#F8FAFC';
  }

  private getTwinZoneBorderColor(): string {
    const color = this.getTwinRiskColor();
    if (color === '#697386') {
      return '#D7DEE8';
    }
    return color;
  }

  private getTwinFanState(): string {
    const record = this.materialTwinLatestRecord;
    const zone = this.getCementZoneConfig();
    if (record === null || zone === null) {
      return '\u7b49\u5f85';
    }
    if (record.temp > zone.temp_max) {
      return '\u81ea\u52a8\u5f00\u542f';
    }
    return '\u7a7a\u95f2';
  }

  private getTwinLiveSummary(): string {
    const record = this.materialTwinLatestRecord;
    const zone = this.getCementZoneConfig();
    if (record === null) {
      return '\u91d1\u4ed3\u6682\u65e0\u6750\u6599\u5386\u53f2\uff0c\u7b49\u5f85 IoTDA \u6570\u636e\u5199\u5165\u3002';
    }
    if (zone === null) {
      return 'Temp ' + record.temp + 'C, Humi ' + record.humi + '%, Lumi ' + record.lumi;
    }
    return 'Temp ' + record.temp + 'C / range ' + zone.temp_min + '-' + zone.temp_max + 'C\nHumi ' + record.humi + '% / range ' + zone.humi_min + '-' + zone.humi_max + '%\nLumi ' + record.lumi + ', \u706f\u5149 ' + record.lamp_status;
  }

  private drawMaterialTrendChart(): void {
    const ctx = this.materialChartContext;
    ctx.clearRect(0, 0, 360, 240);
    ctx.fillStyle = '#F8FAFC';
    ctx.fillRect(0, 0, 360, 240);
    ctx.strokeStyle = '#D7DEE8';
    ctx.lineWidth = 1;
    for (let index = 0; index < 3; index++) {
      const y = 42 + index * 62;
      ctx.beginPath();
      ctx.moveTo(42, y);
      ctx.lineTo(340, y);
      ctx.stroke();
    }
    if (this.materialHistoryRecords.length < 2) {
      ctx.fillStyle = '#697386';
      ctx.font = '14px sans-serif';
      ctx.fillText('\u6570\u636e\u4e0d\u8db3\uff0c\u7b49\u5f85\u66f4\u591a\u534e\u4e3a\u4e91\u8bb0\u5f55\u3002', 58, 120);
      return;
    }
    this.drawMetricLine('temp', '#E35D2F');
    this.drawMetricLine('humi', '#1769E0');
  }

  private drawMetricLine(field: string, color: string): void {
    const ctx = this.materialChartContext;
    const rows = this.materialHistoryRecords;
    let minValue = 999999;
    let maxValue = -999999;
    for (let index = 0; index < rows.length; index++) {
      const value = this.getMaterialMetric(rows[index], field);
      if (value < minValue) {
        minValue = value;
      }
      if (value > maxValue) {
        maxValue = value;
      }
    }
    const minRange = field === 'temp' ? 1.0 : 3.0;
    if (maxValue - minValue < minRange) {
      const center = (maxValue + minValue) / 2;
      minValue = center - minRange / 2;
      maxValue = center + minRange / 2;
    } else {
      const padding = (maxValue - minValue) * 0.18;
      minValue -= padding;
      maxValue += padding;
    }
    const topText = field === 'temp' ? maxValue.toFixed(1) + 'C' : maxValue.toFixed(1) + '%';
    const bottomText = field === 'temp' ? minValue.toFixed(1) + 'C' : minValue.toFixed(1) + '%';
    ctx.fillStyle = color;
    ctx.font = '10px sans-serif';
    ctx.fillText(topText, field === 'temp' ? 4 : 318, 42);
    ctx.fillText(bottomText, field === 'temp' ? 4 : 318, 170);
    ctx.strokeStyle = color;
    ctx.lineWidth = 3;
    ctx.beginPath();
    for (let index = 0; index < rows.length; index++) {
      const value = this.getMaterialMetric(rows[index], field);
      const x = 42 + (286 * index / (rows.length - 1));
      const y = 184 - ((value - minValue) * 142 / (maxValue - minValue));
      if (index === 0) {
        ctx.moveTo(x, y);
      } else {
        ctx.lineTo(x, y);
      }
    }
    ctx.stroke();
    ctx.fillStyle = color;
    for (let index = 0; index < rows.length; index++) {
      const value = this.getMaterialMetric(rows[index], field);
      const x = 42 + (286 * index / (rows.length - 1));
      const y = 184 - ((value - minValue) * 142 / (maxValue - minValue));
      ctx.beginPath();
      ctx.arc(x, y, 3, 0, 6.28);
      ctx.fill();
    }
  }

  private getMaterialMetric(row: MaterialSensorRecord, field: string): number {
    if (field === 'temp') {
      return Number(row.temp);
    }
    if (field === 'humi') {
      return Number(row.humi);
    }
    return 0;
  }

  private getMaterialHistorySummary(): string {
    if (this.materialHistoryRecords.length === 0) {
      return '\u6682\u65e0\u5386\u53f2\u6570\u636e\uff0c\u8bf7\u542f\u52a8\u91d1\u4ed3\u6750\u6599 API \u5e76\u7b49\u5f85\u534e\u4e3a\u4e91\u6570\u636e\u3002';
    }
    let text = '';
    const start = Math.max(this.materialHistoryRecords.length - 6, 0);
    for (let index = start; index < this.materialHistoryRecords.length; index++) {
      const row = this.materialHistoryRecords[index];
      text += this.timeFromIso(row.created_at) + '  Temp ' + row.temp + 'C  Humi ' + row.humi + '%  Lumi ' + row.lumi + '  \u706f\u5149 ' + row.lamp_status;
      if (index < this.materialHistoryRecords.length - 1) {
        text += '\n';
      }
    }
    return text;
  }

  private toNullableNumber(value: string): number | null {
    if (value === '--' || value === '') {
      return null;
    }
    return Number(value);
  }

  private login(): void {
    this.loginWithSupabase();
    return;
    const account = this.username.trim();
    const pwd = this.password.trim();
    if (account === '' || pwd === '') {
      this.loginError = 'Account and password cannot be empty';
      return;
    }
    const workerValid = this.loginRole === 'worker' && account === 'worker' && pwd === '123456';
    const adminValid = this.loginRole === 'admin' && account === 'admin' && pwd === '123456';
    if (!workerValid && !adminValid) {
      this.loginError = 'Account, password or role does not match';
      return;
    }
    this.currentRole = this.loginRole;
    this.activeTab = 'home';
    this.isLoggedIn = true;
  }

  private startAutoRefresh(): void {
    this.refreshCloudData();
    this.refreshAttendanceData();
    if (this.refreshTimer >= 0) {
      return;
    }
    this.refreshTimer = setInterval(() => {
      this.refreshCloudData();
      this.refreshAttendanceData();
      if (this.materialTwinOpen) {
        this.loadMaterialTwin();
      }
    }, 5000);
  }

  private stopAutoRefresh(): void {
    if (this.refreshTimer >= 0) {
      clearInterval(this.refreshTimer);
      this.refreshTimer = -1;
    }
  }

  private startWorkTimer(): void {
    if (this.workTimer >= 0) {
      return;
    }
    this.workTimer = setInterval(() => {
      this.updateLiveWorkDuration();
    }, 1000);
  }

  private stopWorkTimer(): void {
    if (this.workTimer >= 0) {
      clearInterval(this.workTimer);
      this.workTimer = -1;
    }
  }

  private updateLiveWorkDuration(): void {
    if (!this.isLoggedIn || this.currentRole !== 'worker') {
      return;
    }
    if (this.workerCheckInTimestamp === '' || this.workerCheckOutTimestamp !== '') {
      return;
    }
    this.workerWorkDuration = this.durationBetweenIso(this.workerCheckInTimestamp, new Date().toISOString());
  }

  private async refreshCloudData(): Promise<void> {
    if (this.syncing) {
      return;
    }
    this.syncing = true;
    this.cloudStatus = '\u540c\u6b65\u4e2d';
    this.woodCloudStatus = '\u540c\u6b65\u4e2d';
    try {
      const body = await this.requestIotdaShadowFor(CEMENT_IOTDA_CONFIG);
      const shadow = this.readShadowData(body, CEMENT_IOTDA_CONFIG);
      this.tempValue = this.getProperty(shadow.properties, CEMENT_IOTDA_CONFIG.temperatureProperty);
      this.humiValue = this.getProperty(shadow.properties, CEMENT_IOTDA_CONFIG.humidityProperty);
      this.distValue = this.getProperty(shadow.properties, 'Dist');
      this.lumiValue = this.getProperty(shadow.properties, 'Lumi');
      this.lampValue = this.getProperty(shadow.properties, 'LampST');
      this.cementFanSt = this.getProperty(shadow.properties, 'FanSt');
      this.shadowVersion = shadow.version;
      this.cloudStatus = '\u534e\u4e3a\u4e91\u5df2\u8fde\u63a5';
    } catch (error) {
      this.cloudStatus = '\u540c\u6b65\u5931\u8d25';
    }
    try {
      const woodBody = await this.requestIotdaShadowFor(WOOD_IOTDA_CONFIG);
      const woodShadow = this.readShadowData(woodBody, WOOD_IOTDA_CONFIG);
      this.woodTempValue = this.getProperty(woodShadow.properties, WOOD_IOTDA_CONFIG.temperatureProperty);
      this.woodHumiValue = this.getProperty(woodShadow.properties, WOOD_IOTDA_CONFIG.humidityProperty);
      this.woodLumiValue = this.getProperty(woodShadow.properties, 'Lumi');
      this.woodSmokeValue = this.getProperty(woodShadow.properties, 'Smoke');
      this.woodFanSt = this.getProperty(woodShadow.properties, 'FanSt');
      this.woodBuzzerSt = this.getProperty(woodShadow.properties, 'BuzzerSt');
      this.woodCo2Value = this.getProperty(woodShadow.properties, 'CO2');
      this.woodShadowVersion = woodShadow.version;
      this.woodCloudStatus = '\u534e\u4e3a\u4e91\u5df2\u8fde\u63a5';
    } catch (error) {
      this.woodCloudStatus = '\u540c\u6b65\u5931\u8d25: ' + this.errorToBrief(error);
    }
    this.lastSync = this.formatNow();
    this.refreshTick += 1;
    this.saveMaterialSensorRecord();
    this.syncing = false;
  }

  private async requestIotdaShadowFor(config: IotdaConfig): Promise<string> {
    if (config.proxyEndpoint !== '') {
      return await this.requestShadowViaProxy(config.proxyEndpoint);
    }
    const path = buildDeviceShadowPath(config);
    if (path === '') {
      throw new Error('Missing device shadow request path');
    }
    if (config.demoIamToken === '') {
        throw new Error('Missing X-Subject-Token');
    }

    const request = http.createHttp();
    try {
      const header: Record<string, string> = {
        'Content-Type': 'application/json',
        'X-Auth-Token': config.demoIamToken
      };
      if (!config.useAppEndpoint) {
        header['Instance-Id'] = config.instanceId;
      }
      const response = await request.request(config.endpoint + path, {
        method: http.RequestMethod.GET,
        expectDataType: http.HttpDataType.STRING,
        connectTimeout: 10000,
        readTimeout: 10000,
        header: header
      });
      const result = typeof response.result === 'string' ? response.result : JSON.stringify(response.result);
      if (response.responseCode < 200 || response.responseCode >= 300) {
        throw new Error('HTTP ' + response.responseCode + ': ' + result.substring(0, 120));
      }
      return result;
    } finally {
      request.destroy();
    }
  }

  private async requestShadowViaProxy(proxyUrl: string): Promise<string> {
    const request = http.createHttp();
    try {
      const response = await request.request(proxyUrl, {
        method: http.RequestMethod.GET,
        expectDataType: http.HttpDataType.STRING,
        connectTimeout: 10000,
        readTimeout: 10000
      });
      if (response.responseCode < 200 || response.responseCode >= 300) {
        throw new Error('HTTP ' + response.responseCode);
      }
      return typeof response.result === 'string' ? response.result : JSON.stringify(response.result);
    } finally {
      request.destroy();
    }
  }

  private async sendCementFanCommand(state: string, paras: CommandParas): Promise<void> {
    if (this.commandSending) {
      this.commandStatus = '\u4e0a\u4e00\u6761\u547d\u4ee4\u4ecd\u5728\u4e0b\u53d1\u4e2d';
      return;
    }
    this.commandSending = true;
    this.commandStatus = '\u6b63\u5728\u4e0b\u53d1 FanSt=' + state;
    try {
      await this.requestIotdaCommandFor(CEMENT_IOTDA_CONFIG, 'SetFan', paras);
      this.commandStatus = '\u547d\u4ee4\u5df2\u9001\u8fbe IoTDA\uff0c\u7b49\u5f85\u677f\u7aef\u4e0a\u62a5 FanSt';
      await this.delayMs(1500);
      await this.refreshCloudData();
      if (this.cementFanSt === state) {
        this.commandStatus = 'FanSt=' + state + ' \u5df2\u7531\u8bbe\u5907\u5f71\u5b50\u786e\u8ba4';
      } else {
        this.commandStatus = '\u547d\u4ee4\u5df2\u4e0b\u53d1\uff0c\u4f46\u5f71\u5b50 FanSt=' + this.cementFanSt + '\uff0c\u8bf7\u68c0\u67e5\u677f\u7aef\u547d\u4ee4\u5904\u7406\u548c\u5c5e\u6027\u4e0a\u62a5';
      }
    } catch (error) {
      this.commandStatus = '\u547d\u4ee4\u4e0b\u53d1\u5931\u8d25: ' + this.errorToBrief(error);
    }
    this.commandSending = false;
  }

  private async sendWoodFanCommand(state: string, paras: CommandParas): Promise<void> {
    if (this.woodCommandSending) {
      this.woodCommandStatus = '\u4e0a\u4e00\u6761\u547d\u4ee4\u4ecd\u5728\u4e0b\u53d1\u4e2d';
      return;
    }
    this.woodCommandSending = true;
    this.woodCommandStatus = '\u6b63\u5728\u4e0b\u53d1 FanSt=' + state;
    try {
      await this.requestIotdaCommandFor(WOOD_IOTDA_CONFIG, 'Fan', paras);
      this.woodCommandStatus = '\u547d\u4ee4\u5df2\u9001\u8fbe IoTDA\uff0c\u7b49\u5f85\u677f\u7aef\u4e0a\u62a5 FanSt';
      await this.delayMs(1500);
      await this.refreshCloudData();
      if (this.woodFanSt === state) {
        this.woodCommandStatus = 'FanSt=' + state + ' \u5df2\u7531\u8bbe\u5907\u5f71\u5b50\u786e\u8ba4';
      } else {
        this.woodCommandStatus = '\u547d\u4ee4\u5df2\u4e0b\u53d1\uff0c\u4f46\u5f71\u5b50 FanSt=' + this.woodFanSt + '\uff0c\u8bf7\u68c0\u67e5\u6728\u6750\u533a\u677f\u7aef\u547d\u4ee4\u5904\u7406\u548c\u5c5e\u6027\u4e0a\u62a5';
      }
    } catch (error) {
      this.woodCommandStatus = '\u6728\u6750\u533a\u547d\u4ee4\u4e0b\u53d1\u5931\u8d25: ' + this.errorToBrief(error);
    }
    this.woodCommandSending = false;
  }

  private delayMs(milliseconds: number): Promise<void> {
    return new Promise<void>((resolve: () => void) => {
      setTimeout(() => {
        resolve();
      }, milliseconds);
    });
  }

  private async requestIotdaCommandFor(config: IotdaConfig, commandName: string, paras: CommandParas): Promise<string> {
    if (config.demoIamToken === '' || config.projectId === '' || config.deviceId === '') {
      throw new Error('Missing IAM token or device config');
    }

    const path = '/v5/iot/' + config.projectId + '/devices/' + config.deviceId + '/commands';
    const cmdBody: Record<string, Object> = {
      'service_id': config.serviceId,
      'command_name': commandName,
      'paras': paras
    };
    const body = JSON.stringify(cmdBody);

    const request = http.createHttp();
    try {
      const header: Record<string, string> = {
        'Content-Type': 'application/json',
        'X-Auth-Token': config.demoIamToken
      };
      if (!config.useAppEndpoint) {
        header['Instance-Id'] = config.instanceId;
      }
      const response = await request.request(config.endpoint + path, {
        method: http.RequestMethod.POST,
        expectDataType: http.HttpDataType.STRING,
        connectTimeout: 10000,
        readTimeout: 10000,
        header: header,
        extraData: body
      });
      const result = typeof response.result === 'string' ? response.result : JSON.stringify(response.result);
      if (response.responseCode < 200 || response.responseCode >= 300) {
        throw new Error('HTTP ' + response.responseCode + ': ' + result.substring(0, 140));
      }
      return result;
    } finally {
      request.destroy();
    }
  }

  private readShadowData(body: string, config: IotdaConfig): ShadowData {
    const payload = JSON.parse(body) as Record<string, Object>;
    const shadowItems = payload['shadow'] as Array<Record<string, Object>>;
    if (!shadowItems) {
      throw new Error('Shadow data is empty');
    }
    for (let index = 0; index < shadowItems.length; index++) {
      const item = shadowItems[index];
      if (String(item['service_id']) !== config.serviceId) {
        continue;
      }
      const reported = item['reported'] as Record<string, Object>;
      const properties = reported['properties'] as Record<string, Object>;
      return {
        properties: properties,
        eventTime: this.objectToString(reported['event_time']),
        version: this.objectToString(item['version'])
      };
    }
    throw new Error('Service not found: ' + config.serviceId);
  }

  private async connectCamera(): Promise<void> {
    if (this.cameraConnected) {
      return;
    }
    try {
      this.tcpSocket = socket.constructTCPSocketInstance();
      const connectOptions: socket.TCPConnectOptions = {
        address: {
          address: this.cameraIpAddress,
          port: Number(this.cameraPort),
          family: 1
        },
        timeout: 10000
      };
      await this.tcpSocket.connect(connectOptions);
      this.cameraConnected = true;
      this.cameraStatus = '\u76d1\u63a7\u5df2\u8fde\u63a5';
      this.startCameraReceiver();
    } catch (error) {
      this.cameraConnected = false;
      this.cameraStatus = '\u76d1\u63a7\u8fde\u63a5\u5931\u8d25';
    }
  }

  private startCameraReceiver(): void {
    if (!this.tcpSocket) {
      return;
    }
    this.tcpSocket.on('message', (value: SocketMessage) => {
      this.processCameraData(value.message);
    });
    this.tcpSocket.on('error', () => {
      this.cameraStatus = '\u76d1\u63a7\u5f02\u5e38';
      this.disconnectCamera();
    });
    this.tcpSocket.on('close', () => {
      this.disconnectCamera();
    });
  }

  private async processCameraData(data: ArrayBuffer): Promise<void> {
    const newData = new Uint8Array(data);
    const tempBuffer = new Uint8Array(this.cameraBuffer.length + newData.length);
    tempBuffer.set(this.cameraBuffer);
    tempBuffer.set(newData, this.cameraBuffer.length);
    this.cameraBuffer = tempBuffer;

    const startMarker = this.findJpegStart(this.cameraBuffer);
    if (startMarker < 0) {
      if (this.cameraBuffer.length > 2048) {
        this.cameraBuffer = new Uint8Array(0);
      }
      return;
    }
    const endMarker = this.findJpegEnd(this.cameraBuffer, startMarker);
    if (endMarker < 0) {
      return;
    }

    const jpegData = this.cameraBuffer.slice(startMarker, endMarker + 2);
    await this.decodeCameraImage(jpegData);
    this.cameraBuffer = this.cameraBuffer.slice(endMarker + 2);
  }

  private findJpegStart(buffer: Uint8Array): number {
    for (let index = 0; index < buffer.length - 1; index++) {
      if (buffer[index] === 0xFF && buffer[index + 1] === 0xD8) {
        return index;
      }
    }
    return -1;
  }

  private findJpegEnd(buffer: Uint8Array, startIndex: number): number {
    for (let index = startIndex + 2; index < buffer.length - 1; index++) {
      if (buffer[index] === 0xFF && buffer[index + 1] === 0xD9) {
        return index;
      }
    }
    return -1;
  }

  private async decodeCameraImage(jpegData: Uint8Array): Promise<void> {
    try {
      const imageSource = image.createImageSource(jpegData.buffer);
      const decodingOptions: image.DecodingOptions = {
        desiredSize: {
          height: 480,
          width: 640
        },
        desiredPixelFormat: 3,
        desiredRegion: {
          size: {
            height: 480,
            width: 640
          },
          x: 0,
          y: 0
        }
      };
      this.cameraFrame = await imageSource.createPixelMap(decodingOptions);
      this.cloudVideoStatus = 'Video loaded';
    } catch (error) {
      this.cameraStatus = '\u5df2\u8fde\u63a5 ' + this.cameraIpAddress + ':' + this.cameraPort;
    }
  }

  private disconnectCamera(): void {
    if (this.tcpSocket) {
      this.tcpSocket.off('message');
      this.tcpSocket.off('error');
      this.tcpSocket.off('close');
      this.tcpSocket.close();
      this.tcpSocket = null;
    }
        this.cameraStatus = '\u6444\u50cf\u5934\u8fde\u63a5\u5931\u8d25';
    this.cameraBuffer = new Uint8Array(0);
    if (this.cameraStatus !== '\u8fde\u63a5\u5931\u8d25' && this.cameraStatus !== '\u753b\u9762\u89e3\u7801\u5931\u8d25') {
      this.cameraStatus = '\u6444\u50cf\u5934\u5f85\u8fde\u63a5';
    }
  }

  private getProperty(propertiesObject: Object, key: string): string {
    const properties = propertiesObject as Record<string, Object>;
    const value = properties[key];
    return value === undefined || value === '' ? '--' : String(value);
  }

  private objectToString(value: Object | undefined): string {
    return value === undefined ? '--' : String(value);
  }

  private errorToBrief(error: Object): string {
    const message = String(error);
    return message.length > 90 ? message.substring(0, 90) : message;
  }

  private withUnit(value: string, unit: string): string {
    return value === '--' ? '--' : value + unit;
  }

  private getCloudVideoUrl(): string {
    const host = this.cloudVideoHost.trim() === '' ? '39.107.224.246' : this.cloudVideoHost.trim();
    const port = this.cloudVideoHlsPort.trim() === '' ? '8888' : this.cloudVideoHlsPort.trim();
    const stream = this.cloudVideoStreamName.trim() === '' ? 'livecam' : this.cloudVideoStreamName.trim();
    return 'http://' + host + ':' + port + '/' + stream + '/';
  }

  private getRtspPushUrl(): string {
    const host = this.cloudVideoHost.trim() === '' ? '39.107.224.246' : this.cloudVideoHost.trim();
    const port = this.cloudVideoRtspPort.trim() === '' ? '8554' : this.cloudVideoRtspPort.trim();
    const stream = this.cloudVideoStreamName.trim() === '' ? 'livecam' : this.cloudVideoStreamName.trim();
    return 'rtsp://' + host + ':' + port + '/' + stream;
  }

  private reloadCloudVideo(): void {
    this.cloudVideoStatus = '\u91cd\u65b0\u52a0\u8f7d\u4e2d';
    this.cloudVideoController.loadUrl(this.getCloudVideoUrl());
  }

  private getCementStatus(): string {
    const temp = Number(this.tempValue);
    const humi = Number(this.humiValue);
    if (humi >= 65 || temp >= 35) {
      return '\u6b63\u5e38';
    }
    if (humi >= 60 || temp >= 32) {
      return '\u5728\u573a';
    }
    return '\u6b63\u5e38';
  }

  private getCementColor(): string {
    const status = this.getCementStatus();
    if (status === '\u6b63\u5e38') {
      return '#C2410C';
    }
    if (status === '\u5728\u573a') {
      return '#D97706';
    }
    return '#0E9F6E';
  }

  private getCementFanPlan(): string {
    const temp = Number(this.tempValue);
    if (this.tempValue === '--') {
      return '--';
    }
    return temp >= 32 ? 'On' : '\u5173\u95ed';
  }

  private getCementAlarmPlan(): string {
    const humi = Number(this.humiValue);
    if (this.humiValue === '--') {
      return '--';
    }
    return humi >= 60 ? 'Alarm' : '\u6b63\u5e38';
  }

  private getCloudColor(): string {
    if (this.cloudStatus === '\u534e\u4e3a\u4e91\u5df2\u8fde\u63a5') {
      return '#0E9F6E';
    }
    if (this.cloudStatus === '\u540c\u6b65\u5931\u8d25') {
      return '#C2410C';
    }
    return '#1769E0';
  }

  private getCloudBg(): string {
    if (this.cloudStatus === '\u534e\u4e3a\u4e91\u5df2\u8fde\u63a5') {
      return '#E8F7EF';
    }
    if (this.cloudStatus === '\u540c\u6b65\u5931\u8d25') {
      return '#FEEDE8';
    }
    return '#EAF2FF';
  }

  private clearAttendanceRecordSummary(message: string): void {
    this.attendanceRecordSummary = message;
    this.attendanceRecordCount = 0;
  }

  private async resetAttendanceRecordsOnCloud(): Promise<void> {
    if (this.currentAttendanceTaskId < 0) {
      this.resetAttendanceRecord();
      this.clearAttendanceRecordSummary('\u6682\u65e0\u6253\u5361\u4efb\u52a1');
      this.attendanceCloudStatus = 'No records to reset';
      return;
    }
    try {
      const path = '/rest/v1/attendance_records?task_id=eq.' + this.currentAttendanceTaskId;
      await this.supabaseRequest(path, 'DELETE' as http.RequestMethod);
      this.resetAttendanceRecord();
      this.clearAttendanceRecordSummary('\u6682\u65e0\u5de5\u4eba\u6253\u5361');
      this.attendanceCloudStatus = '\u6253\u5361\u8bb0\u5f55\u5df2\u91cd\u7f6e';
    } catch (error) {
      this.attendanceCloudStatus = '\u91cd\u7f6e\u6253\u5361\u5931\u8d25';
    }
  }

  private async publishAttendanceTaskToCloud(): Promise<void> {
    try {
      const body = JSON.stringify({
        title: '\u667a\u6167\u5de5\u5730\u4eca\u65e5\u6253\u5361',
        work_date: this.formatDate(new Date()),
        checkin_start: '07:30:00',
        checkin_end: '09:00:00',
        checkout_start: '17:30:00',
        checkout_end: '19:00:00',
        target_team: '\u4e00\u73ed\u7ec4',
        status: 'active',
        created_by: this.currentUserId > 0 ? this.currentUserId : 1
      });
      const response = await this.supabaseRequest('/rest/v1/attendance_tasks', http.RequestMethod.POST, body);
      const rows = JSON.parse(response) as Array<AttendanceTaskRow>;
      if (rows.length > 0) {
        this.applyAttendanceTask(rows[0]);
      }
      this.resetAttendanceRecord();
      this.clearAttendanceRecordSummary('\u6682\u65e0\u5de5\u4eba\u6253\u5361');
      this.attendanceCloudStatus = '\u6253\u5361\u4efb\u52a1\u5df2\u53d1\u5e03';
    } catch (error) {
      this.attendanceCloudStatus = '\u53d1\u5e03\u6253\u5361\u5931\u8d25';
    }
  }

  private async closeAttendanceTaskOnCloud(): Promise<void> {
    try {
      const path = this.currentAttendanceTaskId > 0
        ? '/rest/v1/attendance_tasks?id=eq.' + this.currentAttendanceTaskId
        : '/rest/v1/attendance_tasks?status=eq.active';
      await this.supabaseRequest(path, 'PATCH' as http.RequestMethod, JSON.stringify({ status: 'closed' }));
      this.workerHasTask = false;
      this.currentAttendanceTaskId = -1;
      this.resetAttendanceRecord();
      this.clearAttendanceRecordSummary('\u6682\u65e0\u6253\u5361\u4efb\u52a1');
      this.attendanceCloudStatus = '\u6253\u5361\u4efb\u52a1\u5df2\u5173\u95ed';
    } catch (error) {
      this.attendanceCloudStatus = '\u5173\u95ed\u6253\u5361\u5931\u8d25';
    }
  }

  private async workerCheckInToCloud(): Promise<void> {
    if (!this.workerHasTask || this.currentAttendanceTaskId < 0 || this.workerCheckInTime !== '') {
      return;
    }
    try {
      const now = new Date();
      const body = JSON.stringify({
        task_id: this.currentAttendanceTaskId,
        worker_id: this.workerCloudId,
        checkin_time: now.toISOString(),
        checkin_status: 'normal',
        work_minutes: 0
      });
      const response = await this.supabaseRequest('/rest/v1/attendance_records', http.RequestMethod.POST, body);
      const rows = JSON.parse(response) as Array<Record<string, Object>>;
      if (rows.length > 0) {
        this.applyAttendanceRecord(rows[0]);
      }
      this.attendanceCloudStatus = '\u7b7e\u5230\u6210\u529f';
    } catch (error) {
      this.attendanceCloudStatus = '\u7b7e\u5230\u5931\u8d25';
      await this.refreshAttendanceRecord();
    }
  }

  private async workerCheckOutToCloud(): Promise<void> {
    if (!this.workerHasTask || this.currentAttendanceTaskId < 0 || this.workerCheckInTime === '' || this.workerCheckOutTime !== '') {
      return;
    }
    try {
      const now = new Date();
      const checkoutTime = this.formatTime(now);
      const minutes = this.calculateWorkMinutes(this.workerCheckInTime, checkoutTime);
      const body = JSON.stringify({
        checkout_time: now.toISOString(),
        checkout_status: 'normal',
        work_minutes: minutes
      });
      const path = '/rest/v1/attendance_records?task_id=eq.' + this.currentAttendanceTaskId + '&worker_id=eq.' + this.workerCloudId;
      const response = await this.supabaseRequest(path, 'PATCH' as http.RequestMethod, body);
      const rows = JSON.parse(response) as Array<Record<string, Object>>;
      if (rows.length > 0) {
        this.applyAttendanceRecord(rows[0]);
      }
      this.attendanceCloudStatus = '\u7b7e\u9000\u6210\u529f';
    } catch (error) {
      this.attendanceCloudStatus = '\u7b7e\u9000\u5931\u8d25';
      await this.refreshAttendanceRecord();
    }
  }

  private publishAttendanceTask(): void {
    this.publishAttendanceTaskToCloud();
    return;
    this.workerHasTask = true;
    this.attendancePublishedAt = this.formatNow();
    this.resetAttendanceRecord();
  }

  private closeAttendanceTask(): void {
    this.closeAttendanceTaskOnCloud();
    return;
    this.workerHasTask = false;
  }

  private resetAttendanceRecord(): void {
    this.workerCheckInTime = '';
    this.workerCheckOutTime = '';
    this.workerCheckInTimestamp = '';
    this.workerCheckOutTimestamp = '';
    this.workerWorkDuration = '0h 0m 0s';
  }

  private getWorkerAttendanceStatus(): string {
    if (!this.workerHasTask) {
      return '\u65e0\u4efb\u52a1';
    }
    if (this.workerCheckInTime === '') {
      return '\u672a\u6253\u5361';
    }
    if (this.workerCheckOutTime === '') {
      return '\u7b7e\u9000';
    }
    return '\u5df2\u7b7e\u9000';
  }

  private getWorkerAttendanceColor(): string {
    const status = this.getWorkerAttendanceStatus();
    if (status === '\u5df2\u7b7e\u9000') {
      return '#0E9F6E';
    }
    if (status === '\u7b7e\u9000') {
      return '#D97706';
    }
    return '#C2410C';
  }

  private getWorkerActionText(): string {
    if (this.workerCheckInTime === '') {
      return '\u7b7e\u5230';
    }
    if (this.workerCheckOutTime === '') {
      return '\u7b7e\u9000';
    }
    return '\u5df2\u5b8c\u6210';
  }

  private getWorkerActionColor(): string {
    if (this.workerCheckInTime === '') {
      return '#1769E0';
    }
    if (this.workerCheckOutTime === '') {
      return '#0E9F6E';
    }
    return '#94A3B8';
  }

  private handleWorkerAttendanceAction(): void {
    if (this.workerCheckInTime === '') {
      this.workerCheckIn();
      return;
    }
    if (this.workerCheckOutTime === '') {
      this.workerCheckOut();
    }
  }

  private workerCheckIn(): void {
    this.workerCheckInToCloud();
    return;
    if (!this.workerHasTask || this.workerCheckInTime !== '') {
      return;
    }
    this.workerCheckInTime = this.formatNow();
  }

  private workerCheckOut(): void {
    this.workerCheckOutToCloud();
    return;
    if (!this.workerHasTask || this.workerCheckInTime === '' || this.workerCheckOutTime !== '') {
      return;
    }
    this.workerCheckOutTime = this.formatNow();
    this.workerWorkDuration = this.calculateWorkDuration(this.workerCheckInTime, this.workerCheckOutTime);
  }

  private durationFromRecord(row: Record<string, Object>): string {
    const checkIn = this.objectToString(row['checkin_time']);
    const checkOut = this.objectToString(row['checkout_time']);
    if (checkIn !== '' && checkIn !== '--' && checkIn !== 'null') {
      if (checkOut !== '' && checkOut !== '--' && checkOut !== 'null') {
        return this.durationBetweenIso(checkIn, checkOut);
      }
      return this.durationBetweenIso(checkIn, new Date().toISOString());
    }
    const minutes = Number(row['work_minutes']);
    return minutes > 0 ? this.secondsToDuration(minutes * 60) : '0h 0m 0s';
  }

  private durationBetweenIso(start: string, end: string): string {
    const startTime = new Date(start).getTime();
    const endTime = new Date(end).getTime();
    if (startTime <= 0 || endTime <= 0 || endTime < startTime) {
      return '0h 0m 0s';
    }
    return this.secondsToDuration(Math.floor((endTime - startTime) / 1000));
  }

  private secondsToDuration(totalSeconds: number): string {
    const seconds = Math.max(totalSeconds, 0);
    const hour = Math.floor(seconds / 3600);
    const minute = Math.floor((seconds % 3600) / 60);
    const second = seconds % 60;
    return hour + 'h ' + minute + 'm ' + second + 's';
  }

  private calculateWorkDuration(start: string, end: string): string {
    return this.secondsToDuration(this.calculateWorkMinutes(start, end) * 60);
  }

  private calculateWorkMinutes(start: string, end: string): number {
    const startParts = start.split(':');
    const endParts = end.split(':');
    if (startParts.length < 2 || endParts.length < 2) {
      return 0;
    }
    const startMinute = Number(startParts[0]) * 60 + Number(startParts[1]);
    const endMinute = Number(endParts[0]) * 60 + Number(endParts[1]);
    return Math.max(endMinute - startMinute, 0);
  }

  private minutesToDuration(duration: number): string {
    const hour = Math.floor(duration / 60);
    const minute = duration % 60;
    return minute === 0 ? hour + 'h' : hour + 'h ' + minute + 'm';
  }

  private formatDate(value: Date): string {
    const year = value.getFullYear();
    const month = String(value.getMonth() + 1).padStart(2, '0');
    const day = String(value.getDate()).padStart(2, '0');
    return String(year) + '-' + month + '-' + day;
  }

  private formatTime(value: Date): string {
    const hour = String(value.getHours()).padStart(2, '0');
    const minute = String(value.getMinutes()).padStart(2, '0');
    return hour + ':' + minute;
  }

  private timePart(value: string): string {
    if (value === '' || value === '--') {
      return '--';
    }
    return value.length >= 5 ? value.substring(0, 5) : value;
  }

  private timeFromIso(value: string): string {
    if (value === '' || value === '--' || value === 'null') {
      return '';
    }
    const date = new Date(value);
    if (String(date) === 'Invalid Date') {
      return '';
    }
    return this.formatTime(date);
  }

  private formatNow(): string {
    const now = new Date();
    const hour = String(now.getHours()).padStart(2, '0');
    const minute = String(now.getMinutes()).padStart(2, '0');
    return hour + ':' + minute;
  }
}
