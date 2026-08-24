import 'package:final_assignment_front/features/dashboard/views/user/widgets/news_page_layout.dart';
import 'package:flutter/material.dart';

class AccidentEvidencePage extends StatelessWidget {
  const AccidentEvidencePage({super.key});

  static const _accent = Colors.orangeAccent;

  @override
  Widget build(BuildContext context) {
    return NewsPageLayout(
      title: '事故证据材料',
      subtitle: '事故现场取证清单与说明',
      accentColor: _accent,
      contentBuilder: (context, theme) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const NewsSummaryPanel(
            title: '现场证据采集',
            description: '拍摄现场全景、车辆位置、损伤部位和路面标识，保留关键材料。',
            icon: Icons.photo_camera_outlined,
            accentColor: _accent,
            chips: ['多角度照片', '行车记录仪', '证人信息'],
          ),
          const NewsSectionTitle(title: '必备证据'),
          const NewsInfoTile(
            title: '照片资料',
            description: '需要提供事故现场、车辆损坏、路面状况的多角度照片。',
            icon: Icons.image_outlined,
            accentColor: _accent,
          ),
          const NewsInfoTile(
            title: '视频资料',
            description: '如有行车记录仪视频或监控视频，可大幅提升处理效率。',
            icon: Icons.videocam_outlined,
            accentColor: _accent,
          ),
          const NewsInfoTile(
            title: '事故详情',
            description: '包括事故时间、地点、天气情况以及双方驾驶员信息。',
            icon: Icons.description_outlined,
            accentColor: _accent,
          ),
        ],
      ),
    );
  }
}
