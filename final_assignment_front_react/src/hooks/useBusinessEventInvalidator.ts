import { useEffect } from 'react';
import { useQueryClient } from '@tanstack/react-query';
import { useBusinessEvents } from '../realtime/BusinessEventContext';
import { appealManagementKeys } from './useAppealManagement';

/**
 * 订阅业务事件，在申诉/支付状态变化时失效对应 React Query 缓存。
 * 对齐 Flutter `BusinessEventListener` 派发后的列表刷新行为。
 */
export function useBusinessEventInvalidator(): void {
  const queryClient = useQueryClient();
  const { subscribe } = useBusinessEvents();

  useEffect(() => {
    const unsubscribe = subscribe((event) => {
      if (event.type === 'APPEAL_STATUS_CHANGED') {
        void queryClient.invalidateQueries({ queryKey: appealManagementKeys.listPrefix() });
        void queryClient.invalidateQueries({ queryKey: ['appeals'] });
        void queryClient.invalidateQueries({ queryKey: ['userAppeals'] });
        void queryClient.invalidateQueries({
          queryKey: appealManagementKeys.detail(event.payload.appealId),
        });
      } else if (event.type === 'PAYMENT_STATUS_CHANGED') {
        void queryClient.invalidateQueries({ queryKey: ['payments'] });
        void queryClient.invalidateQueries({ queryKey: ['fines'] });
      }
    });
    return unsubscribe;
  }, [subscribe, queryClient]);
}
