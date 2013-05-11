#import <Foundation/Foundation.h>

@interface PseudoTTY : NSObject {
    NSFileHandle * master;
    NSFileHandle * slave;
}
@property (strong) NSFileHandle * master;
@property (strong) NSFileHandle * slave;
- (void) disableEcho;
- (void) enableEcho;
@end
