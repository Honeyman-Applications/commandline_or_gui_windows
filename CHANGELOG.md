# CHANGELOG

## 2.2.0

- loads GUI only for non-windows platforms
- added strut for web compiling
- switched from branching to tagging for versioning
- updated example android files
- changed from plugin to package
    - because it will compile on any platform
    - command line is only available on windows

## 2.1.2

- fixed win_32 error
    - ```[ERROR:flutter/shell/platform/windows/direct_manipulation.cc(137)] CoCreateInstance(CLSID_DirectManipulationManager, nullptr, CLSCTX_INPROC_SERVER, IID_IDirectManipulationManager, &manager_) failed flutter: [test1, test2]```
- Changed ```WS_MINIMIZE``` to ```WS_OVERLAPPEDWINDOW | WS_VISIBLE```
    - [huycozy description](https://github.com/flutter/flutter/issues/110948#issuecomment-1237606789)
- locked focus to console when using commandline mode
    - [LockSetForegroundWindow](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-locksetforegroundwindow)
- when gui opens in commandline mode 1 pixel width in top left corner
- ref [Development Cycle: Using args with "flutter run"
  #1](https://github.com/Honeyman-Applications/commandline_or_gui_windows/issues/1#issuecomment-1397461338)
- **requires rerun ```flutter pub run commandline_or_gui_windows:create``` on
  update**

## 2.1.1

- added documentation for running commandline mode using [flutter
  run](https://docs.flutter.dev/reference/flutter-cli)
    - ref [Development Cycle: Using args with "flutter run"
      #1](https://github.com/Honeyman-Applications/commandline_or_gui_windows/issues/1#issue-1548136445)

## 2.0.1

- remove ```<T>``` from ```runAppCommandlineOrGUI```
    - not used anywhere
    - was part of an unimplemented feature
    - increased documentation
- Increased documentation
- fixed minor errors in ```README.md```
- added restore command in bin
- minor bug fixes
- tracking more files updated, and ```.gitignore```

## 2.0.0

- determined that dart ```stdio``` and ```stderr``` can be easily accessed
  through ```dart.io```
- made a commandline tool, because the functionality is more about
  editing ```windows/runner```
  files
    - Added
        - ```bin\\create.dart```
        - ```builder.dart```
- removed:
    - ```syncStdOutAndStdErrWithConsole```
    - ```stdout```
        - use ```dart.io```
            - ```stdout.writeln```
    - ```stderr```
        - use ```dart.io```
            - ```stderr.writeln```
    - ```hideWindow```
    - ```commandlineExit```
- ```runAppCommandlineOrGUI```
    - removed:
        - ```placeHolderAfterLoadedRunning```
        - ```afterLoaded```
        - ```commandline```
    - added:
        - ```commandlineRun```
        - ```args```
- updated documentation

## 1.2.1

- updated the license to MIT to allow better freedom of use of the code

## 1.2.0

- added a commandline exit function
    - only closes if ```closeOnCompleteCommandlineOptionOnly``` is ```true```
    - this way you can keep an app open when debugging
- added CommandlineOrGuiWindows: to all error messages
    - to help identify where the error came from
- added ability to set exit code when app exits commandline mode
- removed unused code from example
- depricated ```syncStdOutAndStdErrWithConsole```
    - it should not have been added, oops :(
- updated readme

## 1.1.1

- fixed example main.cpp
    - args in main were being converted to utf-8
    - ASCII strings now used
- made main.dart ignore parsing errors
    - bool true/false showing errors in gui

## 1.1.0

- Added stderr output to example
    - Added example of how to show stderr to readme
- Wrote required steps to have the app run as a gui or commandline app
    - modifications must be made to C++ code for apps that use this package
    - Following steps allows output to stdout to be displayed in android studio
      run terminal
- Increased documentation

## 1.0.0

- Removed from dart and C++ code:
  -```terminalAsOut```, ```terminalAsStdout```, and ```terminalAsStderr```
- Began tracking more C++ code
- Updated documentation

## 0.1.0

- Added the ability to hide the main window
- Change ```<br/>``` to ```<br>``` in README.md
- Window is now hidden in the example
    - documetion coming in 1.0.0
- no longer require allocation of terminal to write to stdout or stderr
    - this causes issues
    - functions left, but shouldn't be use
- Depricated ```terminalAsOut```, ```terminalAsStdout```,
  and ```terminalAsStderr```

## 0.0.2

- updated yaml to include git repo

## 0.0.1

- Basic functions
    - stdout and stderr to terminal
    - run app in either gui or commandline mode
