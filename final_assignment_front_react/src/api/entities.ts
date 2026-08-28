import { api, generateIdempotencyKey } from './client';

type Params = Record<string, unknown>;

export async function listEntities<T = unknown[]>(basePath: string, params?: Params): Promise<T> {
  const response = await api.get<T>(basePath, { params });
  return response.data;
}

export async function getEntity<T = unknown>(basePath: string, id: string | number): Promise<T> {
  const response = await api.get<T>(`${basePath}/${id}`);
  return response.data;
}

export async function createEntity<T = unknown>(basePath: string, payload: unknown): Promise<T> {
  const response = await api.post<T>(basePath, payload, {
    headers: {
      'Idempotency-Key': generateIdempotencyKey(),
    },
  });
  return response.data;
}

export async function updateEntity<T = unknown>(
  basePath: string,
  id: string | number,
  payload: unknown
): Promise<T> {
  const response = await api.put<T>(`${basePath}/${id}`, payload, {
    headers: {
      'Idempotency-Key': generateIdempotencyKey(),
    },
  });
  return response.data;
}

export async function deleteEntity<T = unknown>(basePath: string, id: string | number): Promise<T> {
  const response = await api.delete<T>(`${basePath}/${id}`);
  return response.data;
}

export async function postWithIdempotency<T = unknown>(url: string, payload: unknown): Promise<T> {
  const response = await api.post<T>(url, payload, {
    headers: {
      'Idempotency-Key': generateIdempotencyKey(),
    },
  });
  return response.data;
}

export async function putWithIdempotency<T = unknown>(url: string, payload: unknown): Promise<T> {
  const response = await api.put<T>(url, payload, {
    headers: {
      'Idempotency-Key': generateIdempotencyKey(),
    },
  });
  return response.data;
}
