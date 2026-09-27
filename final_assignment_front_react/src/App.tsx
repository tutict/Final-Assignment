import { Suspense, lazy, useEffect } from 'react';
import { Navigate, Route, Routes, useLocation, useNavigate } from 'react-router-dom';
import ProtectedRoute from './auth/ProtectedRoute';
import ErrorBoundary from './components/ErrorBoundary';
import PageErrorFallback from './components/PageErrorFallback';
import { ROLES } from './constants/roles';
import { useAuth } from './auth/AuthContext';
import { settingsPathForRole, workspacePathForRole } from './config/navigation';
import LoginPage from './pages/shared/LoginPage';
import { useAgentWindow } from './layouts/AgentWindowContext';

const ManagerLayout = lazy(() => import('./layouts/ManagerLayout'));
const UserLayout = lazy(() => import('./layouts/UserLayout'));
const AppShell = lazy(() => import('./layouts/AppShell'));

const RagManagementPage = lazy(() => import('./pages/admin/RagManagementPage'));
const RequestHistoryPage = lazy(() => import('./pages/manager/RequestHistoryPage'));
const MapPage = lazy(() => import('./pages/shared/MapPage'));
const MainScanPage = lazy(() => import('./pages/shared/MainScanPage'));
const ProgressDetailPage = lazy(() => import('./pages/shared/ProgressDetailPage'));

const ManagerDashboardPage = lazy(() => import('./pages/manager/ManagerDashboardPage'));
const AppealManagementPage = lazy(() => import('./pages/manager/AppealManagementPage'));
const DeductionManagementPage = lazy(() => import('./pages/manager/DeductionManagementPage'));
const DriverListPage = lazy(() => import('./pages/manager/DriverListPage'));
const FineListPage = lazy(() => import('./pages/manager/FineListPage'));
const OffenseListPage = lazy(() => import('./pages/manager/OffenseListPage'));
const VehicleListPage = lazy(() => import('./pages/manager/VehicleListPage'));
const BackupRestorePage = lazy(() => import('./pages/manager/BackupRestorePage'));
const ManagerPersonalPage = lazy(() => import('./pages/manager/ManagerPersonalPage'));
const ManagerSettingPage = lazy(() => import('./pages/manager/ManagerSettingPage'));
const ProgressManagementPage = lazy(() => import('./pages/manager/ProgressManagementPage'));
const UserManagementPage = lazy(() => import('./pages/manager/UserManagementPage'));
const LoginLogPage = lazy(() => import('./pages/manager/LoginLogPage'));
const OperationLogPage = lazy(() => import('./pages/manager/OperationLogPage'));
const SystemLogPage = lazy(() => import('./pages/manager/SystemLogPage'));
const OffenseTypePage = lazy(() => import('./pages/manager/OffenseTypePage'));
const PaymentRecordPage = lazy(() => import('./pages/manager/PaymentRecordPage'));
const RoleManagementPage = lazy(() => import('./pages/manager/RoleManagementPage'));
const PermissionManagementPage = lazy(() => import('./pages/manager/PermissionManagementPage'));
const SystemSettingsPage = lazy(() => import('./pages/manager/SystemSettingsPage'));

const UserDashboardPage = lazy(() => import('./pages/user/UserDashboardPage'));
const UserOffenseListPage = lazy(() => import('./pages/user/UserOffenseListPage'));
const VehicleManagementPage = lazy(() => import('./pages/user/VehicleManagementPage'));
const FineInformationPage = lazy(() => import('./pages/user/FineInformationPage'));
const OnlineProcessingProgressPage = lazy(() => import('./pages/user/OnlineProcessingProgressPage'));
const UserAppealPage = lazy(() => import('./pages/user/UserAppealPage'));
const PersonalMainPage = lazy(() => import('./pages/user/PersonalMainPage'));
const UserSettingPage = lazy(() => import('./pages/user/UserSettingPage'));
const ConsultationFeedbackPage = lazy(() => import('./pages/user/ConsultationFeedbackPage'));

const routeFallback = <div className="placeholder">页面加载中...</div>;

interface LazyPageProps {
  default: React.ComponentType;
}

function renderLazyPage<P extends Record<string, unknown>>(
  LazyComponent: React.LazyExoticComponent<React.ComponentType<P>>,
  props?: P
) {
  const Component = LazyComponent as unknown as React.ComponentType<P>;
  return (
    <Suspense fallback={routeFallback}>
      <Component {...((props || {}) as P)} />
    </Suspense>
  );
}

function renderBoundedPage(
  LazyComponent: React.LazyExoticComponent<React.ComponentType<Record<string, unknown>>>,
  pageName: string
) {
  return (
    <ErrorBoundary fallback={<PageErrorFallback pageName={pageName} />}>
      {renderLazyPage(LazyComponent)}
    </ErrorBoundary>
  );
}

const WORKSPACE_KEY = 'workspace-path';

