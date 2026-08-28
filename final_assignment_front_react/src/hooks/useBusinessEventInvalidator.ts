import { useEffect, useMemo, useState } from 'react';
import { useQueryClient } from '@tanstack/react-query';
import { useBusinessEvents, type BusinessEvent } from '../realtime/BusinessEventContext';

/**
 * 订阅业务事件，在申诉/支付状态变化时失效 React Query 缓存。
 * 返回一个 invalidate 函数，便于页面在事件到来时主动刷新指定 query。
 * 对齐 Flutter `BusinessEventListener` 派发后的列表刷新行为。
 */
export function useBusinessEventInvalidator(): (queryKeys: string[][]) => void {
  const queryClient = useQueryClient();
  const { subscribe } = useBusinessEvents();

  const [pendingKeys, setPendingKeys] = useState<string[][]>([]);

  useEffect(() => {
    const unsubscribe = subscribe((event: BusinessEvent) => {
      if (event.type === 'APPEAL_STATUS_CHANGED') {
        setPendingKeys((prev) => [...prev, ['appeals'], ['userAppeals']]);
      } else if (event.type === 'PAYMENT_STATUS_CHANGED') {
        setPendingKeys((prev) => [...prev, ['payments'], ['fines'], ['offenses']]);
      }
    });
    return unsubscribe;
  }, [subscribe]);

  useEffect(() => {
    if (pendingKeys.length === 0) return;
    for (const key of pendingKeys) {
      void queryClient.invalidateQueries({ queryKey: key });
    }
    setPendingKeys([]);
  }, [pendingKeys, queryClient]);

  return useMemo(
    () => (queryKeys: string[][]) => {
      for (const key of queryKeys) {
        void queryClient.invalidateQueries({ queryKey: key });
      }
    },
    [queryClient]
  );
}
