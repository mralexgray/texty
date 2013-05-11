#import <Cocoa/Cocoa.h>
#import "m_tabManager.h"
#import "Preferences.h"
@interface textyAppDelegate : NSObject <NSApplicationDelegate,NSWindowDelegate> {
	m_tabManager IBOutlet *_tab;
}
@property (weak) IBOutlet NSWindow *window;
@property (strong) m_tabManager *tab;
@property (weak) IBOutlet BGHUDProgressIndicator *working;
@end