function WorkspaceMemory() {
  const location = useLocation();
  useEffect(() => {
    if (location.pathname === '/admin/aiChat' || location.pathname === '/login' || location.pathname === '/') return;
    sessionStorage.setItem(WORKSPACE_KEY, `${location.pathname}${location.search}`);
  }, [location]);
  return null;
}

function OpenAiOnMount() {
  const { openAgent } = useAgentWindow();
  const navigate = useNavigate();
  const { userRole } = useAuth();
  useEffect(() => {
    openAgent();
    const saved = sessionStorage.getItem(WORKSPACE_KEY);
    navigate(workspacePathForRole(userRole, saved), { replace: true });
  }, [navigate, openAgent, userRole]);
  return <div className="placeholder">正在打开 AI 助手，并留在当前工作台。</div>;
}

function ThemeSettingsRedirect() {
  const { userRole } = useAuth();
  return <Navigate to={`${settingsPathForRole(userRole)}?section=appearance`} replace />;
}

const managerRoles = [ROLES.ADMIN, ROLES.SUPER_ADMIN, ROLES.APPEAL_REVIEWER];
const userRoles = [ROLES.USER, ROLES.ADMIN, ROLES.SUPER_ADMIN];
const mapRoles = [ROLES.USER, ROLES.ADMIN, ROLES.SUPER_ADMIN];
const superRoles = [ROLES.SUPER_ADMIN];

