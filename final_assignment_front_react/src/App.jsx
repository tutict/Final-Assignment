import React from 'react';
import { Navigate, Route, Routes } from 'react-router-dom';
import ProtectedRoute from './auth/ProtectedRoute.jsx';
import ManagerLayout from './layouts/ManagerLayout.jsx';
import UserLayout from './layouts/UserLayout.jsx';
import RoleAwareLayout from './layouts/RoleAwareLayout.jsx';

import LoginPage from './pages/shared/LoginPage.jsx';
import AiChatPage from './pages/shared/AiChatPage.jsx';
import MapPage from './pages/shared/MapPage.jsx';
import NewsPage from './pages/shared/NewsPage.jsx';
import MainScanPage from './pages/shared/MainScanPage.jsx';
import ChangeThemesPage from './pages/shared/ChangeThemesPage.jsx';
import ProgressDetailPage from './pages/shared/ProgressDetailPage.jsx';
import PlaceholderPage from './pages/shared/PlaceholderPage.jsx';

import ManagerDashboardPage from './pages/manager/ManagerDashboardPage.jsx';
import TrafficViolationScreenPage from './pages/manager/TrafficViolationScreenPage.jsx';
import AppealManagementPage from './pages/manager/AppealManagementPage.jsx';
import DeductionManagementPage from './pages/manager/DeductionManagementPage.jsx';
import DriverListPage from './pages/manager/DriverListPage.jsx';
import FineListPage from './pages/manager/FineListPage.jsx';
import OffenseListPage from './pages/manager/OffenseListPage.jsx';
import VehicleListPage from './pages/manager/VehicleListPage.jsx';
import BackupRestorePage from './pages/manager/BackupRestorePage.jsx';
import ManagerPersonalPage from './pages/manager/ManagerPersonalPage.jsx';
import ManagerSettingPage from './pages/manager/ManagerSettingPage.jsx';
import ProgressManagementPage from './pages/manager/ProgressManagementPage.jsx';
import ManagerBusinessProcessingPage from './pages/manager/ManagerBusinessProcessingPage.jsx';
import LogManagementPage from './pages/manager/LogManagementPage.jsx';
import UserManagementPage from './pages/manager/UserManagementPage.jsx';
import LoginLogPage from './pages/manager/LoginLogPage.jsx';
import OperationLogPage from './pages/manager/OperationLogPage.jsx';
import SystemLogPage from './pages/manager/SystemLogPage.jsx';
import OffenseTypePage from './pages/manager/OffenseTypePage.jsx';
import PaymentRecordPage from './pages/manager/PaymentRecordPage.jsx';
import RoleManagementPage from './pages/manager/RoleManagementPage.jsx';
import PermissionManagementPage from './pages/manager/PermissionManagementPage.jsx';
import SystemSettingsPage from './pages/manager/SystemSettingsPage.jsx';

import UserDashboardPage from './pages/user/UserDashboardPage.jsx';
import UserOffenseListPage from './pages/user/UserOffenseListPage.jsx';
import VehicleManagementPage from './pages/user/VehicleManagementPage.jsx';
import FineInformationPage from './pages/user/FineInformationPage.jsx';
import BusinessProgressPage from './pages/user/BusinessProgressPage.jsx';
import OnlineProcessingProgressPage from './pages/user/OnlineProcessingProgressPage.jsx';
import UserAppealPage from './pages/user/UserAppealPage.jsx';
import PersonalMainPage from './pages/user/PersonalMainPage.jsx';
import UserSettingPage from './pages/user/UserSettingPage.jsx';
import ConsultationFeedbackPage from './pages/user/ConsultationFeedbackPage.jsx';
import OnlineProcessingPage from './pages/user/OnlineProcessingPage.jsx';

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

