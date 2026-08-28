/**
 * 哈尔滨交通管理服务点（对齐 Flutter `map.dart` 的 `_trafficMapPoints`）。
 */
export interface TrafficMapPoint {
  title: string;
  description: string;
  lat: number;
  lng: number;
  color: string;
}

export const trafficMapPoints: TrafficMapPoint[] = [
  {
    title: '交通管理服务中心',
    description: '违法处理、业务咨询和材料核验的综合服务点。',
    lat: 45.803775,
    lng: 126.534967,
    color: '#2F7DD6',
  },
  {
    title: '违法处理窗口',
    description: '适合办理违法查询、处罚确认和申诉材料提交。',
    lat: 45.77525,
    lng: 126.62374,
    color: '#E0A13A',
  },
  {
    title: '车辆登记窗口',
    description: '办理车辆登记、档案维护和信息核验业务。',
    lat: 45.70748,
    lng: 126.59102,
    color: '#24A39C',
  },
  {
    title: '事故快处服务点',
    description: '用于事故快处指引、证据提交和进度咨询。',
    lat: 45.81173,
    lng: 126.55989,
    color: '#8C74E8',
  },
];
