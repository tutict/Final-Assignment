export function getErrorMessage(error) {
  const status = error?.response?.status;
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
    case 400: {
      const detail = error?.response?.data?.message;
      return detail ? `提交数据有误：${detail}` : '提交的数据格式不正确';
    }
    case 500:
    case 502:
    case 503:
      return '服务器暂时不可用，请稍后重试';
    default:
      return error?.message ?? '操作失败，请稍后重试';
  }
}
