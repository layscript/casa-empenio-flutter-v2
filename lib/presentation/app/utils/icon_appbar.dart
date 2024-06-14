import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

IconData getIcon(int id) {
  switch (id) {
    case 1:
      return FontAwesomeIcons.accusoft;

    case 2:
      return FontAwesomeIcons.doorClosed;

    case 3:
      return FontAwesomeIcons.paperPlane;

    case 4:
      return FontAwesomeIcons.fileArrowDown;

    case 5:
      return FontAwesomeIcons.message;

    case 6:
      return FontAwesomeIcons.cartArrowDown;

    case 7:
      return FontAwesomeIcons.hand;

    case 8:
      return FontAwesomeIcons.piggyBank;

    case 9:
      return FontAwesomeIcons.screwdriverWrench;

    case 10:
      return FontAwesomeIcons.ccDinersClub;

    case 11:
      return FontAwesomeIcons.clockRotateLeft;

    case 12:
      return FontAwesomeIcons.boxOpen;

    case 13:
      return FontAwesomeIcons.expeditedssl;

    case 14:
      return FontAwesomeIcons.paypal;

    case 15:
      return FontAwesomeIcons.shop;

    case 16:
      return FontAwesomeIcons.userGroup;

    case 17:
      return FontAwesomeIcons.users;

    case 18:
      return FontAwesomeIcons.store;

    case 19:
      return FontAwesomeIcons.home;

    default:
      return FontAwesomeIcons.home;
  }
}
