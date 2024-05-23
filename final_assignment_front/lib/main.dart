import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:card_swiper/card_swiper.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(
    ScreenUtilInit(
      designSize: const Size(1080, 1920), // 设计稿宽高的px
      minTextAdapt: true, // 是否根据宽度/高度中的最小值适配文字
      splitScreenMode: true, // 支持分屏尺寸
      useInheritedMediaQuery: true,
      builder: (BuildContext context, Widget? child) {
        return MaterialApp(
          title: 'Flutter Demo',
          theme: ThemeData(
            primarySwatch: Colors.blue,
          ),
          home: TrafficViolationScreen(),
        );
      },
    ),
  );
}

class TrafficViolationScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('12123'),
        centerTitle: true,
        backgroundColor: Colors.blue,
      ),
      body: Column(
        children: <Widget>[
          ComSwiper(
            paginationBuilder: ComPaginationBuilder.circle(),
            bannerList: [
              "https://img0.baidu.com/it/u=2862534777,914942650&fm=253&fmt=auto&app=138&f=JPEG?w=889&h=500",
              "https://img0.baidu.com/it/u=2862534777,914942650&fm=253&fmt=auto&app=138&f=JPEG?w=889&h=500",
              "https://img0.baidu.com/it/u=2862534777,914942650&fm=253&fmt=auto&app=138&f=JPEG?w=889&h=500",
              "https://img0.baidu.com/it/u=2862534777,914942650&fm=253&fmt=auto&app=138&f=JPEG?w=889&h=500",
            ],
            onTap: (index) {
              debugPrint("我点击了第 $index 张图片");
            },
            item: (item) => Padding(
              padding: EdgeInsets.all(ScreenHelper.width(18)),
              child: ClipRRect(
                borderRadius: BorderRadius.all(Radius.circular(ScreenHelper.width(6))),
                child: CaCheImageWidget(imageUrl: item),
              ),
            ),
          ),
          Expanded( // 确保Column中的其他组件在Swiper下方有足够空间显示
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                // 在这里添加您的其他组件
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: CustomBottomNavigationBar(), // 添加底部导航栏
    );
  }
}

// 自定义轮播图设置
class ComSwiper extends StatelessWidget {
  /// 轮播图滚动列表
  final List<String> bannerList;

  /// 高度可定制
  final double widgetHeight;

  /// 返回的 item 的定制
  final Widget Function(String) item;

  /// 是否自动播放
  final bool autoPlay;

  /// 点击的回调
  final void Function(String)? onTap;

  /// 指示器的布局
  final Alignment paginationAlignment;

  /// 指示器距离组件的距离
  final EdgeInsetsGeometry? paginationMargin;

  /// 是否显示指示器
  final bool showSwiperPagination;

  /// 构造指示器
  final SwiperPlugin? paginationBuilder;

  const ComSwiper({
    Key? key,
    required this.bannerList,
    this.widgetHeight = 160,
    required this.item,
    this.autoPlay = true,
    this.onTap,
    this.showSwiperPagination = true,
    this.paginationAlignment = Alignment.bottomRight,
    this.paginationMargin,
    this.paginationBuilder,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widgetHeight,
      child: _swiper(context),
    );
  }

  Widget _swiper(BuildContext context) {
    return Swiper(
      onTap: (index) {
        if (onTap != null) {
          onTap!(bannerList[index]);
        }
      },
      itemCount: bannerList.length,
      autoplay: bannerList.length != 1 ? autoPlay : false,
      itemBuilder: (BuildContext context, int index) => item(bannerList[index]),
      pagination: (bannerList.length != 1) && showSwiperPagination
          ? SwiperPagination(
        alignment: paginationAlignment,
        margin: paginationMargin ?? EdgeInsets.only(right: 20.0, bottom: 20.0),
        builder: paginationBuilder ?? ComPaginationBuilder.circle(
          activeColor: Theme.of(context).indicatorColor,
          color: Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey,
        ),
      )
          : null,
    );
  }
}

class ComPaginationBuilder {
  /// 原点形指示器
  /// [activeColor] 选中的颜色
  /// [color] 默认颜色
  /// [size] 默认的大小
  /// [activeSize] 选中的大小
  /// [space] 间距
  static DotSwiperPaginationBuilder dot({
    Color? activeColor,
    Color? color,
    double size = 10.0,
    double activeSize = 10.0,
    double space = 3.0,
  }) {
    return DotSwiperPaginationBuilder(
      activeSize: activeSize,
      activeColor: activeColor,
      color: color,
      size: size,
      space: space,
    );
  }

