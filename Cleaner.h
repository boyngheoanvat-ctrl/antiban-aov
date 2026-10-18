#ifndef CLEANER_H
#define CLEANER_H

#import <Foundation/Foundation.h>

#ifdef __cplusplus
extern "C" {
#endif

void cleanCacheOnly();
void applySHA256PaddingCheckIfNeeded();

#ifdef __cplusplus
}
#endif

@interface IOSShield : NSObject
+ (void)applyProtections;
@end

#endif // CLEANER_H
