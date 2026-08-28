import { useState } from 'react';
import { getErrorMessage } from '../utils/errorMessages';

interface UseConfirmOptions {
  onSuccess?: (result: unknown) => void;
  onError?: (error: unknown) => void;
}

export function useConfirm(
  action: (...args: unknown[]) => Promise<unknown>,
  { onSuccess, onError }: UseConfirmOptions = {}
) {
  const [loading, setLoading] = useState(false);

  const confirm = async (...args: unknown[]): Promise<unknown | undefined> => {
    setLoading(true);
    try {
      const result = await action(...args);
      onSuccess?.(result);
      return result;
    } catch (error) {
      console.error('[useConfirm] action failed:', error);
      if (onError) {
        onError(error);
      } else {
        alert(getErrorMessage(error));
      }
    } finally {
      setLoading(false);
    }
  };

  return { confirm, loading };
}
