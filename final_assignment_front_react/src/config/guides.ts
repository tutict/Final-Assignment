export interface GuideSection {
  heading: string;
  content: string;
}

export interface GuideArticle {
  id: string;
  title: string;
  sections: GuideSection[];
}

export const guideArticles: GuideArticle[] = [
  {
    id: 'news',
    title: '最新交通资讯',
    sections: [
      { heading: '最新交通资讯', content: '关注最新处罚标准与道路管理政策。' },
      { heading: '安全提示', content: '文明出行，守法驾驶。' },
    ],
  },
  {
    id: 'payment',
    title: '罚款缴纳说明',
    sections: [
      { heading: '缴费说明', content: '支持网银、移动支付与线下窗口。' },
      { heading: '缴费提醒', content: '逾期会产生滞纳金，请及时处理。' },
    ],
  },
  {
    id: 'quick',
    title: '事故快处指南',
    sections: [
      { heading: '快速处理指引', content: '小事故可通过快处流程拍照并上传，避免交通拥堵。' },
      { heading: '材料准备', content: '身份证、驾驶证、行驶证、保险信息。' },
    ],
  },
  {
    id: 'flow',
    title: '事故处理流程',
    sections: [
      { heading: '事故处理流程', content: '报警、现场取证、责任认定、保险理赔、后续处理。' },
      { heading: '注意事项', content: '保持现场，确保安全，及时上传资料。' },
    ],
  },
  {
    id: 'evidence',
    title: '事故证据采集',
    sections: [
      { heading: '现场证据采集', content: '拍摄现场全景、车辆位置、损伤部位和路面标识。' },
      { heading: '关键材料', content: '保留行车记录仪视频、证人联系方式与事故时间记录。' },
    ],
  },
  {
    id: 'video',
    title: '事故处理视频',
    sections: [{ heading: '视频教学', content: '观看事故处理视频教程，了解在线操作步骤。' }],
  },
];

export function findGuide(id: string | null): GuideArticle | undefined {
  if (!id) return undefined;
  return guideArticles.find((article) => article.id === id);
}
