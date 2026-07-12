import { Want } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { formBindingData, FormExtensionAbility, formInfo, formProvider } from '@kit.FormKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

const DOMAIN = 0x0000;
const FORM_ID_KEY = 'ohos.extra.param.key.form_identity';

interface CardData {
  formId: string;
  siteName: string;
  onlineMonitors: string;
  temperature: string;
  humidity: string;
  workers: string;
  alerts: string;
  refreshTime: string;
  updateSource: string;
}

export default class EntryFormAbility extends FormExtensionAbility {
  onAddForm(want: Want): formBindingData.FormBindingData {
    const formId = this.getFormId(want);
    hilog.info(DOMAIN, 'SmartSiteCard', 'onAddForm, formId=%{public}s', formId);
    return formBindingData.createFormBindingData(this.createCardData(formId, '\u73b0\u573a\u6570\u636e'));
  }

  onCastToNormalForm(formId: string): void {
    hilog.info(DOMAIN, 'SmartSiteCard', 'onCastToNormalForm, formId=%{public}s', formId);
  }

  onUpdateForm(formId: string): void {
    hilog.info(DOMAIN, 'SmartSiteCard', 'onUpdateForm, formId=%{public}s', formId);
    this.updateFormData(formId, '\u81ea\u52a8\u5237\u65b0');
  }

  onChangeFormVisibility(newStatus: Record<string, number>): void {
    hilog.info(DOMAIN, 'SmartSiteCard', 'onChangeFormVisibility: %{public}s', JSON.stringify(newStatus));
  }

  onFormEvent(formId: string, message: string): void {
    hilog.info(DOMAIN, 'SmartSiteCard', 'onFormEvent, formId=%{public}s, message=%{public}s', formId, message);
    this.updateFormData(formId, '\u624b\u52a8\u5237\u65b0');
  }

  onRemoveForm(formId: string): void {
    hilog.info(DOMAIN, 'SmartSiteCard', 'onRemoveForm, formId=%{public}s', formId);
  }

  onAcquireFormState(want: Want): formInfo.FormState {
    hilog.info(DOMAIN, 'SmartSiteCard', 'onAcquireFormState');
    return formInfo.FormState.READY;
  }

  private updateFormData(formId: string, source: string): void {
    const data = formBindingData.createFormBindingData(this.createCardData(formId, source));
    formProvider.updateForm(formId, data).then(() => {
      hilog.info(DOMAIN, 'SmartSiteCard', 'updateForm success, formId=%{public}s', formId);
    }).catch((error: BusinessError) => {
      hilog.error(DOMAIN, 'SmartSiteCard', 'updateForm failed: %{public}s', JSON.stringify(error));
    });
  }

  private createCardData(formId: string, source: string): CardData {
    const now = new Date();
    const month = `${now.getMonth() + 1}`.padStart(2, '0');
    const day = `${now.getDate()}`.padStart(2, '0');
    const hour = `${now.getHours()}`.padStart(2, '0');
    const minute = `${now.getMinutes()}`.padStart(2, '0');

    return {
      formId,
      siteName: '\u667a\u6167\u5de5\u5730',
      onlineMonitors: '12/13',
      temperature: '26.8 C',
      humidity: '66%',
      workers: '86',
      alerts: '2',
      refreshTime: `${month}-${day} ${hour}:${minute}`,
      updateSource: source
    };
  }

  private getFormId(want: Want): string {
    const parameters = want.parameters as Record<string, Object> | undefined;
    const formId = parameters?.[FORM_ID_KEY];
    return formId ? `${formId}` : '';
  }
}
