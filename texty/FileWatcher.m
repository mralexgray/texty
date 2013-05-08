#import "FileWatcher.h"
#import <objc/message.h>
@implementation FileWatcher
@synthesize ex,list,wakeup;
static FileWatcher *singleton = nil;
+ (FileWatcher *) shared {
	if (!singleton) {
		singleton = [[FileWatcher alloc] init];
		if (singleton) {
			singleton.ex = [[NSLock alloc] init];
			singleton.list = [[NSMutableDictionary alloc] init];
			singleton.wakeup = [[[Preferences defaultDir] stringByExpandingTildeInPath] stringByAppendingPathComponent:@"TEXTY_KQUEUE_WAKEUP.txt"];
			[singleton watch:[NSURL fileURLWithPath:singleton.wakeup] notify:singleton];
			[singleton performSelectorInBackground:@selector(start) withObject:nil];
		}
	}
	return singleton;
}
- (void) change:(NSInteger) ident {
	id notify = nil;
	NSURL *file = nil;
	[ex lock];
	for (NSURL *u in [list allKeys]) {
		NSMutableDictionary *d = list[u];
		NSNumber *fd = d[@"fd"];
		if ([fd intValue] == ident) {
			notify = d[@"notify"];
			file = u;
			break;
		}
	}
	[ex unlock];

	/* 
	 * must be done outside of the lock because the alert panel is executed in main thread
	 * and it will deadlock when the main thread trys to watch: or unwatch: something
	 * while we ware waiting under lock
	 */
	
	if (notify && file) {
		if ([notify respondsToSelector:@selector(changed_under_your_nose:)])
			objc_msgSend(notify, @selector(changed_under_your_nose:), file);
	}
	
}
- (void) watch:(NSURL *) file notify:(id)who {
	if (!file || !who)
		return;
		
	int fd = open([[file path] UTF8String], O_RDONLY);
	if (fd < 0) return;

	[self unwatch:file];
	[ex lock];
		[[NSString stringWithFormat:@"%lu",time(NULL)] writeToURL:[NSURL fileURLWithPath:wakeup] atomically:NO encoding:NSUTF8StringEncoding error:nil];		
		NSMutableDictionary *d = [NSMutableDictionary dictionary];
		d[@"fd"] = @(fd);
		d[@"notify"] = who;
		list[[file copy]] = d;
	[ex unlock];
}
- (void) unwatch:(NSURL *) file {
	if (!file || !list[file])
		return;
		
	[ex lock];
		[[NSString stringWithFormat:@"%lu",time(NULL)] writeToURL:[NSURL fileURLWithPath:wakeup] atomically:NO encoding:NSUTF8StringEncoding error:nil];	
		NSMutableDictionary *d = list[file];
		if (d) {
			[d removeObjectForKey:@"notify"];		
			int v = [d[@"fd"] intValue];
			close(v);
			[list removeObjectForKey:file];
		}
	[ex unlock];
}

- (int) refresh {
	[ex lock];
		int i=0;
		int count = 0;
		for (NSURL *u in [list allKeys]) {
			NSMutableDictionary *d = list[u];
			NSNumber *fd = d[@"fd"];
			EV_SET(&change[i++], [fd intValue], EVFILT_VNODE, (EV_ADD | EV_ENABLE | EV_ONESHOT), (NOTE_DELETE | NOTE_EXTEND | NOTE_WRITE), 0, 0);
			count++;
			if (count > NEV - 1)
				break;
			
		}
	[ex unlock];
	return count;
}

- (void) start {
	int kq, nev, count = 0;
	kq = kqueue();
	if (kq < 0) {
		perror("kqueue");
		return;
	}
	for (;;) {
		count = [self refresh];	
	    nev = kevent(kq, change, count, event, count,NULL);
		if (nev > 0) {
			/* something changed */
	   		for (int i=0; i < nev ;i++) {
				if (event[i].flags & (NOTE_DELETE | NOTE_EXTEND | NOTE_WRITE)) {
					[self change:event[i].ident];
				}
			}
		} 
	}
	close(kq);
	[ex lock];
	for (NSURL *u in [list allKeys]) {
		NSMutableDictionary *d = list[u];
		NSNumber *fd = d[@"fd"];
		close ([fd intValue]);
	}
	[ex unlock];
}
@end
