// language: Objective-C, file: file.h, target: iOS ARM64
#import <Foundation/Foundation.h>

@interface AntibanEriManager : NSObject
+ (instancetype)sharedInstance;
- (void)startInjection;
@end
