import { useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import PageLayout from '../../components/PageLayout';
import Modal from '../../components/Modal';
import ErrorStateView from '../../components/ErrorStateView';
import { useAuth } from '../../auth/AuthContext';
import {
  getCurrentProfile,
  getDriver,
  updateCurrentUser,
  updateCurrentPassword,
  updateDriver,
  type UserProfile,
  type DriverInformation,
  type SysUser,
} from '../../api/profile';
import { getErrorMessage } from '../../utils/errorMessages';

/**
 * 用户个人主页，对齐 Flutter PersonalMainPage。
 * 展示当前用户档案 + 驾驶员档案，支持编辑基本信息与修改密码。
 */
export default function PersonalMainPage() {
  const { auth } = useAuth();
  const profileQuery = useQuery({
    queryKey: ['profile', 'me'],
    queryFn: getCurrentProfile,
  });

  const driverId = profileQuery.data?.driverId;
  const driverQuery = useQuery({
    queryKey: ['driver', driverId],
    queryFn: () => getDriver(driverId as number),
    enabled: driverId !== undefined,
  });

  const [editing, setEditing] = useState(false);
  const [editForm, setEditForm] = useState<Partial<SysUser>>({});
  const [passwordOpen, setPasswordOpen] = useState(false);
  const [newPassword, setNewPassword] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');
  const [saving, setSaving] = useState(false);
  const [toast, setToast] = useState<{ message: string; isError?: boolean } | null>(null);

  const profile: UserProfile | undefined = profileQuery.data;
  const driver: DriverInformation | null | undefined = driverQuery.data;

  const flashToast = (message: string, isError?: boolean) => {
    setToast({ message, isError });
    window.setTimeout(() => setToast(null), 3000);
  };

  const openEdit = () => {
    setEditForm({
      realName: profile?.displayName || '',
      email: profile?.email || '',
      phoneNumber: profile?.phoneNumber || '',
    });
    setEditing(true);
  };

  const handleSaveProfile = async () => {
    setSaving(true);
    try {
      await updateCurrentUser(editForm);
      flashToast('个人资料已更新');
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

  const isDriverEditable = Boolean(driver && driver.driverId);

  return (
    <PageLayout
      title="个人主页"
      subtitle="账户信息总览"
      headerActions={
        <>
          <button type="button" className="ghost" onClick={openEdit}>
            编辑资料
          </button>
          <button type="button" className="ghost" onClick={() => setPasswordOpen(true)}>
            修改密码
          </button>
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
          <h3>{profile.displayName || auth?.driverName || auth?.userName || '未命名用户'}</h3>
          <div className="detail-grid">
            <ProfileTile label="用户名" value={profile.username} />
            <ProfileTile label="显示名" value={profile.displayName} />
            <ProfileTile label="邮箱" value={profile.email} />
            <ProfileTile label="手机号" value={profile.phoneNumber} />
            <ProfileTile label="角色" value={(profile.roles || []).join('、') || auth?.userRole || 'USER'} />
            <ProfileTile label="驾驶员" value={profile.driverName} />
          </div>
        </div>
      ) : null}

      {driverId !== undefined ? (
        <div className="panel">
          <h3>驾驶员档案</h3>
          {driverQuery.isLoading ? <div className="placeholder">加载中...</div> : null}
          {driverQuery.isError ? (
            <ErrorStateView
              message={getErrorMessage(driverQuery.error)}
              onRetry={() => driverQuery.refetch()}
            />
          ) : null}
          {driver ? (
            <DriverProfileView driver={driver} editable={isDriverEditable} onSaved={() => driverQuery.refetch()} />
          ) : null}
        </div>
      ) : null}

      <Modal
        isOpen={editing}
        title="编辑个人资料"
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

function DriverProfileView({
  driver,
  editable,
  onSaved,
}: {
  driver: DriverInformation;
  editable: boolean;
  onSaved: () => void;
}) {
  const [editing, setEditing] = useState(false);
  const [form, setForm] = useState<Partial<DriverInformation>>({});
  const [saving, setSaving] = useState(false);
  const [toast, setToast] = useState<{ message: string; isError?: boolean } | null>(null);

  const flashToast = (message: string, isError?: boolean) => {
    setToast({ message, isError });
    window.setTimeout(() => setToast(null), 3000);
  };

  const openEdit = () => {
    setForm({
      name: driver.name,
      contactNumber: driver.contactNumber,
      email: driver.email,
      address: driver.address,
      remarks: driver.remarks,
    });
    setEditing(true);
  };

  const handleSave = async () => {
    if (!driver.driverId) return;
    setSaving(true);
    try {
      await updateDriver(driver.driverId, { ...driver, ...form });
      flashToast('驾驶员档案已更新');
      setEditing(false);
      onSaved();
    } catch (error) {
      flashToast(getErrorMessage(error), true);
    } finally {
      setSaving(false);
    }
  };

  return (
    <>
      {toast ? (
        <div className={toast.isError ? 'form-error' : 'form-success'}>{toast.message}</div>
      ) : null}
      <div className="detail-grid">
        <ProfileTile label="姓名" value={driver.name} />
        <ProfileTile label="身份证号" value={driver.idCardNumber} />
        <ProfileTile label="驾驶证号" value={driver.driverLicenseNumber} />
        <ProfileTile label="准驾车型" value={driver.licenseType} />
        <ProfileTile label="联系电话" value={driver.contactNumber} />
        <ProfileTile label="邮箱" value={driver.email} />
        <ProfileTile label="地址" value={driver.address} />
        <ProfileTile label="当前扣分" value={driver.currentPoints} />
        <ProfileTile label="累计扣分" value={driver.totalDeductedPoints} />
        <ProfileTile label="状态" value={driver.status} />
      </div>
      {editable ? (
        <div style={{ marginTop: 16 }}>
          <button type="button" className="ghost" onClick={openEdit}>
            编辑驾驶员档案
          </button>
        </div>
      ) : null}

      <Modal
        isOpen={editing}
        title="编辑驾驶员档案"
        onClose={() => setEditing(false)}
        footerActions={
          <div className="modal-actions">
            <button type="button" className="ghost" onClick={() => setEditing(false)} disabled={saving}>
              取消
            </button>
            <button type="button" className="primary" onClick={handleSave} disabled={saving}>
              {saving ? '保存中...' : '保存'}
            </button>
          </div>
        }
      >
        <div className="form-grid">
          <label className="form-field">
            <span>姓名</span>
            <input
              type="text"
              value={(form.name as string) || ''}
              onChange={(event) => setForm((prev) => ({ ...prev, name: event.target.value }))}
            />
          </label>
          <label className="form-field">
            <span>联系电话</span>
            <input
              type="text"
              value={(form.contactNumber as string) || ''}
              onChange={(event) => setForm((prev) => ({ ...prev, contactNumber: event.target.value }))}
            />
          </label>
          <label className="form-field">
            <span>邮箱</span>
            <input
              type="email"
              value={(form.email as string) || ''}
              onChange={(event) => setForm((prev) => ({ ...prev, email: event.target.value }))}
            />
          </label>
          <label className="form-field full">
            <span>地址</span>
            <input
              type="text"
              value={(form.address as string) || ''}
              onChange={(event) => setForm((prev) => ({ ...prev, address: event.target.value }))}
            />
          </label>
          <label className="form-field full">
            <span>备注</span>
            <textarea
              rows={3}
              value={(form.remarks as string) || ''}
              onChange={(event) => setForm((prev) => ({ ...prev, remarks: event.target.value }))}
            />
          </label>
        </div>
      </Modal>
    </>
  );
}
