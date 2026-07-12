export interface IotdaConfig {
  endpoint: string;
  region: string;
  instanceId: string;
  resourceSpaceId: string;
  resourceSpaceName: string;
  productName: string;
  productId: string;
  projectId: string;
  deviceId: string;
  serviceId: string;
  temperatureProperty: string;
  humidityProperty: string;
  demoIamToken: string;
  proxyEndpoint: string;
  useAppEndpoint: boolean;
}

export const CEMENT_IOTDA_CONFIG: IotdaConfig = {
  endpoint: 'https://b638a00e86.st1.iotda-app.cn-north-4.myhuaweicloud.com',
  region: 'cn-north-4',
  instanceId: 'd4aaa476-be7d-427e-b4d5-d57127c817e1',
  resourceSpaceId: '',
  resourceSpaceName: 'default',
  productName: 'cementzone',
  productId: '6a43ab67cbb0cf6bb96a911c',
  projectId: 'd7384f5ae8bf47cdb3192322e34705e0',
  deviceId: '6a43ab67cbb0cf6bb96a911c_1234',
  serviceId: '123',
  temperatureProperty: 'Temp',
  humidityProperty: 'Humi',
  demoIamToken: '',
  proxyEndpoint: '',
  useAppEndpoint: true
};

export const WOOD_IOTDA_CONFIG: IotdaConfig = {
  endpoint: 'https://b349431dee.st1.iotda-app.cn-north-4.myhuaweicloud.com:443',
  region: 'cn-north-4',
  instanceId: '97ea8a7a-5cdb-4b0d-a4ae-3285825e26e8',
  resourceSpaceId: 'f7671bc74b254ad2bdfe9417fe9919a9',
  resourceSpaceName: 'training-space',
  productName: 'SmartDevice',
  productId: '6a3a6e8e7f2e6c302f7e2b06',
  projectId: '0e7c5e04a662439c813433f94d7ad4e7',
  deviceId: '6a3a6e8e7f2e6c302f7e2b06_GongDone',
  serviceId: 'smartdevice',
  temperatureProperty: 'Temp',
  humidityProperty: 'Humi',
  demoIamToken: '',
  proxyEndpoint: '',
  useAppEndpoint: true
};

export function buildDeviceListPath(config: IotdaConfig): string {
  if (config.projectId === '') {
    return '';
  }
  if (config.useAppEndpoint) {
    return `/v5/iot/${config.projectId}/devices?product_id=${config.productId}`;
  }
  return `/v5/iot/${config.projectId}/devices?product_id=${config.productId}&app_id=${config.resourceSpaceId}`;
}

export function buildDeviceShadowPath(config: IotdaConfig): string {
  if (config.projectId === '' || config.deviceId === '') {
    return '';
  }
  if (config.useAppEndpoint) {
    return `/v5/iot/${config.projectId}/devices/${config.deviceId}/shadow`;
  }
  return `/v5/iot/${config.projectId}/devices/${config.deviceId}/shadow?app_id=${config.resourceSpaceId}`;
}

export function hasDirectIotdaTarget(config: IotdaConfig): boolean {
  return config.projectId !== '' && config.deviceId !== '' && config.demoIamToken !== '';
}

export function hasProxyTarget(config: IotdaConfig): boolean {
  return config.proxyEndpoint !== '';
}
