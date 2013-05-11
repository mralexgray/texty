#import "m_tabManager.h"
@implementation m_tabManager
@synthesize tabView,goto_window = _goto_window,timer,snipplet;
#define CURRENT(__t) 	TextVC *__t = [self.tabView selectedTabViewItem].identifier;

- (m_tabManager *) init {
	return [self initWithFrame:[[NSApp mainWindow] frame]];
}
- (void) createCodeSnipplets {
	self.snipplet = @	[@[@"c template", @"#include <stdio.h>\n\nint main(int ac, char *av[]) {\n\n\n\treturn 0;\n}" ,@0],
							@[@"objc template", @"#import <Foundation/Foundation.h>\n#import <AtoZ/AtoZ.h>\n\nint main(int argc, char *argv[]) {\n	@autoreleasepool {\n\n		NSLog(@\"Poop\");\t}\treturn 0;\n}",@1]].mutableCopy;	
}

- (m_tabManager *) initWithFrame:(NSRect) frame {
	if (self != super.init ) return nil;
	self.tabView 					= [BGHUDTabView.alloc initWithFrame:frame];
	self.tabView.delegate 		= self;
	self.tabView.font				= FONT;
	self.tabView.controlTint 	= NSClearControlTint;
	self.timer = [NSTimer scheduledTimerWithTimeInterval:1 target:self	selector:@selector(handleTimer:) userInfo:nil	repeats:YES];
	[self createCodeSnipplets];
	colorAttr[VARTYPE_COLOR_IDX	] = @{NSForegroundColorAttributeName: VARTYPE_COLOR};
	colorAttr[VALUE_COLOR_IDX		] = @{NSForegroundColorAttributeName: VALUE_COLOR};
	colorAttr[KEYWORD_COLOR_IDX	] = @{NSForegroundColorAttributeName: KEYWORD_COLOR};
	colorAttr[COMMENT_COLOR_IDX	] = @{NSForegroundColorAttributeName: COMMENT_COLOR};
	colorAttr[STRING1_COLOR_IDX	] = @{NSForegroundColorAttributeName: STRING1_COLOR};
	colorAttr[STRING2_COLOR_IDX	] = @{NSForegroundColorAttributeName: STRING2_COLOR};
	colorAttr[PREPROCESS_COLOR_IDX] = @{NSForegroundColorAttributeName: PREPROCESS_COLOR};
	colorAttr[CONDITION_COLOR_IDX	] = @{NSForegroundColorAttributeName: CONDITION_COLOR};
	colorAttr[TEXT_COLOR_IDX		] = @{NSForegroundColorAttributeName: TEXT_COLOR};
	colorAttr[CONSTANT_COLOR_IDX	] = @{NSForegroundColorAttributeName: CONSTANT_COLOR};
	colorAttr[BRACKET_COLOR_IDX	] = @{NSBackgroundColorAttributeName: VARTYPE_COLOR};
	colorAttr[NOBRACKET_COLOR_IDX	] = @{NSBackgroundColorAttributeName: BG_COLOR};

	if (![self openStoredURLs])	[self open:nil];
	[self performSelector:@selector(setTitle:) withObject:nil afterDelay:1];
	return self;
}
- (void) setTitle:(id) sender {	CURRENT(t);	[NSApp mainWindow].title = t.s.fileURL.lastPathComponent;	}
- (void) tabView:(BGHUDTabView *)tabView didSelectTabViewItem:(BGHUDTabViewItem *)tabViewItem {
	CURRENT(t);	[t.text delayedParse];	[NSApp mainWindow].title = t.s.fileURL.lastPathComponent;
}
#pragma mark restore workspace
- (BOOL) openStoredURLs 	{
	BOOL ret = NO;
	NSArray *d = [NSUserDefaults.standardUserDefaults objectForKey:@"openedTabs"];
	for (NSString *f in d) 	if ([m_Storage fileExists:f])
			if ([self open:[NSURL fileURLWithPath:f]])
				ret = YES;
	NSString *selected = [NSUserDefaults.standardUserDefaults objectForKey:@"selectedTab"];
	__block TextVC *exists = nil;
	if (selected) {
		[self walk_tabs:^(TextVC *t) {
			if ([[t.s.fileURL path] isEqualToString:selected]) {
				exists = t;
			}
		}];
		if (exists) [self.tabView selectTabViewItem:exists.tabItem];
	}
	return ret;
}
- (void) storeOpenedURLs 	{
	NSMutableArray *opened = NSMutableArray.new;
	[self walk_tabs:^(TextVC *t) {
			[opened addObject:[t.s.fileURL path]];
	}];
	CURRENT(t);	
	[NSUserDefaults.standardUserDefaults setObject:opened 				forKey:@"openedTabs"];
	[NSUserDefaults.standardUserDefaults setObject:t.s.fileURL.path 	forKey:@"selectedTab"];
}
#pragma mark tabManagement
- (IBAction) selectTabAtIndex:(id) sender {
	NSInteger index = [sender tag];
	NSInteger max = self.tabView.tabViewItems.count;
	if (index >= 0 && max > 0 && index <= (max - 1)) [self.tabView selectTabViewItemAtIndex:index];
}
- (IBAction) goLeft:		(id) sender			{	[self.tabView selectTabViewItemAtIndex:[self getTabIndex:DIRECTION_LEFT]];	}
- (IBAction) goRight:	(id) sender			{	[self.tabView selectTabViewItemAtIndex:[self getTabIndex:DIRECTION_RIGHT]];	}
- (NSInteger) getTabIndex:(int) direction {

	BGHUDTabViewItem *selected = [self.tabView selectedTabViewItem];
	NSInteger selectedIndex = [self.tabView indexOfTabViewItem:selected];
	NSInteger firstIndex = 0;
	NSInteger lastIndex = [self.tabView numberOfTabViewItems] - 1;
	if (lastIndex == firstIndex)
		return selectedIndex;
	if (direction == DIRECTION_LEFT) {
		if (selectedIndex > 0)
			return selectedIndex - 1;
		return lastIndex;
	} else {
		if (selectedIndex < lastIndex) return selectedIndex + 1;
		return 0;
	}
}
- (void) swapTab:(NSInteger) first With:(NSInteger) second {

	BGHUDTabViewItem *f, *s;
	f = [self.tabView tabViewItemAtIndex:first];
	s = [self.tabView tabViewItemAtIndex:second];
	if ([f isEqual:s])
		return;
	[self.tabView removeTabViewItem:f];
	[self.tabView insertTabViewItem:f atIndex:second];
	[self.tabView selectTabViewItemAtIndex:second];
}
- (IBAction)swapRight:	(id)sender 			{
	NSInteger rightIndex = [self getTabIndex:DIRECTION_RIGHT];
	NSInteger selectedIndex = [self.tabView indexOfTabViewItem:[self.tabView selectedTabViewItem]];
	[self swapTab:selectedIndex With:rightIndex];
}
- (IBAction)swapLeft:	(id)sender 			{
	NSInteger leftIndex = [self getTabIndex:DIRECTION_LEFT];
	NSInteger selectedIndex = [self.tabView indexOfTabViewItem:[self.tabView selectedTabViewItem]];
	[self swapTab:selectedIndex With:leftIndex];
}
#pragma mark Open/Save/Close/Goto
- (IBAction)openButton:	(id)sender 			{
	NSOpenPanel *panel	= [NSOpenPanel openPanel];
	CURRENT(t);	
	[panel setDirectoryURL:[[t.s fileURL] URLByDeletingLastPathComponent]];
	panel.allowsMultipleSelection = YES;
	if ([panel runModal] == NSOKButton) {
		NSArray *files = [panel URLs];;
		for (NSURL *url in files) {
			[self performSelector:@selector(open:) withObject:url afterDelay:0];
		}
	}
}
- (IBAction)saveButton:	(id)sender 			{
	CURRENT(t);
	if (t.s.temporary)	[self saveAsButton:nil];
	else 						[t save];
}
- (IBAction)saveAsButton:(id)sender 		{

	CURRENT(t);	NSSavePanel *spanel = NSSavePanel.savePanel;
	[spanel setPrompt:@"Save"];
	[spanel setShowsToolbarButton:YES];
#if 0
	if (t.s.temporary) {
		TextVC *prev = [self.tabView tabViewItemAtIndex:[self getTabIndex:DIRECTION_LEFT]].identifier;
		[spanel setDirectoryURL:[prev.s.fileURL URLByDeletingLastPathComponent]];
	} else {
		[spanel setDirectoryURL:[t.s.fileURL URLByDeletingLastPathComponent]];
	}
#endif
	[spanel setDirectoryURL:[t.s.fileURL URLByDeletingLastPathComponent]];
	[spanel setRepresentedURL:[t.s.fileURL URLByDeletingLastPathComponent]];
	[spanel setExtensionHidden:NO];
	[spanel setNameFieldStringValue:[t.s basename]];
	[spanel beginSheetModalForWindow:[NSApp mainWindow] completionHandler:^(NSInteger result) {
		if (result == NSFileHandlingPanelOKButton) {
			[t saveAs:[spanel URL]];
		}
	}];
}
- (IBAction)closeButton:(id)sender 			{

	CURRENT(t);
	if ([t.ewc.window isVisible]) {
		[t.ewc.e terminate];
		[t.ewc.window orderOut:nil];
		return;
	}

	if ([t is_modified]) {
		NSInteger alertReturn = [t.s fileAlert:t.s.fileURL withMessage:@"WARNING: unsaved data." def:@"Cancel" alternate:@"Close w/o Save" other:@"Save & Close"];
		if (alertReturn == NSAlertOtherReturn) { 			/* Save */
			[t save];
		} else if (alertReturn == NSAlertDefaultReturn) { 	/* Cancel */
			return; 
		}
	}
	/* remove the empty file */
	[t close];
	[self.tabView removeTabViewItem:[self.tabView selectedTabViewItem]];
	if ([[self.tabView tabViewItems] count] == 0) {
		[NSApp terminate: self];
	}
}
- (IBAction)revertToSavedButton:(id)sender{	CURRENT(t); 	[t revertToSaved];	}
- (IBAction)newTabButton:(id)sender 		{	[self open:nil];	}
- (IBAction)goto_action:(id)sender 			{	

	NSTextField *field = sender;
	NSString *value = [field stringValue];
	if ([value rangeOfString:@"^\\d+$" options:NSRegularExpressionSearch].location == NSNotFound) {
		[self walk_tabs:^(TextVC *t) {
			if ([[t.s.fileURL lastPathComponent] rangeOfString:value options:(NSRegularExpressionSearch|NSCaseInsensitiveSearch)].location != NSNotFound) {
				[self.tabView selectTabViewItem:t.tabItem];
			}
		}];
	} else {
		CURRENT(t);
		[t goto_line:[value integerValue]];	
	}
	[self.goto_window orderOut:nil];
}
- (IBAction)commentSelection:(id)sender 	{

	NSString *commentSymbol;
	CURRENT(t);
	commentSymbol = [t extIs:@[@"m",@"h",@"c", @"h",@"m",@"cpp",@"java"]] ? @"//" : @"#";
	[t.text eachLineOfSelectionBeginsWith:commentSymbol] ?
	[t.text insert:commentSymbol atEachLineOfSelectionWithDirection:DIRECTION_LEFT]:
	[t.text insert:commentSymbol atEachLineOfSelectionWithDirection:DIRECTION_RIGHT];	
}
- (IBAction)tabSelection:(id)sender 		{	CURRENT(t);
	[t.text insert:[Preferences defaultTabSymbol] atEachLineOfSelectionWithDirection:[sender tag]];	
}
- (IBAction)goto_button:(id)sender 			{	[self.goto_window isVisible] ? [self.goto_window orderOut:nil]: [self.goto_window makeKeyAndOrderFront:nil];	}
- (BOOL) open:(NSURL *) file					{
	__block TextVC *o = nil;
	[self walk_tabs:^(TextVC *t) {
		if ([t.s.fileURL isEqualTo:file]) {
			o = t;
		};
	}];
	if (o) {
		NSInteger alertReturn = [o.s fileAlert:file withMessage:@"File is already open, do you want to reload it from disk?" def:@"Cancel" alternate:@"Reload" other:nil];
		if (alertReturn == NSAlertAlternateReturn) {
			[o open:file];
			[self.tabView selectTabViewItem:o.tabItem];
			return YES;
		}
		return NO;
	}
	o = [TextVC.alloc initWithFrame:self.tabView.frame];
	if ([o open:file]) {
		[self.tabView addTabViewItem:o.tabItem];
		[self.tabView selectTabViewItem:o.tabItem];
		return YES;
	}
	return NO;
}
- (IBAction) save_all:(id) sender 			{	[self walk_tabs:^(TextVC *t) {		[t save];		}];		}
- (void) walk_tabs:(void (^)(TextVC *t)) callback 	{	for (BGHUDTabViewItem *tabItem in self.tabView.tabViewItems) {
																			TextVC *t = tabItem.identifier;
																			callback(t);
																		}	
}
- (NSApplicationTerminateReply) gonna_terminate 	{
	[self storeOpenedURLs];
	__block unsigned int have_unsaved = 0;
	[self walk_tabs:^(TextVC *t) {
		if ([t is_modified]) {
			have_unsaved++;;
		}		
	}];
	NSInteger ret = NSTerminateNow;
	if (have_unsaved) {
		/* XXX */
		NSInteger alertReturn = NSRunAlertPanel(@"WARNING: unsaved data.", [NSString stringWithFormat:@"You have unsaved data for %u file%s",have_unsaved,(have_unsaved > 1 ? "s." : ".")] ,@"Cancel", @"Close w/o Save",@"Save & Close");
		if (alertReturn == NSAlertOtherReturn) {
			[self save_all:nil];
			ret = NSTerminateNow;
		} else if (alertReturn == NSAlertDefaultReturn) {
			ret = NSTerminateCancel;
		}
	}
	if (ret == NSTerminateNow) {
		[self stopAllTasks:nil];
	}
	return ret;
}
- (void) diff_button:(id) sender 			{
	NSURL *b = [NSURL fileURLWithPath:[(NSMenuItem*)sender title]];
	CURRENT(t);
	[t run_diff_against:b];
}
- (void) encoding_button:(id) sender 		{
	
	NSStringEncoding enc = [(NSMenuItem*)sender tag];		CURRENT(t);
	if ([t.s convertTo:enc]) {		[t reload];		[t save];	}
}
- (void) snipplet_button:(id) sender 		{
	CURRENT(t);
	NSMenuItem *m = sender;
	NSInteger idx = m.tag;	
	NSArray *snip = snipplet[idx];
	NSString *value = [NSString stringWithFormat:@"%@\n",snip[1]];	
	[t.text insertAtBegin:value];
}
- (void) menuWillOpen:(NSMenu *)menu 		{
	CURRENT(t);
	if ([[menu title] isEqualToString:@"diff"]) {
		[menu removeAllItems];
		for (NSString *b in t.s.backups) {
			NSMenuItem *m = [[NSMenuItem alloc] initWithTitle:b action:@selector(diff_button:) keyEquivalent:@""];
			[m setTarget:self];
			[menu addItem:m];		
		}
	} else if ([[menu title] isEqualToString:@"Encoding"]) {
		[menu removeAllItems];
		[menu addItemWithTitle:@"Current Encoding:" action:nil keyEquivalent:@""];
		NSMenuItem *m = [[NSMenuItem alloc] initWithTitle:[t.s currentEncoding] action:nil keyEquivalent:@""];
		[m setTarget:self];
		[menu addItem:m];
		[menu addItem:[NSMenuItem separatorItem]];
		for (NSArray *a in t.s.encodings) {
			NSString *title = a[0];
			m = [[NSMenuItem alloc] initWithTitle:title action:@selector(encoding_button:) keyEquivalent:@""];
			[m setTag:[a[1] intValue]];
			[m setTarget:self];
			[menu addItem:m];
			[m setEnabled:YES];	
		}
	} else if ([[menu title] isEqualToString:@"Snipplets"]) {
		[menu removeAllItems];
		for (NSArray *a in snipplet) {
			NSString *title = a[0];
			NSMenuItem *m = [[NSMenuItem alloc] initWithTitle:title action:@selector(snipplet_button:) keyEquivalent:@""];
			[m setTag:[snipplet indexOfObject:a]];
			[m setTarget:self];
			[menu addItem:m];
			[m setEnabled:YES];	
		}	
	}
}
- (void) menuDidClose:(NSMenu *)menu 		{	}
#pragma mark ExecutePanelWindow
- (void) stopAllTasks:(id) sender 			{	[self walk_tabs:^(TextVC *t) {	[t.ewc.e terminate];	}];	}
- (IBAction)run_button:(id)sender 			{	CURRENT(t);	[t run_self];	}
#pragma mark Timer
- (void) handleTimer:(id) sender 			{	[self performSelectorOnMainThread:@selector(signal:) withObject:self waitUntilDone:YES]; 	}
- (void) signal:(id) sender 					{	if ([NSApp isActive]) {		[self walk_tabs:^(TextVC *t) {	[t signal];	}];	}	}
#pragma mark aways on top action
- (IBAction)alwaysOnTop:(id)sender {	[NSUserDefaults.standardUserDefaults setObject:[NSNumber numberWithBool:([NSUserDefaults.standardUserDefaults boolForKey:@"DefaultAlwaysOnTop"] == YES) ? NO : YES] forKey:@"DefaultAlwaysOnTop"];	}
#pragma mark undo/redo
- (IBAction)undo:(id)sender {	CURRENT(t);	[t.text.undoManager undo];	}
- (IBAction)redo:(id)sender {	CURRENT(t);	[t.text.undoManager redo];	}
@end
