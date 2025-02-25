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
                ? MediaQuery.of(context).size.width
                : MediaQuery.of(context).size.width * 0.8,
            height: isFullScreen
                ? MediaQuery.of(context).size.height
                : MediaQuery.of(context).size.height * 0.6,
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
                      const Row(children: []),
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
                  child: Center(child: Text('')),
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
      content, // 正确传入 Widget 作为位置参数
      slideType: FloatingSlideType.onPoint,
      point: Point(
        MediaQuery.of(context).size.width / 2 -
            (MediaQuery.of(context).size.width * 0.4),
        MediaQuery.of(context).size.height / 2 -
            (MediaQuery.of(context).size.height * 0.3),
      ),
      isSnapToEdge: false,
    );

    floating.open(context);
  }
}
