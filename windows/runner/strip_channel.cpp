#include "strip_channel.h"

#include <flutter/encodable_value.h>
#include <flutter/method_channel.h>
#include <flutter/standard_method_codec.h>
#include <windows.h>
#include <winrt/Windows.Data.Json.h>
#include <winrt/Windows.Foundation.Collections.h>
#include <winrt/base.h>

#include <algorithm>
#include <cstring>
#include <memory>
#include <string>
#include <vector>

namespace {

constexpr wchar_t kClassName[] = L"TntStripWindow";
constexpr int kWidth = 520;
constexpr int kHeight = 112;

// Dart 侧画好的位图（RGBA），原生只负责贴上去
std::vector<uint8_t> g_bgra;
int g_image_width = 0;
int g_image_height = 0;

struct StripSegment {
  std::wstring title;
  std::wstring lane;
  int start = 0;
  int duration = 0;
  COLORREF color = RGB(90, 140, 255);
  bool top = false;
};

struct StripData {
  std::wstring day;
  int now = 0;
  std::vector<StripSegment> segments;
};

StripData g_data;
HWND g_window = nullptr;

std::wstring Utf8ToWide(const std::string& text) {
  if (text.empty()) return L"";
  const int size = ::MultiByteToWideChar(CP_UTF8, 0, text.data(),
                                         static_cast<int>(text.size()), nullptr, 0);
  if (size <= 0) return L"";
  std::wstring wide(size, L'\0');
  ::MultiByteToWideChar(CP_UTF8, 0, text.data(), static_cast<int>(text.size()),
                        wide.data(), size);
  return wide;
}

COLORREF ColorFromArgb(int argb) {
  const int r = (argb >> 16) & 0xFF;
  const int g = (argb >> 8) & 0xFF;
  const int b = argb & 0xFF;
  return RGB(r, g, b);
}

StripData ParsePayload(const std::string& json) {
  StripData data;
  try {
    using winrt::Windows::Data::Json::JsonObject;
    using winrt::Windows::Data::Json::JsonValue;
    const auto root = JsonValue::Parse(Utf8ToWide(json));
    const auto object = root.GetObject();
    data.day = object.GetNamedString(L"day", L"");
    data.now = static_cast<int>(object.GetNamedNumber(L"now", 0));
    const auto segments = object.GetNamedArray(L"segments", nullptr);
    if (segments != nullptr) {
      const uint32_t count = segments.Size();
      for (uint32_t i = 0; i < count; ++i) {
        const auto item = segments.GetObjectAt(i);
        StripSegment segment;
        segment.title = item.GetNamedString(L"title", L"");
        segment.lane = item.GetNamedString(L"lane", L"");
        segment.start = static_cast<int>(item.GetNamedNumber(L"start", 0));
        segment.duration =
            static_cast<int>(item.GetNamedNumber(L"duration", 0));
        segment.color = ColorFromArgb(
            static_cast<int>(item.GetNamedNumber(L"color", 0xFF5B9DFF)));
        segment.top = item.GetNamedBoolean(L"top", false);
        data.segments.push_back(segment);
      }
    }
  } catch (...) {
    // 解析失败就当空数据，不要因为一条坏 JSON 把悬浮窗搞崩
  }
  std::sort(data.segments.begin(), data.segments.end(),
            [](const StripSegment& a, const StripSegment& b) {
              return a.start < b.start;
            });
  return data;
}

void PaintStrip(HWND hwnd) {
  PAINTSTRUCT ps;
  HDC hdc = ::BeginPaint(hwnd, &ps);
  RECT client;
  ::GetClientRect(hwnd, &client);
  const int width = client.right - client.left;
  const int height = client.bottom - client.top;

  const HBRUSH background = ::CreateSolidBrush(RGB(21, 24, 33));
  ::FillRect(hdc, &client, background);
  ::DeleteObject(background);

  if (!g_bgra.empty() && g_image_width > 0 && g_image_height > 0) {
    BITMAPINFO info{};
    info.bmiHeader.biSize = sizeof(BITMAPINFOHEADER);
    info.bmiHeader.biWidth = g_image_width;
    info.bmiHeader.biHeight = -g_image_height;  // 自上而下
    info.bmiHeader.biPlanes = 1;
    info.bmiHeader.biBitCount = 32;
    info.bmiHeader.biCompression = BI_RGB;

    void* bits = nullptr;
    const HDC memory = ::CreateCompatibleDC(hdc);
    const HBITMAP bitmap = ::CreateDIBSection(memory, &info, DIB_RGB_COLORS,
                                              &bits, nullptr, 0);
    if (bitmap != nullptr && bits != nullptr) {
      ::memcpy(bits, g_bgra.data(), g_bgra.size());
      const HGDIOBJ previous = ::SelectObject(memory, bitmap);
      ::SetStretchBltMode(hdc, HALFTONE);
      ::StretchBlt(hdc, 0, 0, width, height, memory, 0, 0, g_image_width,
                   g_image_height, SRCCOPY);
      ::SelectObject(memory, previous);
    }
    if (bitmap != nullptr) ::DeleteObject(bitmap);
    ::DeleteDC(memory);
    ::EndPaint(hwnd, &ps);
    return;
  }

  ::EndPaint(hwnd, &ps);
}

LRESULT CALLBACK StripProc(HWND hwnd, UINT message, WPARAM wparam,
                           LPARAM lparam) {
  switch (message) {
    case WM_PAINT:
      PaintStrip(hwnd);
      return 0;
    case WM_ERASEBKGND:
      return 1;
    case WM_LBUTTONDOWN:
      // 按住就能拖走，像个小挂件
      ::ReleaseCapture();
      ::SendMessageW(hwnd, WM_NCLBUTTONDOWN, HTCAPTION, 0);
      return 0;
    case WM_RBUTTONUP:
      ::ShowWindow(hwnd, SW_HIDE);
      return 0;
    default:
      break;
  }
  return ::DefWindowProcW(hwnd, message, wparam, lparam);
}

void EnsureWindow() {
  if (g_window != nullptr) return;

  WNDCLASSEXW wc{};
  wc.cbSize = sizeof(WNDCLASSEXW);
  wc.lpfnWndProc = StripProc;
  wc.hInstance = ::GetModuleHandleW(nullptr);
  wc.hCursor = ::LoadCursorW(nullptr, IDC_SIZEALL);
  wc.lpszClassName = kClassName;
  ::RegisterClassExW(&wc);

  const int screenWidth = ::GetSystemMetrics(SM_CXSCREEN);
  const int screenHeight = ::GetSystemMetrics(SM_CYSCREEN);
  const int x = screenWidth - kWidth - 24;
  const int y = screenHeight - kHeight - 72;

  g_window = ::CreateWindowExW(
      WS_EX_TOPMOST | WS_EX_TOOLWINDOW | WS_EX_NOACTIVATE, kClassName, L"TNT",
      WS_POPUP, x, y, kWidth, kHeight, nullptr, nullptr,
      ::GetModuleHandleW(nullptr), nullptr);
}

}  // namespace

