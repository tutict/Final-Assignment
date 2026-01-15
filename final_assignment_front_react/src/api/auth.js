import { api } from './client';

export async function login(payload) {
  const response = await api.post('/api/auth/login', payload);
  return response.data;
}

export async function register(payload) {
  const response = await api.post('/api/auth/register', payload);
  return response.data;
}

export async function getAllUsers() {
  const response = await api.get('/api/auth/users');
  return response.data;
}

