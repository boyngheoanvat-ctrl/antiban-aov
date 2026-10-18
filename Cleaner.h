#ifndef CLEANER_H
#define CLEANER_H

#import <Foundation/Foundation.h>

#ifdef __cplusplus
extern "C" {
#endif

// Khai báo các hàm C interface dùng chung
void cleanCacheOnly();
void applySHA256PaddingCheckIfNeeded();

#ifdef __cplusplus
}
#endif

// Khai báo Interface lớp bảo vệ an toàn (Production Shield)
@interface ProductionShield : NSObject
+ (void)applySafeProtections;
@end

#endif // CLEANER_H
