export type RoleCode = 'USER' | 'ADMIN' | 'SUPER_ADMIN' | 'APPEAL_REVIEWER';

export const ROLES = {
  USER: 'USER',
  ADMIN: 'ADMIN',
  SUPER_ADMIN: 'SUPER_ADMIN',
  APPEAL_REVIEWER: 'APPEAL_REVIEWER',
} as const satisfies Record<string, RoleCode>;

export type RoleValue = (typeof ROLES)[keyof typeof ROLES];
