import http from 'k6/http';
import { check, sleep } from 'k6';
import { Rate } from 'k6/metrics';

// 自定义指标
const errorRate = new Rate('errors');

// 测试配置
export const options = {
  stages: [
    { duration: '30s', target: 10 },  // 预热：30秒内增加到10个用户
    { duration: '1m', target: 10 },   // 稳定：保持10个用户1分钟
    { duration: '30s', target: 0 },   // 冷却：30秒内降到0
  ],
  thresholds: {
    'http_req_duration': ['p(95)<1000'],  // 95% 的请求在 1s 内完成
    'errors': ['rate<0.1'],                // 错误率低于 10%
  },
};

// 测试数据
const testMessages = [
  '交通违章如何处理？',
  '查询我的违章记录',
  '罚款如何缴纳？',
  '驾驶证扣分规则',
  '电子眼拍照后多久能查到？',
];

export default function () {
  const url = 'http://localhost:8081/api/ai/chat/stream';

  // 随机选择测试消息
  const message = testMessages[Math.floor(Math.random() * testMessages.length)];

  const payload = JSON.stringify({
    message: message,
    sessionKey: `session-${__VU}-${__ITER}`,  // 虚拟用户ID-迭代次数
    metadata: {
      ragEnabled: Math.random() > 0.5,  // 50% 概率启用 RAG
      topK: 5,
      userId: `user-${__VU}`,
      roles: ['DRIVER'],
    },
  });

  const params = {
    headers: {
      'Content-Type': 'application/json',
    },
    timeout: '30s',
  };

  const response = http.post(url, payload, params);

  // 验证响应
  const checkResult = check(response, {
    'status is 200': (r) => r.status === 200,
    'response has SSE content-type': (r) =>
      r.headers['Content-Type'] && r.headers['Content-Type'].includes('text/event-stream'),
    'response body is not empty': (r) => r.body && r.body.length > 0,
    'response contains data': (r) => r.body && r.body.includes('data:'),
  });

  // 记录错误
  errorRate.add(!checkResult);

  // 模拟用户思考时间
  sleep(Math.random() * 2 + 1); // 1-3秒
}
