import http from 'k6/http';
import { check, sleep } from 'k6';
import { Rate, Trend, Counter } from 'k6/metrics';

// 自定义指标
const errorRate = new Rate('errors');
const responseTime = new Trend('response_time');
const successfulRequests = new Counter('successful_requests');

// 负载测试配置 - 模拟真实用户负载
export const options = {
  stages: [
    { duration: '1m', target: 20 },   // 1分钟增加到20用户
    { duration: '3m', target: 50 },   // 3分钟增加到50用户
    { duration: '5m', target: 50 },   // 保持50用户5分钟
    { duration: '2m', target: 100 },  // 2分钟增加到100用户
    { duration: '5m', target: 100 },  // 保持100用户5分钟
    { duration: '2m', target: 0 },    // 2分钟降到0
  ],
  thresholds: {
    'http_req_duration': ['p(95)<2000', 'p(99)<5000'],
    'http_req_failed': ['rate<0.05'],  // 失败率低于 5%
    'errors': ['rate<0.05'],
  },
};

const BASE_URL = 'http://localhost:8081';

// 测试场景
const scenarios = {
  driver: {
    messages: [
      '我的违章记录在哪里查？',
      '交通罚款如何缴纳？',
      '驾驶证扣分怎么处理？',
      '电子眼拍照多久能查到？',
    ],
    role: 'DRIVER',
    ragEnabled: true,
  },
  admin: {
    messages: [
      '本月违章统计报表',
      '查看部门违章处理情况',
      '用户投诉处理进度',
    ],
    role: 'ADMIN',
    ragEnabled: true,
  },
};

export default function () {
  // 80% 司机用户，20% 管理员用户
  const scenario = Math.random() < 0.8 ? scenarios.driver : scenarios.admin;

  const message = scenario.messages[Math.floor(Math.random() * scenario.messages.length)];

  const payload = JSON.stringify({
    message: message,
    sessionKey: `load-test-${__VU}-${__ITER}`,
    metadata: {
      ragEnabled: scenario.ragEnabled,
      topK: 5,
      userId: `user-${__VU}`,
      roles: [scenario.role],
      temperature: 0.7,
    },
  });

  const params = {
    headers: {
      'Content-Type': 'application/json',
    },
    timeout: '60s',
  };

  const startTime = new Date().getTime();
  const response = http.post(`${BASE_URL}/api/ai/chat/stream`, payload, params);
  const duration = new Date().getTime() - startTime;

  // 记录响应时间
  responseTime.add(duration);

  // 详细验证
  const checks = check(response, {
    'status is 200': (r) => r.status === 200,
    'has SSE headers': (r) => r.headers['Content-Type']?.includes('text/event-stream'),
    'response not empty': (r) => r.body?.length > 0,
    'contains session data': (r) => r.body?.includes('sessionKey'),
    'contains tokens': (r) => r.body?.includes('"type":"token"') || r.body?.includes('"type":"done"'),
  });

  if (checks) {
    successfulRequests.add(1);
  } else {
    errorRate.add(1);
    console.log(`Request failed: VU=${__VU}, Iter=${__ITER}, Status=${response.status}`);
  }

  // 模拟真实用户行为
  sleep(Math.random() * 5 + 2); // 2-7秒思考时间
}

export function handleSummary(data) {
  return {
    'load-test-summary.json': JSON.stringify(data, null, 2),
    'stdout': textSummary(data, { indent: ' ', enableColors: true }),
  };
}

function textSummary(data, options) {
  const indent = options?.indent || '';
  const colors = options?.enableColors || false;

  let output = '\n' + indent + '负载测试总结\n';
  output += indent + '='.repeat(50) + '\n\n';

  // 请求统计
  const httpReqs = data.metrics.http_reqs;
  output += indent + `总请求数: ${httpReqs.values.count}\n`;
  output += indent + `请求速率: ${httpReqs.values.rate.toFixed(2)} req/s\n\n`;

  // 响应时间
  const httpDuration = data.metrics.http_req_duration;
  output += indent + '响应时间:\n';
  output += indent + `  平均: ${httpDuration.values.avg.toFixed(2)}ms\n`;
  output += indent + `  最小: ${httpDuration.values.min.toFixed(2)}ms\n`;
  output += indent + `  最大: ${httpDuration.values.max.toFixed(2)}ms\n`;
  output += indent + `  P95: ${httpDuration.values['p(95)'].toFixed(2)}ms\n`;
  output += indent + `  P99: ${httpDuration.values['p(99)'].toFixed(2)}ms\n\n`;

  // 成功率
  const httpFailed = data.metrics.http_req_failed;
  const successRate = (1 - httpFailed.values.rate) * 100;
  output += indent + `成功率: ${successRate.toFixed(2)}%\n`;
  output += indent + `失败率: ${(httpFailed.values.rate * 100).toFixed(2)}%\n`;

  return output;
}
