export const API_PATHS = {
  AUTH_LOGIN: '/api/auth/login',
  AUTH_REGISTER: '/api/auth/register',
  AUTH_USERS: '/api/auth/users',
  SYSTEM_LOGS_OVERVIEW: '/api/system/logs/overview',
  LOGIN_LOGS_RECENT: '/api/system/logs/login/recent',
  OPERATION_LOGS_RECENT: '/api/system/logs/operation/recent',
  APPEAL_WORKFLOW_EVENT: (appealId, event) =>
    `/api/workflow/appeals/${appealId}/events/${event}`,
  AI_CHAT_STREAM: '/api/ai/chat',
};
