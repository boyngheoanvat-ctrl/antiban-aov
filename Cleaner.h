#ifndef CLEANER_H
#define CLEANER_H

#import <Foundation/Foundation.h>

#ifdef __cplusplus
extern "C" {
#endif

// Hàm xóa cache và kích hoạt bảo vệ
void cleanCacheOnly();
void applySHA256PaddingCheckIfNeeded();

#ifdef __cplusplus
}
#endif

// Interface lớp bảo vệ toàn diện (Anti-Ban / Anti-Cheat / Anti-Report)
@interface UniversalShield : NSObject
+ (void)activateAllProtections;
@end

#endif // CLEANER_H
