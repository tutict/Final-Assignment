import http from 'k6/http';
import { check, sleep } from 'k6';
import { Rate, Trend } from 'k6/metrics';

// 自定义指标
const errorRate = new Rate('errors');
const responseTime = new Trend('response_time_ms');

// 压力测试配置 - 找出系统极限
export const options = {
  stages: [
    { duration: '2m', target: 50 },    // 快速增加到50用户
    { duration: '5m', target: 100 },   // 增加到100用户
    { duration: '5m', target: 200 },   // 增加到200用户
    { duration: '5m', target: 300 },   // 增加到300用户 - 测试极限
    { duration: '2m', target: 400 },   // 推向崩溃点
    { duration: '5m', target: 400 },   // 保持最大压力
    { duration: '3m', target: 0 },     // 恢复
  ],
  thresholds: {
    'http_req_duration': ['p(95)<5000'],  // 放宽阈值
    'http_req_failed': ['rate<0.2'],      // 允许更高的失败率
  },
};

const BASE_URL = 'http://localhost:8081';

const messages = [
  '测试消息1',
  '测试消息2',
  '测试消息3',
  '压力测试查询',
];

export default function () {
  const message = messages[Math.floor(Math.random() * messages.length)];

  const payload = JSON.stringify({
    message: message,
    sessionKey: `stress-${__VU}-${__ITER}`,
    metadata: {
      ragEnabled: false,  // 减少外部依赖
      userId: `stress-user-${__VU}`,
      roles: ['DRIVER'],
    },
  });

  const params = {
    headers: {
      'Content-Type': 'application/json',
    },
    timeout: '90s',  // 更长的超时时间
  };

  const start = Date.now();
  const response = http.post(`${BASE_URL}/api/ai/chat/stream`, payload, params);
  const duration = Date.now() - start;

  responseTime.add(duration);

  const success = check(response, {
    'status is 200': (r) => r.status === 200,
    'has content': (r) => r.body && r.body.length > 0,
  });

  errorRate.add(!success);

  if (!success) {
    console.log(`[VU ${__VU}] Failed: Status=${response.status}, Duration=${duration}ms`);
  }

  // 最小延迟，快速发送请求
  sleep(0.5 + Math.random() * 0.5); // 0.5-1秒
}

export function handleSummary(data) {
  const summary = {
    timestamp: new Date().toISOString(),
    test_type: 'stress',
    total_requests: data.metrics.http_reqs.values.count,
    request_rate: data.metrics.http_reqs.values.rate,
    response_times: {
      avg: data.metrics.http_req_duration.values.avg,
      min: data.metrics.http_req_duration.values.min,
      max: data.metrics.http_req_duration.values.max,
      p50: data.metrics.http_req_duration.values.med,
      p95: data.metrics.http_req_duration.values['p(95)'],
      p99: data.metrics.http_req_duration.values['p(99)'],
    },
    error_rate: data.metrics.http_req_failed.values.rate,
    vus_max: data.metrics.vus_max.values.max,
  };

  return {
    'stress-test-results.json': JSON.stringify(summary, null, 2),
  };
}
