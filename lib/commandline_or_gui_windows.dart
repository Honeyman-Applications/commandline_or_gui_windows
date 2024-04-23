/*
  Bradley Honeyman
  April 22, 2024

  This file is used to export windows or web based on platform
  mobile uses windows, but errors are thrown when the functions are called

 */

export 'strut.dart' if (dart.library.html) './web.dart' if (dart.library.io) './windows.dart';
