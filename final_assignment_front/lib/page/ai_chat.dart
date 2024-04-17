import 'package:flutter/material.dart';



class AIChatPage extends StatefulWidget {
  @override
  AIJumpChatPageState createState() => AIChatPageState();
}

class AIChatPageState extends State<AIChatPage> {
  // 模拟的消息列表
  final List<Message> _messages = [];
  // 控制器用于文本输入
  TextEditingController _textEditingController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('AI 客服助手'),
      ),
      body: Column(
        children: <Widget>[
          Flexible(
            child: ListView.builder(
              padding: EdgeInsets.all(8.0),
              itemCount: _messages.length,
              reverse: true, // 使列表从底部开始，最新消息在最上面
              itemBuilder: (context, index) {
                final message = _messages[index];
                return ListTile(
                  title: message.isFromUser
                      ? Text(message.content, style: TextStyle(color: Colors.black))
                      : Text(message.content, style: TextStyle(color: Colors.blue)),
                );
              },
            ),
          ),
          Divider(height: 1), // 分隔线
          Flexible(
            child: Column(
              children: <Widget>[
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.0),
                  child: Row(
                    children: <Widget>[
                      Flexible(
                        child: TextField(
                          controller: _textEditingController,
                          decoration: InputDecoration(
                            hintText: '输入您的问题...',
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.all(Radius.circular(25.0)),
                            ),
                          ),
                          onSubmitted: (value) {
                            // 用户提交输入的问题
                            addMessage(value);
                          },
                        ),
                      ),
                      SizedBox(width: 8.0),
                      ElevatedButton(
                        onPressed: () {
                          // 用户点击发送按钮
                          _textEditingController.text.isNotEmpty
                              ? addMessage(_textEditingController.text)
                              : null;
                        },
                        child: Text('发送'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 添加消息到列表并滚动到最新的消息
  void addMessage(String content) {
    setState(() {
      // 添加用户消息
      _messages.add(Message(time: DateTime.now(), content: content, isFromUser: true));
      // 模拟AI回复
      simulateAIResponse();
    });
    _scrollToBottom();
  }

  // 模拟AI回复
  void simulateAIResponse() {
    // 这里可以根据实际情况调用AI接口获取回复内容
    String aiResponse = '这是AI的回复';
    setState(() {
      _messages.add(Message(time: DateTime.now(), content: aiResponse, isFromUser: false));
    });
    _scrollToBottom();
  }

  // 滚动到消息列表底部
  void _scrollToBottom() {
    ScrollableState? scrollableState = Scaffold.of(context).showBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container();
      },
    ) as ScrollableState;

    scrollableState?.animateTo(
      0.0,
      duration: Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }
}

// 消息模型
class Message {
  String content;
  bool isFromUser;
  DateTime time;

  Message({
    required this.content,
    this.isFromUser = false,
    required this.time,
  });
}