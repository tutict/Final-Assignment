import http from 'k6/http';
import { check } from 'k6';

export const BACKENDS = {
  spring: { name: 'spring', envKey: 'BASE_URL_SPRING', baseUrl: 'http://127.0.0.1:8080' },
  cloud: { name: 'cloud', envKey: 'BASE_URL_CLOUD', baseUrl: 'http://127.0.0.1:8080' },
  go: { name: 'go', envKey: 'BASE_URL_GO', baseUrl: 'http://127.0.0.1:8080' },
  quarkus: { name: 'quarkus', envKey: 'BASE_URL_QUARKUS', baseUrl: 'http://127.0.0.1:8080' },
};

export function backendName() {
  return String(__ENV.BACKEND || __ENV.PERF_BACKEND || 'spring').toLowerCase();
}

export function resolveBaseUrl(name) {
  const backendKey = String(name || backendName()).toLowerCase();
  const explicit = (__ENV.BASE_URL || '').replace(/\/$/, '');
  if (explicit && !name) {
    return explicit;
  }
  const spec = BACKENDS[backendKey] || BACKENDS.spring;
  const fromEnv = (__ENV[spec.envKey] || '').replace(/\/$/, '');
  if (fromEnv) {
    return fromEnv;
  }
  if (explicit) {
    return explicit;
  }
  return spec.baseUrl;
}

export function healthPaths() {
  return [
    '/actuator/health/liveness',
    '/actuator/health',
    '/q/health/live',
    '/api/health',
    '/api/actuator/health',
    '/readyz',
  ];
}

export function unwrap(payload) {
  if (!payload || typeof payload !== 'object') {
    return payload;
  }
  if (Object.prototype.hasOwnProperty.call(payload, 'data') &&
      (payload.success === true || payload.success === false || payload.errorCode || payload.message)) {
    return payload.data;
  }
  return payload;
}

export function jsonBody(response) {
  try {
    return unwrap(response.json());
  } catch (_) {
    return null;
  }
}

export function rawJson(response) {
  try {
    return response.json();
  } catch (_) {
    return null;
  }
}

export function accessToken(response) {
  const body = rawJson(response) || {};
  return body.accessToken || body.jwtToken || body.token || unwrap(body)?.accessToken || unwrap(body)?.jwtToken;
}

export function jsonHeaders(endpoint) {
  return {
    headers: {
      'Content-Type': 'application/json',
      Accept: 'application/json',
      Connection: 'keep-alive',
    },
    tags: endpoint ? { endpoint } : undefined,
  };
}

export function authHeaders(token, endpoint) {
  return {
    headers: {
      Authorization: `Bearer ${token}`,
      'Content-Type': 'application/json',
      Accept: 'application/json',
    },
    tags: endpoint ? { endpoint } : undefined,
  };
}

export function streamHeaders(token, endpoint) {
  return {
    headers: {
      Authorization: `Bearer ${token}`,
      'Content-Type': 'application/json',
      Accept: 'text/event-stream',
      Connection: 'keep-alive',
    },
    tags: endpoint ? { endpoint } : undefined,
  };
}

export function login(baseUrl, username, password, endpoint) {
  return http.post(
    `${baseUrl}/api/auth/login`,
    JSON.stringify({ username, password }),
    jsonHeaders(endpoint || 'login'),
  );
}

export function assertLogin(response, username) {
  const ok = check(response, {
    [`${username} login status is 200`]: (r) => r.status === 200,
    [`${username} login has token`]: (r) => Boolean(accessToken(r)),
  });
  if (!ok) {
    throw new Error(`Login failed for ${username}: status=${response.status} body=${response.body}`);
  }
}

export function parseSseEvents(body) {
  const events = [];
  const lines = String(body || '').split(/\r?\n/);
  let currentType = '';
  for (const line of lines) {
    const trimmed = line.trim();
    if (!trimmed) {
      continue;
    }
    if (trimmed.startsWith('event:')) {
      currentType = trimmed.slice(6).trim();
      continue;
    }
    if (!trimmed.startsWith('data:')) {
      continue;
    }
    const raw = trimmed.slice(5).trim();
    if (!raw || raw === '[DONE]') {
      continue;
    }
    try {
      const parsed = JSON.parse(raw);
      if (parsed && typeof parsed === 'object') {
        if (!parsed.type && currentType) {
          parsed.type = currentType;
        }
        events.push(parsed);
      }
    } catch (_) {
      events.push({ type: currentType || 'token', token: raw });
    }
    currentType = '';
  }
  return events;
}

export function sseTypes(body) {
  return new Set(parseSseEvents(body).map((event) => String(event.type || '').toLowerCase()).filter(Boolean));
}

export function sseHas(body, type) {
  return sseTypes(body).has(String(type).toLowerCase());
}

export function ragResults(response) {
  const body = jsonBody(response);
  if (Array.isArray(body)) {
    return body;
  }
  if (Array.isArray(body?.results)) {
    return body.results;
  }
  if (Array.isArray(body?.hits)) {
    return body.hits;
  }
  return [];
}

export function ragDocuments(response) {
  const body = jsonBody(response);
  if (Array.isArray(body)) {
    return body;
  }
  if (Array.isArray(body?.items)) {
    return body.items;
  }
  if (Array.isArray(body?.records)) {
    return body.records;
  }
  if (Array.isArray(body?.content)) {
    return body.content;
  }
  return [];
}

export function firstDocumentId(response) {
  const docs = ragDocuments(response);
  const first = docs[0];
  if (!first) {
    return '';
  }
  return first.id || first.documentId || first.document?.id || '';
}