export default function App() {
  return (
    <Routes>
      <Route path="/" element={<Navigate to="/login" replace />} />
      <Route path="/login" element={<LoginPage />} />

      <Route
        element={
          <ProtectedRoute allowRoles={["ADMIN", "SUPER_ADMIN", "APPEAL_REVIEWER"]}>
            <ManagerLayout />
          </ProtectedRoute>
        }
      >
        <Route path="/dashboard" element={<ManagerDashboardPage />} />
        <Route path="/trafficViolationScreen" element={<TrafficViolationScreenPage />} />
        <Route path="/appealManagement" element={<AppealManagementPage />} />
        <Route path="/deductionManagement" element={<DeductionManagementPage />} />
        <Route path="/driverList" element={<DriverListPage />} />
        <Route path="/fineList" element={<FineListPage />} />
        <Route path="/offenseList" element={<OffenseListPage />} />
        <Route path="/vehicleList" element={<VehicleListPage />} />
        <Route path="/backupAndRestore" element={<BackupRestorePage />} />
        <Route path="/managerPersonalPage" element={<ManagerPersonalPage />} />
        <Route path="/managerSetting" element={<ManagerSettingPage />} />
        <Route path="/progressManagement" element={<ProgressManagementPage />} />
        <Route path="/managerBusinessProcessing" element={<ManagerBusinessProcessingPage />} />
        <Route path="/logManagement" element={<LogManagementPage />} />
        <Route path="/userManagementPage" element={<UserManagementPage />} />
        <Route path="/loginLogPage" element={<LoginLogPage />} />
        <Route path="/operationLogPage" element={<OperationLogPage />} />
        <Route path="/systemLogPage" element={<SystemLogPage />} />
        <Route path="/offenseType" element={<OffenseTypePage />} />
        <Route path="/paymentRecord" element={<PaymentRecordPage />} />
        <Route path="/roleManagement" element={<RoleManagementPage />} />
        <Route path="/permissionManagement" element={<PermissionManagementPage />} />
        <Route path="/systemSettings" element={<SystemSettingsPage />} />
        <Route path="/progressDetailPage/:id" element={<ProgressDetailPage />} />
      </Route>

      <Route
        element={
          <ProtectedRoute allowRoles={["USER", "ADMIN", "SUPER_ADMIN"]}>
            <UserLayout />
          </ProtectedRoute>
        }
      >
        <Route path="/userDashboard" element={<UserDashboardPage />} />
        <Route path="/userOffenseListPage" element={<UserOffenseListPage />} />
        <Route path="/vehicleManagement" element={<VehicleManagementPage />} />
        <Route path="/fineInformation" element={<FineInformationPage />} />
        <Route path="/businessProgress" element={<BusinessProgressPage />} />
        <Route path="/onlineProcessingProgress" element={<OnlineProcessingProgressPage />} />
        <Route path="/onlineProcessing" element={<OnlineProcessingPage />} />
        <Route path="/userAppeal" element={<UserAppealPage />} />
        <Route path="/personalMain" element={<PersonalMainPage />} />
        <Route path="/userSetting" element={<UserSettingPage />} />
        <Route path="/consultation" element={<ConsultationFeedbackPage />} />
      </Route>

      <Route
        path="/aiChat"
        element={
          <ProtectedRoute allowRoles={["USER", "ADMIN", "SUPER_ADMIN"]}>
            <RoleAwareLayout headerTitle="AI 智能助手" headerSubtitle="智能问答与业务指引" />
          </ProtectedRoute>
        }
      >
        <Route index element={<AiChatPage />} />
      </Route>

      <Route
        path="/map"
        element={
          <ProtectedRoute allowRoles={["USER", "ADMIN", "SUPER_ADMIN"]}>
            <RoleAwareLayout headerTitle="违法地图" headerSubtitle="数据分布与热点分析" />
          </ProtectedRoute>
        }
      >
        <Route index element={<MapPage />} />
      </Route>

      <Route
        path="/mainScan"
        element={
          <ProtectedRoute allowRoles={["USER", "ADMIN", "SUPER_ADMIN"]}>
            <RoleAwareLayout headerTitle="扫码服务" headerSubtitle="快速处理入口" />
          </ProtectedRoute>
        }
      >
        <Route index element={<MainScanPage />} />
      </Route>

      <Route
        path="/changeThemes"
        element={
          <ProtectedRoute allowRoles={["USER", "ADMIN", "SUPER_ADMIN"]}>
            <RoleAwareLayout headerTitle="主题管理" headerSubtitle="界面风格设置" />
          </ProtectedRoute>
        }
      >
        <Route index element={<ChangeThemesPage />} />
      </Route>

      <Route
        path="/accidentEvidencePage"
        element={
          <ProtectedRoute allowRoles={["USER", "ADMIN", "SUPER_ADMIN"]}>
            <RoleAwareLayout headerTitle="事故证据采集" headerSubtitle="快捷指南" />
          </ProtectedRoute>
        }
      >
        <Route index element={<NewsPage title="事故证据采集" sections={newsContent.accidentEvidencePage} />} />
      </Route>
      <Route
        path="/accidentProgressPage"
        element={
          <ProtectedRoute allowRoles={["USER", "ADMIN", "SUPER_ADMIN"]}>
            <RoleAwareLayout headerTitle="事故处理流程" headerSubtitle="快速指南" />
          </ProtectedRoute>
        }
      >
        <Route index element={<NewsPage title="事故处理流程" sections={newsContent.accidentProgressPage} />} />
      </Route>
      <Route
        path="/accidentQuickGuidePage"
        element={
          <ProtectedRoute allowRoles={["USER", "ADMIN", "SUPER_ADMIN"]}>
            <RoleAwareLayout headerTitle="事故快处指南" headerSubtitle="快速指南" />
          </ProtectedRoute>
        }
      >
        <Route index element={<NewsPage title="事故快处指南" sections={newsContent.accidentQuickGuidePage} />} />
      </Route>
      <Route
        path="/accidentVideoQuickPage"
        element={
          <ProtectedRoute allowRoles={["USER", "ADMIN", "SUPER_ADMIN"]}>
            <RoleAwareLayout headerTitle="事故处理视频" headerSubtitle="快速指南" />
          </ProtectedRoute>
        }
      >
        <Route index element={<NewsPage title="事故处理视频" sections={newsContent.accidentVideoQuickPage} />} />
      </Route>
      <Route
        path="/finePaymentNoticePage"
        element={
          <ProtectedRoute allowRoles={["USER", "ADMIN", "SUPER_ADMIN"]}>
            <RoleAwareLayout headerTitle="罚款缴纳说明" headerSubtitle="快速指南" />
          </ProtectedRoute>
        }
      >
        <Route index element={<NewsPage title="罚款缴纳说明" sections={newsContent.finePaymentNoticePage} />} />
      </Route>
      <Route
        path="/latestTrafficViolationNewsPage"
        element={
          <ProtectedRoute allowRoles={["USER", "ADMIN", "SUPER_ADMIN"]}>
            <RoleAwareLayout headerTitle="最新交通资讯" headerSubtitle="权威资讯" />
          </ProtectedRoute>
        }
      >
        <Route index element={<NewsPage title="最新交通资讯" sections={newsContent.latestTrafficViolationNewsPage} />} />
      </Route>

      <Route
        element={
          <ProtectedRoute allowRoles={["USER", "ADMIN", "SUPER_ADMIN"]}>
            <RoleAwareLayout headerTitle="账户中心" headerSubtitle="账户与安全设置" />
          </ProtectedRoute>
        }
      >
        <Route
          path="/accountAndSecurity"
          element={<PlaceholderPage title="账户与安全" description="账号安全设置" />}
        />
        <Route
          path="/changePassword"
          element={<PlaceholderPage title="修改密码" description="更新账户密码" />}
        />
        <Route
          path="/deleteAccount"
          element={<PlaceholderPage title="删除账户" description="注销账户流程" />}
        />
        <Route
          path="/informationStatement"
          element={<PlaceholderPage title="信息声明" description="隐私与信息使用说明" />}
        />
        <Route
          path="/migrateAccount"
          element={<PlaceholderPage title="账户迁移" description="迁移账户数据" />}
        />
        <Route
          path="/changeMobilePhoneNumber"
          element={<PlaceholderPage title="修改手机号" description="更新绑定手机号" />}
        />
        <Route
          path="/personalInfo"
          element={<PlaceholderPage title="个人信息" description="更新个人资料" />}
        />
      </Route>

      <Route path="*" element={<Navigate to="/login" replace />} />
    </Routes>
  );
}
