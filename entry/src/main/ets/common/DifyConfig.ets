export interface DifyConfig {
  apiUrl: string;
  apiKey: string;
  user: string;
}

export const DIFY_CONFIG: DifyConfig = {
  apiUrl: 'http://172.22.54.210/v1/chat-messages',
  apiKey: '',
  user: 'devstudio-user'
};
