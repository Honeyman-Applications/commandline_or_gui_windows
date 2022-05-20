# Changes made to windows/runner files


### All files that are modified will be located in the ```C:\path_to_your_project\windows\runner``` folder
- ```main.cpp```
  - tell linker that this app uses the console subsystem
    - ```#pragma comment(linker, "/subsystem:console")```
  - create logic that hides the gui or console based on passed arguments
    - this required changes to other files listed below
  - change main from ```int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev, _In_ wchar_t *command_line, _In_ int show_command)``` to ```int main(int argc, char *argv[])```
    - remove ```::AttachConsole(ATTACH_PARENT_PROCESS)```, because console provided by OS
  - Example:
```cpp
#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <windows.h>

#include "flutter_window.h"
#include "utils.h"

// ******* ADDED *******
#include "win32_window.h"                     // where flag to hide gui is added
#pragma comment(linker, "/subsystem:console") // tells the linker to use console subsystem

/*
  New main, because the app is now a console app
*/
int main(int argc, char *argv[])
{

  // if any arguments are passed run in commandline mode
  if (argc > 1)
  {
    H_HIDE_WINDOW = true;
  }
  else
  {
    ::ShowWindow(::GetConsoleWindow(), SW_HIDE);
  }

  // Initialize COM, so that it is available for use in the library and/or
  // plugins.
  ::CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);

  flutter::DartProject project(L"data");

  std::vector<std::string> command_line_arguments =
      GetCommandLineArguments();

  project.set_dart_entrypoint_arguments(std::move(command_line_arguments));

  FlutterWindow window(project);
  Win32Window::Point origin(10, 10);
  Win32Window::Size size(1280, 720);
  // change string to show a different title
  if (!window.CreateAndShow(L"commandline_or_gui_windows_example", origin, size))
  {
    return EXIT_FAILURE;
  }
  window.SetQuitOnClose(true);

  ::MSG msg;
  while (::GetMessage(&msg, nullptr, 0, 0))
  {
    ::TranslateMessage(&msg);
    ::DispatchMessage(&msg);
  }

  ::CoUninitialize();
  return EXIT_SUCCESS;
}
```
- ```win32_window.h```
  - Add the flag to hide or show the gui
  - In the example, I only add ```extern bool H_HIDE_WINDOW;``` to the file
  - Example:
```cpp
#ifndef RUNNER_WIN32_WINDOW_H_
#define RUNNER_WIN32_WINDOW_H_

#include <windows.h>

#include <functional>
#include <memory>
#include <string>

// ******* ADDED *******
extern bool H_HIDE_WINDOW;

// see example for full code. The below code is not modified for this plugin to work
```
- ```win32_window.cpp```
  - Add default value of flag to hide gui ```bool H_HIDE_WINDOW = false;```
  - Change ```CreateWindow``` to hide or show gui based on flag
