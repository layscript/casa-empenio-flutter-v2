import 'package:casa_empenio_pe/presentation/app/assets/assets.dart';
import 'package:flutter/material.dart';

const _defaultTextStyle = TextStyle(
  letterSpacing: 0.125,
  color: AppColors.black,
//
);
ThemeData buildTheme(BuildContext context) {
  final themeData = Theme.of(context);
  const radio = BorderRadius.all(Radius.circular(14));
  return ThemeData(
    useMaterial3: false,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.blue,
      primary: AppColors.blue,
    ),
    primaryColor: AppColors.blue,
    dividerColor: Colors.transparent,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.blue,
      foregroundColor: AppColors.white,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: AppColors.white,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
    ),
    cardTheme: const CardTheme(
      color: AppColors.white,
      elevation: 2,
      margin: EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: radio),
    ),
    dialogTheme: const DialogTheme(
      backgroundColor: AppColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(22)),
      ),
    ),
    snackBarTheme: const SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: radio),
    ),
    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.blue,
      foregroundColor: AppColors.white,
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.divider,
      space: 1,
      thickness: 1,
    ),
    scaffoldBackgroundColor: const Color(0xFFF4F6FB),
    platform: TargetPlatform.iOS,
    checkboxTheme: CheckboxThemeData(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(4)),
      ),
      fillColor: MaterialStateProperty.resolveWith(
        (states) => states.contains(MaterialState.selected)
            ? AppColors.blue
            : AppColors.secondaryText,
      ),
    ),
    //hintColor: AppColors.secondaryText,

    /* bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.white,
      showUnselectedLabels: true,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: AppColors.orange,
      unselectedItemColor: AppColors.secondaryText,
      elevation: 0,
      selectedIconTheme: IconThemeData(
        size: 24,
      ),
      unselectedIconTheme: IconThemeData(
        size: 24,
      ),
      selectedLabelStyle: TextStyle(
        fontSize: 10,
        color: AppColors.orange,
      ),
      unselectedLabelStyle: TextStyle(
        fontSize: 10,
      ),
    ), */
    /*  switchTheme: SwitchThemeData(
      trackColor: MaterialStateProperty.all(AppColors.primary),
      thumbColor: MaterialStateProperty.all(AppColors.primary),
      overlayColor: MaterialStateProperty.all(AppColors.primary),
    ),
    checkboxTheme: CheckboxThemeData(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(4)),
      ),
      fillColor: MaterialStateProperty.resolveWith(
        (states) => states.contains(MaterialState.selected)
            ? AppColors.primary
            : AppColors.secondaryText,
      ),
    ),
    radioTheme: RadioThemeData(
      fillColor: MaterialStateProperty.resolveWith(
        (states) => states.contains(MaterialState.selected)
            ? AppColors.primary
            : AppColors.secondaryText,
      ),
    ), */
    inputDecorationTheme: const InputDecorationTheme(
      enabledBorder: OutlineInputBorder(
        borderRadius: radio,
        borderSide: BorderSide(color: Color(0xFFCDD6E0)),
      ),
      errorStyle: TextStyle(
        color: AppColors.error,
        fontSize: 9,
        height: 0.8,
      ),
      border: OutlineInputBorder(
        borderRadius: radio,
        borderSide: BorderSide(
          color: AppColors.secondaryText,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: radio,
        borderSide: BorderSide(
          color: AppColors.error,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: radio,
        borderSide: BorderSide(
          color: AppColors.error,
        ),
      ),
      filled: true,
      isDense: true,
      fillColor: AppColors.white,
      labelStyle: TextStyle(
        fontSize: 14,
      ),
      // contentPadding: EdgeInsets.fromLTRB(12, 20, 0, 20),
      contentPadding: EdgeInsets.only(left: 15, top: 18, bottom: 18),
      focusedBorder: OutlineInputBorder(
        borderRadius: radio,
        borderSide: BorderSide(
          color: AppColors.buttonPrimary,
        ),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ButtonStyle(
        elevation: MaterialStateProperty.all(0),
        backgroundColor: MaterialStateProperty.resolveWith<Color>(
          (Set<MaterialState> states) => states.contains(MaterialState.disabled)
              ? AppColors.disabledButton
              : AppColors.blue,
        ),
        //overlayColor: MaterialStateProperty.all(AppColors.primaryHover),
        animationDuration: const Duration(seconds: 500),
        shape: MaterialStateProperty.all(
          const RoundedRectangleBorder(borderRadius: radio),
        ),
        //padding: MaterialStateProperty.all(horizontalViewSpacing),
        fixedSize: MaterialStateProperty.all(const Size.fromHeight(50)),
        minimumSize: MaterialStateProperty.all(const Size.fromHeight(50)),
        foregroundColor: MaterialStateProperty.all(AppColors.white),
        textStyle: MaterialStateProperty.all(
          const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.white,
          ),
        ),
      ),
    ),
    textTheme: themeData.textTheme.copyWith(
      // subtitle1: const TextStyle(
      //   fontSize: 15,
      //   fontWeight: FontWeight.w500,
      //   color: AppColors.black,
      // ),
      // headline1: _defaultTextStyle,
      // headline2: _defaultTextStyle,
      // headline3: _defaultTextStyle,
      // headline4: _defaultTextStyle,
      // headline5: _defaultTextStyle,
      // headline6: _defaultTextStyle,
      // subtitle2: _defaultTextStyle,
      // bodyText1: _defaultTextStyle,
      // bodyText2: _defaultTextStyle,
      // button: _defaultTextStyle,
      // caption: _defaultTextStyle,
      // overline: _defaultTextStyle,
    ),
  );
}
