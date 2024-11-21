import 'package:flutter/material.dart';
import 'package:flutter_floating/floating/assist/Point.dart';
import 'package:flutter_floating/floating/assist/floating_slide_type.dart';
import 'package:flutter_floating/floating/floating.dart';

class FloatingWindow extends StatefulWidget with FloatingBase {
  const FloatingWindow({super.key});

  @override
  State<FloatingWindow> createState() => _FloatingWindowState();
}

class _FloatingWindowState extends State<FloatingWindow> {
  late Floating floating;
  bool isFullScreen = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return StatefulBuilder(
      builder: (context, setState) {
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
            width: isFullScreen
                ? MediaQueryData.fromView(
                        WidgetsBinding.instance.platformDispatcher.views.first) .size .width
                : MediaQueryData.fromView(
                        WidgetsBinding .instance.platformDispatcher.views.first) .size .width * 0.8,
            height: isFullScreen
                ? MediaQueryData.fromView(
                        WidgetsBinding.instance.platformDispatcher.views.first) .size .height
                : MediaQueryData.fromView(
                        WidgetsBinding .instance.platformDispatcher.views.first) .size .height * 0.6,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 35.0,
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
                      const Row(
                        children: [],
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.crop_square,
                                color: Colors.white),
                            onPressed: () {
                              setState(() {
                                isFullScreen = !isFullScreen;
                              });
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
                const Expanded(
                  child: Center(
                    child: Text(''),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

mixin FloatingBase {
  void initializeFloating(BuildContext context, Widget content) {
    final floating = Floating(
      context as Widget,
      slideType: FloatingSlideType.onPoint,
      point: Point(
        MediaQueryData.fromView(
                        WidgetsBinding.instance.platformDispatcher.views.first)
                    .size .width / 2 -
            (MediaQueryData.fromView(
                        WidgetsBinding.instance.platformDispatcher.views.first)
                    .size .width * 0.4),
        MediaQueryData.fromView(
                        WidgetsBinding.instance.platformDispatcher.views.first)
                    .size .height / 2 -
            (MediaQueryData.fromView(
                        WidgetsBinding.instance.platformDispatcher.views.first)
                    .size .height * 0.3),
      ),
      isSnapToEdge: false,

      /// 是否自动吸附到屏幕边缘
    );

    floating.open(context);
  }
}
