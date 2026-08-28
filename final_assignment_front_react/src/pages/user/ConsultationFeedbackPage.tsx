import { useState } from 'react';
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import PageLayout from '../../components/PageLayout';
import {
  createFeedback,
  listFeedback,
  updateFeedback,
  type FeedbackRecord,
} from '../../api/feedback';
import { getErrorMessage } from '../../utils/errorMessages';
import { useAuth } from '../../auth/AuthContext';

const FEEDBACK_KEY = ['feedback'] as const;

export default function ConsultationFeedbackPage() {
  const { auth } = useAuth();
  const queryClient = useQueryClient();
  const [form, setForm] = useState({ content: '', contact: '', feedbackType: '咨询' });
  const [submitError, setSubmitError] = useState('');
  const [submitted, setSubmitted] = useState(false);

  const listQuery = useQuery({
    queryKey: FEEDBACK_KEY,
    queryFn: listFeedback,
  });

  const createMutation = useMutation({
    mutationFn: createFeedback,
    onSuccess: () => {
      void queryClient.invalidateQueries({ queryKey: FEEDBACK_KEY });
      setForm({ content: '', contact: '', feedbackType: '咨询' });
      setSubmitted(true);
      window.setTimeout(() => setSubmitted(false), 3000);
    },
    onError: (error) => setSubmitError(getErrorMessage(error)),
  });

  const handleSubmit = (event: React.FormEvent) => {
    event.preventDefault();
    setSubmitError('');
    if (!form.content.trim()) {
      setSubmitError('请填写反馈内容');
      return;
    }
    createMutation.mutate({
      content: form.content,
      contact: form.contact || auth?.userEmail || undefined,
      feedbackType: form.feedbackType,
    });
  };

  const records: FeedbackRecord[] = Array.isArray(listQuery.data) ? listQuery.data : [];

  return (
    <PageLayout title="咨询反馈" subtitle="提交问题与建议">
      <form className="feedback-form" onSubmit={handleSubmit}>
        <label className="form-field">
          <span>反馈类型</span>
          <select
            value={form.feedbackType}
            onChange={(event) => setForm((prev) => ({ ...prev, feedbackType: event.target.value }))}
          >
            <option value="咨询">咨询</option>
            <option value="建议">建议</option>
            <option value="投诉">投诉</option>
            <option value="其他">其他</option>
          </select>
        </label>
        <label className="form-field full">
          <span>内容</span>
          <textarea
            rows={4}
            value={form.content}
            onChange={(event) => setForm((prev) => ({ ...prev, content: event.target.value }))}
            placeholder="请描述您的问题或建议"
          />
        </label>
        <label className="form-field">
          <span>联系方式（选填）</span>
          <input
            type="text"
            value={form.contact}
            onChange={(event) => setForm((prev) => ({ ...prev, contact: event.target.value }))}
            placeholder="邮箱或手机号"
          />
        </label>
        {submitError ? <div className="form-error">{submitError}</div> : null}
        {submitted ? <div className="form-success">反馈已提交，感谢您的支持。</div> : null}
        <button type="submit" className="primary" disabled={createMutation.isPending}>
          {createMutation.isPending ? '提交中...' : '提交反馈'}
        </button>
      </form>

      <div className="panel">
        <h3>我的反馈记录</h3>
        {listQuery.isLoading ? <div className="placeholder">加载中...</div> : null}
        {listQuery.isError ? (
          <div className="form-error">{getErrorMessage(listQuery.error)}</div>
        ) : null}
        {!listQuery.isLoading && records.length === 0 ? (
          <div className="placeholder">暂无反馈记录</div>
        ) : null}
        <ul className="feedback-list">
          {records.map((record) => (
            <li key={String(record.feedbackId ?? record.content)}>
              <strong>[{record.feedbackType || '反馈'}]</strong>
              <span>{record.content}</span>
              {record.status ? <em>状态：{record.status}</em> : null}
            </li>
          ))}
        </ul>
      </div>
    </PageLayout>
  );
}

// 预留：用于后续行内编辑（对齐 Flutter updateFeedback）
export function useFeedbackUpdater() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: ({ id, payload }: { id: number; payload: Partial<FeedbackRecord> }) =>
      updateFeedback(id, payload),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: FEEDBACK_KEY }),
  });
}
