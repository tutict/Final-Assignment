import React, { Suspense, lazy } from 'react';
import { Navigate, Route, Routes } from 'react-router-dom';
import ProtectedRoute from './auth/ProtectedRoute.jsx';
import { ROLES } from './constants/roles.js';
import LoginPage from './pages/shared/LoginPage.jsx';

const ManagerLayout = lazy(() => import('./layouts/ManagerLayout.jsx'));
const AdminLayout = lazy(() => import('./layouts/AdminLayout.jsx'));
const UserLayout = lazy(() => import('./layouts/UserLayout.jsx'));
const RoleAwareLayout = lazy(() => import('./layouts/RoleAwareLayout.jsx'));

const AiChatPage = lazy(() => import('./pages/shared/AiChatPage.jsx'));
const MapPage = lazy(() => import('./pages/shared/MapPage.jsx'));
const NewsPage = lazy(() => import('./pages/shared/NewsPage.jsx'));
const MainScanPage = lazy(() => import('./pages/shared/MainScanPage.jsx'));
const ChangeThemesPage = lazy(() => import('./pages/shared/ChangeThemesPage.jsx'));
const ProgressDetailPage = lazy(() => import('./pages/shared/ProgressDetailPage.jsx'));
const PlaceholderPage = lazy(() => import('./pages/shared/PlaceholderPage.jsx'));

const ManagerDashboardPage = lazy(() => import('./pages/manager/ManagerDashboardPage.jsx'));
const TrafficViolationScreenPage = lazy(() => import('./pages/manager/TrafficViolationScreenPage.jsx'));
const AppealManagementPage = lazy(() => import('./pages/manager/AppealManagementPage.jsx'));
const DeductionManagementPage = lazy(() => import('./pages/manager/DeductionManagementPage.jsx'));
const DriverListPage = lazy(() => import('./pages/manager/DriverListPage.jsx'));
const FineListPage = lazy(() => import('./pages/manager/FineListPage.jsx'));
const OffenseListPage = lazy(() => import('./pages/manager/OffenseListPage.jsx'));
const VehicleListPage = lazy(() => import('./pages/manager/VehicleListPage.jsx'));
const BackupRestorePage = lazy(() => import('./pages/manager/BackupRestorePage.jsx'));
const ManagerPersonalPage = lazy(() => import('./pages/manager/ManagerPersonalPage.jsx'));
const ManagerSettingPage = lazy(() => import('./pages/manager/ManagerSettingPage.jsx'));
const ProgressManagementPage = lazy(() => import('./pages/manager/ProgressManagementPage.jsx'));
const ManagerBusinessProcessingPage = lazy(() => import('./pages/manager/ManagerBusinessProcessingPage.jsx'));
const LogManagementPage = lazy(() => import('./pages/manager/LogManagementPage.jsx'));
const UserManagementPage = lazy(() => import('./pages/manager/UserManagementPage.jsx'));
const LoginLogPage = lazy(() => import('./pages/manager/LoginLogPage.jsx'));
const OperationLogPage = lazy(() => import('./pages/manager/OperationLogPage.jsx'));
const SystemLogPage = lazy(() => import('./pages/manager/SystemLogPage.jsx'));
const OffenseTypePage = lazy(() => import('./pages/manager/OffenseTypePage.jsx'));
const PaymentRecordPage = lazy(() => import('./pages/manager/PaymentRecordPage.jsx'));
const RoleManagementPage = lazy(() => import('./pages/manager/RoleManagementPage.jsx'));
const PermissionManagementPage = lazy(() => import('./pages/manager/PermissionManagementPage.jsx'));
const SystemSettingsPage = lazy(() => import('./pages/manager/SystemSettingsPage.jsx'));

