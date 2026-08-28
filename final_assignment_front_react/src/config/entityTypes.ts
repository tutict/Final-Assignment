export type FieldType =
  | 'int'
  | 'double'
  | 'String'
  | 'DateTime'
  | 'bool'
  | 'select';

export interface FieldValidation {
  required?: boolean;
  pattern?: RegExp;
  enum?: readonly string[];
  min?: number;
  max?: number;
  message?: string;
}

export interface EntityField {
  name: string;
  type?: FieldType | string;
  label?: string;
  readOnly?: boolean;
  validation?: FieldValidation;
  options?: readonly string[];
}

export interface EntityConfig {
  key: string;
  label: string;
  basePath: string;
  idField: string;
  subtitle?: string;
  useCustomPage?: boolean;
  listParams?: Record<string, unknown>;
  displayFields: string[];
  editableFields: string[];
  fields: EntityField[];
  list?: () => Promise<unknown[]>;
  queryResult?: unknown;
  preparePayload?: (payload: Record<string, unknown>) => Record<string, unknown>;
  errorRowMessage?: (row: Record<string, unknown>) => string | null | undefined;
  /** 行级「详情」回调；CrudPage 若提供则向 DataTable 透传 onView（对齐 Flutter OffenseDetailPage）。 */
  onView?: (row: Record<string, unknown>) => void;
}

export type EntityKey =
  | 'drivers'
  | 'vehicles'
  | 'offenses'
  | 'deductions'
  | 'fines'
  | 'payments'
  | 'offenseTypes'
  | 'appeals'
  | 'progress'
  | 'users'
  | 'roles'
  | 'permissions'
  | 'systemSettings'
  | 'backups'
  | 'loginLogs'
  | 'operationLogs'
  | 'systemLogs';

export type EntityConfigs = Record<EntityKey, EntityConfig>;
