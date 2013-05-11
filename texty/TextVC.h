#import <Cocoa/Cocoa.h>
#import "m_Storage.h"
#import "m_parse.h"
#import "ExecuteWC.h"
#import "Preferences.h"
#import "STextView.h"
@interface TextVC : NSViewController <m_StorageDelegate,NSTextViewDelegate> {
	m_Storage *s;
	m_parse *parser;
	ExecuteWC *ewc;
	STextView *text;
	NSScrollView *scroll;
	NSTabViewItem *tabItem;
	BOOL something_changed, need_to_autosave, locked;
	long autosave_ts;
}
@property (weak) 	 NSProgressIndicator * working;
@property (strong) ExecuteWC *ewc;
@property (strong) m_Storage *s;
@property (strong) m_parse *parser;
@property (strong) STextView *text;
@property (strong) NSTabViewItem *tabItem;
@property (strong) NSScrollView *scroll;

-   (id) initWithFrame:(NSRect) frame;
- (BOOL) open:	 (NSURL*)file;
- (BOOL) extIs: (NSArray*) ext;
- (BOOL) saveAs:(NSURL*) to;
- (BOOL) save;
- (BOOL) is_modified;
- (void) signal;
- (void) revertToSaved;
- (void) goto_line:(NSInteger) want_line;
- (void) reload;
- (void) close;
- (void) lockText;
- (void) label:(int) type;
+ (void) scrollEnd:(NSTextView*) tv;

- (void) run_self;
- (void) run_diff_against:(NSURL *) b;
- (void) run: (NSString *) cmd withTimeout:(int) timeout;
- (void) changed_under_my_nose:(NSURL *) file;
@end
