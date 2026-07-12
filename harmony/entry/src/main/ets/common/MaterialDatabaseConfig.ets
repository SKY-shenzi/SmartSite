export interface MaterialDatabaseConfig {
  apiBaseUrl: string;
  zoneCode: string;
  zoneName: string;
  requestTimeoutMs: number;
}

export const MATERIAL_DATABASE_CONFIG: MaterialDatabaseConfig = {
  // Kingbase material API running on your computer/server.
  // If your LAN IP changes, update this value.
  apiBaseUrl: 'http://172.22.54.210:8088',
  zoneCode: 'cement_zone',
  zoneName: '\u6c34\u6ce5\u5b58\u50a8\u533a',
  requestTimeoutMs: 10000
};

export function buildMaterialRecordsPath(limit: number = 24, zoneCode: string = MATERIAL_DATABASE_CONFIG.zoneCode): string {
  return `/api/material-records?zoneCode=${encodeURIComponent(zoneCode)}&limit=${limit}`;
}
