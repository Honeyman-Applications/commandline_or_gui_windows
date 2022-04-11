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
    - Following steps allows output to stdout to be displayed in android studio run terminal
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
- Depricated ```terminalAsOut```, ```terminalAsStdout```, and ```terminalAsStderr```

## 0.0.2

- updated yaml to include git repo

## 0.0.1

- Basic functions
    - stdout and stderr to terminal
    - run app in either gui or commandline mode
