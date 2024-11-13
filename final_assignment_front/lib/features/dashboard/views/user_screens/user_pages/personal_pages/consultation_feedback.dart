import 'package:flutter/cupertino.dart';

class ConsultationFeedback extends StatelessWidget {
  const ConsultationFeedback({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('咨询反馈'),
        leading: GestureDetector(
          onTap: () {
            Navigator.pop(context);
          },
          child: const Icon(CupertinoIcons.back),
        ),
        backgroundColor: CupertinoColors.systemBlue,
        brightness: Brightness.dark,
      ),
      child: SafeArea(
        child: CupertinoScrollbar(
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              Container(
                decoration: BoxDecoration(
                  color: CupertinoColors.extraLightBackgroundGray,
                  borderRadius: BorderRadius.circular(12.0),
                  border: Border.all(
                    color: CupertinoColors.separator,
                    width: 0.5,
                  ),
                ),
                child: const CupertinoTextField(
                  placeholder: '请输入您的反馈...',
                  maxLines: 6,
                  padding: EdgeInsets.all(12.0),
                  decoration: null,
                ),
              ),
              const SizedBox(height: 20.0),
              CupertinoButton.filled(
                borderRadius: BorderRadius.circular(10.0),
                child: const Text('提交反馈'),
                onPressed: () {
                  // Handle submission
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
