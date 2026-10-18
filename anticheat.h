// language: Objective-C, file: file.h, target: iOS ARM64
#import <Foundation/Foundation.h>

@interface TelemetryInterceptor : NSObject
+ (instancetype)sharedInstance;
- (void)initializeHooks;
@end
