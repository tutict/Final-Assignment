/**
 * 当前用户资料与驾驶员档案 API。
 * 对齐 Flutter UserProfileService / DriverInformationControllerApi / UserManagementControllerApi。
 */
import { api, generateIdempotencyKey } from "./client";
import { API_PATHS } from "../constants/apiPaths";

export interface UserProfile {
  authUserId?: number;
  username?: string;
  displayName?: string;
  email?: string;
  phoneNumber?: string;
  roles?: string[];
  driverId?: number;
  driverName?: string;
}

export interface DriverInformation {
  driverId?: number;
  authUserId?: number;
  name?: string;
  idCardNumber?: string;
  gender?: string;
  birthdate?: string;
  contactNumber?: string;
  email?: string;
  address?: string;
  driverLicenseNumber?: string;
  licenseType?: string;
  allowedVehicleType?: string;
  firstLicenseDate?: string;
  issueDate?: string;
  expiryDate?: string;
  issuingAuthority?: string;
  currentPoints?: number;
  totalDeductedPoints?: number;
  status?: string;
  createdAt?: string;
  updatedAt?: string;
  remarks?: string;
  [key: string]: unknown;
}

export interface SysUser {
  userId?: number;
  username?: string;
  password?: string;
  email?: string;
  phoneNumber?: string;
  realName?: string;
  status?: string;
  createdTime?: string;
  modifiedTime?: string;
  remarks?: string;
  [key: string]: unknown;
}

/** GET /api/auth/me —— 当前用户档案（对齐 Flutter getCurrentProfile）。 */
export async function getCurrentProfile(): Promise<UserProfile> {
  const response = await api.get<UserProfile>(API_PATHS.AUTH_ME);
  return response.data || {};
}

/** GET /api/users/search/username/{username} —— 按用户名查询用户（管理员端用）。 */
export async function getUserByUsername(username: string): Promise<SysUser | null> {
  try {
    const response = await api.get<SysUser>(API_PATHS.USERS_BY_USERNAME(username));
    return response.data || null;
  } catch {
    return null;
  }
}

/** GET /api/drivers/{driverId} —— 驾驶员档案。 */
export async function getDriver(driverId: string | number): Promise<DriverInformation | null> {
  try {
    const response = await api.get<DriverInformation>(API_PATHS.DRIVERS_BY_ID(driverId));
    return response.data || null;
  } catch {
    return null;
  }
}

/** PUT /api/drivers/{driverId} —— 全量更新驾驶员档案（对齐 Flutter updateDriver）。 */
export async function updateDriver(
  driverId: string | number,
  payload: DriverInformation
): Promise<DriverInformation> {
  const response = await api.put<DriverInformation>(
    API_PATHS.DRIVERS_BY_ID(driverId),
    payload,
    { headers: { "Idempotency-Key": generateIdempotencyKey() } }
  );
  return response.data || {};
}

/** PUT /api/users/{userId} —— 更新用户（密码/邮箱/备注等，对齐 Flutter updateUser）。 */
export async function updateUser(
  userId: string | number,
  payload: Partial<SysUser>
): Promise<SysUser> {
  const response = await api.put<SysUser>(API_PATHS.USERS_BY_ID(userId), payload, {
    headers: { "Idempotency-Key": generateIdempotencyKey() },
  });
  return response.data || {};
}

/** PUT /api/users/me/password —— 修改当前用户密码（对齐 Flutter updateCurrentPassword）。 */
export async function updateCurrentPassword(newPassword: string): Promise<void> {
  await api.put(API_PATHS.USERS_ME_PASSWORD, JSON.stringify(newPassword), {
    headers: {
      "Content-Type": "text/plain; charset=utf-8",
      "Idempotency-Key": generateIdempotencyKey(),
    },
  });
}

/** PUT /api/users/me —— 更新当前用户基本信息（对齐 Flutter UpdateCurrentUser）。 */
export async function updateCurrentUser(
  payload: Partial<SysUser>
): Promise<void> {
  await api.put(API_PATHS.USERS_ME, payload, {
    headers: { "Idempotency-Key": generateIdempotencyKey() },
  });
}
