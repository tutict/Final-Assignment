import http from 'k6/http';
import { check, sleep } from 'k6';
import { Counter, Rate, Trend } from 'k6/metrics';

const restUrl = (__ENV.KAFKA_REST_URL || 'http://127.0.0.1:8082').replace(/\/$/, '');
const topic = __ENV.KAFKA_TOPIC || 'perf-kafka-http';
const duration = __ENV.PERF_DURATION || '20s';
const rate = Number(__ENV.PERF_KAFKA_RATE || '20');
const vus = Number(__ENV.PERF_KAFKA_VUS || '16');
const maxVUs = Number(__ENV.PERF_KAFKA_MAX_VUS || String(Math.max(vus * 2, 32)));
const batchSize = Number(__ENV.PERF_KAFKA_BATCH_SIZE || '10');
const payloadBytes = Number(__ENV.PERF_KAFKA_PAYLOAD_BYTES || '256');
const strict = (__ENV.PERF_STRICT || 'false').toLowerCase() === 'true';

const produceSuccess = new Rate('kafka_pandaproxy_produce_success');
const produceLatency = new Trend('kafka_pandaproxy_produce_ms', true);
const recordsSent = new Counter('kafka_pandaproxy_records_sent');

export const options = {
  scenarios: {
    kafka_pandaproxy_produce: {
      executor: 'constant-arrival-rate',
      rate,
      timeUnit: '1s',
      duration,
      preAllocatedVUs: vus,
      maxVUs: maxVUs,
    },
  },
  thresholds: strict
    ? {
        kafka_pandaproxy_produce_success: ['rate>0.99'],
        kafka_pandaproxy_produce_ms: ['p(95)<500', 'p(99)<1000'],
      }
    : {},
};

export function setup() {
  const res = http.get(`${restUrl}/topics`, {
    tags: { endpoint: 'pandaproxy_topics' },
  });
  check(res, {
    'pandaproxy topics reachable': (r) => r.status === 200,
    'target topic exists': (r) => r.body && r.body.includes(`"${topic}"`),
  });
}

function buildValue(iteration, index) {
  const marker = `${__VU}-${iteration}-${index}`;
  const paddingSize = Math.max(payloadBytes - marker.length, 0);
  return {
    traceId: marker,
    source: 'k6-pandaproxy',
    payload: 'x'.repeat(paddingSize),
    timestamp: Date.now(),
  };
}

export default function () {
  const iteration = __ITER;
  const records = [];
  for (let i = 0; i < batchSize; i += 1) {
    records.push({
      key: `k6-${__VU}-${iteration}-${i}`,
      value: buildValue(iteration, i),
    });
  }

  const res = http.post(
    `${restUrl}/topics/${topic}`,
    JSON.stringify({ records }),
    {
      headers: {
        Accept: 'application/vnd.kafka.v2+json, application/json',
        'Content-Type': 'application/vnd.kafka.json.v2+json',
      },
      tags: { endpoint: 'pandaproxy_produce' },
    },
  );

  const ok = res.status >= 200 && res.status < 300;
  produceSuccess.add(ok);
  produceLatency.add(res.timings.duration);
  if (ok) {
    recordsSent.add(batchSize);
  }
  check(res, {
    'produce accepted': () => ok,
  });
  sleep(0.01);
}