void RegisterStripChannel(flutter::FlutterEngine* engine) {
  static std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>>
      channel;

  channel = std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
      engine->messenger(), "tnt/strip",
      &flutter::StandardMethodCodec::GetInstance());

  channel->SetMethodCallHandler(
      [](const flutter::MethodCall<flutter::EncodableValue>& call,
         std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>>
             result) {
        const flutter::EncodableMap* args = nullptr;
        if (call.arguments() != nullptr) {
          args = std::get_if<flutter::EncodableMap>(call.arguments());
        }

        if (call.method_name() == "update") {
          std::string payload;
          if (args != nullptr) {
            const auto it = args->find(flutter::EncodableValue("payload"));
            if (it != args->end()) {
              const auto* text = std::get_if<std::string>(&it->second);
              if (text != nullptr) payload = *text;
            }
          }
          g_data = ParsePayload(payload);

          if (args != nullptr) {
            const auto imageIt = args->find(flutter::EncodableValue("rgba"));
            const auto widthIt = args->find(flutter::EncodableValue("width"));
            const auto heightIt = args->find(flutter::EncodableValue("height"));
            const auto* rgba = imageIt == args->end()
                                   ? nullptr
                                   : std::get_if<std::vector<uint8_t>>(
                                         &imageIt->second);
            const auto* imageWidth = widthIt == args->end()
                                         ? nullptr
                                         : std::get_if<int32_t>(&widthIt->second);
            const auto* imageHeight =
                heightIt == args->end()
                    ? nullptr
                    : std::get_if<int32_t>(&heightIt->second);
            if (rgba != nullptr && imageWidth != nullptr &&
                imageHeight != nullptr && *imageWidth > 0 && *imageHeight > 0 &&
                rgba->size() ==
                    static_cast<size_t>(*imageWidth) *
                        static_cast<size_t>(*imageHeight) * 4) {
              g_image_width = *imageWidth;
              g_image_height = *imageHeight;
              g_bgra.resize(rgba->size());
              for (size_t i = 0; i + 3 < rgba->size(); i += 4) {
                g_bgra[i + 0] = (*rgba)[i + 2];  // B
                g_bgra[i + 1] = (*rgba)[i + 1];  // G
                g_bgra[i + 2] = (*rgba)[i + 0];  // R
                g_bgra[i + 3] = 0xFF;
              }
            }
          }
          EnsureWindow();
          if (g_window != nullptr) {
            ::ShowWindow(g_window, SW_SHOWNOACTIVATE);
            ::SetWindowPos(g_window, HWND_TOPMOST, 0, 0, 0, 0,
                           SWP_NOMOVE | SWP_NOSIZE | SWP_NOACTIVATE);
            ::InvalidateRect(g_window, nullptr, TRUE);
          }
          result->Success(flutter::EncodableValue(true));
          return;
        }

        if (call.method_name() == "stop") {
          if (g_window != nullptr) {
            ::ShowWindow(g_window, SW_HIDE);
            ::DestroyWindow(g_window);
            g_window = nullptr;
          }
          result->Success(flutter::EncodableValue(true));
          return;
        }

        result->NotImplemented();
      });
}
