#include <gdk/gdk.h>

#include "my_application.h"

int main(int argc, char** argv) {
  // Flutter 3.50's Wayland renderer can deadlock the window on a resize
  // (flutter/flutter#196529), so the app runs on XWayland where there is
  // one and uses Wayland only without it. GDK_BACKEND=wayland still forces
  // Wayland. Remove once the engine fix has shipped.
  gdk_set_allowed_backends("x11,wayland");
  g_autoptr(MyApplication) app = my_application_new();
  return g_application_run(G_APPLICATION(app), argc, argv);
}
