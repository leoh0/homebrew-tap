require 'formula'

class Fltk < Formula
  homepage 'http://www.fltk.org/'
  url 'http://fossies.org/linux/misc/fltk-1.3.2-source.tar.gz'
  sha1 '25071d6bb81cc136a449825bfd574094b48f07fb'
  revision 1

  option :universal

  depends_on 'libpng'
  depends_on 'jpeg'

  fails_with :clang do
    build 318
    cause "http://llvm.org/bugs/show_bug.cgi?id=10338"
  end

  # First patch is to fix issue with -lpng not found.
  # Based on: https://trac.macports.org/browser/trunk/dports/aqua/fltk/files/patch-src-Makefile.diff
  #
  # Second patch is to fix compile issue with clang 3.4.
  # Based on: http://www.fltk.org/strfiles/3046/fltk-clang3.4-1.patch
  patch :DATA

  def install
    ENV.universal_binary if build.universal?
    system "./configure", "--prefix=#{prefix}",
                          "--enable-threads",
                          "--enable-shared"
    system "make install"
  end
end

__END__
diff --git a/src/Makefile b/src/Makefile
index fcad5f0..5a5a850 100644
--- a/src/Makefile
+++ b/src/Makefile
@@ -355,7 +355,7 @@ libfltk_images.1.3.dylib: $(IMGOBJECTS) libfltk.1.3.dylib
 		-install_name $(libdir)/$@ \
 		-current_version 1.3.1 \
 		-compatibility_version 1.3.0 \
-		$(IMGOBJECTS)  -L. $(LDLIBS) $(IMAGELIBS) -lfltk
+		$(IMGOBJECTS)  -L. $(LDLIBS) $(IMAGELIBS) -lfltk $(LDFLAGS)
 	$(RM) libfltk_images.dylib
 	$(LN) libfltk_images.1.3.dylib libfltk_images.dylib
 
diff --git a/fluid/Fl_Type.h b/fluid/Fl_Type.h
index fdbe320..bd7e741 100644
--- a/fluid/Fl_Type.h
+++ b/fluid/Fl_Type.h
@@ -36,7 +36,7 @@ void set_modflag(int mf);
 class Fl_Type {

   friend class Widget_Browser;
-  friend Fl_Widget *make_type_browser(int,int,int,int,const char *l=0);
+  friend Fl_Widget *make_type_browser(int,int,int,int,const char *);
   friend class Fl_Window_Type;
   virtual void setlabel(const char *); // virtual part of label(char*)

diff --git a/src/Fl_cocoa.mm b/src/Fl_cocoa.mm
index a361f29..ed5926d 100644
--- a/src/Fl_cocoa.mm
+++ b/src/Fl_cocoa.mm
@@ -364,7 +364,7 @@ void* DataReady::DataReadyThread(void *o)
                                            timestamp:0
                                         windowNumber:0 context:NULL 
 					     subtype:FLTKDataReadyEvent data1:0 data2:0];
-        [NSApp postEvent:event atStart:NO];
+        [[NSApplication sharedApplication] postEvent:event atStart:NO];
 	[localPool release];
         return(NULL);		// done with thread
       }
@@ -471,7 +471,7 @@ static void breakMacEventLoop()
                                      timestamp:0
                                   windowNumber:0 context:NULL 
 				       subtype:FLTKTimerEvent data1:0 data2:0];
-  [NSApp postEvent:event atStart:NO];
+  [[NSApplication sharedApplication] postEvent:event atStart:NO];
   fl_unlock_function();
 }
 
@@ -707,7 +707,7 @@ static double do_queued_events( double time = 0.0 )
   }
   
   fl_unlock_function();
