/**
 * 系统治理页（仅超级管理员），对齐 Flutter SystemGovernancePage。
 * 集中审查系统日志、异常链路与 RAG 知识资料的导航枢纽。
 */
import {
  FiBookOpen,
  FiLogIn,
  FiList,
  FiSearch,
  FiShield,
} from 'react-icons/fi';
import BusinessHubPage from '../../components/BusinessHubPage';

const OPTIONS = [
  {
    title: '操作日志审查',
    description: '审查关键业务操作、异常请求和幂等链路。',
    badge: 'Audit',
    icon: FiSearch,
    target: '/admin/operationLogPage',
  },
  {
    title: '登录日志审查',
    description: '核对登录来源、失败记录、浏览器和设备信息。',
    badge: 'Login',
    icon: FiLogIn,
    target: '/admin/loginLogPage',
  },
  {
    title: '系统请求日志',
    description: '查看接口请求历史、业务状态和异常回放线索。',
    badge: 'System',
    icon: FiList,
    target: '/admin/systemLogPage',
  },
  {
    title: 'RAG 资料管理',
    description: '录入知识资料、触发回填并检查索引切片状态。',
    badge: 'RAG',
    icon: FiBookOpen,
    target: '/admin/ragManagement',
  },
];

export default function SystemGovernancePage() {
  return (
    <BusinessHubPage
      title="系统治理"
      subtitle="超级管理员工作区"
      headerIcon={FiShield}
      headerNote="集中审查系统日志、异常链路和 RAG 知识资料，普通管理员仅处理业务。"
      options={OPTIONS}
      countLabel="4 个入口"
    />
  );
}
