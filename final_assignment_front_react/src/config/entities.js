import { API_PATHS } from '../constants/apiPaths.js';

export const entityConfigs = {
  /**
   * @entity DriverInformation
   * @backendDto com.tutict.finalassignmentbackend.entity.DriverInformation
   * @apiPath /api/drivers
   * @description 驾驶员信息实体。记录驾驶员身份、驾驶证、联系方式和记分状态。
   */
  drivers: {
    key: 'drivers',
    label: '驾驶员信息',
    basePath: API_PATHS.DRIVERS,
    idField: 'driverId',
    displayFields: ['driverId', 'name', 'idCardNumber', 'contactNumber', 'driverLicenseNumber', 'licenseType', 'currentPoints', 'status'],
    editableFields: ['name', 'idCardNumber', 'gender', 'birthdate', 'contactNumber', 'email', 'address', 'driverLicenseNumber', 'licenseType', 'allowedVehicleType', 'firstLicenseDate', 'issueDate', 'expiryDate', 'issuingAuthority', 'status', 'remarks'],
    fields: [
      { name: 'driverId', type: 'int', readOnly: true },
      // 后端字段：driverId | 来源：DriverInformation.driverId
      // 标识/关联字段，写入时需以后端约束为准
      { name: 'name', type: 'String' },
      // 后端字段：name | 来源：DriverInformation.name
      { name: 'idCardNumber', type: 'String' },
      // 后端字段：idCardNumber | 来源：DriverInformation.idCardNumber
      { name: 'gender', type: 'String' },
      // 后端字段：gender | 来源：DriverInformation.gender
      { name: 'birthdate', type: 'DateTime' },
      // 后端字段：birthdate | 来源：DriverInformation.birthdate
      { name: 'contactNumber', type: 'String' },
      // 后端字段：contactNumber | 来源：DriverInformation.contactNumber
      { name: 'email', type: 'String' },
      // 后端字段：email | 来源：DriverInformation.email
      { name: 'address', type: 'String' },
      // 后端字段：address | 来源：DriverInformation.address
      { name: 'driverLicenseNumber', type: 'String' },
      // 后端字段：driverLicenseNumber | 来源：DriverInformation.driverLicenseNumber
      { name: 'licenseType', type: 'String' },
      // 后端字段：licenseType | 来源：DriverInformation.licenseType
      { name: 'allowedVehicleType', type: 'String' },
      // 后端字段：allowedVehicleType | @todo 确认后端字段名和 DTO 来源，暂时按字面推断
      // 可能是准驾车型兼容字段，需确认是否对应 licenseType 或独立字段
      { name: 'firstLicenseDate', type: 'DateTime' },
      // 后端字段：firstLicenseDate | 来源：DriverInformation.firstLicenseDate
      { name: 'issueDate', type: 'DateTime' },
      // 后端字段：issueDate | 来源：DriverInformation.issueDate
      { name: 'expiryDate', type: 'DateTime' },
      // 后端字段：expiryDate | 来源：DriverInformation.expiryDate
      { name: 'issuingAuthority', type: 'String' },
      // 后端字段：issuingAuthority | 来源：DriverInformation.issuingAuthority
      { name: 'currentPoints', type: 'int' },
      // 后端字段：currentPoints | 来源：DriverInformation.currentPoints
      { name: 'totalDeductedPoints', type: 'int' },
      // 后端字段：totalDeductedPoints | 来源：DriverInformation.totalDeductedPoints
      { name: 'status', type: 'String' },
      // 后端字段：status | 枚举：Active / Suspended / Revoked / Expired
      // 驾驶证状态，区别于用户账号状态或车辆状态
      { name: 'createdAt', type: 'DateTime', readOnly: true },
      // 后端字段：createdAt | 来源：DriverInformation.createdAt
      // @readonly 审计时间字段，由后端生成或维护
      { name: 'updatedAt', type: 'DateTime', readOnly: true },
      // 后端字段：updatedAt | 来源：DriverInformation.updatedAt
      // @readonly 审计时间字段，由后端生成或维护
      { name: 'createdBy', type: 'String' },
      // 后端字段：createdBy | 来源：DriverInformation.createdBy
      { name: 'updatedBy', type: 'String' },
      // 后端字段：updatedBy | 来源：DriverInformation.updatedBy
      { name: 'deletedAt', type: 'DateTime' },
      // 后端字段：deletedAt | 来源：DriverInformation.deletedAt
      // @readonly 审计时间字段，由后端生成或维护
      { name: 'remarks', type: 'String' },
      // 后端字段：remarks | 来源：DriverInformation.remarks
    ],
  },
  /**
   * @entity VehicleInformation
   * @backendDto com.tutict.finalassignmentbackend.entity.VehicleInformation
   * @apiPath /api/vehicles
   * @description 车辆信息实体。记录车辆基本信息、车主信息和车辆状态。
   */
  vehicles: {
    key: 'vehicles',
    label: '车辆信息',
    basePath: API_PATHS.VEHICLES,
    idField: 'vehicleId',
    displayFields: ['vehicleId', 'licensePlate', 'vehicleType', 'brand', 'model', 'ownerName', 'ownerContact', 'status'],
    editableFields: ['licensePlate', 'plateColor', 'vehicleType', 'brand', 'model', 'vehicleColor', 'engineNumber', 'frameNumber', 'ownerName', 'ownerIdCard', 'ownerContact', 'ownerAddress', 'firstRegistrationDate', 'registrationDate', 'issuingAuthority', 'status', 'inspectionExpiryDate', 'insuranceExpiryDate', 'remarks'],
    fields: [
      { name: 'vehicleId', type: 'int', readOnly: true },
      // 后端字段：vehicleId | 来源：VehicleInformation.vehicleId
      // 标识/关联字段，写入时需以后端约束为准
      { name: 'licensePlate', type: 'String' },
      // 后端字段：licensePlate | 来源：VehicleInformation.licensePlate
      { name: 'plateColor', type: 'String' },
      // 后端字段：plateColor | 来源：VehicleInformation.plateColor
      { name: 'vehicleType', type: 'String' },
      // 后端字段：vehicleType | 来源：VehicleInformation.vehicleType
      { name: 'brand', type: 'String' },
      // 后端字段：brand | 来源：VehicleInformation.brand
      { name: 'model', type: 'String' },
      // 后端字段：model | 来源：VehicleInformation.model
      { name: 'vehicleColor', type: 'String' },
      // 后端字段：vehicleColor | 来源：VehicleInformation.vehicleColor
      { name: 'engineNumber', type: 'String' },
      // 后端字段：engineNumber | 来源：VehicleInformation.engineNumber
      { name: 'frameNumber', type: 'String' },
      // 后端字段：frameNumber | 来源：VehicleInformation.frameNumber
      { name: 'ownerName', type: 'String' },
      // 后端字段：ownerName | 来源：VehicleInformation.ownerName
      { name: 'ownerIdCard', type: 'String' },
      // 后端字段：ownerIdCard | 来源：VehicleInformation.ownerIdCard
      { name: 'ownerContact', type: 'String' },
      // 后端字段：ownerContact | 来源：VehicleInformation.ownerContact
      { name: 'ownerAddress', type: 'String' },
      // 后端字段：ownerAddress | 来源：VehicleInformation.ownerAddress
      { name: 'firstRegistrationDate', type: 'DateTime' },
      // 后端字段：firstRegistrationDate | 来源：VehicleInformation.firstRegistrationDate
      { name: 'registrationDate', type: 'DateTime' },
      // 后端字段：registrationDate | 来源：VehicleInformation.registrationDate
      { name: 'issuingAuthority', type: 'String' },
      // 后端字段：issuingAuthority | 来源：VehicleInformation.issuingAuthority
      { name: 'status', type: 'String' },
      // 后端字段：status | 枚举：Active / Inactive / Scrapped / Stolen / Mortgaged
      // 车辆当前状态，区别于 plateStatusSnapshot 的历史快照语义
      { name: 'inspectionExpiryDate', type: 'DateTime' },
      // 后端字段：inspectionExpiryDate | 来源：VehicleInformation.inspectionExpiryDate
      { name: 'insuranceExpiryDate', type: 'DateTime' },
      // 后端字段：insuranceExpiryDate | 来源：VehicleInformation.insuranceExpiryDate
      { name: 'createdAt', type: 'DateTime', readOnly: true },
      // 后端字段：createdAt | 来源：VehicleInformation.createdAt
      // @readonly 审计时间字段，由后端生成或维护
      { name: 'updatedAt', type: 'DateTime', readOnly: true },
      // 后端字段：updatedAt | 来源：VehicleInformation.updatedAt
      // @readonly 审计时间字段，由后端生成或维护
      { name: 'createdBy', type: 'String' },
      // 后端字段：createdBy | 来源：VehicleInformation.createdBy
      { name: 'updatedBy', type: 'String' },
      // 后端字段：updatedBy | 来源：VehicleInformation.updatedBy
      { name: 'deletedAt', type: 'DateTime' },
      // 后端字段：deletedAt | 来源：VehicleInformation.deletedAt
      // @readonly 审计时间字段，由后端生成或维护
      { name: 'remarks', type: 'String' },
      // 后端字段：remarks | 来源：VehicleInformation.remarks
      { name: 'plateStatusSnapshot', type: 'String' },
      // 后端字段：currentStatus | @deprecated 兼容旧版 UI 字段，保留为车牌状态快照
      // 记录违法发生时的车牌状态，不代表车辆当前 status；需后端确认快照来源
    ],
  },
  /**
   * @entity OffenseInformation
   * @backendDto com.tutict.finalassignmentbackend.entity.OffenseRecord
   * @apiPath /api/offenses
   * @description 违法记录实体。记录司机的交通违法行为，包含案件状态和处理流程。
   */
  offenses: {
    key: 'offenses',
    label: '违法记录',
    basePath: API_PATHS.OFFENSES,
    idField: 'offenseId',
    displayFields: ['offenseId', 'offenseNumber', 'offenseTime', 'offenseLocation', 'driverName', 'licensePlate', 'offenseType', 'fineAmount', 'deductedPoints', 'processStatus'],
    editableFields: ['offenseCode', 'offenseNumber', 'offenseTime', 'offenseLocation', 'offenseProvince', 'offenseCity', 'driverId', 'vehicleId', 'offenseDescription', 'evidenceType', 'evidenceUrls', 'enforcementAgency', 'fineAmount', 'deductedPoints', 'detentionDays', 'remarks'],
    fields: [
      { name: 'offenseId', type: 'int', readOnly: true },
      // 后端字段：offenseId | 违法记录主键
      // 与 driverId、vehicleId 共同描述哪位驾驶员驾驶哪辆车产生本条违法记录
      { name: 'offenseCode', type: 'String' },
      // 后端字段：offenseCode | 来源：OffenseInformation.offenseCode
      { name: 'offenseNumber', type: 'String' },
      // 后端字段：offenseNumber | 来源：OffenseInformation.offenseNumber
      { name: 'offenseTime', type: 'DateTime' },
      // 后端字段：offenseTime | 违法实际发生时间
      // 区别于 createdAt：createdAt 是记录创建时间
      { name: 'offenseLocation', type: 'String' },
      // 后端字段：offenseLocation | 来源：OffenseInformation.offenseLocation
      { name: 'offenseProvince', type: 'String' },
      // 后端字段：offenseProvince | 来源：OffenseInformation.offenseProvince
      { name: 'offenseCity', type: 'String' },
      // 后端字段：offenseCity | 来源：OffenseInformation.offenseCity
      { name: 'driverId', type: 'int' },
      // 后端字段：driverId | 关联 DriverInformation.driverId
      // 与 offenseId、vehicleId 共同组成违法记录的驾驶员/车辆关联
      { name: 'vehicleId', type: 'int' },
      // 后端字段：vehicleId | 关联 VehicleInformation.vehicleId
      // 与 offenseId、driverId 共同组成违法记录的驾驶员/车辆关联
      { name: 'offenseDescription', type: 'String' },
      // 后端字段：offenseDescription | 来源：OffenseInformation.offenseDescription
      { name: 'evidenceType', type: 'String' },
      // 后端字段：evidenceType | 来源：OffenseInformation.evidenceType
      { name: 'evidenceUrls', type: 'String' },
      // 后端字段：evidenceUrls | 来源：OffenseInformation.evidenceUrls
      { name: 'enforcementAgency', type: 'String' },
      // 后端字段：enforcementAgency | 来源：OffenseInformation.enforcementAgency
      { name: 'enforcementOfficer', type: 'String' },
      // 后端字段：enforcementOfficer | 来源：OffenseInformation.enforcementOfficer
      { name: 'enforcementDevice', type: 'String' },
      // 后端字段：enforcementDevice | 来源：OffenseInformation.enforcementDevice
      { name: 'processStatus', type: 'String' },
      // 后端字段：processStatus | 枚举来源：后端 OffenseProcessState；前端展示见 STATUS/STATUSES 常量
      // 枚举：Unprocessed / Processing / Processed / Appealing / Appeal_Approved / Appeal_Rejected / Cancelled
      // 由后端 workflow/state machine 控制；不在 editableFields 中，前端表单不应直接修改
      { name: 'notificationStatus', type: 'String' },
      // 后端字段：notificationStatus | 枚举：Not_Sent / Sent / Received / Confirmed
      // 表示违法通知送达进度；@todo 确认通知失败是否使用额外枚举值
      { name: 'notificationTime', type: 'DateTime' },
      // 后端字段：notificationTime | 来源：OffenseInformation.notificationTime
      { name: 'fineAmount', type: 'double' },
      // 后端字段：fineAmount | 来源：OffenseInformation.fineAmount
      { name: 'deductedPoints', type: 'int' },
      // 后端字段：deductedPoints | 来源：OffenseInformation.deductedPoints
      { name: 'detentionDays', type: 'int' },
      // 后端字段：detentionDays | 来源：OffenseInformation.detentionDays
      { name: 'processTime', type: 'DateTime' },
      // 后端字段：processTime | 来源：OffenseInformation.processTime
      { name: 'processHandler', type: 'String' },
      // 后端字段：processHandler | 来源：OffenseInformation.processHandler
      { name: 'processResult', type: 'String' },
      // 后端字段：processResult | 来源：OffenseInformation.processResult
      { name: 'createdAt', type: 'DateTime', readOnly: true },
      // 后端字段：createdAt | @readonly 记录创建时间，由后端生成
      // 区别于 offenseTime：本字段表示记录进入系统的时间
      { name: 'updatedAt', type: 'DateTime', readOnly: true },
      // 后端字段：updatedAt | 来源：OffenseInformation.updatedAt
      // @readonly 审计时间字段，由后端生成或维护
      { name: 'createdBy', type: 'String' },
      // 后端字段：createdBy | 来源：OffenseInformation.createdBy
      { name: 'updatedBy', type: 'String' },
      // 后端字段：updatedBy | 来源：OffenseInformation.updatedBy
      { name: 'deletedAt', type: 'DateTime' },
      // 后端字段：deletedAt | 来源：OffenseInformation.deletedAt
      // @readonly 审计时间字段，由后端生成或维护
      { name: 'remarks', type: 'String' },
      // 后端字段：remarks | 来源：OffenseInformation.remarks
      { name: 'licensePlate', type: 'String' },
      // 后端字段：licensePlate | @deprecated 兼容聚合展示字段，不属于 OffenseRecord 核心表字段
      // @todo 确认是否来自车辆关联查询或视图 DTO
      { name: 'driverName', type: 'String' },
      // 后端字段：driverName | @deprecated 兼容聚合展示字段，不属于 OffenseRecord 核心表字段
      // @todo 确认是否来自驾驶员关联查询或视图 DTO
      { name: 'offenseType', type: 'String' },
      // 后端字段：offenseType | @deprecated 兼容聚合展示字段，不属于 OffenseRecord 核心表字段
      // @todo 确认是否来自违法类型字典关联查询或视图 DTO
      // @todo 后端模型包含 idempotencyKey；当前实体配置未声明该字段。
      // 仅添加注释不新增字段，需确认是否应作为只读兼容字段暴露。
    ],
  },
  /**
   * @entity DeductionRecord
   * @backendDto com.tutict.finalassignmentbackend.entity.DeductionRecord
   * @apiPath /api/deductions
   * @description 扣分记录实体。记录违法记录产生的驾驶员扣分及恢复流程。
   */
  deductions: {
    key: 'deductions',
    label: '扣分记录',
    basePath: API_PATHS.DEDUCTIONS,
    idField: 'deductionId',
    displayFields: ['deductionId', 'offenseId', 'driverId', 'deductedPoints', 'deductionTime', 'scoringCycle', 'status', 'handler'],
    editableFields: ['offenseId', 'driverId', 'deductedPoints', 'deductionTime', 'scoringCycle', 'status', 'restoreReason', 'remarks'],
    fields: [
      { name: 'deductionId', type: 'int', readOnly: true },
      // 后端字段：deductionId | 来源：DeductionRecord.deductionId
      // 标识/关联字段，写入时需以后端约束为准
      { name: 'offenseId', type: 'int' },
      // 后端字段：offenseId | 来源：DeductionRecord.offenseId
      // 标识/关联字段，写入时需以后端约束为准
      { name: 'driverId', type: 'int' },
      // 后端字段：driverId | 来源：DeductionRecord.driverId
      // 标识/关联字段，写入时需以后端约束为准
      { name: 'deductedPoints', type: 'int' },
      // 后端字段：deductedPoints | 来源：DeductionRecord.deductedPoints
      { name: 'deductionTime', type: 'DateTime' },
      // 后端字段：deductionTime | 来源：DeductionRecord.deductionTime
      { name: 'scoringCycle', type: 'String' },
      // 后端字段：scoringCycle | 来源：DeductionRecord.scoringCycle
      { name: 'handler', type: 'String' },
      // 后端字段：handler | 来源：DeductionRecord.handler
      { name: 'handlerDept', type: 'String' },
      // 后端字段：handlerDept | 来源：DeductionRecord.handlerDept
      { name: 'approver', type: 'String' },
      // 后端字段：approver | 来源：DeductionRecord.approver
      { name: 'approvalTime', type: 'DateTime' },
      // 后端字段：approvalTime | 来源：DeductionRecord.approvalTime
      { name: 'status', type: 'String' },
      // 后端字段：status | 枚举：Effective / Cancelled / Restored
      // 扣分记录状态，Cancelled/Restored 可能触发积分恢复逻辑
      { name: 'restoreTime', type: 'DateTime' },
      // 后端字段：restoreTime | 来源：DeductionRecord.restoreTime
      { name: 'restoreReason', type: 'String' },
      // 后端字段：restoreReason | 来源：DeductionRecord.restoreReason
      { name: 'createdAt', type: 'DateTime', readOnly: true },
      // 后端字段：createdAt | 来源：DeductionRecord.createdAt
      // @readonly 审计时间字段，由后端生成或维护
      { name: 'updatedAt', type: 'DateTime', readOnly: true },
      // 后端字段：updatedAt | 来源：DeductionRecord.updatedAt
      // @readonly 审计时间字段，由后端生成或维护
      { name: 'remarks', type: 'String' },
      // 后端字段：remarks | 来源：DeductionRecord.remarks
    ],
  },
  /**
   * @entity FineInformation
   * @backendDto com.tutict.finalassignmentbackend.entity.FineRecord
   * @apiPath /api/fines
   * @description 罚款记录实体。记录违法记录对应的罚款金额、缴款期限和支付状态。
   */
  fines: {
    key: 'fines',
    label: '罚款记录',
    basePath: API_PATHS.FINES,
    idField: 'fineId',
    displayFields: ['fineId', 'offenseId', 'fineNumber', 'fineAmount', 'lateFee', 'totalAmount', 'paymentDeadline', 'paymentStatus', 'status'],
    editableFields: ['offenseId', 'fineNumber', 'fineAmount', 'lateFee', 'totalAmount', 'fineDate', 'paymentDeadline', 'issuingAuthority', 'paymentStatus', 'status', 'remarks'],
    fields: [
      { name: 'fineId', type: 'int', readOnly: true },
      // 后端字段：fineId | 来源：FineInformation.fineId
      // 标识/关联字段，写入时需以后端约束为准
      { name: 'offenseId', type: 'int' },
      // 后端字段：offenseId | 关联 OffenseInformation.offenseId
      // 一条违法记录可生成对应罚款记录，具体唯一性由后端约束确认
      { name: 'fineNumber', type: 'String' },
      // 后端字段：fineNumber | 来源：FineInformation.fineNumber
      { name: 'fineAmount', type: 'double' },
      // 后端字段：fineAmount | 基础罚款金额
      // 通常与 lateFee 共同计算 totalAmount，最终金额以后端返回为准
      { name: 'lateFee', type: 'double' },
      // 后端字段：lateFee | 滞纳金金额
      // 是否产生滞纳金由后端根据 paymentDeadline 和支付状态计算
      { name: 'totalAmount', type: 'double' },
      // 后端字段：totalAmount | 应缴总金额
      // 通常由 fineAmount + lateFee 形成；如有减免，以后端计算结果为准
      { name: 'fineDate', type: 'DateTime' },
      // 后端字段：fineDate | 来源：FineInformation.fineDate
      { name: 'paymentDeadline', type: 'DateTime' },
      // 后端字段：paymentDeadline | 来源：FineInformation.paymentDeadline
      { name: 'issuingAuthority', type: 'String' },
      // 后端字段：issuingAuthority | 来源：FineInformation.issuingAuthority
      { name: 'handler', type: 'String' },
      // 后端字段：handler | 来源：FineInformation.handler
      { name: 'approver', type: 'String' },
      // 后端字段：approver | 来源：FineInformation.approver
      { name: 'paymentStatus', type: 'String' },
      // 后端字段：paymentStatus | 枚举：Unpaid / Partial / Paid / Overdue / Waived
      // 支付状态，描述缴款进度；区别于 status 的罚单记录状态
      { name: 'paidAmount', type: 'double' },
      // 后端字段：paidAmount | 已支付金额
      // 通常与 totalAmount 一起计算 unpaidAmount，最终金额以后端返回为准
      { name: 'unpaidAmount', type: 'double' },
      // 后端字段：unpaidAmount | 未支付金额
      // 通常为 totalAmount 扣除 paidAmount 后的结果，最终金额以后端返回为准
      { name: 'fineTime', type: 'String' },
      // 后端字段：fineTime | @deprecated 旧版前端兼容字段，后端 FineRecord 未显式声明
      // @todo 确认是否应改用 fineDate
      { name: 'payee', type: 'String' },
      // 后端字段：payee | @deprecated 旧版前端兼容字段，后端 FineRecord 未显式声明
      // @todo 确认是否来自支付收款配置或 PaymentRecord
      { name: 'accountNumber', type: 'String' },
      // 后端字段：accountNumber | @deprecated 旧版前端兼容字段，后端 FineRecord 未显式声明
      // @todo 确认是否来自支付收款配置，展示时需避免暴露完整账号
      { name: 'bank', type: 'String' },
      // 后端字段：bank | @deprecated 旧版前端兼容字段，后端 FineRecord 未显式声明
      // @todo 确认是否来自支付收款配置
      { name: 'receiptNumber', type: 'String' },
      // 后端字段：receiptNumber | @deprecated 旧版前端兼容字段，后端 FineRecord 未显式声明
      // @todo 确认是否应来自 PaymentRecord.receiptNumber
      { name: 'createdAt', type: 'DateTime', readOnly: true },
      // 后端字段：createdAt | 来源：FineInformation.createdAt
      // @readonly 审计时间字段，由后端生成或维护
      { name: 'updatedAt', type: 'DateTime', readOnly: true },
      // 后端字段：updatedAt | 来源：FineInformation.updatedAt
      // @readonly 审计时间字段，由后端生成或维护
      { name: 'createdBy', type: 'String' },
      // 后端字段：createdBy | 来源：FineInformation.createdBy
      { name: 'updatedBy', type: 'String' },
      // 后端字段：updatedBy | 来源：FineInformation.updatedBy
      { name: 'deletedAt', type: 'DateTime' },
      // 后端字段：deletedAt | 来源：FineInformation.deletedAt
      // @readonly 审计时间字段，由后端生成或维护
      { name: 'remarks', type: 'String' },
      // 后端字段：remarks | 来源：FineInformation.remarks
      { name: 'status', type: 'String' },
      // 后端字段：status | 罚单记录状态，区别于 paymentStatus 的支付状态
      // @todo 后端 FineRecord 当前未显式声明 status 字段，需确认枚举值和来源
      // @todo 后端模型包含 idempotencyKey；当前实体配置未声明该字段。
      // 仅添加注释不新增字段，需确认是否应作为只读兼容字段暴露。
    ],
  },
  /**
   * @entity PaymentRecord
   * @backendDto com.tutict.finalassignmentbackend.entity.PaymentRecord
   * @apiPath /api/payments
   * @description 缴费记录实体。记录罚款的支付流水、支付渠道和退款信息。
   */
  payments: {
    key: 'payments',
    label: '缴费记录',
    basePath: API_PATHS.PAYMENTS,
    idField: 'paymentId',
    useCustomPage: true,
    displayFields: ['paymentId', 'fineId', 'paymentNumber', 'paymentAmount', 'paymentMethod', 'paymentTime', 'payerName', 'paymentStatus', 'receiptNumber'],
    editableFields: ['fineId', 'paymentAmount', 'paymentMethod', 'paymentChannel', 'payerName', 'payerContact', 'remarks'],
    fields: [
      { name: 'paymentId', type: 'int', readOnly: true },
      // 后端字段：paymentId | 来源：PaymentRecord.paymentId
      // 标识/关联字段，写入时需以后端约束为准
      { name: 'fineId', type: 'int' },
      // 后端字段：fineId | 关联 FineInformation.fineId
      // 关系：FineInformation 1:N PaymentRecord；多笔缴费/退款流水可指向同一罚款记录
      { name: 'paymentNumber', type: 'String' },
      // 后端字段：paymentNumber | 来源：PaymentRecord.paymentNumber
      { name: 'paymentAmount', type: 'double' },
      // 后端字段：paymentAmount | 来源：PaymentRecord.paymentAmount
      { name: 'paymentMethod', type: 'String' },
      // 后端字段：paymentMethod | 来源：PaymentRecord.paymentMethod
      { name: 'paymentTime', type: 'DateTime' },
      // 后端字段：paymentTime | 来源：PaymentRecord.paymentTime
      { name: 'paymentChannel', type: 'String' },
      // 后端字段：paymentChannel | 来源：PaymentRecord.paymentChannel
      { name: 'payerName', type: 'String' },
      // 后端字段：payerName | 来源：PaymentRecord.payerName
      { name: 'payerIdCard', type: 'String' },
      // 后端字段：payerIdCard | 缴款人身份证号
      // @sensitive 涉及个人身份信息，前端展示需脱敏
      { name: 'payerContact', type: 'String' },
      // 后端字段：payerContact | 缴款人联系电话
      // @sensitive 涉及个人联系方式，前端展示需脱敏
      { name: 'bankName', type: 'String' },
      // 后端字段：bankName | 来源：PaymentRecord.bankName
      { name: 'bankAccount', type: 'String' },
      // 后端字段：bankAccount | 银行账号
      // @sensitive 不应在前端展示完整原始值
      { name: 'transactionId', type: 'String' },
      // 后端字段：transactionId | 来源：PaymentRecord.transactionId
      // 标识/关联字段，写入时需以后端约束为准
      { name: 'receiptNumber', type: 'String' },
      // 后端字段：receiptNumber | 来源：PaymentRecord.receiptNumber
      { name: 'receiptUrl', type: 'String' },
      // 后端字段：receiptUrl | 来源：PaymentRecord.receiptUrl
      { name: 'paymentStatus', type: 'String' },
      // 后端字段：paymentStatus | 枚举：Pending / Success / Failed / Refunded / Cancelled
      // 支付流水状态，区别于 FineInformation.paymentStatus 的罚款整体缴纳进度
      { name: 'refundAmount', type: 'double' },
      // 后端字段：refundAmount | 来源：PaymentRecord.refundAmount
      { name: 'refundTime', type: 'DateTime' },
      // 后端字段：refundTime | 来源：PaymentRecord.refundTime
      { name: 'createdAt', type: 'DateTime', readOnly: true },
      // 后端字段：createdAt | 来源：PaymentRecord.createdAt
      // @readonly 审计时间字段，由后端生成或维护
      { name: 'updatedAt', type: 'DateTime', readOnly: true },
      // 后端字段：updatedAt | 来源：PaymentRecord.updatedAt
      // @readonly 审计时间字段，由后端生成或维护
      { name: 'createdBy', type: 'String' },
      // 后端字段：createdBy | 来源：PaymentRecord.createdBy
      { name: 'updatedBy', type: 'String' },
      // 后端字段：updatedBy | 来源：PaymentRecord.updatedBy
      { name: 'deletedAt', type: 'DateTime' },
      // 后端字段：deletedAt | 来源：PaymentRecord.deletedAt
      // @readonly 审计时间字段，由后端生成或维护
      { name: 'remarks', type: 'String' },
      // 后端字段：remarks | 来源：PaymentRecord.remarks
    ],
  },
  /**
   * @entity OffenseTypeDict
   * @backendDto com.tutict.finalassignmentbackend.entity.OffenseTypeDict
   * @apiPath /api/offense-types
   * @description 违法类型字典实体。定义违法代码、处罚标准和扣分规则。
   */
  offenseTypes: {
    key: 'offenseTypes',
    label: '违法类型字典',
    basePath: API_PATHS.OFFENSE_TYPES,
    idField: 'typeId',
    displayFields: ['typeId', 'offenseCode', 'offenseName', 'category', 'standardFineAmount', 'deductedPoints', 'severityLevel', 'status'],
    editableFields: ['offenseCode', 'offenseName', 'category', 'description', 'standardFineAmount', 'minFineAmount', 'maxFineAmount', 'deductedPoints', 'detentionDays', 'licenseSuspensionDays', 'severityLevel', 'legalBasis', 'status', 'remarks'],
    fields: [
      { name: 'typeId', type: 'int', readOnly: true },
      // 后端字段：typeId | 来源：OffenseTypeDict.typeId
      // 标识/关联字段，写入时需以后端约束为准
      { name: 'offenseCode', type: 'String' },
      // 后端字段：offenseCode | 来源：OffenseTypeDict.offenseCode
      { name: 'offenseName', type: 'String' },
      // 后端字段：offenseName | 来源：OffenseTypeDict.offenseName
      { name: 'category', type: 'String' },
      // 后端字段：category | 来源：OffenseTypeDict.category
      { name: 'description', type: 'String' },
      // 后端字段：description | 来源：OffenseTypeDict.description
      { name: 'standardFineAmount', type: 'double' },
      // 后端字段：standardFineAmount | 来源：OffenseTypeDict.standardFineAmount
      { name: 'minFineAmount', type: 'double' },
      // 后端字段：minFineAmount | 来源：OffenseTypeDict.minFineAmount
      { name: 'maxFineAmount', type: 'double' },
      // 后端字段：maxFineAmount | 来源：OffenseTypeDict.maxFineAmount
      { name: 'deductedPoints', type: 'int' },
      // 后端字段：deductedPoints | 来源：OffenseTypeDict.deductedPoints
      { name: 'detentionDays', type: 'int' },
      // 后端字段：detentionDays | 来源：OffenseTypeDict.detentionDays
      { name: 'licenseSuspensionDays', type: 'int' },
      // 后端字段：licenseSuspensionDays | 来源：OffenseTypeDict.licenseSuspensionDays
      { name: 'severityLevel', type: 'String' },
      // 后端字段：severityLevel | 枚举：Minor / Moderate / Severe / Critical
      // 违法严重程度，通常影响默认罚款和扣分展示
      { name: 'legalBasis', type: 'String' },
      // 后端字段：legalBasis | 来源：OffenseTypeDict.legalBasis
      { name: 'status', type: 'String' },
      // 后端字段：status | 来源：OffenseTypeDict.status
      // 状态字段，枚举含义随实体不同，需避免跨实体复用
      { name: 'createdAt', type: 'DateTime', readOnly: true },
      // 后端字段：createdAt | 来源：OffenseTypeDict.createdAt
      // @readonly 审计时间字段，由后端生成或维护
      { name: 'updatedAt', type: 'DateTime', readOnly: true },
      // 后端字段：updatedAt | 来源：OffenseTypeDict.updatedAt
      // @readonly 审计时间字段，由后端生成或维护
      { name: 'deletedAt', type: 'DateTime' },
      // 后端字段：deletedAt | 来源：OffenseTypeDict.deletedAt
      // @readonly 审计时间字段，由后端生成或维护
      { name: 'remarks', type: 'String' },
      // 后端字段：remarks | 来源：OffenseTypeDict.remarks
    ],
  },
  /**
   * @entity AppealRecord
   * @backendDto com.tutict.finalassignmentbackend.entity.AppealRecord
   * @apiPath /api/appeals
   * @description 申诉记录实体。记录针对违法记录的申诉受理、审核和处理结果。
   */
  appeals: {
    key: 'appeals',
    label: '申诉记录',
    basePath: API_PATHS.APPEAL_LIST,
    idField: 'appealId',
    displayFields: ['appealId', 'appealNumber', 'appellantName', 'appealType', 'appealTime', 'acceptanceStatus', 'processStatus', 'processResult'],
    editableFields: ['offenseId', 'appealNumber', 'appellantName', 'appellantIdCard', 'appellantContact', 'appellantEmail', 'appellantAddress', 'appealType', 'appealReason', 'appealTime', 'evidenceDescription', 'evidenceUrls'],
    fields: [
      { name: 'appealId', type: 'int', readOnly: true },
      // 后端字段：appealId | 来源：AppealRecord.appealId
      // 标识/关联字段，写入时需以后端约束为准
      { name: 'offenseId', type: 'int' },
      // 后端字段：offenseId | 来源：AppealRecord.offenseId
      // 标识/关联字段，写入时需以后端约束为准
      { name: 'appealNumber', type: 'String' },
      // 后端字段：appealNumber | 来源：AppealRecord.appealNumber
      { name: 'appellantName', type: 'String' },
      // 后端字段：appellantName | 来源：AppealRecord.appellantName
      { name: 'appellantIdCard', type: 'String' },
      // 后端字段：appellantIdCard | 来源：AppealRecord.appellantIdCard
      { name: 'appellantContact', type: 'String' },
      // 后端字段：appellantContact | 来源：AppealRecord.appellantContact
      { name: 'appellantEmail', type: 'String' },
      // 后端字段：appellantEmail | 来源：AppealRecord.appellantEmail
      { name: 'appellantAddress', type: 'String' },
      // 后端字段：appellantAddress | 来源：AppealRecord.appellantAddress
      { name: 'appealType', type: 'String' },
      // 后端字段：appealType | 来源：AppealRecord.appealType
      { name: 'appealReason', type: 'String' },
      // 后端字段：appealReason | 来源：AppealRecord.appealReason
      { name: 'appealTime', type: 'DateTime' },
      // 后端字段：appealTime | 来源：AppealRecord.appealTime
      { name: 'evidenceDescription', type: 'String' },
      // 后端字段：evidenceDescription | 来源：AppealRecord.evidenceDescription
      { name: 'evidenceUrls', type: 'String' },
      // 后端字段：evidenceUrls | 来源：AppealRecord.evidenceUrls
      { name: 'acceptanceStatus', type: 'String' },
      // 后端字段：acceptanceStatus | 枚举：Pending / Accepted / Rejected / Need_Supplement
      // 申诉受理状态，来源于后端 AppealAcceptanceState
      { name: 'acceptanceTime', type: 'DateTime' },
      // 后端字段：acceptanceTime | 来源：AppealRecord.acceptanceTime
      { name: 'acceptanceHandler', type: 'String' },
      // 后端字段：acceptanceHandler | 来源：AppealRecord.acceptanceHandler
      { name: 'rejectionReason', type: 'String' },
      // 后端字段：rejectionReason | 来源：AppealRecord.rejectionReason
      { name: 'processStatus', type: 'String' },
      // 后端字段：processStatus | 枚举：Unprocessed / Under_Review / Approved / Rejected / Withdrawn（Approved/Rejected 见 STATUSES 常量）
      // 由后端 workflow 控制，前端审核按钮应通过 workflowPermissions 判断
      { name: 'processTime', type: 'DateTime' },
      // 后端字段：processTime | 来源：AppealRecord.processTime
      { name: 'processResult', type: 'String' },
      // 后端字段：processResult | 来源：AppealRecord.processResult
      { name: 'processHandler', type: 'String' },
      // 后端字段：processHandler | 来源：AppealRecord.processHandler
      { name: 'createdAt', type: 'DateTime', readOnly: true },
      // 后端字段：createdAt | 来源：AppealRecord.createdAt
      // @readonly 审计时间字段，由后端生成或维护
      { name: 'updatedAt', type: 'DateTime', readOnly: true },
      // 后端字段：updatedAt | 来源：AppealRecord.updatedAt
      // @readonly 审计时间字段，由后端生成或维护
    ],
  },
  /**
   * @entity SysRequestHistory
   * @backendDto com.tutict.finalassignmentbackend.entity.SysRequestHistory
   * @apiPath /api/progress
   * @description 业务进度实体。记录幂等请求的业务处理状态和审计线索。
   */
  progress: {
    key: 'progress',
    label: '业务进度',
    basePath: API_PATHS.PROGRESS,
    idField: 'id',
    useCustomPage: true,
    displayFields: ['id', 'businessType', 'businessId', 'businessStatus', 'userId', 'createdTime', 'modifiedTime'],
    editableFields: [],
    fields: [
      { name: 'id', type: 'int', readOnly: true },
      // 后端字段：id | 来源：SysRequestHistory.id
      // 标识/关联字段，写入时需以后端约束为准
      { name: 'idempotencyKey', type: 'String' },
      // 后端字段：idempotencyKey | 幂等键，由后端生成，用于防重复提交
      // 前端不应手动设置此字段
      { name: 'requestMethod', type: 'String' },
      // 后端字段：requestMethod | 来源：SysRequestHistory.requestMethod
      { name: 'requestUrl', type: 'String' },
      // 后端字段：requestUrl | 来源：SysRequestHistory.requestUrl
      { name: 'requestParams', type: 'String' },
      // 后端字段：requestParams | 请求参数快照
      // @sensitive 可能包含业务入参或个人信息，展示和日志输出前应脱敏
      { name: 'businessType', type: 'String' },
      // 后端字段：businessType | 来源：SysRequestHistory.businessType
      { name: 'businessId', type: 'int' },
      // 后端字段：businessId | 来源：SysRequestHistory.businessId
      // 标识/关联字段，写入时需以后端约束为准
      { name: 'businessStatus', type: 'String' },
      // 后端字段：businessStatus | 业务层状态：PROCESSING / SUCCESS / FAILED
      // 区别于 HTTP 状态码；表示幂等请求对应业务的处理结果
      { name: 'userId', type: 'int' },
      // 后端字段：userId | 来源：SysRequestHistory.userId
      // 标识/关联字段，写入时需以后端约束为准
      { name: 'requestIp', type: 'String' },
      // 后端字段：requestIp | 来源：SysRequestHistory.requestIp
      { name: 'createdTime', type: 'DateTime', readOnly: true },
      // 后端字段：createdTime | 来源：SysRequestHistory.createdTime
      // @readonly 审计时间字段，由后端生成或维护
      { name: 'modifiedTime', type: 'DateTime', readOnly: true },
      // 后端字段：modifiedTime | 来源：SysRequestHistory.modifiedTime
      // @readonly 审计时间字段，由后端生成或维护
      { name: 'deletedAt', type: 'DateTime' },
      // 后端字段：deletedAt | 来源：SysRequestHistory.deletedAt
      // @readonly 审计时间字段，由后端生成或维护
    ],
  },
  /**
   * @entity SysUser
   * @backendDto com.tutict.finalassignmentbackend.entity.SysUser
   * @apiPath /api/users
   * @description 用户管理实体。记录系统用户基础资料、账号状态和登录安全信息。
   */
  users: {
    key: 'users',
    label: '用户管理',
    basePath: API_PATHS.USERS,
    idField: 'userId',
    useCustomPage: true,
    displayFields: ['userId', 'username', 'realName', 'contactNumber', 'email', 'department', 'position', 'status', 'lastLoginTime'],
    editableFields: ['username', 'realName', 'gender', 'contactNumber', 'email', 'department', 'position', 'employeeNumber', 'status', 'accountExpiryDate', 'remarks'],
    fields: [
      { name: 'userId', type: 'int', readOnly: true },
      // 后端字段：userId | 来源：SysUser.userId
      // 标识/关联字段，写入时需以后端约束为准
      { name: 'username', type: 'String' },
      // 后端字段：username | 来源：SysUser.username
      { name: 'password', type: 'String' },
      // 后端字段：password | @sensitive 密码哈希/密文字段
      // 不应在前端展示原始值，也不应通过通用表单回显
      { name: 'salt', type: 'String' },
      // 后端字段：salt | @sensitive 密码盐字段
      // 不应在前端展示或编辑
      { name: 'realName', type: 'String' },
      // 后端字段：realName | 来源：SysUser.realName
      { name: 'idCardNumber', type: 'String' },
      // 后端字段：idCardNumber | 用户身份证号
      // @sensitive 涉及个人身份信息，前端展示需脱敏
      { name: 'gender', type: 'String' },
      // 后端字段：gender | 来源：SysUser.gender
      { name: 'contactNumber', type: 'String' },
      // 后端字段：contactNumber | 联系电话
      // @sensitive 涉及个人联系方式，前端展示需脱敏
      { name: 'email', type: 'String' },
      // 后端字段：email | 来源：SysUser.email
      { name: 'department', type: 'String' },
      // 后端字段：department | 来源：SysUser.department
      { name: 'position', type: 'String' },
      // 后端字段：position | 来源：SysUser.position
      { name: 'employeeNumber', type: 'String' },
      // 后端字段：employeeNumber | 来源：SysUser.employeeNumber
      { name: 'status', type: 'String' },
      // 后端字段：status | 枚举：Active / Inactive / Locked / Expired
      // 用户账号状态，区别于驾驶证、车辆或角色状态
      { name: 'accountExpiryDate', type: 'DateTime' },
      // 后端字段：accountExpiryDate | 来源：SysUser.accountExpiryDate
      { name: 'loginFailures', type: 'int' },
      // 后端字段：loginFailures | 来源：SysUser.loginFailures
      { name: 'lastLoginTime', type: 'DateTime' },
      // 后端字段：lastLoginTime | 来源：SysUser.lastLoginTime
      { name: 'lastLoginIp', type: 'String' },
      // 后端字段：lastLoginIp | 来源：SysUser.lastLoginIp
      { name: 'passwordUpdateTime', type: 'DateTime' },
      // 后端字段：passwordUpdateTime | 来源：SysUser.passwordUpdateTime
      { name: 'createdTime', type: 'DateTime', readOnly: true },
      // 后端字段：createdTime | 来源：SysUser.createdTime
      // @readonly 审计时间字段，由后端生成或维护
      { name: 'modifiedTime', type: 'DateTime', readOnly: true },
      // 后端字段：modifiedTime | 来源：SysUser.modifiedTime
      // @readonly 审计时间字段，由后端生成或维护
      { name: 'createdBy', type: 'String' },
      // 后端字段：createdBy | 来源：SysUser.createdBy
      { name: 'updatedBy', type: 'String' },
      // 后端字段：updatedBy | 来源：SysUser.updatedBy
      { name: 'deletedAt', type: 'DateTime' },
      // 后端字段：deletedAt | 来源：SysUser.deletedAt
      // @readonly 审计时间字段，由后端生成或维护
      { name: 'remarks', type: 'String' },
      // 后端字段：remarks | 来源：SysUser.remarks
    ],
  },
  /**
   * @entity SysRole
   * @backendDto com.tutict.finalassignmentbackend.entity.SysRole
   * @apiPath /api/roles
   * @description 角色管理实体。记录系统角色、数据权限范围和启停状态。
   */
  roles: {
    key: 'roles',
    label: '角色管理',
    basePath: API_PATHS.ROLES,
    idField: 'roleId',
    displayFields: ['roleId', 'roleCode', 'roleName', 'roleType', 'dataScope', 'status', 'sortOrder'],
    editableFields: ['roleCode', 'roleName', 'roleType', 'roleDescription', 'dataScope', 'status', 'sortOrder', 'remarks'],
    fields: [
      { name: 'roleId', type: 'int', readOnly: true },
      // 后端字段：roleId | 来源：SysRole.roleId
      // 标识/关联字段，写入时需以后端约束为准
      { name: 'roleCode', type: 'String' },
      // 后端字段：roleCode | 来源：SysRole.roleCode
      { name: 'roleName', type: 'String' },
      // 后端字段：roleName | 来源：SysRole.roleName
      { name: 'roleType', type: 'String' },
      // 后端字段：roleType | 枚举：System / Business / Custom
      // 角色类型，影响角色治理和可编辑范围
      { name: 'roleDescription', type: 'String' },
      // 后端字段：roleDescription | 来源：SysRole.roleDescription
      { name: 'dataScope', type: 'String' },
      // 后端字段：dataScope | 枚举：All / Department / Department_And_Sub / Self / Custom
      // 数据权限范围，影响用户可见数据边界
      { name: 'status', type: 'String' },
      // 后端字段：status | 来源：SysRole.status
      // 状态字段，枚举含义随实体不同，需避免跨实体复用
      { name: 'sortOrder', type: 'int' },
      // 后端字段：sortOrder | 来源：SysRole.sortOrder
      { name: 'createdTime', type: 'DateTime', readOnly: true },
      // 后端字段：createdTime | 来源：SysRole.createdTime
      // @readonly 审计时间字段，由后端生成或维护
      { name: 'modifiedTime', type: 'DateTime', readOnly: true },
      // 后端字段：modifiedTime | 来源：SysRole.modifiedTime
      // @readonly 审计时间字段，由后端生成或维护
      { name: 'createdBy', type: 'String' },
      // 后端字段：createdBy | 来源：SysRole.createdBy
      { name: 'updatedBy', type: 'String' },
      // 后端字段：updatedBy | 来源：SysRole.updatedBy
      { name: 'deletedAt', type: 'DateTime' },
      // 后端字段：deletedAt | 来源：SysRole.deletedAt
      // @readonly 审计时间字段，由后端生成或维护
      { name: 'remarks', type: 'String' },
      // 后端字段：remarks | 来源：SysRole.remarks
    ],
  },
  /**
   * @entity SysPermission
   * @backendDto com.tutict.finalassignmentbackend.entity.SysPermission
   * @apiPath /api/permissions
   * @description 权限管理实体。记录菜单、按钮、API 和数据权限定义。
   */
  permissions: {
    key: 'permissions',
    label: '权限管理',
    basePath: API_PATHS.PERMISSIONS,
    idField: 'permissionId',
    displayFields: ['permissionId', 'permissionCode', 'permissionName', 'permissionType', 'menuPath', 'isVisible', 'status', 'sortOrder'],
    editableFields: ['parentId', 'permissionCode', 'permissionName', 'permissionType', 'permissionDescription', 'menuPath', 'menuIcon', 'component', 'isVisible', 'isExternal', 'sortOrder', 'status', 'remarks'],
    fields: [
      { name: 'permissionId', type: 'int', readOnly: true },
      // 后端字段：permissionId | 来源：SysPermission.permissionId
      // 标识/关联字段，写入时需以后端约束为准
      { name: 'parentId', type: 'int' },
      // 后端字段：parentId | 来源：SysPermission.parentId
      // 标识/关联字段，写入时需以后端约束为准
      { name: 'permissionCode', type: 'String' },
      // 后端字段：permissionCode | 来源：SysPermission.permissionCode
      { name: 'permissionName', type: 'String' },
      // 后端字段：permissionName | 来源：SysPermission.permissionName
      { name: 'permissionType', type: 'String' },
      // 后端字段：permissionType | 枚举：Menu / Button / API / Data
      // 权限类型，影响菜单渲染、按钮控制和接口授权
      { name: 'permissionDescription', type: 'String' },
      // 后端字段：permissionDescription | 来源：SysPermission.permissionDescription
      { name: 'menuPath', type: 'String' },
      // 后端字段：menuPath | 来源：SysPermission.menuPath
      { name: 'menuIcon', type: 'String' },
      // 后端字段：menuIcon | 来源：SysPermission.menuIcon
      { name: 'component', type: 'String' },
      // 后端字段：component | 来源：SysPermission.component
      { name: 'apiPath', type: 'String' },
      // 后端字段：apiPath | API 权限路径
      // 与 apiMethod 共同定义接口级权限
      { name: 'apiMethod', type: 'String' },
      // 后端字段：apiMethod | 枚举：GET / POST / PUT / DELETE
      // 与 apiPath 共同定义接口级权限
      { name: 'isVisible', type: 'bool' },
      // 后端字段：isVisible | 来源：SysPermission.isVisible
      { name: 'isExternal', type: 'bool' },
      // 后端字段：isExternal | 来源：SysPermission.isExternal
      { name: 'sortOrder', type: 'int' },
      // 后端字段：sortOrder | 来源：SysPermission.sortOrder
      { name: 'status', type: 'String' },
      // 后端字段：status | 来源：SysPermission.status
      // 状态字段，枚举含义随实体不同，需避免跨实体复用
      { name: 'createdTime', type: 'DateTime', readOnly: true },
      // 后端字段：createdTime | 来源：SysPermission.createdTime
      // @readonly 审计时间字段，由后端生成或维护
      { name: 'modifiedTime', type: 'DateTime', readOnly: true },
      // 后端字段：modifiedTime | 来源：SysPermission.modifiedTime
      // @readonly 审计时间字段，由后端生成或维护
      { name: 'createdBy', type: 'String' },
      // 后端字段：createdBy | 来源：SysPermission.createdBy
      { name: 'updatedBy', type: 'String' },
      // 后端字段：updatedBy | 来源：SysPermission.updatedBy
      { name: 'deletedAt', type: 'DateTime' },
      // 后端字段：deletedAt | 来源：SysPermission.deletedAt
      // @readonly 审计时间字段，由后端生成或维护
      { name: 'remarks', type: 'String' },
      // 后端字段：remarks | 来源：SysPermission.remarks
    ],
  },
  /**
   * @entity SysSettings
   * @backendDto com.tutict.finalassignmentbackend.entity.SysSettings
   * @apiPath /api/system/settings
   * @description 系统设置实体。记录系统级配置项及兼容聚合字段。
   */
  systemSettings: {
    key: 'systemSettings',
    label: '系统设置',
    basePath: API_PATHS.SYSTEM_SETTINGS,
    idField: 'settingId',
    displayFields: ['settingId', 'systemName', 'systemVersion', 'systemDescription', 'dateFormat', 'pageSize', 'loginTimeout', 'sessionTimeout', 'modifiedTime'],
    editableFields: ['systemName', 'systemDescription', 'copyrightInfo', 'loginTimeout', 'sessionTimeout', 'dateFormat', 'pageSize', 'remarks'],
    fields: [
      { name: 'settingId', type: 'int', readOnly: true },
      // 后端字段：settingId | 来源：SysSettings.settingId
      // 标识/关联字段，写入时需以后端约束为准
      { name: 'settingKey', type: 'String' },
      // 后端字段：settingKey | 来源：SysSettings.settingKey
      { name: 'settingValue', type: 'String' },
      // 后端字段：settingValue | 设置值
      // @sensitive 当 isEncrypted=true 或字段含密钥/密码时，不应在前端展示原始值
      { name: 'settingType', type: 'String' },
      // 后端字段：settingType | 来源：SysSettings.settingType
      { name: 'category', type: 'String' },
      // 后端字段：category | 来源：SysSettings.category
      { name: 'description', type: 'String' },
      // 后端字段：description | 来源：SysSettings.description
      { name: 'isEncrypted', type: 'bool' },
      // 后端字段：isEncrypted | 标记 settingValue 是否加密
      // 前端应据此决定是否遮蔽 settingValue
      { name: 'isEditable', type: 'bool' },
      // 后端字段：isEditable | 来源：SysSettings.isEditable
      { name: 'sortOrder', type: 'int' },
      // 后端字段：sortOrder | 来源：SysSettings.sortOrder
      { name: 'createdTime', type: 'DateTime', readOnly: true },
      // 后端字段：createdTime | 来源：SysSettings.createdTime
      // @readonly 审计时间字段，由后端生成或维护
      { name: 'modifiedTime', type: 'DateTime', readOnly: true },
      // 后端字段：modifiedTime | 来源：SysSettings.modifiedTime
      // @readonly 审计时间字段，由后端生成或维护
      { name: 'updatedBy', type: 'String' },
      // 后端字段：updatedBy | 来源：SysSettings.updatedBy
      { name: 'deletedAt', type: 'DateTime' },
      // 后端字段：deletedAt | 来源：SysSettings.deletedAt
      // @readonly 审计时间字段，由后端生成或维护
      { name: 'remarks', type: 'String' },
      // 后端字段：remarks | 来源：SysSettings.remarks
      { name: 'systemName', type: 'String' },
      // 后端字段：systemName | @deprecated 聚合展示字段，后端 SysSettings 未显式声明
      // @todo 确认是否由 settingKey/settingValue 聚合生成
      { name: 'systemVersion', type: 'String' },
      // 后端字段：systemVersion | @deprecated 聚合展示字段，后端 SysSettings 未显式声明
      // @todo 确认是否由 settingKey/settingValue 聚合生成
      { name: 'systemDescription', type: 'String' },
      // 后端字段：systemDescription | @deprecated 聚合展示字段，后端 SysSettings 未显式声明
      // @todo 确认是否由 settingKey/settingValue 聚合生成
      { name: 'copyrightInfo', type: 'String' },
      // 后端字段：copyrightInfo | @deprecated 聚合展示字段，后端 SysSettings 未显式声明
      // @todo 确认是否由 settingKey/settingValue 聚合生成
      { name: 'storagePath', type: 'String' },
      // 后端字段：storagePath | @deprecated 聚合展示字段，后端 SysSettings 未显式声明
      // @sensitive 可能暴露服务器路径；@todo 确认是否应前端展示
      { name: 'loginTimeout', type: 'int' },
      // 后端字段：loginTimeout | @deprecated 聚合展示字段，后端 SysSettings 未显式声明
      // @todo 确认是否由 settingKey/settingValue 聚合生成
      { name: 'sessionTimeout', type: 'int' },
      // 后端字段：sessionTimeout | @deprecated 聚合展示字段，后端 SysSettings 未显式声明
      // @todo 确认是否由 settingKey/settingValue 聚合生成
      { name: 'dateFormat', type: 'String' },
      // 后端字段：dateFormat | @deprecated 聚合展示字段，后端 SysSettings 未显式声明
      // @todo 确认是否由 settingKey/settingValue 聚合生成
      { name: 'pageSize', type: 'int' },
      // 后端字段：pageSize | @deprecated 聚合展示字段，后端 SysSettings 未显式声明
      // @todo 确认是否由 settingKey/settingValue 聚合生成
      { name: 'smtpServer', type: 'String' },
      // 后端字段：smtpServer | @deprecated 聚合展示字段，后端 SysSettings 未显式声明
      // @sensitive 可能暴露邮件服务器配置；@todo 确认是否应前端展示
      { name: 'emailAccount', type: 'String' },
      // 后端字段：emailAccount | @deprecated 聚合展示字段，后端 SysSettings 未显式声明
      // @sensitive 邮件账号不应在前端展示完整原始值
      { name: 'emailPassword', type: 'String' },
      // 后端字段：emailPassword | @deprecated 聚合展示字段，后端 SysSettings 未显式声明
      // @sensitive 邮件密码/密钥不应在前端展示原始值
    ],
  },
  /**
   * @entity SysBackupRestore
   * @backendDto com.tutict.finalassignmentbackend.entity.SysBackupRestore
   * @apiPath /api/system/backup
   * @description 备份恢复实体。记录系统备份文件、备份状态和恢复操作结果。
   */
  backups: {
    key: 'backups',
    label: '备份记录',
    basePath: API_PATHS.SYSTEM_BACKUP,
    idField: 'backupId',
    displayFields: ['backupId', 'backupType', 'backupFileName', 'backupFileSize', 'backupTime', 'backupDuration', 'backupHandler', 'restoreStatus', 'status'],
    editableFields: [],
    fields: [
      { name: 'backupId', type: 'int', readOnly: true },
      // 后端字段：backupId | 来源：SysBackupRestore.backupId
      // 标识/关联字段，写入时需以后端约束为准
      { name: 'backupType', type: 'String' },
      // 后端字段：backupType | 来源：SysBackupRestore.backupType
      { name: 'backupFileName', type: 'String' },
      // 后端字段：backupFileName | 来源：SysBackupRestore.backupFileName
      { name: 'backupFilePath', type: 'String' },
      // 后端字段：backupFilePath | 来源：SysBackupRestore.backupFilePath
      { name: 'backupFileSize', type: 'int' },
      // 后端字段：backupFileSize | 来源：SysBackupRestore.backupFileSize
      { name: 'backupTime', type: 'DateTime' },
      // 后端字段：backupTime | 来源：SysBackupRestore.backupTime
      { name: 'backupDuration', type: 'int' },
      // 后端字段：backupDuration | 来源：SysBackupRestore.backupDuration
      { name: 'backupHandler', type: 'String' },
      // 后端字段：backupHandler | 来源：SysBackupRestore.backupHandler
      { name: 'restoreTime', type: 'DateTime' },
      // 后端字段：restoreTime | 来源：SysBackupRestore.restoreTime
      { name: 'restoreDuration', type: 'int' },
      // 后端字段：restoreDuration | 来源：SysBackupRestore.restoreDuration
      { name: 'restoreStatus', type: 'String' },
      // 后端字段：restoreStatus | 枚举：Success / Failed / Partial
      // 本次恢复操作状态，区别于 status 的备份记录整体状态
      { name: 'restoreHandler', type: 'String' },
      // 后端字段：restoreHandler | 来源：SysBackupRestore.restoreHandler
      { name: 'errorMessage', type: 'String' },
      // 后端字段：errorMessage | 来源：SysBackupRestore.errorMessage
      { name: 'status', type: 'String' },
      // 后端字段：status | 枚举：Success / Failed / In_Progress
      // 备份记录整体状态，区别于 restoreStatus 的恢复操作结果
      { name: 'createdTime', type: 'DateTime', readOnly: true },
      // 后端字段：createdTime | 来源：SysBackupRestore.createdTime
      // @readonly 审计时间字段，由后端生成或维护
      { name: 'modifiedTime', type: 'DateTime', readOnly: true },
      // 后端字段：modifiedTime | 来源：SysBackupRestore.modifiedTime
      // @readonly 审计时间字段，由后端生成或维护
      { name: 'deletedAt', type: 'DateTime' },
      // 后端字段：deletedAt | 来源：SysBackupRestore.deletedAt
      // @readonly 审计时间字段，由后端生成或维护
      { name: 'remarks', type: 'String' },
      // 后端字段：remarks | 来源：SysBackupRestore.remarks
    ],
  },
  /**
   * @entity AuditLoginLog
   * @backendDto com.tutict.finalassignmentbackend.entity.AuditLoginLog
   * @apiPath /api/logs/login
   * @description 登录日志实体。记录用户登录、退出、失败原因和客户端环境。
   */
  loginLogs: {
    key: 'loginLogs',
    label: '登录日志',
    basePath: API_PATHS.LOGIN_LOGS,
    idField: 'logId',
    displayFields: ['logId', 'username', 'loginTime', 'logoutTime', 'loginResult', 'failureReason', 'loginIp', 'loginLocation', 'browserType', 'osType', 'deviceType'],
    editableFields: [],
    fields: [
      { name: 'logId', type: 'int', readOnly: true },
      // 后端字段：logId | 来源：AuditLoginLog.logId
      // 标识/关联字段，写入时需以后端约束为准
      // @readonly 日志实体不可编辑，前端仅用于审计展示
      { name: 'username', type: 'String' },
      // 后端字段：username | 来源：AuditLoginLog.username
      // @readonly 日志实体不可编辑，前端仅用于审计展示
      { name: 'loginTime', type: 'DateTime' },
      // 后端字段：loginTime | 来源：AuditLoginLog.loginTime
      // @readonly 日志实体不可编辑，前端仅用于审计展示
      { name: 'logoutTime', type: 'DateTime' },
      // 后端字段：logoutTime | 来源：AuditLoginLog.logoutTime
      // @readonly 日志实体不可编辑，前端仅用于审计展示
      { name: 'loginResult', type: 'String' },
      // 后端字段：loginResult | 来源：AuditLoginLog.loginResult
      // @readonly 日志实体不可编辑，前端仅用于审计展示
      { name: 'failureReason', type: 'String' },
      // 后端字段：failureReason | 来源：AuditLoginLog.failureReason
      // @readonly 日志实体不可编辑，前端仅用于审计展示
      { name: 'loginIp', type: 'String' },
      // 后端字段：loginIp | 来源：AuditLoginLog.loginIp
      // @readonly 日志实体不可编辑，前端仅用于审计展示
      { name: 'loginLocation', type: 'String' },
      // 后端字段：loginLocation | 来源：AuditLoginLog.loginLocation
      // @readonly 日志实体不可编辑，前端仅用于审计展示
      { name: 'browserType', type: 'String' },
      // 后端字段：browserType | 来源：AuditLoginLog.browserType
      // @readonly 日志实体不可编辑，前端仅用于审计展示
      { name: 'browserVersion', type: 'String' },
      // 后端字段：browserVersion | 来源：AuditLoginLog.browserVersion
      // @readonly 日志实体不可编辑，前端仅用于审计展示
      { name: 'osType', type: 'String' },
      // 后端字段：osType | 来源：AuditLoginLog.osType
      // @readonly 日志实体不可编辑，前端仅用于审计展示
      { name: 'osVersion', type: 'String' },
      // 后端字段：osVersion | 来源：AuditLoginLog.osVersion
      // @readonly 日志实体不可编辑，前端仅用于审计展示
      { name: 'deviceType', type: 'String' },
      // 后端字段：deviceType | 来源：AuditLoginLog.deviceType
      // @readonly 日志实体不可编辑，前端仅用于审计展示
      { name: 'userAgent', type: 'String' },
      // 后端字段：userAgent | 来源：AuditLoginLog.userAgent
      // @readonly 日志实体不可编辑，前端仅用于审计展示
      { name: 'sessionId', type: 'String' },
      // 后端字段：sessionId | 来源：AuditLoginLog.sessionId
      // @readonly 日志实体不可编辑，前端仅用于审计展示
      // @sensitive 会话标识，不应在前端展示完整原始值
      { name: 'token', type: 'String' },
      // 后端字段：token | 来源：AuditLoginLog.token
      // @readonly 日志实体不可编辑，前端仅用于审计展示
      // @sensitive 访问令牌，不应在前端展示原始值
      { name: 'createdAt', type: 'DateTime', readOnly: true },
      // 后端字段：createdAt | 来源：AuditLoginLog.createdAt
      // @readonly 审计时间字段，由后端生成或维护
      { name: 'deletedAt', type: 'DateTime' },
      // 后端字段：deletedAt | 来源：AuditLoginLog.deletedAt
      // @readonly 审计时间字段，由后端生成或维护
      { name: 'remarks', type: 'String' },
      // 后端字段：remarks | 来源：AuditLoginLog.remarks
      // @readonly 日志实体不可编辑，前端仅用于审计展示
    ],
  },
  /**
   * @entity AuditOperationLog
   * @backendDto com.tutict.finalassignmentbackend.entity.AuditOperationLog
   * @apiPath /api/logs/operation
   * @description 操作日志实体。记录用户操作、请求、响应和变更审计信息。
   */
  operationLogs: {
    key: 'operationLogs',
    label: '操作日志',
    basePath: API_PATHS.OPERATION_LOGS,
    idField: 'logId',
    displayFields: ['logId', 'operationType', 'operationModule', 'operationFunction', 'operationContent', 'operationTime', 'username', 'requestMethod', 'requestUrl', 'requestIp', 'operationResult', 'errorMessage', 'executionTime'],
    editableFields: [],
    fields: [
      { name: 'logId', type: 'int', readOnly: true },
      // 后端字段：logId | 来源：AuditOperationLog.logId
      // 标识/关联字段，写入时需以后端约束为准
      // @readonly 日志实体不可编辑，前端仅用于审计展示
      { name: 'operationType', type: 'String' },
      // 后端字段：operationType | 来源：AuditOperationLog.operationType
      // @readonly 日志实体不可编辑，前端仅用于审计展示
      { name: 'operationModule', type: 'String' },
      // 后端字段：operationModule | 来源：AuditOperationLog.operationModule
      // @readonly 日志实体不可编辑，前端仅用于审计展示
      { name: 'operationFunction', type: 'String' },
      // 后端字段：operationFunction | 来源：AuditOperationLog.operationFunction
      // @readonly 日志实体不可编辑，前端仅用于审计展示
      { name: 'operationContent', type: 'String' },
      // 后端字段：operationContent | 来源：AuditOperationLog.operationContent
      // @readonly 日志实体不可编辑，前端仅用于审计展示
      { name: 'operationTime', type: 'DateTime' },
      // 后端字段：operationTime | 来源：AuditOperationLog.operationTime
      // @readonly 日志实体不可编辑，前端仅用于审计展示
      { name: 'userId', type: 'int' },
      // 后端字段：userId | 来源：AuditOperationLog.userId
      // 标识/关联字段，写入时需以后端约束为准
      // @readonly 日志实体不可编辑，前端仅用于审计展示
      { name: 'username', type: 'String' },
      // 后端字段：username | 来源：AuditOperationLog.username
      // @readonly 日志实体不可编辑，前端仅用于审计展示
      { name: 'realName', type: 'String' },
      // 后端字段：realName | 来源：AuditOperationLog.realName
      // @readonly 日志实体不可编辑，前端仅用于审计展示
      { name: 'requestMethod', type: 'String' },
      // 后端字段：requestMethod | 来源：AuditOperationLog.requestMethod
      // @readonly 日志实体不可编辑，前端仅用于审计展示
      { name: 'requestUrl', type: 'String' },
      // 后端字段：requestUrl | 来源：AuditOperationLog.requestUrl
      // @readonly 日志实体不可编辑，前端仅用于审计展示
      { name: 'requestParams', type: 'String' },
      // 后端字段：requestParams | 来源：AuditOperationLog.requestParams
      // @readonly 日志实体不可编辑，前端仅用于审计展示
      // @sensitive 请求参数可能包含个人信息或凭据，展示前应脱敏
      { name: 'requestIp', type: 'String' },
      // 后端字段：requestIp | 来源：AuditOperationLog.requestIp
      // @readonly 日志实体不可编辑，前端仅用于审计展示
      { name: 'operationResult', type: 'String' },
      // 后端字段：operationResult | 来源：AuditOperationLog.operationResult
      // @readonly 日志实体不可编辑，前端仅用于审计展示
      { name: 'responseData', type: 'String' },
      // 后端字段：responseData | 来源：AuditOperationLog.responseData
      // @readonly 日志实体不可编辑，前端仅用于审计展示
      // @sensitive 响应数据可能包含业务敏感信息，展示前应脱敏
      { name: 'errorMessage', type: 'String' },
      // 后端字段：errorMessage | 来源：AuditOperationLog.errorMessage
      // @readonly 日志实体不可编辑，前端仅用于审计展示
      { name: 'executionTime', type: 'int' },
      // 后端字段：executionTime | 来源：AuditOperationLog.executionTime
      // @readonly 日志实体不可编辑，前端仅用于审计展示
      { name: 'oldValue', type: 'String' },
      // 后端字段：oldValue | 来源：AuditOperationLog.oldValue
      // @readonly 日志实体不可编辑，前端仅用于审计展示
      // @sensitive 变更前数据可能包含敏感字段，展示前应脱敏
      { name: 'newValue', type: 'String' },
      // 后端字段：newValue | 来源：AuditOperationLog.newValue
      // @readonly 日志实体不可编辑，前端仅用于审计展示
      // @sensitive 变更后数据可能包含敏感字段，展示前应脱敏
      { name: 'createdAt', type: 'DateTime', readOnly: true },
      // 后端字段：createdAt | 来源：AuditOperationLog.createdAt
      // @readonly 审计时间字段，由后端生成或维护
      { name: 'deletedAt', type: 'DateTime' },
      // 后端字段：deletedAt | 来源：AuditOperationLog.deletedAt
      // @readonly 审计时间字段，由后端生成或维护
      { name: 'remarks', type: 'String' },
      // 后端字段：remarks | 来源：AuditOperationLog.remarks
      // @readonly 日志实体不可编辑，前端仅用于审计展示
    ],
  },
  /**
   * @entity SystemLogView
   * @backendDto com.tutict.finalassignmentbackend.controller.SystemLogsController
   * @apiPath /api/system/logs
   * @description 系统日志聚合视图。汇总登录日志、操作日志和请求历史，仅用于只读展示。
   */
  systemLogs: {
    key: 'systemLogs',
    label: '系统日志',
    basePath: API_PATHS.SYSTEM_LOGS,
    idField: 'id',
    useCustomPage: true,
    displayFields: ['logId', 'logType', 'logContent', 'operationTime', 'operationUser', 'operationIpAddress', 'remarks'],
    editableFields: [],
    fields: [
      { name: 'logId', type: 'int', readOnly: true },
      // 后端字段：logId | 来源：SystemLogView.logId
      // 标识/关联字段，写入时需以后端约束为准
      // @readonly 日志实体不可编辑，前端仅用于审计展示
      { name: 'logType', type: 'String', readOnly: true },
      // 后端字段：logType | 来源：SystemLogView.logType
      // @readonly 日志实体不可编辑，前端仅用于审计展示
      { name: 'logContent', type: 'String', readOnly: true },
      // 后端字段：logContent | 来源：SystemLogView.logContent
      // @readonly 日志实体不可编辑，前端仅用于审计展示
      { name: 'operationTime', type: 'DateTime', readOnly: true },
      // 后端字段：operationTime | 来源：SystemLogView.operationTime
      // @readonly 日志实体不可编辑，前端仅用于审计展示
      { name: 'operationUser', type: 'String', readOnly: true },
      // 后端字段：operationUser | 来源：SystemLogView.operationUser
      // @readonly 日志实体不可编辑，前端仅用于审计展示
      { name: 'operationIpAddress', type: 'String', readOnly: true },
      // 后端字段：operationIpAddress | 来源：SystemLogView.operationIpAddress
      // @readonly 日志实体不可编辑，前端仅用于审计展示
      { name: 'remarks', type: 'String', readOnly: true },
      // 后端字段：remarks | 来源：SystemLogView.remarks
      // @readonly 日志实体不可编辑，前端仅用于审计展示
    ],
  },
};

export const entityList = Object.values(entityConfigs);
