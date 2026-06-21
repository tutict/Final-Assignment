import http from 'k6/http';
import { check, sleep } from 'k6';
import { Rate } from 'k6/metrics';

const errorRate = new Rate('errors');

// 峰值测试配置 - 模拟突发流量
export const options = {
  stages: [
    { duration: '10s', target: 10 },    // 正常流量
    { duration: '1m', target: 10 },     // 稳定
    { duration: '10s', target: 200 },   // 突然激增！
    { duration: '3m', target: 200 },    // 保持高峰
    { duration: '10s', target: 10 },    // 快速降低
    { duration: '3m', target: 10 },     // 恢复正常
    { duration: '10s', target: 0 },     // 结束
  ],
  thresholds: {
    'http_req_duration': ['p(95)<3000'],
    'errors': ['rate<0.15'],  // 峰值时允许更高错误率
  },
};

const BASE_URL = 'http://localhost:8081';

export default function () {
  const payload = JSON.stringify({
    message: '峰值测试查询',
    sessionKey: `spike-${__VU}-${__ITER}`,
    metadata: {
      ragEnabled: false,
      userId: `spike-user-${__VU}`,
      roles: ['DRIVER'],
    },
  });

  const response = http.post(`${BASE_URL}/api/ai/chat/stream`, payload, {
    headers: { 'Content-Type': 'application/json' },
    timeout: '60s',
  });

  const success = check(response, {
    'status is 200': (r) => r.status === 200,
    'has content': (r) => r.body?.length > 0,
  });

  errorRate.add(!success);

  sleep(1);
}
