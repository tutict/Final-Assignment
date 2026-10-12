import { describe, expect, it, vi } from 'vitest';
import { render, screen, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { MemoryRouter } from 'react-router-dom';
import LoginPage from '../pages/shared/LoginPage';
import { useAuth } from '../auth/AuthContext';

vi.mock('../auth/AuthContext', () => ({
  useAuth: vi.fn(),
}));

const mockUseAuth = vi.mocked(useAuth);

// The login tab and the submit button share the label「登录」; the submit
// control is the primary one inside the form element.
const submitButton = () =>
  document.querySelector<HTMLButtonElement>('form button[type="submit"]')!;

function renderLogin() {
  return render(
    <MemoryRouter>
      <LoginPage />
    </MemoryRouter>
  );
}

describe('LoginPage', () => {
  it('rejects an empty form with the username prompt', async () => {
    mockUseAuth.mockReturnValue({
      login: vi.fn(),
      register: vi.fn(),
      logout: vi.fn(),
      isAuthenticated: false,
      loading: false,
      roles: [],
      userRole: 'USER',
    } as unknown as ReturnType<typeof useAuth>);

    const user = userEvent.setup();
    renderLogin();
    await user.click(submitButton());

    expect(await screen.findByText('请输入邮箱或用户名')).toBeInTheDocument();
    expect(mockUseAuth().login).not.toHaveBeenCalled();
  });

  it('rejects an empty password before calling the API', async () => {
    mockUseAuth.mockReturnValue({
      login: vi.fn(),
      register: vi.fn(),
      logout: vi.fn(),
      isAuthenticated: false,
      loading: false,
      roles: [],
      userRole: 'USER',
    } as unknown as ReturnType<typeof useAuth>);

    const user = userEvent.setup();
    renderLogin();
    await user.type(screen.getByLabelText(/邮箱 \/ 用户名/), 'driver@ce.com');
    await user.click(submitButton());

    expect(await screen.findByText('请输入密码')).toBeInTheDocument();
    expect(mockUseAuth().login).not.toHaveBeenCalled();
  });

  it('calls login and redirects on success', async () => {
    const login = vi.fn().mockResolvedValue({ ok: true });
    mockUseAuth.mockReturnValue({
      login,
      register: vi.fn(),
      logout: vi.fn(),
      isAuthenticated: false,
      loading: false,
      roles: ['ROLE_USER'],
      userRole: 'USER',
    } as unknown as ReturnType<typeof useAuth>);
    localStorage.setItem('userRole', 'USER');

    const user = userEvent.setup();
    renderLogin();
    await user.type(screen.getByLabelText(/邮箱 \/ 用户名/), 'driver@ce.com');
    await user.type(screen.getByLabelText(/^密码/), '123456');
    await user.click(submitButton());

    await waitFor(() => expect(login).toHaveBeenCalledWith('driver@ce.com', '123456'));
  });

  it('shows the backend message when login fails', async () => {
    const login = vi.fn().mockResolvedValue({ ok: false, message: '账号已被停用' });
    mockUseAuth.mockReturnValue({
      login,
      register: vi.fn(),
      logout: vi.fn(),
      isAuthenticated: false,
      loading: false,
      roles: [],
      userRole: 'USER',
    } as unknown as ReturnType<typeof useAuth>);

    const user = userEvent.setup();
    renderLogin();
    await user.type(screen.getByLabelText(/邮箱 \/ 用户名/), 'driver@ce.com');
    await user.type(screen.getByLabelText(/^密码/), '123456');
    await user.click(submitButton());

    expect(await screen.findByText('账号已被停用')).toBeInTheDocument();
  });
});