const UserDashboardPage = lazy(() => import('./pages/user/UserDashboardPage.jsx'));
const UserOffenseListPage = lazy(() => import('./pages/user/UserOffenseListPage.jsx'));
const VehicleManagementPage = lazy(() => import('./pages/user/VehicleManagementPage.jsx'));
const FineInformationPage = lazy(() => import('./pages/user/FineInformationPage.jsx'));
const BusinessProgressPage = lazy(() => import('./pages/user/BusinessProgressPage.jsx'));
const OnlineProcessingProgressPage = lazy(() => import('./pages/user/OnlineProcessingProgressPage.jsx'));
const UserAppealPage = lazy(() => import('./pages/user/UserAppealPage.jsx'));
const PersonalMainPage = lazy(() => import('./pages/user/PersonalMainPage.jsx'));
const UserSettingPage = lazy(() => import('./pages/user/UserSettingPage.jsx'));
const ConsultationFeedbackPage = lazy(() => import('./pages/user/ConsultationFeedbackPage.jsx'));
const OnlineProcessingPage = lazy(() => import('./pages/user/OnlineProcessingPage.jsx'));

const routeFallback = <div className="placeholder">页面加载中...</div>;

function renderLazyPage(LazyComponent, props) {
  return (
    <Suspense fallback={routeFallback}>
      <LazyComponent {...props} />
    </Suspense>
  );
}

const newsContent = {
  accidentEvidencePage: [
    { heading: '现场证据采集', content: '拍摄现场全景、车辆位置、损伤部位和路面标识。' },
    { heading: '关键材料', content: '保留行车记录仪视频、证人联系方式与事故时间记录。' },
  ],
  accidentProgressPage: [
    { heading: '事故处理流程', content: '报警、现场取证、责任认定、保险理赔、后续处理。' },
    { heading: '注意事项', content: '保持现场，确保安全，及时上传资料。' },
  ],
  accidentQuickGuidePage: [
    { heading: '快速处理指引', content: '小事故可通过快处流程拍照并上传，避免交通拥堵。' },
    { heading: '材料准备', content: '身份证、驾驶证、行驶证、保险信息。' },
  ],
  accidentVideoQuickPage: [
    { heading: '视频教学', content: '观看事故处理视频教程，了解在线操作步骤。' },
  ],
  finePaymentNoticePage: [
    { heading: '缴费说明', content: '支持网银、移动支付与线下窗口。' },
    { heading: '缴费提醒', content: '逾期会产生滞纳金，请及时处理。' },
  ],
  latestTrafficViolationNewsPage: [
    { heading: '最新交通资讯', content: '关注最新处罚标准与道路管理政策。' },
    { heading: '安全提示', content: '文明出行，守法驾驶。' },
  ],
};

const managerRoles = [ROLES.ADMIN, ROLES.SUPER_ADMIN, ROLES.APPEAL_REVIEWER];
const userRoles = [ROLES.USER, ROLES.ADMIN, ROLES.SUPER_ADMIN];

