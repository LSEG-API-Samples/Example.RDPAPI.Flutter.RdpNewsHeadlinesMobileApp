import 'package:flutter/material.dart';

final kHintTextStyle = TextStyle(
  color: Colors.white54,
  fontFamily: 'Arial',
);

final wbLabelStyle = TextStyle(
  color: Colors.white,
  fontWeight: FontWeight.bold,
  fontFamily: 'Arial',
);

final errLabelStyle = TextStyle(
  color: Color(0xFFC9E26C),
  fontSize: 16,
  fontWeight: FontWeight.bold,
  fontFamily: 'Arial',
);

final kBoxDecorationStyle = BoxDecoration(
  color: Color(0xFF6CA8F1),
  borderRadius: BorderRadius.circular(10.0),
  boxShadow: [
    BoxShadow(
      color: Colors.black12,
      blurRadius: 6.0,
      offset: Offset(0, 2),
    ),
  ],
);

final errorBoxDecorationStyle = BoxDecoration(
  color: Colors.transparent,
  borderRadius: BorderRadius.circular(10.0),
);
