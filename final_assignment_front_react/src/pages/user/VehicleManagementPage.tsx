import { useMemo } from 'react';
import CrudPage from '../shared/CrudPage';
import { entityConfigs } from '../../config/entities';
import { listEntities } from '../../api/entities';
import { getCurrentProfile } from '../../api/profile';
import { useAuth } from '../../auth/AuthContext';
import { useAgentPrefill, hasPlatePrefill } from '../../hooks/useAgentPrefill';
import type { EntityConfig } from '../../config/entityTypes';

function matchesCurrentUser(
  item: Record<string, unknown>,
  tokens: string[],
  driverId?: number
): boolean {
  if (driverId != null && Number(itemDriverId) === Number(driverId)) {
    return true;
  }
  const ownerName = String(item.ownerName || item.owner_name || '').trim().toLowerCase();
  const ownerContact = String(item.ownerContact || item.contact_number || item.owner_contact || '').trim();
  const ownerIdCard = String(item.ownerIdCard || item.id_card_number || item.owner_id_card || '').trim();
  const itemDriverId = item.driverId ?? item.driver_id;
  return tokens.some((token) => {
    if (!token) return false;
    return (
      ownerName === token ||
      ownerName.includes(token) ||
      ownerContact === token ||
      ownerIdCard === token
    );
  });
}

/**
 * 用户车辆管理页，对齐 Flutter VehicleManagementPage。
 * 优先按当前账号绑定的驾驶员档案取车，避免用登录显示名误伤车主姓名。
 */
export default function VehicleManagementPage() {
  const { auth } = useAuth();
  const prefill = useAgentPrefill();
  const plate = hasPlatePrefill(prefill) ? prefill.licensePlate : '';

  const config: EntityConfig = useMemo(
    () => ({
      ...entityConfigs.vehicles,
      label: '我的车辆',
      subtitle: '查看和管理您名下的车辆',
      list: async () => {
        const profile = await getCurrentProfile().catch(() => ({}));
        const driverId = Number(profile.driverId) || undefined;
        const tokens = [
          auth?.userName,
          auth?.userEmail,
          auth?.driverName,
          profile.displayName,
          profile.username,
          profile.driverName,
          profile.email,
          profile.phoneNumber,
        ]
          .map((value) => String(value || '').trim().toLowerCase())
          .filter((value) => value.length >= 2);

        let data: Record<string, unknown>[] = [];
        if (driverId) {
          try {
            data = await listEntities<Record<string, unknown>[]>(
              `${entityConfigs.vehicles.basePath}/drivers/${driverId}/records`
            );
          } catch {
            data = [];
          }
        }
        if (!data.length) {
          const all = await listEntities<Record<string, unknown>[]>(
            entityConfigs.vehicles.basePath
          );
          data = all.filter((item) => matchesCurrentUser(item, tokens, driverId));
        }

        if (plate) {
          data = data.filter((item) =>
            String(item.licensePlate || '').toUpperCase().includes(plate.toUpperCase())
          );
        }
        return data;
      },
    }),
    [auth?.userName, auth?.userEmail, auth?.driverName, plate]
  );

  return (
    <>
      {plate ? (
        <div className="panel" role="status">
          <h3>AI 助手已为您定位车牌</h3>
          <p>
            车牌号：<strong>{plate}</strong>，已按该车牌过滤车辆。
          </p>
        </div>
      ) : null}
      <CrudPage config={config} />
    </>
  );
}