-  NSEvent *event = [NSApp nextEventMatchingMask:NSAnyEventMask 
+  NSEvent *event = [[NSApplication sharedApplication] nextEventMatchingMask:NSAnyEventMask 
                                       untilDate:[NSDate dateWithTimeIntervalSinceNow:time] 
                                          inMode:NSDefaultRunLoopMode dequeue:YES];  
   if (event != nil) {
@@ -901,11 +901,11 @@ static void cocoaMouseHandler(NSEvent *theEvent)
 @implementation FLTextView
 - (void)insertText:(id)aString
 {
-  [[[NSApp keyWindow] contentView] insertText:aString];
+  [[[[NSApplication sharedApplication] keyWindow] contentView] insertText:aString];
 }
 - (void)doCommandBySelector:(SEL)aSelector
 {
-  [[[NSApp keyWindow] contentView] doCommandBySelector:aSelector];
+  [[[[NSApplication sharedApplication] keyWindow] contentView] doCommandBySelector:aSelector];
 }
 @end
 
@@ -1170,7 +1170,7 @@ void fl_open_callback(void (*cb)(const char *)) {
   Fl::call_screen_init();
   // FLTK windows have already been notified they were moved,
   // but they had the old main_screen_height, so they must be notified again.
-  NSArray *windows = [NSApp windows];
+  NSArray *windows = [[NSApplication sharedApplication] windows];
   int count = [windows count];
   for (int i = 0; i < count; i++) {
     NSWindow *win = [windows objectAtIndex:i];
@@ -1270,7 +1270,7 @@ void fl_open_callback(void (*cb)(const char *)) {
 {
   // without this, the opening of the 1st window is delayed by several seconds
   // under Mac OS 10.8 when a file is dragged on the application icon
-  if (fl_mac_os_version >= 100800 && seen_open_file) [[NSApp mainWindow] orderFront:self];
+  if (fl_mac_os_version >= 100800 && seen_open_file) [[[NSApplication sharedApplication] mainWindow] orderFront:self];
 }
 @end
 
@@ -1301,10 +1301,10 @@ void fl_open_callback(void (*cb)(const char *)) {
     // command.  This one makes all modifiers consistent by always sending key ups.
     // FLView treats performKeyEquivalent to keyDown, but performKeyEquivalent is
     // still needed for the system menu.
-    [[NSApp keyWindow] sendEvent:theEvent];
+    [[[NSApplication sharedApplication] keyWindow] sendEvent:theEvent];
     return;
     }
-  [NSApp sendEvent:theEvent]; 
+  [[NSApplication sharedApplication] sendEvent:theEvent]; 
 }
 @end
 
@@ -1318,16 +1318,16 @@ void fl_open_display() {
   if ( !beenHereDoneThat ) {
     beenHereDoneThat = 1;
     
-    BOOL need_new_nsapp = (NSApp == nil);
+    BOOL need_new_nsapp = ([NSApplication sharedApplication] == nil);
     if (need_new_nsapp) [NSApplication sharedApplication];
     NSAutoreleasePool *localPool;
     localPool = [[NSAutoreleasePool alloc] init]; // never released
-    [NSApp setDelegate:[[FLDelegate alloc] init]];
-    if (need_new_nsapp) [NSApp finishLaunching];
+    [[NSApplication sharedApplication] setDelegate:[[FLDelegate alloc] init]];
+    if (need_new_nsapp) [[NSApplication sharedApplication] finishLaunching];
 
     // empty the event queue but keep system events for drag&drop of files at launch
     NSEvent *ign_event;
-    do ign_event = [NSApp nextEventMatchingMask:(NSAnyEventMask & ~NSSystemDefinedMask)
+    do ign_event = [[NSApplication sharedApplication] nextEventMatchingMask:(NSAnyEventMask & ~NSSystemDefinedMask)
 					untilDate:[NSDate dateWithTimeIntervalSinceNow:0] 
 					   inMode:NSDefaultRunLoopMode 
 					  dequeue:YES];
@@ -1367,10 +1367,10 @@ void fl_open_display() {
         }
       }
     }
-    if (![NSApp servicesMenu]) createAppleMenu();
-    fl_system_menu = [NSApp mainMenu];
+    if (![[NSApplication sharedApplication] servicesMenu]) createAppleMenu();
+    fl_system_menu = [[NSApplication sharedApplication] mainMenu];
     main_screen_height = [[[NSScreen screens] objectAtIndex:0] frame].size.height;
-    [[NSNotificationCenter defaultCenter] addObserver:[NSApp delegate] 
+    [[NSNotificationCenter defaultCenter] addObserver:[[NSApplication sharedApplication] delegate] 
 					     selector:@selector(anyWindowWillClose:) 
 						 name:NSWindowWillCloseNotification 
 					       object:nil];
@@ -1394,7 +1394,7 @@ static void get_window_frame_sizes(int &bx, int &by, int &bt) {
   static int top, left, bottom;
   if (first) {
     first = false;
-    if (NSApp == nil) fl_open_display();
+    if ([NSApplication sharedApplication] == nil) fl_open_display();
     NSRect inside = { {20,20}, {100,100} };
     NSRect outside = [NSWindow  frameRectForContentRect:inside styleMask:NSTitledWindowMask];
     left = int(outside.origin.x - inside.origin.x);
@@ -2231,7 +2231,7 @@ void Fl_X::make(Fl_Window* w)
     w->set_visible();
     if ( w->border() || (!w->modal() && !w->tooltip_window()) ) Fl::handle(FL_FOCUS, w);
     Fl::first_window(w);
-    [cw setDelegate:[NSApp delegate]];
+    [cw setDelegate:(FLDelegate*)[[NSApplication sharedApplication] delegate]];
     if (fl_show_iconic) { 
       fl_show_iconic = 0;
       [cw miniaturize:nil];
@@ -2875,7 +2875,7 @@ void Fl_X::set_cursor(Fl_Cursor c)
 		initWithString:[NSString stringWithFormat:@" GUI with FLTK %d.%d", 
 		FL_MAJOR_VERSION, FL_MINOR_VERSION ]] autorelease], @"Credits",
                 	     nil];
-    [NSApp orderFrontStandardAboutPanelWithOptions:options];
+    [[NSApplication sharedApplication] orderFrontStandardAboutPanelWithOptions:options];
 }
 //#include <FL/Fl_PostScript.H>
 - (void)printPanel
@@ -2980,12 +2980,12 @@ static void createAppleMenu(void)
   mainmenu = [[NSMenu alloc] initWithTitle:@""];
   [mainmenu addItem:menuItem];
   if (fl_mac_os_version < 100600) {
-    //	[NSApp setAppleMenu:appleMenu];
+    //	[[NSApplication sharedApplication] setAppleMenu:appleMenu];
     //	to avoid compiler warning raised by use of undocumented setAppleMenu	:
-    [NSApp performSelector:@selector(setAppleMenu:) withObject:appleMenu];
+    [[NSApplication sharedApplication] performSelector:@selector(setAppleMenu:) withObject:appleMenu];
   }
-  [NSApp setServicesMenu:services];
-  [NSApp setMainMenu:mainmenu];
+  [[NSApplication sharedApplication] setServicesMenu:services];
+  [[NSApplication sharedApplication] setMainMenu:mainmenu];
   [services release];
   [mainmenu release];
   [appleMenu release];
@@ -3053,7 +3053,7 @@ void fl_mac_set_about( Fl_Callback *cb, void *user_data, int shortcut)
   aboutItem.callback(cb);
   aboutItem.user_data(user_data);
   aboutItem.shortcut(shortcut);
-  NSMenu *appleMenu = [[[NSApp mainMenu] itemAtIndex:0] submenu];
+  NSMenu *appleMenu = [[[[NSApplication sharedApplication] mainMenu] itemAtIndex:0] submenu];
   CFStringRef cfname = CFStringCreateCopy(NULL, (CFStringRef)[[appleMenu itemAtIndex:0] title]);
   [appleMenu removeItemAtIndex:0];
   FLMenuItem *item = [[[FLMenuItem alloc] initWithTitle:(NSString*)cfname 
@@ -3290,7 +3290,7 @@ int Fl::dnd(void)
     while(win->window()) win = win->window();
   }
   NSView *myview = [Fl_X::i(win)->xid contentView];
-  NSEvent *theEvent = [NSApp currentEvent];
+  NSEvent *theEvent = [[NSApplication sharedApplication] currentEvent];
   
   int width, height;
   NSImage *image;
