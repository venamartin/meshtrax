#include "flutter_window.h"

#include <optional>

#include "flutter/generated_plugin_registrant.h"

namespace {

constexpr wchar_t kSettingsKey[] = L"Software\\MeshTrax";
constexpr wchar_t kPlacementValue[] = L"WindowPlacement";

void SaveWindowPlacement(HWND hwnd) {
  WINDOWPLACEMENT placement = {sizeof(placement)};
  if (!GetWindowPlacement(hwnd, &placement)) {
    return;
  }
  RegSetKeyValueW(HKEY_CURRENT_USER, kSettingsKey, kPlacementValue, REG_BINARY,
                  &placement, sizeof(placement));
}

// Applies the saved size and position without showing the window. Returns
// whether it should be shown maximized. Windows moves a placement that is
// entirely off-screen (e.g. a disconnected monitor) back onto a visible one.
bool RestoreWindowPlacement(HWND hwnd) {
  WINDOWPLACEMENT placement = {};
  DWORD size = sizeof(placement);
  if (RegGetValueW(HKEY_CURRENT_USER, kSettingsKey, kPlacementValue,
                   RRF_RT_REG_BINARY, nullptr, &placement,
                   &size) != ERROR_SUCCESS ||
      size != sizeof(placement) || placement.length != sizeof(placement)) {
    return false;
  }
  const bool maximized =
      placement.showCmd == SW_SHOWMAXIMIZED ||
      (placement.showCmd == SW_SHOWMINIMIZED &&
       (placement.flags & WPF_RESTORETOMAXIMIZED));
  placement.showCmd = SW_HIDE;
  placement.flags = 0;
  SetWindowPlacement(hwnd, &placement);
  return maximized;
}

}  // namespace

FlutterWindow::FlutterWindow(const flutter::DartProject& project)
    : project_(project) {}

FlutterWindow::~FlutterWindow() {}

bool FlutterWindow::OnCreate() {
  if (!Win32Window::OnCreate()) {
    return false;
  }

  const bool maximized = RestoreWindowPlacement(GetHandle());

  RECT frame = GetClientArea();

  // The size here must match the window dimensions to avoid unnecessary surface
  // creation / destruction in the startup path.
  flutter_controller_ = std::make_unique<flutter::FlutterViewController>(
      frame.right - frame.left, frame.bottom - frame.top, project_);
  // Ensure that basic setup of the controller was successful.
  if (!flutter_controller_->engine() || !flutter_controller_->view()) {
    return false;
  }
  RegisterPlugins(flutter_controller_->engine());
  SetChildContent(flutter_controller_->view()->GetNativeWindow());

  flutter_controller_->engine()->SetNextFrameCallback([this, maximized]() {
    if (maximized) {
      ShowWindow(GetHandle(), SW_SHOWMAXIMIZED);
    } else {
      this->Show();
    }
  });

  // Flutter can complete the first frame before the "show window" callback is
  // registered. The following call ensures a frame is pending to ensure the
  // window is shown. It is a no-op if the first frame hasn't completed yet.
  flutter_controller_->ForceRedraw();

  return true;
}

void FlutterWindow::OnDestroy() {
  if (flutter_controller_) {
    flutter_controller_ = nullptr;
  }

  Win32Window::OnDestroy();
}

LRESULT
FlutterWindow::MessageHandler(HWND hwnd, UINT const message,
                              WPARAM const wparam,
                              LPARAM const lparam) noexcept {
  if (message == WM_CLOSE) {
    SaveWindowPlacement(hwnd);
  }

  // Give Flutter, including plugins, an opportunity to handle window messages.
  if (flutter_controller_) {
    std::optional<LRESULT> result =
        flutter_controller_->HandleTopLevelWindowProc(hwnd, message, wparam,
                                                      lparam);
    if (result) {
      return *result;
    }
  }

  switch (message) {
    case WM_FONTCHANGE:
      flutter_controller_->engine()->ReloadSystemFonts();
      break;
  }

  return Win32Window::MessageHandler(hwnd, message, wparam, lparam);
}
