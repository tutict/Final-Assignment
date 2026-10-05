interface ApiError {
  response?: {
    status?: number;
    data?: { message?: string };
  };
  message?: string;
}

function fieldMessages(data: unknown): string {
  if (!data || typeof data !== "object") return "";
  const rows = (data as { data?: unknown }).data;
  if (!Array.isArray(rows)) return "";
  return rows
    .map((item) => {
      if (!item || typeof item !== "object") return "";
      return String((item as { message?: unknown }).message || "").trim();
    })
    .filter(Boolean)
    .join("；");
}

export function getErrorMessage(error: unknown): string {
  const e = (error || {}) as ApiError;
  const status = e.response?.status;
  const fields = fieldMessages(e.response?.data);
  const isOffline =
    typeof window !== 'undefined' && window.navigator && !window.navigator.onLine;

  if (!status && isOffline) {
    return '网络连接已断开，请检查网络设置';
  }

  switch (status) {
    case 401:
      return '登录已过期，请重新登录';
    case 403:
      return '您没有权限执行此操作';
    case 404:
      return '请求的数据不存在';
    case 422:
    case 400:
    case 409: {
      const detail = e.response?.data?.message;
      if (status === 409) {
        return fields || (detail && detail !== '数据约束冲突' ? detail : '数据冲突，请检查是否重复提交');
      }
      return fields || (detail ? `提交数据有误：${detail}` : '提交的数据格式不正确');
    }
    case 500:
    case 502:
    case 503:
      return '服务器暂时不可用，请稍后重试';
    default:
      return e.message ?? '操作失败，请稍后重试';
  }
}
