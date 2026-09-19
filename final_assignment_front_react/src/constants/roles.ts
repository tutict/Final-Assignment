export type RoleCode = 'USER' | 'ADMIN' | 'SUPER_ADMIN' | 'APPEAL_REVIEWER';

export const ROLES = {
  USER: 'USER',
  ADMIN: 'ADMIN',
  SUPER_ADMIN: 'SUPER_ADMIN',
  APPEAL_REVIEWER: 'APPEAL_REVIEWER',
} as const satisfies Record<string, RoleCode>;

export type RoleValue = (typeof ROLES)[keyof typeof ROLES];

export const ROLE_LABELS: Record<string, string> = {
  USER: '普通用户',
  ADMIN: '管理员',
  SUPER_ADMIN: '超级管理员',
  APPEAL_REVIEWER: '申诉审核员',
};

export function resolveRoleLabel(role: string | undefined): string {
  if (!role) {
    return ROLE_LABELS.USER;
  }
  return ROLE_LABELS[role] || ROLE_LABELS[role.replace(/^ROLE_/, '')] || '普通用户';
}
