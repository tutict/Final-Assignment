/**
 * @hook useConfirm
 * @description 包装确认类异步动作，统一提供 loading 状态与成功/失败回调。
 *
 * @param {(...args: unknown[]) => Promise<unknown>} action - 需要确认后执行的异步函数；confirm 会把参数原样传给它。
 * @param {{ onSuccess?: (result: unknown) => void, onError?: (error: unknown) => void }} [options] - 回调配置。
 *
 * @returns {{
 *   confirm: (...args: unknown[]) => Promise<unknown|undefined>,  // 执行 action，并在完成后触发对应回调
 *   loading: boolean,  // action 执行期间为 true，通常用于禁用按钮防止重复点击
 * }}
 *
 * @example
 * const modal = useModalState();
 * const { confirm, loading } = useConfirm(
 *   () => deleteEntity(modal.activeRow.id),
 *   { onSuccess: modal.close }
 * );
 *
 * @notes
 * - onSuccess 在 action resolve 后触发，参数为 action 返回值。
 * - onError 在 action reject 后触发，参数为捕获到的 error；confirm 会吞掉该错误并返回 undefined。
 * - loading 只覆盖当前 Hook 实例的 action 执行过程，调用方应据此禁用确认按钮。
 */
import { useState } from 'react';
import { getErrorMessage } from '../utils/errorMessages.js';

export function useConfirm(action, { onSuccess, onError } = {}) {
  const [loading, setLoading] = useState(false);

  const confirm = async (...args) => {
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
