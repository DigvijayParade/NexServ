class AppLocalizations {
  static String tr(String locale, String en, String hi, String mr) {
    if (locale == 'Hindi') return hi;
    if (locale == 'Marathi') return mr;
    return en;
  }
}
