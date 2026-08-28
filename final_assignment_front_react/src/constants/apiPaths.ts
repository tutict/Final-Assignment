export const API_PATHS = {
  AUTH_LOGIN: '/api/auth/login',
  AUTH_REGISTER: '/api/auth/register',
  AUTH_USERS: '/api/auth/users',
  AUTH_REFRESH: '/api/auth/refresh',
  AUTH_LOGOUT: '/api/auth/logout',
  AUTH_ME: '/api/auth/me',
  USERS: '/api/users',
  USERS_ME: '/api/users/me',
  USERS_ME_PASSWORD: '/api/users/me/password',
  USERS_BY_ID: (userId: string | number) => `/api/users/${userId}`,
  USERS_BY_USERNAME: (username: string) =>
    `/api/users/search/username/${encodeURIComponent(username)}`,
  DRIVERS: '/api/drivers',
  DRIVERS_BY_ID: (driverId: string | number) => `/api/drivers/${driverId}`,
  VEHICLES: '/api/vehicles',
  OFFENSES: '/api/offenses',
  DEDUCTIONS: '/api/deductions',
  FINES: '/api/fines',
  PAYMENTS: '/api/payments',
  OFFENSE_TYPES: '/api/offense-types',
  PROGRESS: '/api/progress',
  PROGRESS_BY_STATUS: '/api/progress/status',
  PROGRESS_BY_TIME_RANGE: '/api/progress/timeRange',
  ROLES: '/api/roles',
  PERMISSIONS: '/api/permissions',
  SYSTEM_LOGS: '/api/system/logs',
  SYSTEM_SETTINGS: '/api/system/settings',
  SYSTEM_BACKUP: '/api/system/backup',
  LOGIN_LOGS: '/api/logs/login',
  OPERATION_LOGS: '/api/logs/operation',
  LOGIN_LOGS_SEARCH_USERNAME: '/api/logs/login/search/username',
  LOGIN_LOGS_SEARCH_RESULT: '/api/logs/login/search/result',
  LOGIN_LOGS_SEARCH_TIME_RANGE: '/api/logs/login/search/time-range',
  OPERATION_LOGS_SEARCH_USER: (userId: string | number) =>
    `/api/logs/operation/search/user/${userId}`,
  OPERATION_LOGS_SEARCH_RESULT: '/api/logs/operation/search/result',
  OPERATION_LOGS_SEARCH_TIME_RANGE: '/api/logs/operation/search/time-range',
  SYSTEM_LOGS_OVERVIEW: '/api/system/logs/overview',
  LOGIN_LOGS_RECENT: '/api/system/logs/login/recent',
  OPERATION_LOGS_RECENT: '/api/system/logs/operation/recent',
  REQUEST_HISTORY_BY_ID: (historyId: string | number) =>
    `/api/system/logs/requests/${historyId}`,
  REQUEST_HISTORY_SEARCH: (field: RequestHistorySearchField) =>
    `/api/system/logs/requests/search/${field}`,
  APPEAL_LIST: '/api/appeals',
  APPEAL_WORKFLOW_EVENT: (appealId: string | number, event: string) =>
    `/api/workflow/appeals/${appealId}/events/${event}`,
  // AI 聊天：POST + SSE，对齐 Flutter AiChatApi（/api/ai/chat/stream）
  AI_CHAT: '/api/ai/chat',
  AI_CHAT_STREAM: '/api/ai/chat/stream',
  AI_CHAT_ACTIONS: '/api/ai/chat/actions',
  // RAG 管理（仅超级管理员，对齐后端 RagManagementController /api/rag/admin）
  RAG_ADMIN: '/api/rag/admin',
  RAG_OVERVIEW: '/api/rag/admin/overview',
  RAG_DOCUMENTS: '/api/rag/admin/documents',
  RAG_DOCUMENTS_UPLOAD: '/api/rag/admin/documents/upload',
  RAG_DOCUMENTS_MANUAL: '/api/rag/admin/documents/manual',
  RAG_DOCUMENTS_BY_ID: (documentId: string) => `/api/rag/admin/documents/${documentId}`,
  RAG_BACKFILL: '/api/rag/admin/backfill',
  RAG_BACKFILL_RUN: '/api/rag/admin/backfill/run',
  RAG_EMBEDDING_RUN: '/api/rag/admin/embedding/run',
  RAG_EMBEDDING_REQUEUE: '/api/rag/admin/embedding/requeue',
  RAG_INDEX_MIGRATE: '/api/rag/admin/index/migrate',
  FEEDBACK: '/api/feedback',
  FEEDBACK_BY_ID: (id: string | number) => `/api/feedback/${id}`,
} as const;

export type RequestHistorySearchField =
  | 'idempotency'
  | 'method'
  | 'url'
  | 'business-type'
  | 'business-id'
  | 'status'
  | 'user'
  | 'ip'
  | 'time-range';
