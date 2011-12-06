#import "m_exec.h"
#import "PseudoTTY.h"
@implementation m_exec
@synthesize delegate = _delegate,task,_rc,_command,_terminated,_startTime,_timeout,pty;
- (void) sendTitle:(NSString *) s {
	if ([self.delegate respondsToSelector:@selector(taskAddExecuteTitle:)]) 
		[self.delegate taskAddExecuteTitle:s];
}
- (void) sendString:(NSString *) s {
	if ([self.delegate respondsToSelector:@selector(taskAddExecuteText:)]) 
		[self.delegate taskAddExecuteText:s];
	
}
- (void) send:(NSData *) data {
	NSString *dataValue = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
	[self sendString:dataValue];
}
- (void) readWhatIsLeft:(NSFileHandle *)fh {
	NSData *data;
	while ((data = [fh availableData]) && [data length]) {
		[self send:data];	
	}
}
- (void)readPipe:(NSNotification *)notification {
	NSFileHandle *fh = [notification object];
	NSData *data;
	data = [[notification userInfo] objectForKey:NSFileHandleNotificationDataItem];
	if ([data length]){
		[self send:data];
		[fh readInBackgroundAndNotify];
	} else {
		[self sendTerminate];
	}
}

- (BOOL) diff:(NSURL *) a against:(NSURL *) b {
	return [self execute:[NSString stringWithFormat:@"diff -rupN %@ %@",[a path],[b path]] withTimeout:0];
}
- (void) sendStart {
	[self sendTitle:_command];
	[self sendString:[NSString stringWithFormat:@"\n[%@] START TASK(timeout: %@): %@\n",_startTime,(_timeout == 0 ? @"NOTIMEOUT" : [NSString stringWithFormat:@"%d",_timeout]),_command]];

}
- (void) sendTerminate {
	[task waitUntilExit];
	NSString *timedOut = @"";
	if (_terminated) {
		timedOut = @" [TOUT]";
	} 
	NSDate *now = [NSDate date];
	NSTimeInterval diff = [now timeIntervalSinceDate:self._startTime];

	[self sendString:[NSString stringWithFormat:@"\n[%@ - took: %llfs] END TASK(RC: %d%@): %@\n",now,diff,[task terminationStatus],timedOut,_command]];
	if ([self.delegate respondsToSelector:@selector(taskDidTerminate)])
		[self.delegate taskDidTerminate];

}
- (void) terminate {
	[task terminate];
	[task waitUntilExit];
}
- (void) restart {
	[self terminate];
	[self execute:_command withTimeout:_timeout];
}
- (void) timeoutWatcher {
	if (_timeout > 0) {
		dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
		dispatch_async(queue, ^{
			sleep(_timeout);
			if (self.task && [self.task isRunning]) {
				self._terminated = YES;
				[self.task terminate];
			}
		});
	}
}
- (BOOL) execute:(NSString *) command withTimeout:(int)timeout {
	if ([task isRunning]) 
		return NO;

	self.pty = [[PseudoTTY alloc] init];
	if (self.pty == nil)
		return NO;
	
	self.task = [[NSTask alloc] init];
	self._command = [command copy];
	self._rc = 0;
	self._timeout = timeout;
	[task setLaunchPath: @"/bin/sh"];
	NSArray *arguments = [NSArray arrayWithObjects: @"-c", command,nil];		
	[task setArguments: arguments];
    [task setCurrentDirectoryPath:[@"~" stringByExpandingTildeInPath]];
	[task setStandardInput: pty.slave];
	[task setStandardOutput: pty.slave];
	[task setStandardError: pty.slave];
    NSMutableDictionary *environment = [[NSMutableDictionary alloc] initWithDictionary:[[NSProcessInfo processInfo] environment]];
	[environment setValue:@"xterm" forKey:@"TERM"];
	[task setEnvironment:[NSDictionary dictionaryWithDictionary:environment]];
	self._startTime = [NSDate date];
	[self sendStart];
	[task launch];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(readPipe:) name:NSFileHandleReadCompletionNotification object:pty.master];
    [pty.master readInBackgroundAndNotify];

	[self timeoutWatcher];
	return YES;
}
- (void) dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}
@end