  /// 带数字分页的指示器
  /// 效果：1/4
  /// [activeColor] 选中的颜色
  /// [color] 默认颜色
  /// [fontSize] 默认的大小
  /// [activeFontSize] 选中的大小
  static FractionPaginationBuilder fraction({
    Color? color,
    double fontSize = 20.0,
    Color? activeColor,
    double activeFontSize = 35.0,
  }) {
    return FractionPaginationBuilder(
      color: color,
      fontSize: fontSize,
      activeColor: activeColor,
      activeFontSize: activeFontSize,
    );
  }

  /// 方块指示器
  /// [activeColor] 选中的颜色
  /// [color] 默认颜色
  /// [size] 默认的大小
  /// [activeSize] 选中的大小
  static RectSwiperPaginationBuilder rect({
    Color? activeColor,
    Color? color,
    Size size = const Size(12.0, 12.0),
    Size activeSize = const Size(18.0, 12.0),
    double space = 3.0,
  }) {
    return RectSwiperPaginationBuilder(
      activeSize: activeSize,
      activeColor: activeColor,
      color: color,
      size: size,
      space: space,
    );
  }

  /// 圆形指示器（假设不存在 CirCleSwiperPaginationBuilder，则手动实现一个圆形指示器）
  static SwiperPlugin circle({
    Color? activeColor,
    Color? color,
    double size = 10.0,
    double activeSize = 12.0,
    double space = 3.0,
  }) {
    return SwiperCustomPagination(
      builder: (BuildContext context, SwiperPluginConfig config) {
        List<Widget> dots = [];
        for (int i = 0; i < config.itemCount; ++i) {
          bool active = i == config.activeIndex;
          dots.add(Container(
            key: Key('pagination_$i'),
            margin: EdgeInsets.all(space),
            child: ClipOval(
              child: Container(
                color: active ? activeColor : color,
                width: active ? activeSize : size,
                height: active ? activeSize : size,
              ),
            ),
          ));
        }
        return Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: dots,
        );
      },
    );
  }
}

class ScreenHelper {
  static double width(double value) {
    // 请根据需要调整此函数的实现
    return value;
  }
}

class CaCheImageWidget extends StatelessWidget {
  final String imageUrl;

  const CaCheImageWidget({Key? key, required this.imageUrl}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Image.network(imageUrl);
  }
}

class CustomBottomNavigationBar extends StatefulWidget {
  const CustomBottomNavigationBar({Key? key}) : super(key: key);

  @override
  CustomBottomNavigationBarState createState() => CustomBottomNavigationBarState();
}

class CustomBottomNavigationBarState extends State<CustomBottomNavigationBar> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        Container(
          color: Colors.black, // 设置背景颜色为黑色
          height: 65, // 导航栏高度
        ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              _buildNavItem(Icons.home, '首页', 0),
              _buildNavItem(Icons.business, '业务办理进度', 1),
              _buildNavItem(Icons.qr_code_scanner, '扫一扫', 2, isScanButton: true),
              _buildNavItem(Icons.location_on, '服务网点', 3),
              _buildNavItem(Icons.person, '我的', 4),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index, {bool isScanButton = false}) {
    return GestureDetector(
      onTap: () => _onItemTapped(index),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          if (isScanButton) Stack(
            clipBehavior: Clip.none,
            children: [
              ClipPath(
                clipper: ScanButtonClipper(),
                child: Container(
                  color: Colors.black,
                  height: 60,
                  width: 70,
                ),
              ),
              Positioned(
                top: -25,
                left: 0,
                right: 0,
                child: CircleAvatar(
                  radius: 35,
                  backgroundColor: Colors.blue[800],
                  child: Icon(icon, color: Colors.white, size: 25),
                ),
              ),
            ],
          ) else Icon(icon, color: _selectedIndex == index ? Colors.blue[800] : Colors.grey[300]),
          if (!isScanButton)
            SizedBox(height: 8), // 添加一些间隔
          if (!isScanButton)
            Text(
              label,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: _selectedIndex == index ? Colors.blue[800] : Colors.grey[300]),
            ),
        ],
      ),
    );
  }
}

class ScanButtonClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(0, size.height);
    path.quadraticBezierTo(size.width / 2, 0, size.width, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) {
    return false;
  }
}
