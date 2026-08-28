/**
 * 业务事件 WebSocket 监听器（React 版）。
 *
 * 对齐 Flutter `BusinessEventListener`：连接 `/eventbus/websocket`，
 * 派发 `APPEAL_STATUS_CHANGED` / `PAYMENT_STATUS_CHANGED` 事件，
 * 并在 `ASYNC_OPERATION_FAILED` 时触发回调。
 *
 * 使用 React Context + 自定义事件订阅模式，替代 Flutter 的 GetxService Stream。
 */
import {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useMemo,
  useRef,
  useState,
  type ReactNode,
} from 'react';

export interface AppealStatusChange {
  appealId: number;
  newStatus: string;
  updatedAt?: string;
}

export interface PaymentStatusChange {
  paymentId: number;
  newStatus: string;
  fineId?: number;
  updatedAt?: string;
}

export type BusinessEvent =
  | { type: 'APPEAL_STATUS_CHANGED'; payload: AppealStatusChange }
  | { type: 'PAYMENT_STATUS_CHANGED'; payload: PaymentStatusChange }
  | { type: 'ASYNC_OPERATION_FAILED'; message: string };

type Listener = (event: BusinessEvent) => void;

interface BusinessEventContextValue {
  connected: boolean;
  subscribe: (listener: Listener) => () => void;
}

const BusinessEventContext = createContext<BusinessEventContextValue | null>(null);

const WS_BASE =
  import.meta.env.VITE_WS_BASE_URL ||
  (typeof window !== 'undefined'
    ? `${window.location.protocol === 'https:' ? 'wss' : 'ws'}://${window.location.host}`
    : 'ws://localhost:5173');

const RECONNECT_DELAYS = [1000, 2000, 4000, 8000, 15000];

function asInt(value: unknown): number {
  if (value === null || value === undefined) return 0;
  if (typeof value === 'number') return Math.trunc(value);
  return Number.parseInt(String(value), 10) || 0;
}

function asNullableInt(value: unknown): number | undefined {
  if (value === null || value === undefined) return undefined;
  if (typeof value === 'number') return Math.trunc(value);
  const parsed = Number.parseInt(String(value), 10);
  return Number.isNaN(parsed) ? undefined : parsed;
}

function parseEvent(raw: string): BusinessEvent | null {
  try {
    const data = JSON.parse(raw) as Record<string, unknown>;
    const type = data.type as string | undefined;
    switch (type) {
      case 'APPEAL_STATUS_CHANGED':
        return {
          type,
          payload: {
            appealId: asInt(data.appealId),
            newStatus: String(data.newStatus ?? ''),
            updatedAt: data.updatedAt ? String(data.updatedAt) : undefined,
          },
        };
      case 'PAYMENT_STATUS_CHANGED':
        return {
          type,
          payload: {
            paymentId: asInt(data.paymentId),
            fineId: asNullableInt(data.fineId),
            newStatus: String(data.newStatus ?? ''),
            updatedAt: data.updatedAt ? String(data.updatedAt) : undefined,
          },
        };
      case 'ASYNC_OPERATION_FAILED':
        return {
          type,
          message: String(data.message ?? '操作处理失败，请刷新页面确认'),
        };
      default:
        return null;
    }
  } catch {
    return null;
  }
}

export function BusinessEventProvider({ children }: { children: ReactNode }) {
  const [connected, setConnected] = useState(false);
  const listenersRef = useRef<Set<Listener>>(new Set());
  const socketRef = useRef<WebSocket | null>(null);
  const reconnectAttemptRef = useRef(0);
  const reconnectTimerRef = useRef<number | null>(null);

  const notify = useCallback((event: BusinessEvent) => {
    listenersRef.current.forEach((listener) => {
      try {
        listener(event);
      } catch {
        /* 单个监听器异常不影响其他监听器 */
      }
    });
  }, []);

  const scheduleReconnect = useCallback(() => {
    if (reconnectTimerRef.current !== null) return;
    const delay =
      RECONNECT_DELAYS[Math.min(reconnectAttemptRef.current, RECONNECT_DELAYS.length - 1)];
    reconnectTimerRef.current = window.setTimeout(() => {
      reconnectTimerRef.current = null;
      reconnectAttemptRef.current += 1;
      connect();
    }, delay);
  }, []);

  const connect = useCallback(() => {
    if (socketRef.current && socketRef.current.readyState <= WebSocket.OPEN) return;

    let socket: WebSocket;
    try {
      socket = new WebSocket(`${WS_BASE}/eventbus/websocket`);
    } catch {
      scheduleReconnect();
      return;
    }
    socketRef.current = socket;

    socket.onopen = () => {
      reconnectAttemptRef.current = 0;
      setConnected(true);
    };
    socket.onmessage = (event: MessageEvent) => {
      const parsed = parseEvent(typeof event.data === 'string' ? event.data : '');
      if (parsed) notify(parsed);
    };
    socket.onerror = () => {
      setConnected(false);
    };
    socket.onclose = () => {
      setConnected(false);
      socketRef.current = null;
      scheduleReconnect();
    };
  }, [notify, scheduleReconnect]);

  useEffect(() => {
    connect();
    return () => {
      if (reconnectTimerRef.current !== null) {
        window.clearTimeout(reconnectTimerRef.current);
        reconnectTimerRef.current = null;
      }
      const socket = socketRef.current;
      if (socket) {
        socket.onclose = null;
        socket.close();
        socketRef.current = null;
      }
      setConnected(false);
    };
  }, [connect]);

  const subscribe = useCallback((listener: Listener) => {
    listenersRef.current.add(listener);
    return () => {
      listenersRef.current.delete(listener);
    };
  }, []);

  const value = useMemo<BusinessEventContextValue>(
    () => ({ connected, subscribe }),
    [connected, subscribe]
  );

  return (
    <BusinessEventContext.Provider value={value}>{children}</BusinessEventContext.Provider>
  );
}

export function useBusinessEvents(): BusinessEventContextValue {
  const ctx = useContext(BusinessEventContext);
  if (!ctx) {
    throw new Error('useBusinessEvents must be used within BusinessEventProvider');
  }
  return ctx;
}
