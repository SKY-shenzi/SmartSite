const crypto = require('crypto');
const http = require('http');
const https = require('https');

const config = {
  ak: process.env.HUAWEI_AK || '',
  sk: process.env.HUAWEI_SK || '',
  endpointHost: process.env.IOTDA_ENDPOINT_HOST || 'iotda.cn-north-4.myhuaweicloud.com',
  projectId: process.env.HUAWEI_PROJECT_ID || '0e7c5e04a662439c813433f94d7ad4e7',
  instanceId: process.env.IOTDA_INSTANCE_ID || '97ea8a7a-5cdb-4b0d-a4ae-3285825e26e8',
  appId: process.env.IOTDA_APP_ID || 'f7671bc74b254ad2bdfe9417fe9919a9',
  deviceId: process.env.IOTDA_DEVICE_ID || '6a3a6e8e7f2e6c302f7e2b06_GongDone',
  serviceId: process.env.IOTDA_SERVICE_ID || 'smartdevice',
  tempProperty: process.env.IOTDA_TEMP_PROPERTY || 'Temp',
  humiProperty: process.env.IOTDA_HUMI_PROPERTY || 'Humi',
  port: Number(process.env.PORT || 8787)
};

function sha256Hex(value) {
  return crypto.createHash('sha256').update(value, 'utf8').digest('hex');
}

function hmacSha256Hex(secret, value) {
  return crypto.createHmac('sha256', secret).update(value, 'utf8').digest('hex');
}

function utcStamp() {
  return new Date().toISOString().replace(/[-:]/g, '').replace(/\.\d{3}Z$/, 'Z');
}

function encodeQueryValue(value) {
  return encodeURIComponent(value).replace(/[!'()*]/g, (char) =>
    `%${char.charCodeAt(0).toString(16).toUpperCase()}`
  );
}

function buildAuthorization(method, canonicalUri, query, headers, payload) {
  const signedHeaders = Object.keys(headers).map((key) => key.toLowerCase()).sort();
  const canonicalHeaders = signedHeaders
    .map((key) => `${key}:${headers[key].trim().replace(/\s+/g, ' ')}\n`)
    .join('');
  const canonicalQueryString = Object.keys(query)
    .sort()
    .map((key) => `${encodeQueryValue(key)}=${encodeQueryValue(query[key])}`)
    .join('&');
  const canonicalRequest = [
    method,
    canonicalUri,
    canonicalQueryString,
    canonicalHeaders,
    signedHeaders.join(';'),
    sha256Hex(payload)
  ].join('\n');
  const stringToSign = [
    'SDK-HMAC-SHA256',
    headers['x-sdk-date'],
    sha256Hex(canonicalRequest)
  ].join('\n');
  return `SDK-HMAC-SHA256 Access=${config.ak}, SignedHeaders=${signedHeaders.join(';')}, Signature=${hmacSha256Hex(config.sk, stringToSign)}`;
}

function callIotdaShadow() {
  return new Promise((resolve, reject) => {
    if (!config.ak || !config.sk) {
      reject(new Error('Missing HUAWEI_AK or HUAWEI_SK'));
      return;
    }
    if (!config.projectId) {
      reject(new Error('Missing HUAWEI_PROJECT_ID for cn-north-4'));
      return;
    }

    const method = 'GET';
    const canonicalUri = `/v5/iot/${config.projectId}/devices/${encodeURIComponent(config.deviceId)}/shadow`;
    const query = { app_id: config.appId };
    const payload = '';
    const headers = {
      'content-type': 'application/json',
      'host': config.endpointHost,
      'instance-id': config.instanceId,
      'x-sdk-date': utcStamp()
    };
    const authorization = buildAuthorization(method, canonicalUri, query, headers, payload);
    const path = `${canonicalUri}?app_id=${encodeQueryValue(config.appId)}`;

    const req = https.request({
      method,
      hostname: config.endpointHost,
      path,
      headers: {
        'Authorization': authorization,
        'Content-Type': headers['content-type'],
        'Host': headers.host,
        'Instance-Id': headers['instance-id'],
        'X-Sdk-Date': headers['x-sdk-date']
      },
      timeout: 12000
    }, (res) => {
      let body = '';
      res.setEncoding('utf8');
      res.on('data', (chunk) => {
        body += chunk;
      });
      res.on('end', () => {
        if (res.statusCode < 200 || res.statusCode >= 300) {
          reject(new Error(`IoTDA HTTP ${res.statusCode}: ${body}`));
          return;
        }
        resolve(body);
      });
    });

    req.on('timeout', () => {
      req.destroy(new Error('IoTDA request timeout'));
    });
    req.on('error', reject);
    req.end();
  });
}

function parseShadow(body) {
  const payload = JSON.parse(body);
  const service = (payload.shadow || []).find((item) => item.service_id === config.serviceId);
  const properties = service && service.reported && service.reported.properties ? service.reported.properties : {};
  return {
    source: 'iotda',
    serviceId: config.serviceId,
    temperature: properties[config.tempProperty] === undefined ? '' : String(properties[config.tempProperty]),
    humidity: properties[config.humiProperty] === undefined ? '' : String(properties[config.humiProperty]),
    raw: payload
  };
}

const server = http.createServer(async (req, res) => {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');

  if (req.method === 'OPTIONS') {
    res.writeHead(204);
    res.end();
    return;
  }

  if (req.method !== 'GET' || req.url.split('?')[0] !== '/api/iotda/shadow') {
    res.writeHead(404, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ error: 'Not found' }));
    return;
  }

  try {
    const shadowBody = await callIotdaShadow();
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify(parseShadow(shadowBody)));
  } catch (error) {
    res.writeHead(502, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ error: error.message }));
  }
});

server.listen(config.port, '0.0.0.0', () => {
  console.log(`IoTDA proxy listening on http://0.0.0.0:${config.port}/api/iotda/shadow`);
});
