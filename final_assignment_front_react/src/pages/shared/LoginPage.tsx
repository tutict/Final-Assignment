import { useEffect, useState } from 'react';
import { Navigate, useLocation, useNavigate } from 'react-router-dom';
import { useAuth } from '../../auth/AuthContext';
import { ROLES } from '../../constants/roles';
import LocalCaptcha from '../../components/LocalCaptcha';
import Modal from '../../components/Modal';
import { updateCurrentPassword } from '../../api/profile';
import { getAccessToken } from '../../auth/tokens';
import { getErrorMessage } from '../../utils/errorMessages';

type LoginMode = 'login' | 'register' | 'recover';

interface LoginForm {
  username: string;
  password: string;
  confirmPassword: string;
}

const MIN_PASSWORD_LENGTH = 5;

export default function LoginPage() {
  const { login, register, isAuthenticated, userRole, loading } = useAuth();
  const [mode, setMode] = useState<LoginMode>('login');
  const [form, setForm] = useState<LoginForm>({
    username: '',
    password: '',
    confirmPassword: '',
  });
  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');
  // 本地验证码弹窗（对齐 Flutter LocalCaptchaMain，仅注册/重置时弹出）
  const [captchaOpen, setCaptchaOpen] = useState(false);
  const [captchaVerified, setCaptchaVerified] = useState(false);
  const location = useLocation();
  const navigate = useNavigate();

  // 重置密码流程（对齐 Flutter _recoverPassword）：验证码通过后弹出新密码对话框
  const [resetOpen, setResetOpen] = useState(false);
  const [resetNewPassword, setResetNewPassword] = useState('');
  const [resetSaving, setResetSaving] = useState(false);

  useEffect(() => {
    if (!success) return;
    const timer = window.setTimeout(() => setSuccess(''), 3000);
    return () => window.clearTimeout(timer);
  }, [success]);

  if (isAuthenticated) {
    return <Navigate to={userRole === ROLES.ADMIN ? '/dashboard' : '/userDashboard'} replace />;
  }

  const handleChange = (key: keyof LoginForm, value: string) => {
    setForm((prev) => ({ ...prev, [key]: value }));
  };

  const switchMode = (next: LoginMode) => {
    if (next === mode) return;
    setMode(next);
    setCaptchaVerified(false);
    setError('');
    setForm((prev) => ({ ...prev, password: '', confirmPassword: '' }));
  };

  const handleSubmit = async (event: React.FormEvent) => {
    event.preventDefault();
    setError('');

    if (!form.username) {
      setError('请输入邮箱或用户名');
      return;
    }

    if (mode === 'register') {
      if (!form.password) {
        setError('请输入密码');
        return;
      }
      if (form.password.length < MIN_PASSWORD_LENGTH) {
        setError('密码长度至少 5 位');
        return;
      }
      if (form.password !== form.confirmPassword) {
        setError('两次密码输入不一致');
        return;
      }
      // 对齐 Flutter：注册前先校验本地验证码
      if (!captchaVerified) {
        setCaptchaOpen(true);
        return;
      }
      const result = await register({
        username: form.username,
        password: form.password,
      });
      if (!result.ok) {
        setError(result.message || '注册失败');
        setCaptchaVerified(false);
        return;
      }
      // 注册成功后重置验证码状态，避免下次注册跳过
      setCaptchaVerified(false);
    }

    if (mode === 'recover') {
      // 重置密码是已鉴权流程（复用当前会话 JWT）。对齐 Flutter：未登录直接提示。
      if (!getAccessToken()) {
        setError('重置密码需要先登录。如忘记密码，请联系管理员重置。');
        return;
      }
      if (!captchaVerified) {
        setCaptchaOpen(true);
        return;
      }
      // 验证码通过后弹出设置新密码对话框
      setResetNewPassword('');
      setResetOpen(true);
      return;
    }

    if (!form.password) {
      setError('请输入密码');
      return;
    }

    const result = await login(form.username, form.password);
    if (!result.ok) {
      setError(result.message || '登录失败');
      return;
    }

    const storedRole = localStorage.getItem('userRole') || userRole;
    const from = (location.state as { from?: { pathname?: string } } | null)?.from?.pathname;
    const redirectTo = from || (storedRole === ROLES.ADMIN ? '/dashboard' : '/userDashboard');
    navigate(redirectTo, { replace: true });
  };

  const handleCaptchaClose = (successCaptcha: boolean) => {
    setCaptchaOpen(false);
    if (successCaptcha) {
      setCaptchaVerified(true);
      setError('');
    }
  };

  const handleResetPassword = async () => {
    if (!resetNewPassword) {
      setError('请输入新密码');
      return;
    }
    if (resetNewPassword.length < MIN_PASSWORD_LENGTH) {
      setError('密码长度至少 5 位');
      return;
    }
    setResetSaving(true);
    try {
      await updateCurrentPassword(resetNewPassword);
      setResetOpen(false);
      setCaptchaVerified(false);
      setResetNewPassword('');
      setError('');
      setMode('login');
      setForm((prev) => ({ ...prev, password: '', confirmPassword: '' }));
      setSuccess('密码已重置，请使用新密码登录');
    } catch (e) {
      setError(getErrorMessage(e));
    } finally {
      setResetSaving(false);
    }
  };

  const isRecover = mode === 'recover';
  const submitLabel = isRecover
    ? '重置密码'
    : mode === 'login'
      ? '登录'
      : '注册并登录';

  return (
    <div className="login-page">
      <div className="login-card">
        <div className="login-brand">
          <div className="brand-mark">TA</div>
          <div>
            <h1>交通违法处理系统</h1>
            <p>智能合规 · 智慧服务 · 协同治理</p>
          </div>
        </div>
        <div className="login-tabs">
          <button
            type="button"
            className={mode === 'login' ? 'active' : ''}
            onClick={() => switchMode('login')}
          >
            登录
          </button>
          <button
            type="button"
            className={mode === 'register' ? 'active' : ''}
            onClick={() => switchMode('register')}
          >
            注册
          </button>
        </div>
        <form onSubmit={handleSubmit} className="login-form">
          <label>
            邮箱 / 用户名
            <input
              type="text"
              value={form.username}
              onChange={(event) => handleChange('username', event.target.value)}
              placeholder="请输入邮箱或用户名"
            />
          </label>
          {isRecover ? null : (
            <label>
              密码
              <input
                type="password"
                value={form.password}
                onChange={(event) => handleChange('password', event.target.value)}
                placeholder="请输入密码"
              />
            </label>
          )}
          {mode === 'register' ? (
            <label>
              确认密码
              <input
                type="password"
                value={form.confirmPassword}
                onChange={(event) => handleChange('confirmPassword', event.target.value)}
                placeholder="再次输入密码"
              />
            </label>
          ) : null}
          {error ? <div className="form-error">{error}</div> : null}
          {success ? <div className="form-success">{success}</div> : null}
          <button type="submit" className="primary" disabled={loading || resetSaving}>
            {loading || resetSaving ? '处理中...' : submitLabel}
          </button>
        </form>
        <div className="login-links">
          {isRecover ? (
            <button type="button" className="link-button" onClick={() => switchMode('login')}>
              返回登录
            </button>
          ) : (
            <button type="button" className="link-button" onClick={() => switchMode('recover')}>
              忘记密码
            </button>
          )}
        </div>
      </div>
      <LocalCaptcha isOpen={captchaOpen} onClose={handleCaptchaClose} />
      <Modal
        isOpen={resetOpen}
        title="重置密码"
        onClose={() => setResetOpen(false)}
        footerActions={
          <div className="modal-actions">
            <button
              type="button"
              className="ghost"
              onClick={() => setResetOpen(false)}
              disabled={resetSaving}
            >
              取消
            </button>
            <button
              type="button"
              className="primary"
              onClick={handleResetPassword}
              disabled={resetSaving}
            >
              {resetSaving ? '保存中...' : '确定'}
            </button>
          </div>
        }
      >
        <div className="form-grid">
          <label className="form-field full">
            <span>新密码</span>
            <input
              type="password"
              value={resetNewPassword}
              autoFocus
              onChange={(event) => setResetNewPassword(event.target.value)}
              placeholder="至少 5 位"
            />
          </label>
        </div>
      </Modal>
    </div>
  );
}
