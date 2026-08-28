/**
 * 用户业务办理枢纽，对齐 Flutter BusinessProgressPage。
 * 4 个入口瓦片：违法详情 / 罚款缴纳 / 用户申诉 / 车辆登记。
 */
import {
  FiCreditCard,
  FiInfo,
  FiFlag,
  FiTruck,
} from 'react-icons/fi';
import BusinessHubPage from '../../components/BusinessHubPage';

const OPTIONS = [
  {
    title: '违法详情',
    description: '查看个人违法记录、处理状态和关联车辆信息。',
    badge: '待核验',
    icon: FiInfo,
    target: '/userOffenseListPage',
  },
  {
    title: '罚款缴纳',
    description: '核对缴款记录，进入罚款信息与支付状态页面。',
    badge: '在线办理',
    icon: FiCreditCard,
    target: '/fineInformation',
  },
  {
    title: '用户申诉',
    description: '提交申诉材料，跟进审核意见和办理进度。',
    badge: '材料提交',
    icon: FiFlag,
    target: '/userAppeal',
  },
  {
    title: '车辆登记',
    description: '维护车牌、车主和车辆档案等基础资料。',
    badge: '资料维护',
    icon: FiTruck,
    target: '/vehicleManagement',
  },
];

export default function BusinessProgressPage() {
  return (
    <BusinessHubPage
      title="业务办理"
      subtitle="集中处理违法查询、罚款缴纳、申诉提交和车辆资料维护"
      headerIcon={FiInfo}
      headerNote="集中处理违法查询、罚款缴纳、申诉提交和车辆资料维护。"
      options={OPTIONS}
      countLabel="4 个入口"
      hint="办理前请确认身份证号、驾驶证号和车辆资料已完善。"
    />
  );
}
