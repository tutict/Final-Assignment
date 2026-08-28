import { api, generateIdempotencyKey } from './client';
import { API_PATHS } from '../constants/apiPaths';

export interface FeedbackPayload {
  feedbackType?: string;
  content: string;
  contact?: string;
  rating?: number;
  [key: string]: unknown;
}

export interface FeedbackRecord {
  feedbackId?: number;
  feedbackType?: string;
  content?: string;
  contact?: string;
  rating?: number;
  status?: string;
  [key: string]: unknown;
}

export async function createFeedback(
  payload: FeedbackPayload
): Promise<FeedbackRecord> {
  const response = await api.post<FeedbackRecord>(API_PATHS.FEEDBACK, payload, {
    headers: { 'Idempotency-Key': generateIdempotencyKey() },
  });
  return response.data;
}

export async function listFeedback(): Promise<FeedbackRecord[]> {
  const response = await api.get<FeedbackRecord[]>(API_PATHS.FEEDBACK);
  return response.data;
}

export async function updateFeedback(
  id: string | number,
  payload: Partial<FeedbackPayload>
): Promise<FeedbackRecord> {
  const response = await api.put<FeedbackRecord>(API_PATHS.FEEDBACK_BY_ID(id), payload, {
    headers: { 'Idempotency-Key': generateIdempotencyKey() },
  });
  return response.data;
}
