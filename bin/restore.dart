/*
  Bradley Honeyman
  May 24, 2022

  This is used as an entrypoint in-order to allow the
  tool to modify windows/runner files

 */
import 'package:commandline_or_gui_windows/builder.dart';

void main(List<String> arguments) {
  Builder(arguments: arguments).restore();
}
