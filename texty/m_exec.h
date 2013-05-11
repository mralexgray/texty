#import <Foundation/Foundation.h>
#import "PseudoTTY.h"
@protocol m_execDelegate <NSObject>
@optional
- (void) taskAddExecuteText:(NSString *) text;
- (void) taskDidTerminate;
- (void) taskDidStart;
@end
@interface m_exec : NSObject {
	id <m_execDelegate> delegate;
	NSTask *task;
	NSString *_command;
	int _rc;
	NSDate *_startTime;
	BOOL _terminated;
	int _timeout;
	PseudoTTY *pty;
	NSLock *serial;
}
@property (strong) PseudoTTY *pty;
@property (unsafe_unretained) id <m_execDelegate> delegate;
@property (strong) NSTask *task;
@property (strong) NSDate *_startTime;
@property (assign) int _rc;
@property (strong) NSString * _command;
@property (assign) BOOL _terminated;
@property (assign) int _timeout;
@property (strong) NSLock *serial;
- (void) sendSignal:(int) signal;
- (void) terminate;
- (void) readPipe:(NSNotification *)notification;
- (void) restart;
+ (NSString *) diff:(NSURL *) a against:(NSURL *) b;
- (BOOL) execute:(NSString *) command withTimeout:(int) timeout;
- (void) write:(NSString *) value;
@end
