import 'package:flutter/material.dart';

class SelectTextItem extends StatelessWidget {
  const SelectTextItem({
    required Key key,
    required this.title,
    required this.onTap,
    this.content = "",
    this.textAlign = TextAlign.start,
    required this.titleStyle,
    required this.contentStyle,
    required this.height,
    this.isShowArrow = true,
    required this.imageName,
  }) : super(key: key);

  final GestureTapCallback onTap;
  final String title;
  final String content;
  final TextAlign textAlign;
  final TextStyle? titleStyle;
  final TextStyle? contentStyle;
  final double? height;
  final bool isShowArrow; //是否显示右侧箭头
  final String? imageName; //左侧图片名字 不传则不显示图片

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: height ?? 50.0,
        margin: const EdgeInsets.only(left: 16, right: 16),
        width: double.infinity,
        decoration: BoxDecoration(
            border: Border(
                //下面的分割线 width 这个参数应该是控制分割线高度的
                bottom: Divider.createBorderSide(context,
                    color: const Color(0xFFEEEEEE), width: 1))),
        child: Row(
          children: <Widget>[
            imageName == null
                ? Container()
                : Image.asset(
                    imageName!,
                    width: 22,
                    height: 22,
                  ),
            Text(title,
                style: titleStyle ??
                    const TextStyle(
                      color: Color(0xFF333333),
                      fontSize: 14.0,
                    )),
            Expanded(
              child: Container(
                padding: const EdgeInsets.only(left: 16, right: 16),
                child: Text(content,
                    textAlign: textAlign,
                    overflow: TextOverflow.ellipsis,
                    style: contentStyle ??
                        const TextStyle(
                          fontSize: 14.0,
                          color: Color(0xFFCCCCCC),
                        )),
              ),
            ),
            //这里为了方便用了系统icon 可以设置一张arrow 的图片
            // Image.asset(
            //   '',
            //   width: 16,
            //   height: 16,
            // )
            isShowArrow
                ? const Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                  )
                : Container(),
          ],
        ),
      ),
    );
  }
}
