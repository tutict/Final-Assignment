import 'package:flutter/material.dart';

part 'api_path.dart';
part 'assets_path.dart';

const double kBorderRadius = 8.0;
const double kSpacing = 16.0;
const Duration kAnimationDuration = Duration(milliseconds: 300);

const List<Color> kFontColorPallets = [
  Color.fromRGBO(255, 255, 255, 1),
  Color.fromRGBO(230, 230, 230, 1),
  Color.fromRGBO(170, 170, 170, 1),
  Color.fromRGBO(100, 100, 100, 1),
];

const Color kNotifColor = Color.fromRGBO(74, 177, 120, 1);

const List<BoxShadow> kBoxShadows = [
  BoxShadow(
    color: Colors.black12,
    offset: Offset(0, 4),
    blurRadius: 8,
  ),
];

const TextStyle kTitleTextStyle = TextStyle(
  fontSize: 24,
  fontWeight: FontWeight.bold,
  color: Colors.black87,
);

const TextStyle kBodyTextStyle = TextStyle(
  fontSize: 16,
  color: Colors.black54,
);

final ButtonStyle kButtonStyle = ElevatedButton.styleFrom(
  backgroundColor: kNotifColor,
  padding:
      const EdgeInsets.symmetric(horizontal: kSpacing * 2, vertical: kSpacing),
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(kBorderRadius),
  ),
);

const InputDecoration kInputDecoration = InputDecoration(
  border: OutlineInputBorder(
    borderRadius: BorderRadius.all(Radius.circular(kBorderRadius)),
  ),
  contentPadding:
      EdgeInsets.symmetric(horizontal: kSpacing, vertical: kSpacing / 2),
  hintStyle: TextStyle(color: Colors.grey),
);
