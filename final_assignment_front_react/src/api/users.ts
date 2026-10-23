/**
 * 用户管理 API，对齐后端 UserManagementController（/api/users，SUPER_ADMIN / ADMIN）。
 * 对齐 Flutter UserManagementControllerApi。
 * 列表与检索端点返回裸 JSON 数组（无分页包装），检索参数 page/size 为 1-based。
 */
import { api, generateIdempotencyKey } from './client';
import { listAllPages, unwrapPayload } from './entities';
import { API_PATHS } from '../constants/apiPaths';

export interface ManagedUser {
  userId?: number;
  username?: string;
  realName?: string;
  gender?: string;
  contactNumber?: string;
  email?: string;
  department?: string;
  position?: string;
  employeeNumber?: string;
  status?: string;
  accountExpiryDate?: string;
  lastLoginTime?: string;
  remarks?: string;
  [key: string]: unknown;
}

export interface ManagedUserInput {
  username?: string;
  realName?: string;
  gender?: string;
  contactNumber?: string;
  email?: string;
  department?: string;
  position?: string;
  employeeNumber?: string;
  status?: string;
  accountExpiryDate?: string;
  remarks?: string;
  password?: string;
}

const DEFAULT_PAGE = 1;

async function searchUsers(
  path: string,
  params: Record<string, string | number>
): Promise<ManagedUser[]> {
  return listAllPages<ManagedUser>(path, { ...params, page: DEFAULT_PAGE });
}

/** GET /api/users —— 全量用户列表（后端分页，自动翻页取全量）。 */
export async function listUsers(): Promise<ManagedUser[]> {
  return listAllPages<ManagedUser>(API_PATHS.USERS);
}

/** GET /api/users/search/username/prefix —— 按账号前缀检索。 */
export function searchUsersByUsernamePrefix(username: string): Promise<ManagedUser[]> {
  return searchUsers(API_PATHS.USERS_SEARCH_USERNAME_PREFIX, { username });
}

/** GET /api/users/search/real-name/prefix —— 按姓名前缀检索。 */
export function searchUsersByRealNamePrefix(realName: string): Promise<ManagedUser[]> {
  return searchUsers(API_PATHS.USERS_SEARCH_REAL_NAME_PREFIX, { realName });
}

/** GET /api/users/search/contact —— 按联系电话检索。 */
export function searchUsersByContact(contactNumber: string): Promise<ManagedUser[]> {
  return searchUsers(API_PATHS.USERS_SEARCH_CONTACT, { contactNumber });
}

/** GET /api/users/search/status —— 按状态检索。 */
export function searchUsersByStatus(status: string): Promise<ManagedUser[]> {
  return searchUsers(API_PATHS.USERS_SEARCH_STATUS, { status });
}

/** GET /api/users/search/department —— 按部门检索。 */
export function searchUsersByDepartment(department: string): Promise<ManagedUser[]> {
  return searchUsers(API_PATHS.USERS_SEARCH_DEPARTMENT, { department });
}

/** POST /api/users —— 新建用户。 */
export async function createUser(payload: ManagedUserInput): Promise<ManagedUser | null> {
  const response = await api.post<unknown>(API_PATHS.USERS, payload, {
    headers: { 'Idempotency-Key': generateIdempotencyKey() },
  });
  const body = unwrapPayload<unknown>(response.data);
  if (!body || typeof body !== 'object') {
    return null;
  }
  const record = body as Record<string, unknown>;
  return (record.data && typeof record.data === 'object'
    ? record.data
    : record) as ManagedUser;
}

/** PUT /api/users/{userId} —— 更新用户。 */
export async function updateUser(
  userId: string | number,
  payload: ManagedUserInput
): Promise<void> {
  await api.put(API_PATHS.USERS_BY_ID(userId), payload, {
    headers: { 'Idempotency-Key': generateIdempotencyKey() },
  });
}

/** DELETE /api/users/{userId} —— 删除用户。 */
export async function deleteUser(userId: string | number): Promise<void> {
  await api.delete(API_PATHS.USERS_BY_ID(userId));
}
