import { API_PATHS } from '../constants/apiPaths.js';
import { api } from './client';

export async function login(payload) {
  const response = await api.post(API_PATHS.AUTH_LOGIN, payload);
  return response.data;
}

export async function register(payload) {
  const response = await api.post(API_PATHS.AUTH_REGISTER, payload);
  return response.data;
}

export async function getAllUsers() {
  const response = await api.get(API_PATHS.AUTH_USERS);
  return response.data;
}
