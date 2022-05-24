// flutter library for gui
import 'package:flutter/material.dart';

// import of the plugin
import 'package:commandline_or_gui_windows/commandline_or_gui_windows.dart';

// used to write to stdout and stderr
import 'dart:io';

// not part of plugin, added to add commandline input
import 'package:args/args.dart';

/*
  Commandline and dart
    https://dart.dev/tutorials/server/cmdline
  Error codes:
    https://docs.microsoft.com/en-us/windows/win32/debug/system-error-codes--0-499-
 */
void main(List<String> args) async {
  // create flags
  ArgParser parser = ArgParser();
  parser.addOption(
    "two_multiplied_by",
    abbr: "m",
    mandatory: false,
    help: "Pass an int, and see 2 * int",
  );
  parser.addFlag(
    "help",
    abbr: "h",
    negatable: true,
    defaultsTo: false,
    help: "If passed help for flags is displayed",
  );

  // parse results exit if error
  ArgResults results;
  try {
    // parse
    results = parser.parse(args);

    // if help is passed display help
    if (results["help"]) {
      stdout.writeln(parser.usage);
      exit(0);
    }
  } catch (err) {
    stderr.writeln(err.toString());
    exit(1);
  }

  /*
    Runs in commandline mode if one or more args are passed
    trys to multiply by the value passed by two_multiplied_by
    and outputs result to stdout
    on error prints to stderr
    if no args, runs in gui mode
   */
  CommandlineOrGuiWindows.runAppCommandlineOrGUI(
    // if there are 1 or more args passed the app will run in commandline mode
    argsCount: args.length,

    // if false the app won't close at the end of commandline mode
    // this is allows you to work on code without builing after every change
    // set to true if you want the app to close when commandline finishes
    closeOnCompleteCommandlineOptionOnly: false,

    // when in commandline mode run the below function
    commandlineRun: () async {
      // if a value is passed attempt to parse and multiply by 2
      if (results["two_multiplied_by"] != null) {
        try {
          stdout.writeln(int.parse(results["two_multiplied_by"]) * 2);
        } catch (err) {
          stderr.writeln(
              "Unable to multiply, 2 * ${results["two_multiplied_by"]}:\n${err.toString()}");
          CommandlineOrGuiWindows.commandlineExit(
              exitCode: 87); // ERROR_INVALID_PARAMETER
        }
        // write error to stderr and send 1 as error exit code
      } else {
        stdout.writeln("You didn't pass anything to be multiplied by 2");
      }
    },

    // gui to be shown when running in gui mode
    gui: const MaterialApp(
      home: Scaffold(
        body: Center(
          child: Text("Hello World"),
        ),
      ),
    ),
  );
}
