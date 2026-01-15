import React, { useState } from 'react';
import { Navigate, useLocation, useNavigate } from 'react-router-dom';
import { useAuth } from '../../auth/AuthContext.jsx';

export default function LoginPage() {
  const { login, register, isAuthenticated, userRole, loading } = useAuth();
  const [mode, setMode] = useState('login');
  const [form, setForm] = useState({
    username: '',
    password: '',
    confirmPassword: '',
  });
  const [error, setError] = useState('');
  const location = useLocation();
  const navigate = useNavigate();

  if (isAuthenticated) {
    return <Navigate to={userRole === 'ADMIN' ? '/dashboard' : '/userDashboard'} replace />;
  }

  const handleChange = (key, value) => {
    setForm((prev) => ({ ...prev, [key]: value }));
  };

  const handleSubmit = async (event) => {
    event.preventDefault();
    setError('');

    if (!form.username || !form.password) {
      setError('请输入用户名和密码');
      return;
    }

    if (mode === 'register') {
      if (form.password.length < 5) {
        setError('密码长度至少 5 位');
        return;
      }
      if (form.password !== form.confirmPassword) {
        setError('两次密码输入不一致');
        return;
      }
      const result = await register({
        username: form.username,
        password: form.password,
      });
      if (!result.ok) {
        setError(result.message || '注册失败');
        return;
      }
    }

    const result = await login(form.username, form.password);
    if (!result.ok) {
      setError(result.message || '登录失败');
      return;
    }

    const storedRole = localStorage.getItem('userRole') || userRole;
    const redirectTo = location.state?.from?.pathname || (storedRole === 'ADMIN' ? '/dashboard' : '/userDashboard');
    navigate(redirectTo, { replace: true });
  };

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
          <button type="button" className={mode === 'login' ? 'active' : ''} onClick={() => setMode('login')}>
            登录
          </button>
          <button type="button" className={mode === 'register' ? 'active' : ''} onClick={() => setMode('register')}>
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
          <label>
            密码
            <input
              type="password"
              value={form.password}
              onChange={(event) => handleChange('password', event.target.value)}
              placeholder="请输入密码"
            />
          </label>
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
          <button type="submit" className="primary" disabled={loading}>
            {loading ? '处理中...' : mode === 'login' ? '登录' : '注册并登录'}
          </button>
        </form>
      </div>
    </div>
  );
}

