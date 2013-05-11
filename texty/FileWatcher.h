#import <Foundation/Foundation.h>
#import "Preferences.h"
#include <sys/event.h>
#include <sys/time.h> 
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h> 
#import <AtoZ/AtoZ.h>

#define NEV 256
@interface FileWatcher : BaseModel
{
//	NSLock *ex;
//	NSString *wakeup;
//	NSMutableDictionary *list;
	struct kevent change[NEV];
	struct kevent event[NEV];
}
//+ (FileWatcher *) shared;
- (void) watch:(NSURL *) file notify:(id)who;
- (void) unwatch:(NSURL *) file;

@property (strong) NSMutableDictionary *list;
@property (strong) NSLock *ex;
@property (strong) NSString *wakeup;
- (void) start;
@end