export default function App() {
  return (
    <>
    <WorkspaceMemory />
    <Routes>
      <Route path="/" element={<Navigate to="/login" replace />} />
      <Route path="/login" element={<LoginPage />} />

      <Route path="/businessProgress" element={<Navigate to="/userDashboard" replace />} />
      <Route path="/managerBusinessProcessing" element={<Navigate to="/dashboard" replace />} />
      <Route path="/trafficViolationScreen" element={<Navigate to="/dashboard" replace />} />
      <Route path="/offenseScreen" element={<Navigate to="/dashboard" replace />} />
      <Route path="/onlineProcessing" element={<Navigate to="/onlineProcessingProgress" replace />} />
      <Route path="/admin/systemGovernance" element={<Navigate to="/admin/operationLogPage" replace />} />
      <Route path="/admin/logManagement" element={<Navigate to="/admin/operationLogPage" replace />} />
      <Route path="/changeThemes" element={<ThemeSettingsRedirect />} />
      <Route path="/admin/changeThemes" element={<ThemeSettingsRedirect />} />
      <Route path="/latestTrafficViolationNewsPage" element={<Navigate to="/userDashboard?guide=news" replace />} />
      <Route path="/latestOffenseNewsPage" element={<Navigate to="/userDashboard?guide=news" replace />} />
      <Route path="/finePaymentNoticePage" element={<Navigate to="/fineInformation?guide=payment" replace />} />
      <Route path="/accidentQuickGuidePage" element={<Navigate to="/userOffenseListPage?guide=quick" replace />} />
      <Route path="/accidentProgressPage" element={<Navigate to="/userOffenseListPage?guide=flow" replace />} />
      <Route path="/accidentEvidencePage" element={<Navigate to="/userOffenseListPage?guide=evidence" replace />} />
      <Route path="/accidentVideoQuickPage" element={<Navigate to="/userOffenseListPage?guide=video" replace />} />
      <Route path="/accountAndSecurity" element={<Navigate to="/userSetting" replace />} />
      <Route path="/changePassword" element={<Navigate to="/userSetting" replace />} />
      <Route path="/deleteAccount" element={<Navigate to="/userSetting" replace />} />
      <Route path="/informationStatement" element={<Navigate to="/userSetting" replace />} />
      <Route path="/migrateAccount" element={<Navigate to="/userSetting" replace />} />
      <Route path="/changeMobilePhoneNumber" element={<Navigate to="/personalMain" replace />} />
      <Route path="/personalInfo" element={<Navigate to="/personalMain" replace />} />

      <Route
        element={
          <ProtectedRoute allowRoles={managerRoles}>
            {renderLazyPage(ManagerLayout)}
          </ProtectedRoute>
        }
      >
        <Route path="/dashboard" element={renderBoundedPage(ManagerDashboardPage, '管理端首页')} />
        <Route path="/appealManagement" element={renderBoundedPage(AppealManagementPage, '申诉管理')} />
        <Route path="/deductionManagement" element={renderLazyPage(DeductionManagementPage)} />
        <Route path="/driverList" element={renderLazyPage(DriverListPage)} />
        <Route path="/fineList" element={renderBoundedPage(FineListPage, '罚款管理')} />
        <Route path="/offenseList" element={renderBoundedPage(OffenseListPage, '违法记录')} />
        <Route path="/vehicleList" element={renderLazyPage(VehicleListPage)} />
        <Route path="/progressManagement" element={renderLazyPage(ProgressManagementPage)} />
        <Route path="/offenseType" element={<ProtectedRoute allowRoles={superRoles}>{renderLazyPage(OffenseTypePage)}</ProtectedRoute>} />
        <Route path="/paymentRecord" element={renderLazyPage(PaymentRecordPage)} />
        <Route
          path="/ragManagement"
          element={
            <ProtectedRoute allowRoles={[ROLES.ADMIN, ROLES.SUPER_ADMIN]}>
              {renderBoundedPage(RagManagementPage, 'RAG 资料管理')}
            </ProtectedRoute>
          }
        />
      </Route>

      <Route
        path="/admin"
        element={
          <ProtectedRoute allowRoles={managerRoles}>
            {renderLazyPage(AppShell)}
          </ProtectedRoute>
        }
      >
        <Route index element={<Navigate to="/dashboard" replace />} />
        <Route path="backupAndRestore" element={<ProtectedRoute allowRoles={superRoles}>{renderLazyPage(BackupRestorePage)}</ProtectedRoute>} />
        <Route path="managerPersonalPage" element={renderLazyPage(ManagerPersonalPage)} />
        <Route path="managerSetting" element={renderLazyPage(ManagerSettingPage)} />
        <Route path="logManagement" element={<Navigate to="/admin/operationLogPage" replace />} />
        <Route path="userManagementPage" element={<ProtectedRoute allowRoles={superRoles}>{renderLazyPage(UserManagementPage)}</ProtectedRoute>} />
        <Route path="loginLogPage" element={<ProtectedRoute allowRoles={superRoles}>{renderLazyPage(LoginLogPage)}</ProtectedRoute>} />
        <Route path="operationLogPage" element={<ProtectedRoute allowRoles={superRoles}>{renderLazyPage(OperationLogPage)}</ProtectedRoute>} />
        <Route path="systemLogPage" element={<ProtectedRoute allowRoles={superRoles}>{renderBoundedPage(SystemLogPage, '系统日志')}</ProtectedRoute>} />
        <Route path="requestHistory" element={<ProtectedRoute allowRoles={superRoles}>{renderBoundedPage(RequestHistoryPage, '请求历史检索')}</ProtectedRoute>} />
        <Route path="roleManagement" element={<ProtectedRoute allowRoles={superRoles}>{renderLazyPage(RoleManagementPage)}</ProtectedRoute>} />
        <Route path="permissionManagement" element={<ProtectedRoute allowRoles={superRoles}>{renderLazyPage(PermissionManagementPage)}</ProtectedRoute>} />
        <Route path="systemSettings" element={<ProtectedRoute allowRoles={superRoles}>{renderLazyPage(SystemSettingsPage)}</ProtectedRoute>} />
        <Route path="ragManagement" element={<Navigate to="/ragManagement" replace />} />
        <Route path="systemGovernance" element={<Navigate to="/admin/operationLogPage" replace />} />
      </Route>

      <Route
        path="/admin/aiChat"
        element={
          <ProtectedRoute allowRoles={[...userRoles, ROLES.APPEAL_REVIEWER]}>
            {renderLazyPage(AppShell)}
          </ProtectedRoute>
        }
      >
        <Route index element={<OpenAiOnMount />} />
      </Route>

      <Route
        path="/admin/map"
        element={
          <ProtectedRoute allowRoles={mapRoles}>
            {renderLazyPage(AppShell)}
          </ProtectedRoute>
        }
      >
        <Route index element={renderLazyPage(MapPage)} />
      </Route>

      <Route
        element={
          <ProtectedRoute allowRoles={userRoles}>
            {renderLazyPage(UserLayout)}
          </ProtectedRoute>
        }
      >
        <Route path="/userDashboard" element={renderLazyPage(UserDashboardPage)} />
        <Route path="/userOffenseListPage" element={renderBoundedPage(UserOffenseListPage, '违法记录')} />
        <Route path="/vehicleManagement" element={renderLazyPage(VehicleManagementPage)} />
        <Route path="/fineInformation" element={renderBoundedPage(FineInformationPage, '罚款信息')} />
        <Route path="/onlineProcessingProgress" element={renderLazyPage(OnlineProcessingProgressPage)} />
        <Route path="/userAppeal" element={renderLazyPage(UserAppealPage)} />
        <Route path="/personalMain" element={renderLazyPage(PersonalMainPage)} />
        <Route path="/userSetting" element={renderLazyPage(UserSettingPage)} />
        <Route path="/consultation" element={renderLazyPage(ConsultationFeedbackPage)} />
      </Route>


      <Route
        path="/progressDetailPage/:id"
        element={
          <ProtectedRoute allowRoles={[...userRoles, ROLES.APPEAL_REVIEWER]}>
            {renderLazyPage(AppShell)}
          </ProtectedRoute>
        }
      >
        <Route index element={renderLazyPage(ProgressDetailPage)} />
      </Route>

      <Route
        path="/mainScan"
        element={
          <ProtectedRoute allowRoles={userRoles}>
            {renderLazyPage(AppShell)}
          </ProtectedRoute>
        }
      >
        <Route index element={renderLazyPage(MainScanPage)} />
      </Route>

      <Route path="*" element={<Navigate to="/login" replace />} />
    </Routes>
    </>
  );
}

export type { LazyPageProps };
