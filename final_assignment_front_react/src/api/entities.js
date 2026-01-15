import { api, generateIdempotencyKey } from './client';

export async function listEntities(basePath, params) {
  const response = await api.get(basePath, { params });
  return response.data;
}

export async function getEntity(basePath, id) {
  const response = await api.get(`${basePath}/${id}`);
  return response.data;
}

export async function createEntity(basePath, payload) {
  const response = await api.post(basePath, payload, {
    headers: {
      'Idempotency-Key': generateIdempotencyKey(),
    },
  });
  return response.data;
}

export async function updateEntity(basePath, id, payload) {
  const response = await api.put(`${basePath}/${id}`, payload, {
    headers: {
      'Idempotency-Key': generateIdempotencyKey(),
    },
  });
  return response.data;
}

export async function deleteEntity(basePath, id) {
  const response = await api.delete(`${basePath}/${id}`);
  return response.data;
}

export async function postWithIdempotency(url, payload) {
  const response = await api.post(url, payload, {
    headers: {
      'Idempotency-Key': generateIdempotencyKey(),
    },
  });
  return response.data;
}

export async function putWithIdempotency(url, payload) {
  const response = await api.put(url, payload, {
    headers: {
      'Idempotency-Key': generateIdempotencyKey(),
    },
  });
  return response.data;
}

