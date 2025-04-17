import 'package:final_assignment_front/features/dashboard/views/user_screens/user_dashboard.dart';
import 'package:flutter/material.dart';
import 'package:get/Get.dart';
import 'package:google_fonts/google_fonts.dart';

class AccidentProgressPage extends StatefulWidget {
  const AccidentProgressPage({super.key});

  @override
  State<AccidentProgressPage> createState() => _AccidentProgressPageState();
}

class _AccidentProgressPageState extends State<AccidentProgressPage> {
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
              isDarkMode ? Colors.deepPurple[900]! : Colors.deepPurple,
              // 暗色模式使用更深的紫色
              isDarkMode
                  ? Theme.of(context).colorScheme.surface
                  : Theme.of(context).colorScheme.surface,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context, '事故处理状态追踪'),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle(context, '如何跟踪事故处理状态'),
                      _buildStepCard(
                        context,
                        '1. 登录系统',
                        '使用您的账号登录交通违法处理管理系统，进入用户仪表板。',
                      ),
                      _buildStepCard(
                        context,
                        '2. 进入事故管理',
                        '在仪表板中选择“事故管理”选项，查看所有已提交的事故记录。',
                      ),
                      _buildStepCard(
                        context,
                        '3. 查看进度详情',
                        '点击具体事故编号，查看当前状态（如“已提交”、“审核中”或“已完成”）。',
                      ),
                      const SizedBox(height: 16.0),
                      _buildSectionTitle(context, '实用建议'),
                      _buildContentCard(
                        context,
                        '定期检查',
                        '建议每周登录系统检查事故处理进度，确保及时响应审核要求。',
                      ),
                      _buildContentCard(
                        context,
                        '通知设置',
                        '启用系统通知，获取状态更新的实时提醒，避免遗漏重要信息。',
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
          color: isDarkMode ? Colors.white : Colors.white,
        ),
      ),
    );
  }

  Widget _buildStepCard(BuildContext context, String title, String content) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      color: isDarkMode ? Colors.grey[800] : Colors.white.withOpacity(0.9),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isDarkMode
              ? Colors.deepPurple
              : Theme.of(context).colorScheme.primary,
          child: Text(
            title.split('.')[0], // 提取步骤编号
            style: const TextStyle(color: Colors.white),
          ),
        ),
        title: Text(
          title,
          style: GoogleFonts.roboto(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white : Colors.black87,
          ),
        ),
        subtitle: Text(
          content,
          style: GoogleFonts.roboto(
            fontSize: 16,
            color: isDarkMode ? Colors.white70 : Colors.black54,
          ),
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
                    ? Colors.deepPurpleAccent
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
