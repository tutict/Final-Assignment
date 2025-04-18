import 'package:final_assignment_front/features/dashboard/views/user_screens/user_dashboard.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class FinePaymentNoticePage extends StatefulWidget {
  const FinePaymentNoticePage({super.key});

  @override
  State<FinePaymentNoticePage> createState() => _FinePaymentNoticePageState();
}

class _FinePaymentNoticePageState extends State<FinePaymentNoticePage> {
  final controller = Get.find<UserDashboardController>();

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              isDarkMode
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.primary, // 保持主题主色
              isDarkMode
                  ? Theme.of(context).colorScheme.surface
                  : Theme.of(context).colorScheme.surface,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context, '罚款缴纳须知'),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle(context, '最新通知'),
                      _buildContentCard(
                        context,
                        '2025年2月新规',
                        '从即日起，所有交通罚款需通过在线平台缴纳，线下窗口将逐步关闭。',
                      ),
                      _buildContentCard(
                        context,
                        '缴纳方式',
                        '支持银行卡、支付宝和微信支付，确保账户余额充足以避免逾期。',
                      ),
                      _buildSectionTitle(context, '注意事项'),
                      _buildContentCard(
                        context,
                        '逾期后果',
                        '未在30天内缴纳罚款将产生滞纳金，严重者可能影响个人信用。',
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String title) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back,
                color: isDarkMode ? Colors.white : Colors.white),
            onPressed: () => controller.exitSidebarContent(),
          ),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.roboto(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: GoogleFonts.roboto(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: isDarkMode
              ? Colors.white
              : Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }

  Widget _buildContentCard(BuildContext context, String title, String content) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      color: isDarkMode ? Colors.grey[800] : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.roboto(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDarkMode
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              content,
              style: GoogleFonts.roboto(
                fontSize: 16,
                color: isDarkMode ? Colors.white70 : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