```cpp
#include "win32_window.h"

#include <flutter_windows.h>

#include "resource.h"

// ******* ADDED *******
bool H_HIDE_WINDOW = false;

namespace
{

  constexpr const wchar_t kWindowClassName[] = L"FLUTTER_RUNNER_WIN32_WINDOW";

  // The number of Win32Window objects that currently exist.
  static int g_active_window_count = 0;

  using EnableNonClientDpiScaling = BOOL __stdcall(HWND hwnd);

  // Scale helper to convert logical scaler values to physical using passed in
  // scale factor
  int Scale(int source, double scale_factor)
  {
    return static_cast<int>(source * scale_factor);
  }

  // Dynamically loads the |EnableNonClientDpiScaling| from the User32 module.
  // This API is only needed for PerMonitor V1 awareness mode.
  void EnableFullDpiSupportIfAvailable(HWND hwnd)
  {
    HMODULE user32_module = LoadLibraryA("User32.dll");
    if (!user32_module)
    {
      return;
    }
    auto enable_non_client_dpi_scaling =
        reinterpret_cast<EnableNonClientDpiScaling *>(
            GetProcAddress(user32_module, "EnableNonClientDpiScaling"));
    if (enable_non_client_dpi_scaling != nullptr)
    {
      enable_non_client_dpi_scaling(hwnd);
      FreeLibrary(user32_module);
    }
  }

} // namespace

// Manages the Win32Window's window class registration.
class WindowClassRegistrar
{
public:
  ~WindowClassRegistrar() = default;

  // Returns the singleton registar instance.
  static WindowClassRegistrar *GetInstance()
  {
    if (!instance_)
    {
      instance_ = new WindowClassRegistrar();
    }
    return instance_;
  }

  // Returns the name of the window class, registering the class if it hasn't
  // previously been registered.
  const wchar_t *GetWindowClass();

  // Unregisters the window class. Should only be called if there are no
  // instances of the window.
  void UnregisterWindowClass();

private:
  WindowClassRegistrar() = default;

  static WindowClassRegistrar *instance_;

  bool class_registered_ = false;
};

WindowClassRegistrar *WindowClassRegistrar::instance_ = nullptr;

const wchar_t *WindowClassRegistrar::GetWindowClass()
{
  if (!class_registered_)
  {
    WNDCLASS window_class{};
    window_class.hCursor = LoadCursor(nullptr, IDC_ARROW);
    window_class.lpszClassName = kWindowClassName;
    window_class.style = CS_HREDRAW | CS_VREDRAW;
    window_class.cbClsExtra = 0;
    window_class.cbWndExtra = 0;
    window_class.hInstance = GetModuleHandle(nullptr);
    window_class.hIcon =
        LoadIcon(window_class.hInstance, MAKEINTRESOURCE(IDI_APP_ICON));
    window_class.hbrBackground = 0;
    window_class.lpszMenuName = nullptr;
    window_class.lpfnWndProc = Win32Window::WndProc;
    RegisterClass(&window_class);
    class_registered_ = true;
  }
  return kWindowClassName;
}

void WindowClassRegistrar::UnregisterWindowClass()
{
  UnregisterClass(kWindowClassName, nullptr);
  class_registered_ = false;
}

Win32Window::Win32Window()
{
  ++g_active_window_count;
}

Win32Window::~Win32Window()
{
  --g_active_window_count;
  Destroy();
}

bool Win32Window::CreateAndShow(const std::wstring &title,
                                const Point &origin,
                                const Size &size)
{
  Destroy();

  const wchar_t *window_class =
      WindowClassRegistrar::GetInstance()->GetWindowClass();

  const POINT target_point = {static_cast<LONG>(origin.x),
                              static_cast<LONG>(origin.y)};
  HMONITOR monitor = MonitorFromPoint(target_point, MONITOR_DEFAULTTONEAREST);
  UINT dpi = FlutterDesktopGetDpiForMonitor(monitor);
  double scale_factor = dpi / 96.0;

  /*
  // original
    HWND window = CreateWindow(
        window_class, title.c_str(), WS_OVERLAPPEDWINDOW | WS_VISIBLE,
        Scale(origin.x, scale_factor), Scale(origin.y, scale_factor),
        Scale(size.width, scale_factor), Scale(size.height, scale_factor),
        nullptr, nullptr, GetModuleHandle(nullptr), this);
  */
  // ******* ADDED *******
  HWND window;
  if (H_HIDE_WINDOW)
  {
    window = CreateWindow(
        window_class, title.c_str(), WS_MINIMIZE,
        Scale(origin.x, scale_factor), Scale(origin.y, scale_factor),
        Scale(size.width, scale_factor), Scale(size.height, scale_factor),
        nullptr, nullptr, GetModuleHandle(nullptr), this);

    ShowWindow(window, SW_HIDE);
  }
  else
  {
    window = CreateWindow(
        window_class, title.c_str(), WS_OVERLAPPEDWINDOW | WS_VISIBLE,
        Scale(origin.x, scale_factor), Scale(origin.y, scale_factor),
        Scale(size.width, scale_factor), Scale(size.height, scale_factor),
        nullptr, nullptr, GetModuleHandle(nullptr), this);
  }
  // ******* ADDED *******

  if (!window)
  {
    return false;
  }

  return OnCreate();
}

// static
LRESULT CALLBACK Win32Window::WndProc(HWND const window,
                                      UINT const message,
                                      WPARAM const wparam,
                                      LPARAM const lparam) noexcept
{
  if (message == WM_NCCREATE)
  {
    auto window_struct = reinterpret_cast<CREATESTRUCT *>(lparam);
    SetWindowLongPtr(window, GWLP_USERDATA,
                     reinterpret_cast<LONG_PTR>(window_struct->lpCreateParams));

    auto that = static_cast<Win32Window *>(window_struct->lpCreateParams);
    EnableFullDpiSupportIfAvailable(window);
    that->window_handle_ = window;
  }
  else if (Win32Window *that = GetThisFromHandle(window))
  {
    return that->MessageHandler(window, message, wparam, lparam);
  }

  return DefWindowProc(window, message, wparam, lparam);
}

LRESULT
Win32Window::MessageHandler(HWND hwnd,
                            UINT const message,
                            WPARAM const wparam,
                            LPARAM const lparam) noexcept
{
  switch (message)
  {
  case WM_DESTROY:
    window_handle_ = nullptr;
    Destroy();
    if (quit_on_close_)
    {
      PostQuitMessage(0);
    }
    return 0;

  case WM_DPICHANGED:
  {
    auto newRectSize = reinterpret_cast<RECT *>(lparam);
    LONG newWidth = newRectSize->right - newRectSize->left;
    LONG newHeight = newRectSize->bottom - newRectSize->top;

    SetWindowPos(hwnd, nullptr, newRectSize->left, newRectSize->top, newWidth,
                 newHeight, SWP_NOZORDER | SWP_NOACTIVATE);

    return 0;
  }
  case WM_SIZE:
  {
    RECT rect = GetClientArea();
    if (child_content_ != nullptr)
    {
      // Size and position the child window.
      MoveWindow(child_content_, rect.left, rect.top, rect.right - rect.left,
                 rect.bottom - rect.top, TRUE);
    }
    return 0;
  }

  case WM_ACTIVATE:
    if (child_content_ != nullptr)
    {
      SetFocus(child_content_);
    }
    return 0;
  }

  return DefWindowProc(window_handle_, message, wparam, lparam);
}

void Win32Window::Destroy()
{
  OnDestroy();

  if (window_handle_)
  {
    DestroyWindow(window_handle_);
    window_handle_ = nullptr;
  }
  if (g_active_window_count == 0)
  {
    WindowClassRegistrar::GetInstance()->UnregisterWindowClass();
  }
}

Win32Window *Win32Window::GetThisFromHandle(HWND const window) noexcept
{
  return reinterpret_cast<Win32Window *>(
      GetWindowLongPtr(window, GWLP_USERDATA));
}

void Win32Window::SetChildContent(HWND content)
{
  child_content_ = content;
  SetParent(content, window_handle_);
  RECT frame = GetClientArea();

  MoveWindow(content, frame.left, frame.top, frame.right - frame.left,
             frame.bottom - frame.top, true);

  SetFocus(child_content_);
}

RECT Win32Window::GetClientArea()
{
  RECT frame;
  GetClientRect(window_handle_, &frame);
  return frame;
}

HWND Win32Window::GetHandle()
{
  return window_handle_;
}

void Win32Window::SetQuitOnClose(bool quit_on_close)
{
  quit_on_close_ = quit_on_close;
}

bool Win32Window::OnCreate()
{
  // No-op; provided for subclasses.
  return true;
}

void Win32Window::OnDestroy()
{
  // No-op; provided for subclasses.
}

```