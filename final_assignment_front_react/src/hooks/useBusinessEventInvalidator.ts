import { useEffect, useMemo } from 'react';
import { useQueryClient } from '@tanstack/react-query';
import { useBusinessEvents, type BusinessEvent } from '../realtime/BusinessEventContext';

function eventQueryKeys(event: BusinessEvent): string[][] {
  if (event.type === 'APPEAL_STATUS_CHANGED') {
    return [['appeals'], ['userAppeals']];
  }
  if (event.type === 'PAYMENT_STATUS_CHANGED') {
    return [['payments'], ['fines'], ['offenses']];
  }
  return [];
}

/**
 * 订阅业务事件，在申诉/支付状态变化时失效 React Query 缓存。
 * 返回一个 invalidate 函数，便于页面在事件到来时主动刷新指定 query。
 * 对齐 Flutter `BusinessEventListener` 派发后的列表刷新行为。
 */
export function useBusinessEventInvalidator(): (queryKeys: string[][]) => void {
  const queryClient = useQueryClient();
  const { subscribe } = useBusinessEvents();

  useEffect(() => {
    const unsubscribe = subscribe((event: BusinessEvent) => {
      for (const key of eventQueryKeys(event)) {
        void queryClient.invalidateQueries({ queryKey: key });
      }
    });
    return unsubscribe;
  }, [subscribe, queryClient]);

  return useMemo(
    () => (queryKeys: string[][]) => {
      for (const key of queryKeys) {
        void queryClient.invalidateQueries({ queryKey: key });
      }
    },
    [queryClient]
  );
}
