import { useState } from 'react';

export function useConfirm(action, { onSuccess, onError } = {}) {
  const [loading, setLoading] = useState(false);

  const confirm = async (...args) => {
    setLoading(true);
    try {
      const result = await action(...args);
      onSuccess?.(result);
      return result;
    } catch (error) {
      onError?.(error);
    } finally {
      setLoading(false);
    }
  };

  return { confirm, loading };
}
