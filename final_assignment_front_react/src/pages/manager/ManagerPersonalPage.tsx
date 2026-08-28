import { useState } from 'react';
import { useQuery, useQueryClient } from '@tanstack/react-query';
import PageLayout from '../../components/PageLayout';
import Modal from '../../components/Modal';
import ErrorStateView from '../../components/ErrorStateView';
import { useAuth } from '../../auth/AuthContext';
import { ROLES } from '../../constants/roles';
import {
  getCurrentProfile,
  getDriver,
  createDriver,
  updateCurrentUser,
  updateCurrentPassword,
  updateUser,
  type UserProfile,
  type SysUser,
  type DriverInformation,
} from '../../api/profile';
import { getErrorMessage } from '../../utils/errorMessages';

/**
 * 管理员信息页，对齐 Flutter ManagerPersonalPage。
 * 展示当前管理员档案 + 驾驶员档案（若有），支持编辑基本信息与修改密码。
 * 超级管理员可编辑其他用户（通过 userId）——此处仅提供当前账号编辑入口。
 * 若管理员无驾驶员档案，自动建档一份占位档案（对齐 Flutter auto-provision）。
 */
export default function ManagerPersonalPage() {
  const { auth } = useAuth();
  const isSuperAdmin = auth?.userRole === ROLES.SUPER_ADMIN;
  const queryClient = useQueryClient();

  const profileQuery = useQuery({
    queryKey: ['profile', 'me'],
    queryFn: getCurrentProfile,
  });

  const driverId = profileQuery.data?.driverId ?? auth?.userId;
  const driverQuery = useQuery({
    queryKey: ['driver', driverId],
    queryFn: () => getDriver(driverId as number),
    enabled: driverId !== undefined,
  });

  // 自动建档：管理员无驾驶员档案时创建占位档案（对齐 Flutter _loadCurrentManager）
  const autoProvisioning = driverId !== undefined && !driverQuery.isLoading && driverQuery.data === null;

  const [editing, setEditing] = useState(false);
  const [editForm, setEditForm] = useState<Partial<SysUser>>({});
  const [passwordOpen, setPasswordOpen] = useState(false);
  const [newPassword, setNewPassword] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');
  const [saving, setSaving] = useState(false);
  const [toast, setToast] = useState<{ message: string; isError?: boolean } | null>(null);
  // 仅在确认 null 后触发一次建档
  const [provisionTried, setProvisionTried] = useState(false);

  const profile: UserProfile | undefined = profileQuery.data;
  const driver: DriverInformation | null | undefined = driverQuery.data;

  const flashToast = (message: string, isError?: boolean) => {
    setToast({ message, isError });
    window.setTimeout(() => setToast(null), 3000);
  };

  const handleAutoProvision = async () => {
    if (!driverId) return;
    const stub: DriverInformation = {
      driverId: Number(driverId),
      name: profileQuery.data?.username || auth?.userName || '未知用户',
      contactNumber: '',
      idCardNumber: '',
    };
    try {
      await createDriver(stub);
      await queryClient.invalidateQueries({ queryKey: ['driver', driverId] });
    } catch (error) {
      flashToast(`自动建档失败：${getErrorMessage(error)}`, true);
    }
  };
  if (autoProvisioning && !provisionTried) {
    setProvisionTried(true);
    void handleAutoProvision();
  }

  const openEdit = () => {
    setEditForm({
      realName: profile?.displayName || '',
      email: profile?.email || '',
      phoneNumber: profile?.phoneNumber || '',
      remarks: '',
    });
    setEditing(true);
  };

  const handleSaveProfile = async () => {
    setSaving(true);
    try {
      await updateCurrentUser(editForm);
      flashToast('管理员资料已更新');
      setEditing(false);
      await profileQuery.refetch();
    } catch (error) {
      flashToast(getErrorMessage(error), true);
    } finally {
      setSaving(false);
    }
  };

  const handleChangePassword = async () => {
    if (!newPassword) {
      flashToast('请输入新密码', true);
      return;
    }
    if (newPassword !== confirmPassword) {
      flashToast('两次输入的密码不一致', true);
      return;
    }
    setSaving(true);
    try {
      await updateCurrentPassword(newPassword);
      flashToast('密码已修改');
      setPasswordOpen(false);
      setNewPassword('');
      setConfirmPassword('');
    } catch (error) {
      flashToast(getErrorMessage(error), true);
    } finally {
      setSaving(false);
    }
  };

  // 超级管理员可重置指定用户的密码（对齐 Flutter updateUser 路径）
  const [resetUserId, setResetUserId] = useState('');
  const [resetPassword, setResetPassword] = useState('');
  const [resetOpen, setResetOpen] = useState(false);
  const handleResetPassword = async () => {
    const userIdNum = Number(resetUserId);
    if (!resetUserId || Number.isNaN(userIdNum)) {
      flashToast('请输入有效的用户 ID', true);
      return;
    }
    if (!resetPassword) {
      flashToast('请输入新密码', true);
      return;
    }
    setSaving(true);
    try {
      await updateUser(userIdNum, { password: resetPassword });
      flashToast(`用户 ${userIdNum} 的密码已重置`);
      setResetOpen(false);
      setResetUserId('');
      setResetPassword('');
    } catch (error) {
      flashToast(getErrorMessage(error), true);
    } finally {
      setSaving(false);
    }
  };

  return (
    <PageLayout
      title="管理员信息"
      subtitle="账户与权限概览"
      headerActions={
        <>
          <button type="button" className="ghost" onClick={openEdit}>
            编辑资料
          </button>
          <button type="button" className="ghost" onClick={() => setPasswordOpen(true)}>
            修改密码
          </button>
          {isSuperAdmin ? (
            <button type="button" className="ghost" onClick={() => setResetOpen(true)}>
              重置用户密码
            </button>
          ) : null}
        </>
      }
    >
      {toast ? (
        <div className={toast.isError ? 'form-error' : 'form-success'}>{toast.message}</div>
      ) : null}

      {profileQuery.isLoading ? <div className="placeholder">加载中...</div> : null}
      {profileQuery.isError ? (
        <ErrorStateView
          message={getErrorMessage(profileQuery.error)}
          onRetry={() => profileQuery.refetch()}
        />
      ) : null}

      {profile ? (
        <div className="profile-card">
          <h3>{profile.displayName || auth?.userName || '管理员'}</h3>
          <div className="detail-grid">
            <ProfileTile label="用户名" value={profile.username} />
            <ProfileTile label="显示名" value={profile.displayName} />
            <ProfileTile label="邮箱" value={profile.email} />
            <ProfileTile label="手机号" value={profile.phoneNumber} />
            <ProfileTile label="角色" value={(profile.roles || []).join('、') || auth?.userRole || ROLES.ADMIN} />
            <ProfileTile label="驾驶员" value={profile.driverName} />
          </div>
        </div>
      ) : null}

      {driverId !== undefined && driver ? (
        <div className="panel">
          <h3>驾驶员档案</h3>
          <div className="detail-grid">
            <ProfileTile label="姓名" value={driver.name} />
            <ProfileTile label="驾驶证号" value={driver.driverLicenseNumber} />
            <ProfileTile label="准驾车型" value={driver.licenseType} />
            <ProfileTile label="联系电话" value={driver.contactNumber} />
            <ProfileTile label="邮箱" value={driver.email} />
            <ProfileTile label="状态" value={driver.status} />
          </div>
        </div>
      ) : null}

      {autoProvisioning ? (
        <div className="panel">
          <h3>驾驶员档案</h3>
          <div className="placeholder">尚未关联驾驶员档案，正在自动建档...</div>
        </div>
      ) : null}

      <Modal
        isOpen={editing}
        title="编辑管理员资料"
        onClose={() => setEditing(false)}
        footerActions={
          <div className="modal-actions">
            <button type="button" className="ghost" onClick={() => setEditing(false)} disabled={saving}>
              取消
            </button>
            <button type="button" className="primary" onClick={handleSaveProfile} disabled={saving}>
              {saving ? '保存中...' : '保存'}
            </button>
          </div>
        }
      >
        <div className="form-grid">
          <label className="form-field">
            <span>显示名</span>
            <input
              type="text"
              value={(editForm.realName as string) || ''}
              onChange={(event) => setEditForm((prev) => ({ ...prev, realName: event.target.value }))}
            />
          </label>
          <label className="form-field">
            <span>邮箱</span>
            <input
              type="email"
              value={(editForm.email as string) || ''}
              onChange={(event) => setEditForm((prev) => ({ ...prev, email: event.target.value }))}
            />
          </label>
          <label className="form-field">
            <span>手机号</span>
            <input
              type="text"
              value={(editForm.phoneNumber as string) || ''}
              onChange={(event) => setEditForm((prev) => ({ ...prev, phoneNumber: event.target.value }))}
            />
          </label>
        </div>
      </Modal>

      <Modal
        isOpen={passwordOpen}
        title="修改密码"
        onClose={() => setPasswordOpen(false)}
        footerActions={
          <div className="modal-actions">
            <button type="button" className="ghost" onClick={() => setPasswordOpen(false)} disabled={saving}>
              取消
            </button>
            <button type="button" className="primary" onClick={handleChangePassword} disabled={saving}>
              {saving ? '保存中...' : '确认修改'}
            </button>
          </div>
        }
      >
        <div className="form-grid">
          <label className="form-field full">
            <span>新密码</span>
            <input
              type="password"
              value={newPassword}
              onChange={(event) => setNewPassword(event.target.value)}
            />
          </label>
          <label className="form-field full">
            <span>确认新密码</span>
            <input
              type="password"
              value={confirmPassword}
              onChange={(event) => setConfirmPassword(event.target.value)}
            />
          </label>
        </div>
      </Modal>

      <Modal
        isOpen={resetOpen}
        title="重置用户密码（超级管理员）"
        onClose={() => setResetOpen(false)}
        footerActions={
          <div className="modal-actions">
            <button type="button" className="ghost" onClick={() => setResetOpen(false)} disabled={saving}>
              取消
            </button>
            <button type="button" className="primary" onClick={handleResetPassword} disabled={saving}>
              {saving ? '保存中...' : '重置'}
            </button>
          </div>
        }
      >
        <div className="form-grid">
          <label className="form-field full">
            <span>用户 ID</span>
            <input
              type="text"
              value={resetUserId}
              placeholder="目标用户的 userId"
              onChange={(event) => setResetUserId(event.target.value)}
            />
          </label>
          <label className="form-field full">
            <span>新密码</span>
            <input
              type="password"
              value={resetPassword}
              onChange={(event) => setResetPassword(event.target.value)}
            />
          </label>
        </div>
      </Modal>
    </PageLayout>
  );
}

interface ProfileTileProps {
  label: string;
  value?: string | number | null;
}

function ProfileTile({ label, value }: ProfileTileProps) {
  return (
    <div className="profile-tile">
      <span className="profile-tile-label">{label}</span>
      <span className="profile-tile-value">{value || value === 0 ? String(value) : '-'}</span>
    </div>
  );
}
