require 'formula'

class SpatialiteGui17 < Formula
  homepage 'https://www.gaia-gis.it/fossil/spatialite_gui/index'
  url 'http://www.gaia-gis.it/gaia-sins/spatialite-gui-sources/spatialite_gui-1.7.1.tar.gz'
  sha1 '3b9d88e84ffa5a4f913cf74b098532c2cd15398f'

  conflicts_with 'spatialite-gui', :because => 'spatialite-gui in main tap'

  depends_on 'pkg-config' => :build
  depends_on 'libxml2'
  depends_on 'libspatialite'
  depends_on 'libgaiagraphics'
  depends_on 'wxmac-29'
  depends_on 'geos'
  depends_on 'proj'
  depends_on 'freexl'
  depends_on 'sqlite'

  def patches
    patch_set = {
      :p1 => DATA
    }
    patch_set
  end

  def install
    system "./configure", "--prefix=#{prefix}"
    system "make install"
  end
end

__END__

For some strange reason, wxWidgets does not take the required steps to register
programs as GUI apps like other toolkits do. This necessitates the creation of
an app bundle on OS X.

This clever hack sidesteps the headache of packing simple programs into app
bundles:

  http://www.miscdebris.net/blog/2010/03/30/
    solution-for-my-mac-os-x-gui-program-doesnt-get-focus-if-its-outside-an-application-bundle
---
 Main.cpp |   21 +++++++++++++++++++++
 1 files changed, 21 insertions(+), 0 deletions(-)

diff --git a/Main.cpp b/Main.cpp
index a857e8a..9c90afb 100644
--- a/Main.cpp
+++ b/Main.cpp
@@ -71,6 +71,12 @@
 #define unlink	_unlink
 #endif

+#ifdef __WXMAC__
+// Allow the program to run and recieve focus without creating an app bundle.
+#include <Carbon/Carbon.h>
+extern "C" { void CPSEnableForegroundOperation(ProcessSerialNumber* psn); }
+#endif
+
 IMPLEMENT_APP(MyApp)
      bool MyApp::OnInit()
 {
@@ -86,6 +92,21 @@ IMPLEMENT_APP(MyApp)
   frame->Show(true);
   SetTopWindow(frame);
   frame->LoadConfig(path);
+
+#ifdef __WXMAC__
+  // Acquire the necessary resources to run as a GUI app without being inside
+  // an app bundle.
+  //
+  // Credit for this hack goes to:
+  //
+  //   http://www.miscdebris.net/blog/2010/03/30/solution-for-my-mac-os-x-gui-program-doesnt-get-focus-if-its-outside-an-application-bundle
+  ProcessSerialNumber psn;
+
+  GetCurrentProcess( &psn );
+  CPSEnableForegroundOperation( &psn );
+  SetFrontProcess( &psn );
+#endif
+
   return true;
 }

--
1.7.9
