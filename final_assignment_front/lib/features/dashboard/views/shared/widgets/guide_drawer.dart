import 'package:final_assignment_front/features/dashboard/views/shared/widgets/guide_controller.dart';
import 'package:final_assignment_front/features/dashboard/views/user/pages/news/accident_evidence_page.dart';
import 'package:final_assignment_front/features/dashboard/views/user/pages/news/accident_progress_page.dart';
import 'package:final_assignment_front/features/dashboard/views/user/pages/news/accident_quick_guide_page.dart';
import 'package:final_assignment_front/features/dashboard/views/user/pages/news/accident_video_quick_page.dart';
import 'package:final_assignment_front/features/dashboard/views/user/pages/news/fine_payment_notice_page.dart';
import 'package:final_assignment_front/features/dashboard/views/user/pages/news/latest_offense_news_page.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class GuideDrawer extends StatelessWidget {
  const GuideDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final id = GuideController.guideId.value;
      if (id == null || id.isEmpty) return const SizedBox.shrink();
      final width = MediaQuery.sizeOf(context).width;
      final panelWidth = width >= 1100 ? 440.0 : width;
      return Align(
        alignment: Alignment.centerRight,
        child: Material(
          elevation: 8,
          child: SizedBox(
            width: panelWidth,
            height: double.infinity,
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    tooltip: '关闭指引',
                    onPressed: GuideController.close,
                    icon: const Icon(Icons.close),
                  ),
                ),
                Expanded(child: _guidePage(id)),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _guidePage(String id) {
    switch (id) {
      case 'payment':
        return const FinePaymentNoticePage();
      case 'quick':
        return const AccidentQuickGuidePage();
      case 'flow':
        return const AccidentProgressPage();
      case 'evidence':
        return const AccidentEvidencePage();
      case 'video':
        return const AccidentVideoQuickPage();
      case 'news':
      default:
        return const LatestOffenseNewsPage();
    }
  }
}

class GuideDrawerPanel extends StatelessWidget {
  const GuideDrawerPanel({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 8,
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: IconButton(
              tooltip: '关闭指引',
              onPressed: GuideController.close,
              icon: const Icon(Icons.close),
            ),
          ),
          Expanded(child: _page(id)),
        ],
      ),
    );
  }

  static Widget _page(String id) {
    switch (id) {
      case 'payment':
        return const FinePaymentNoticePage();
      case 'quick':
        return const AccidentQuickGuidePage();
      case 'flow':
        return const AccidentProgressPage();
      case 'evidence':
        return const AccidentEvidencePage();
      case 'video':
        return const AccidentVideoQuickPage();
      case 'news':
      default:
        return const LatestOffenseNewsPage();
    }
  }
}
