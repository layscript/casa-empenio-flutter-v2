import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

IconData getIcon(int id) {
  switch (id) {
    case 1:
      return FontAwesomeIcons.sackDollar;

    case 2:
      return FontAwesomeIcons.fileSignature;

    case 3:
      return FontAwesomeIcons.chartLine;

    case 4:
      return FontAwesomeIcons.fileArrowDown;

    case 5:
      return FontAwesomeIcons.briefcase;

    case 6:
      return FontAwesomeIcons.cartArrowDown;

    case 7:
      return FontAwesomeIcons.houseLaptop;

    case 8:
      return FontAwesomeIcons.piggyBank;

    case 9:
      return FontAwesomeIcons.tag;

    case 10:
      return FontAwesomeIcons.ccDinersClub;

    case 11:
      return FontAwesomeIcons.clockRotateLeft;

    case 12:
      return FontAwesomeIcons.boxOpen;

    case 13:
      return FontAwesomeIcons.boxesPacking;

    case 14:
      return FontAwesomeIcons.paypal;

    case 15:
      return FontAwesomeIcons.file;

    case 16:
      return FontAwesomeIcons.expeditedssl;

    case 17:
      return FontAwesomeIcons.users;

    case 18:
      return FontAwesomeIcons.sitemap;

    case 19:
      return FontAwesomeIcons.house;

    case 9001:
      return FontAwesomeIcons.folderOpen;

    case 9002:
      return FontAwesomeIcons.userShield;

    case 9003:
      return FontAwesomeIcons.gears;

    case 9004:
      return FontAwesomeIcons.store;

    default:
      return FontAwesomeIcons.house;
  }
}
