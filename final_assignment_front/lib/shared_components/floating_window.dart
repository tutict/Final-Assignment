import 'package:flutter/material.dart';
import 'package:flutter_floating/floating/assist/Point.dart';
import 'package:flutter_floating/floating/assist/floating_slide_type.dart';
import 'package:flutter_floating/floating/floating.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '悬浮窗示例',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const FloatingWindowExample(),
    );
  }
}

class FloatingWindowExample extends StatefulWidget {
  const FloatingWindowExample({super.key});

  @override
  State<FloatingWindowExample> createState() => _FloatingWindowExampleState();
}

class _FloatingWindowExampleState extends State<FloatingWindowExample> {
  late Floating floating;

  @override
  void initState() {
    super.initState();
    floating = Floating(
      _buildFloatingWidget(),
      slideType: FloatingSlideType.onPoint,
      point: Point(
          MediaQueryData.fromView(WidgetsBinding .instance.platformDispatcher.views.first)
                      .size .width / 2 -
              (MediaQueryData.fromView(WidgetsBinding .instance.platformDispatcher.views.first)
                      .size .width * 0.4),
          MediaQueryData.fromView(WidgetsBinding .instance.platformDispatcher.views.first)
                      .size .height / 2 -
              (MediaQueryData.fromView(WidgetsBinding .instance.platformDispatcher.views.first)
                      .size .height * 0.45)),
      isSnapToEdge: false,
    );
  }

  Widget _buildFloatingWidget() {
    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha((0.2 * 255).toInt()),
              blurRadius: 20.0,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        width: MediaQueryData.fromView(
                    WidgetsBinding.instance.platformDispatcher.views.first)
                .size .width * 0.8,
        height: MediaQueryData.fromView(
                    WidgetsBinding.instance.platformDispatcher.views.first)
                .size .height * 0.9,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 35,
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              decoration: const BoxDecoration(
                color: Colors.blueAccent,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20.0),
                  topRight: Radius.circular(20.0),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(),
                  Row(
                    children: [
                      IconButton(
                        icon:
                            const Icon(Icons.crop_square, color: Colors.white),
                        onPressed: () {
                          // 全屏逻辑
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () {
                          floating.close();
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('悬浮窗示例'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            floating.open(context);
          },
          child: const Text('创建悬浮窗口'),
        ),
      ),
    );
  }
}
