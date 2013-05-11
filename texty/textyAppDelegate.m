#import "textyAppDelegate.h"

@implementation textyAppDelegate


- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	[Preferences initialValues];
	[NSApplication.sharedApplication setDelegate:self];
	NSLog(@"%@", [NSApp delegate]);
	[NSNotificationCenter.defaultCenter postNotification:[NSNotification notificationWithName:@"AppDelegateSet" object:self]];
	[NSNotificationCenter.defaultCenter addObserverForName:@"ParsingDidFinishForTextView" object:nil queue:NSOperationQueue.mainQueue usingBlock:^(NSNotification *note) {
		[_working stopAnimation:self];
	}];
	[NSApplication.sharedApplication setPresentationOptions:NSFullScreenWindowMask];
	[_window setCollectionBehavior: NSWindowCollectionBehaviorFullScreenPrimary];
	[_window becomeFirstResponder];
	[_window setContentView:self.tab.tabView];
	[_window.contentView addSubview:_working];
	NSRect r = _working.frame;
	NSRect cR = [_window.contentView frame];
	[_working setFrame:(NSRect){cR.size.width-r.size.width,0,r.size.width, r.size.height}]; 
	_window.delegate = self;
}
- (void) application:(NSApplication *)sender openFiles:(NSArray *)filenames {
	for (NSString *file in filenames) {
		NSURL *fileURL = [NSURL fileURLWithPath:file];
		[self.tab open:fileURL];
	}
}
- (BOOL)application:(NSApplication *)theApplication openFile:(NSString *)filename {
	NSURL *fileURL = [NSURL fileURLWithPath:filename];
	[self.tab open:fileURL];
	return TRUE;
}
- (BOOL) applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender {
	return YES;
}
- (NSApplicationTerminateReply) applicationShouldTerminate:(NSApplication *)sender {
	return [self.tab gonna_terminate];
}
- (void)windowDidResignMain:(NSNotification *)notification {

	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DefaultAlwaysOnTop"] == YES) {
		[self.window setLevel:NSFloatingWindowLevel];
	} else {
		[self.window setLevel:NSNormalWindowLevel];
	}
}
- (void)windowDidBecomeMain:(NSNotification *)notification {
  [self.window setLevel:NSNormalWindowLevel];
}
@end
