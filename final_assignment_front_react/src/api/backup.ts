/**
 * 备份与恢复 API，对齐 Flutter BackupRestoreControllerApi + 后端 BackupRestoreController。
 * 提供备份列表、创建、更新（含恢复）、删除、详情，以及按文件名/状态的服务端搜索。
 */
import { api, generateIdempotencyKey } from './client';
import { API_PATHS } from '../constants/apiPaths';

export interface BackupRestore {
  backupId?: number;
  backupType?: string;
  backupFileName?: string;
  backupFilePath?: string;
  backupFileSize?: number;
  backupTime?: string;
  backupDuration?: number;
  backupHandler?: string;
  restoreTime?: string;
  restoreDuration?: number;
  restoreStatus?: string;
  restoreHandler?: string;
  errorMessage?: string;
  status?: string;
  createdTime?: string;
  modifiedTime?: string;
  remarks?: string;
  idempotencyKey?: string;
  [key: string]: unknown;
}

const BASE = API_PATHS.SYSTEM_BACKUP;

export async function listBackups(status?: string): Promise<BackupRestore[]> {
  const response = await api.get<BackupRestore[]>(BASE, {
    params: status ? { status } : undefined,
  });
  return Array.isArray(response.data) ? response.data : [];
}

export async function getBackup(backupId: number): Promise<BackupRestore> {
  const response = await api.get<BackupRestore>(`${BASE}/${backupId}`);
  return response.data;
}

export async function createBackup(payload: Partial<BackupRestore>): Promise<BackupRestore> {
  const idempotencyKey = generateIdempotencyKey();
  const response = await api.post<BackupRestore>(
    BASE,
    { ...payload, idempotencyKey },
    { headers: { 'Idempotency-Key': idempotencyKey } }
  );
  return response.data;
}

export async function updateBackup(
  backupId: number,
  payload: Partial<BackupRestore>
): Promise<BackupRestore> {
  const idempotencyKey = generateIdempotencyKey();
  const response = await api.put<BackupRestore>(
    `${BASE}/${backupId}`,
    { ...payload, idempotencyKey },
    { headers: { 'Idempotency-Key': idempotencyKey } }
  );
  return response.data;
}

export async function deleteBackup(backupId: number): Promise<void> {
  await api.delete(`${BASE}/${backupId}`);
}

/** 恢复备份（对齐 Flutter _restoreBackup：置 restoreStatus/status=RESTORED + restoreTime=now）。 */
export async function restoreBackup(backup: BackupRestore): Promise<BackupRestore> {
  if (backup.backupId == null) throw new Error('备份 ID 为空');
  return updateBackup(backup.backupId, {
    ...backup,
    restoreTime: new Date().toISOString(),
    restoreStatus: 'RESTORED',
    status: 'RESTORED',
  });
}

/** 按文件名前缀搜索（对齐后端 /search/file-name）。 */
export async function searchBackupsByFileName(fileName: string): Promise<BackupRestore[]> {
  const response = await api.get<BackupRestore[]>(`${BASE}/search/file-name`, {
    params: { backupFileName: fileName },
  });
  return Array.isArray(response.data) ? response.data : [];
}