export default function App() {
  return (
    <Routes>
      <Route path="/" element={<Navigate to="/login" replace />} />
      <Route path="/login" element={<LoginPage />} />

      <Route
        element={
          <ProtectedRoute allowRoles={managerRoles}>
            {renderLazyPage(ManagerLayout)}
          </ProtectedRoute>
        }
      >
        <Route path="/dashboard" element={renderLazyPage(ManagerDashboardPage)} />
        <Route path="/trafficViolationScreen" element={renderLazyPage(TrafficViolationScreenPage)} />
        <Route path="/appealManagement" element={renderLazyPage(AppealManagementPage)} />
        <Route path="/deductionManagement" element={renderLazyPage(DeductionManagementPage)} />
        <Route path="/driverList" element={renderLazyPage(DriverListPage)} />
        <Route path="/fineList" element={renderLazyPage(FineListPage)} />
        <Route path="/offenseList" element={renderLazyPage(OffenseListPage)} />
        <Route path="/vehicleList" element={renderLazyPage(VehicleListPage)} />
        <Route path="/progressManagement" element={renderLazyPage(ProgressManagementPage)} />
        <Route path="/managerBusinessProcessing" element={renderLazyPage(ManagerBusinessProcessingPage)} />
        <Route path="/offenseType" element={renderLazyPage(OffenseTypePage)} />
        <Route path="/paymentRecord" element={renderLazyPage(PaymentRecordPage)} />
        <Route path="/progressDetailPage/:id" element={renderLazyPage(ProgressDetailPage)} />
      </Route>

      <Route
        path="/admin"
        element={
          <ProtectedRoute allowRoles={managerRoles}>
            {renderLazyPage(AdminLayout)}
          </ProtectedRoute>
        }
      >
        <Route index element={<Navigate to="/admin/logManagement" replace />} />
        <Route path="backupAndRestore" element={renderLazyPage(BackupRestorePage)} />
        <Route path="managerPersonalPage" element={renderLazyPage(ManagerPersonalPage)} />
        <Route path="managerSetting" element={renderLazyPage(ManagerSettingPage)} />
        <Route path="logManagement" element={renderLazyPage(LogManagementPage)} />
        <Route path="userManagementPage" element={renderLazyPage(UserManagementPage)} />
        <Route path="loginLogPage" element={renderLazyPage(LoginLogPage)} />
        <Route path="operationLogPage" element={renderLazyPage(OperationLogPage)} />
        <Route path="systemLogPage" element={renderLazyPage(SystemLogPage)} />
        <Route path="roleManagement" element={renderLazyPage(RoleManagementPage)} />
        <Route path="permissionManagement" element={renderLazyPage(PermissionManagementPage)} />
        <Route path="systemSettings" element={renderLazyPage(SystemSettingsPage)} />
        <Route path="aiChat" element={renderLazyPage(AiChatPage)} />
        <Route path="map" element={renderLazyPage(MapPage)} />
      </Route>

      <Route
        element={
          <ProtectedRoute allowRoles={userRoles}>
            {renderLazyPage(UserLayout)}
          </ProtectedRoute>
        }
      >
        <Route path="/userDashboard" element={renderLazyPage(UserDashboardPage)} />
        <Route path="/userOffenseListPage" element={renderLazyPage(UserOffenseListPage)} />
        <Route path="/vehicleManagement" element={renderLazyPage(VehicleManagementPage)} />
        <Route path="/fineInformation" element={renderLazyPage(FineInformationPage)} />
        <Route path="/businessProgress" element={renderLazyPage(BusinessProgressPage)} />
        <Route path="/onlineProcessingProgress" element={renderLazyPage(OnlineProcessingProgressPage)} />
        <Route path="/onlineProcessing" element={renderLazyPage(OnlineProcessingPage)} />
        <Route path="/userAppeal" element={renderLazyPage(UserAppealPage)} />
        <Route path="/personalMain" element={renderLazyPage(PersonalMainPage)} />
        <Route path="/userSetting" element={renderLazyPage(UserSettingPage)} />
        <Route path="/consultation" element={renderLazyPage(ConsultationFeedbackPage)} />
      </Route>

      <Route
        path="/mainScan"
        element={
          <ProtectedRoute allowRoles={userRoles}>
            {renderLazyPage(RoleAwareLayout, {
              headerTitle: '扫码服务',
              headerSubtitle: '快速处理入口',
            })}
          </ProtectedRoute>
        }
      >
        <Route index element={renderLazyPage(MainScanPage)} />
      </Route>

      <Route
        path="/changeThemes"
        element={
          <ProtectedRoute allowRoles={userRoles}>
            {renderLazyPage(RoleAwareLayout, {
              headerTitle: '主题管理',
              headerSubtitle: '界面风格设置',
            })}
          </ProtectedRoute>
        }
      >
        <Route index element={renderLazyPage(ChangeThemesPage)} />
      </Route>

      <Route
        path="/accidentEvidencePage"
        element={
          <ProtectedRoute allowRoles={userRoles}>
            {renderLazyPage(RoleAwareLayout, {
              headerTitle: '事故证据采集',
              headerSubtitle: '快捷指南',
            })}
          </ProtectedRoute>
        }
      >
        <Route
          index
          element={renderLazyPage(NewsPage, {
            title: '事故证据采集',
            sections: newsContent.accidentEvidencePage,
          })}
        />
      </Route>
      <Route
        path="/accidentProgressPage"
        element={
          <ProtectedRoute allowRoles={userRoles}>
            {renderLazyPage(RoleAwareLayout, {
              headerTitle: '事故处理流程',
              headerSubtitle: '快速指南',
            })}
          </ProtectedRoute>
        }
      >
        <Route
          index
          element={renderLazyPage(NewsPage, {
            title: '事故处理流程',
            sections: newsContent.accidentProgressPage,
          })}
        />
      </Route>
      <Route
        path="/accidentQuickGuidePage"
        element={
          <ProtectedRoute allowRoles={userRoles}>
            {renderLazyPage(RoleAwareLayout, {
              headerTitle: '事故快处指南',
              headerSubtitle: '快速指南',
            })}
          </ProtectedRoute>
        }
      >
        <Route
          index
          element={renderLazyPage(NewsPage, {
            title: '事故快处指南',
            sections: newsContent.accidentQuickGuidePage,
          })}
        />
      </Route>
      <Route
        path="/accidentVideoQuickPage"
        element={
          <ProtectedRoute allowRoles={userRoles}>
            {renderLazyPage(RoleAwareLayout, {
              headerTitle: '事故处理视频',
              headerSubtitle: '快速指南',
            })}
          </ProtectedRoute>
        }
      >
        <Route
          index
          element={renderLazyPage(NewsPage, {
            title: '事故处理视频',
            sections: newsContent.accidentVideoQuickPage,
          })}
        />
      </Route>
      <Route
        path="/finePaymentNoticePage"
        element={
          <ProtectedRoute allowRoles={userRoles}>
            {renderLazyPage(RoleAwareLayout, {
              headerTitle: '罚款缴纳说明',
              headerSubtitle: '快速指南',
            })}
          </ProtectedRoute>
        }
      >
        <Route
          index
          element={renderLazyPage(NewsPage, {
            title: '罚款缴纳说明',
            sections: newsContent.finePaymentNoticePage,
          })}
        />
      </Route>
      <Route
        path="/latestTrafficViolationNewsPage"
        element={
          <ProtectedRoute allowRoles={userRoles}>
            {renderLazyPage(RoleAwareLayout, {
              headerTitle: '最新交通资讯',
              headerSubtitle: '权威资讯',
            })}
          </ProtectedRoute>
        }
      >
        <Route
          index
          element={renderLazyPage(NewsPage, {
            title: '最新交通资讯',
            sections: newsContent.latestTrafficViolationNewsPage,
          })}
        />
      </Route>

      <Route
        element={
          <ProtectedRoute allowRoles={userRoles}>
            {renderLazyPage(RoleAwareLayout, {
              headerTitle: '账户中心',
              headerSubtitle: '账户与安全设置',
            })}
          </ProtectedRoute>
        }
      >
        <Route
          path="/accountAndSecurity"
          element={renderLazyPage(PlaceholderPage, {
            title: '账户与安全',
            description: '账号安全设置',
          })}
        />
        <Route
          path="/changePassword"
          element={renderLazyPage(PlaceholderPage, {
            title: '修改密码',
            description: '更新账户密码',
          })}
        />
        <Route
          path="/deleteAccount"
          element={renderLazyPage(PlaceholderPage, {
            title: '删除账户',
            description: '注销账户流程',
          })}
        />
        <Route
          path="/informationStatement"
          element={renderLazyPage(PlaceholderPage, {
            title: '信息声明',
            description: '隐私与信息使用说明',
          })}
        />
        <Route
          path="/migrateAccount"
          element={renderLazyPage(PlaceholderPage, {
            title: '账户迁移',
            description: '迁移账户数据',
          })}
        />
        <Route
          path="/changeMobilePhoneNumber"
          element={renderLazyPage(PlaceholderPage, {
            title: '修改手机号',
            description: '更新绑定手机号',
          })}
        />
        <Route
          path="/personalInfo"
          element={renderLazyPage(PlaceholderPage, {
            title: '个人信息',
            description: '更新个人资料',
          })}
        />
      </Route>

      <Route path="*" element={<Navigate to="/login" replace />} />
    </Routes>
  );
}
