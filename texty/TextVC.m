#import "TextVC.h"
#define L_LOCKED	0
#define L_MODIFIED	1
#define L_DEFAULT	2
#define L_UNDEFINED 3
@implementation TextVC
@synthesize tabItem,s,parser,text,scroll,ewc;

+ (void) scrollEnd:(NSTextView *) tv {
	NSRange range = { [[tv string] length], 0 };
	[tv scrollRangeToVisible: range];
}
- (void) changed_under_my_nose:(NSURL *) file {
		if (locked == NO)
			[self performSelectorOnMainThread:@selector(lockText) withObject:nil waitUntilDone:YES];
}
- (void) signal {
	if (need_to_autosave) {
		if (time(NULL) - autosave_ts > [Preferences defaultAutoSaveInterval]) {
			if (s.temporary)
				[s migrate:s.fileURL withString:[text string] autosaving:YES];
			else 
				[s autosave:NO];
			autosave_ts = time(NULL);
			need_to_autosave = NO;
		}
	}
	if (something_changed) {
		if ([self is_modified]) {
			[self label:L_MODIFIED];
			need_to_autosave = YES;
		} else {
			[self label:L_DEFAULT];
		}
		something_changed = NO;
	}
}
- (void) label:(int) type {
	switch(type) {
	case L_MODIFIED:
		tabItem.label = [NSString stringWithFormat:@"%@ *",[s basename]];
		break;
	case L_LOCKED:
		tabItem.label = [NSString stringWithFormat:@"%@ *Locked*",[s basename]];
		break;
	case L_DEFAULT:
		tabItem.label = [NSString stringWithFormat:@"%@",[s basename]];			
		break;
	case L_UNDEFINED:
	default:
		tabItem.label = @"aaaaa :) should never happen";
	}
}
- (void) lockText {
	NSInteger alert = [s fileAlert:s.fileURL withMessage:@"The File was modified by someone else\nReload or Overwrite it." def:@"Cancel" alternate:@"Reload" other:@"Overwrite"];
	if (alert == NSAlertAlternateReturn) {
		if ([self open:self.s.fileURL])
			return;
	} else if (alert == NSAlertOtherReturn) {
		if ([self save])
			return;
	}
	[self label:L_LOCKED];
	locked = YES;
	[text setBackgroundColor:[NSColor darkGrayColor]];
	[text setEditable:NO];	
}
- (id) initWithFrame:(NSRect) frame {
    self = [super init];
    if (self) {
		self.s = [[m_Storage alloc] init];
		s.delegate = self;
		self.parser = [[m_parse alloc] init];
		self.tabItem  = [[NSTabViewItem alloc] initWithIdentifier:self];
		self.scroll = [[NSScrollView alloc] initWithFrame:frame];
		NSSize contentSize = [self.scroll contentSize];
		[scroll setBorderType:NSNoBorder];
		[scroll setHasVerticalScroller:YES];
		[scroll setHasHorizontalScroller:NO];
		[scroll setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
		tabItem.view = scroll;
		self.text = [[STextView alloc] initWithFrame:NSMakeRect(0, 0, contentSize.width, contentSize.height)];
		locked = NO;
		[self label:L_UNDEFINED];
		[self.scroll setDocumentView:self.text];
		NSView *m = [self.scroll contentView];
		[m setPostsBoundsChangedNotifications:YES];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(boundsDidChange:) name:NSViewBoundsDidChangeNotification object:m]; 
    }
    return self;
}
- (void) responder {
	[text setSelectedRange:NSMakeRange(0, 0)];
	[scroll becomeFirstResponder];
}
- (void) syntax_reload {
	[text.parser initSyntax:[[s basename] pathExtension] box:text._box];
	[text delayedParse];
}
- (BOOL) saveAs:(NSURL *) to {
	if ([s migrate:to withString:[text string] autosaving:NO]) {
		[self syntax_reload];
		[self label:L_DEFAULT];
		return YES;
	}
	return NO;
}
- (BOOL) save {
	return [self saveAs:s.fileURL];
}
- (void) revertToSaved {
	[text setString:s.data];
}
- (BOOL) is_modified {
	return ![[text string] isEqualToString:s.data];
}
- (void) goto_line:(NSInteger) want_line {
	NSRange area = [text rangeOfLine:want_line];
	if (area.location != NSNotFound) {
		[text setSelectedRange: area];
		[text scrollRangeToVisible: area];
	}
}
- (void) reload {
	[text setString:s.data];
	[self label:L_DEFAULT];
	[self performSelector:@selector(responder) withObject:self afterDelay:0];
	[self syntax_reload];

}
- (BOOL) open:(NSURL *)file {
	if ([s open:file]) {
		[self reload];
		return YES;
	}
	return NO;
}

- (BOOL) extIs:(NSArray *) ext {
	NSString *fileExt = [s.fileURL pathExtension];
	for (NSString *str in ext)
		if ([fileExt isEqualToString:str])
			return YES;
	return NO;
}

- (void) boundsDidChange:(id) noti {
	[text delayedParse];
}

- (void) run_diff_against:(NSURL *) b {
	NSURL *a = s.fileURL;
	[self run:[m_exec diff:a against:b] withTimeout:0];
}
- (void) run_self {
	NSString *cmd = [text.parser get_execute_command:text];
	if (!cmd) {
		cmd = [Preferences defaultCommand];
	}
	[self save];
	cmd = [cmd stringByReplacingOccurrencesOfString:@"{MYSELF}" withString:[s.fileURL path]];
	cmd = [cmd stringByReplacingOccurrencesOfString:@"{MYSELF_BASENAME}" withString:[s basename]];
	cmd = [cmd stringByReplacingOccurrencesOfString:@"{MYSELF_BASENAME_NOEXT}" withString:[[s basename] stringByDeletingPathExtension]];
	cmd = [cmd stringByReplacingOccurrencesOfString:@"{MYDIR}" withString:[[s.fileURL path] stringByDeletingLastPathComponent]];
	int timeout = DEFAULT_EXECUTE_TIMEOUT;  
	if ([cmd rangeOfString:@"{NOTIMEOUT}"].location != NSNotFound) {
		timeout = 0;
		cmd = [cmd stringByReplacingOccurrencesOfString:@"{NOTIMEOUT}" withString:@""];
	}
	
	if ([cmd rangeOfString:@"^\\s*?http(s)?://" options:NSRegularExpressionSearch].location != NSNotFound) {
		[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:[cmd stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]]];
		return;
	}
	[self run:cmd withTimeout:timeout];
}

- (void) run: (NSString *) cmd withTimeout:(int) timeout {
	if (!ewc)
		self.ewc = [[ExecuteWC alloc] init];
	[ewc execute:cmd withTimeout:timeout];
	[ewc.window makeKeyAndOrderFront:nil];
}

- (void) close {
	[s close];
	[ewc.e terminate];
	self.ewc = nil;
}
@end
