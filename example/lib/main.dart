import 'package:flutter/material.dart';
import 'package:commandline_or_gui_windows/commandline_or_gui_windows.dart';

// not part of plugin, added to add commandline input
import 'package:args/args.dart';

void main(List<String> args) async {
  /*
   not part of plugin, added to add commandline input
   ref:
   https://pub.dev/packages/args
   if run from shell:
   .\commandline_or_gui_windows_example.exe -a
   it will run in commandline mode
   if run from shell:
   .\commandline_or_gui_windows_example.exe
   it will run in gui mode
  */
  ArgParser parser = ArgParser();
  parser.addFlag(
    "automation",
    abbr: "a",
  );
  ArgResults results = parser.parse(args);

  // part of plugin, main entry. This runciton runs runApp
  await CommandlineOrGuiWindows.runAppCommandlineOrGUI(
    // if you want to run in gui or commandline mode
    commandline: results["automation"], // parsed option from above

    // code you want to run if in commandline mode
    afterLoaded: () async {
      await CommandlineOrGuiWindows.stdout("Hello World");
    },

    // gui of the app
    gui: const MaterialApp(
      home: Scaffold(
        body: Center(
          child: Text("This is the gui of the app"),
        ),
      ),
    ),
  );
}
