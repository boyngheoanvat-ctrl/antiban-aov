#import "Cleaner.h"
#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#include <filesystem>

namespace fs = std::filesystem;

// ==========================================
// HÀM HOOK DÙNG CHUNG (ÉP TRẢ VỀ FALSE/NO)
// ==========================================
static BOOL replacement_BoolShield(id self, SEL _cmd, ...) {
    NSString *selectorName = NSStringFromSelector(_cmd);
    NSLog(@"[UniversalShield] 🛡️ Đã chặn & ép trả về FALSE cho hàm: [%@ %@]", NSStringFromClass([self class]), selectorName);
    return NO; 
}

@implementation UniversalShield

+ (void)activateAllProtections {
    NSLog(@"[UniversalShield] 🚀 Đang kích hoạt hệ thống bảo vệ toàn diện (Anti-Ban, Anti-Cheat, Anti-Report)...");
    
    int numClasses = objc_getClassList(NULL, 0);
    if (numClasses <= 0) return;
    
    Class *classes = (Class *)malloc(sizeof(Class) * numClasses);
    numClasses = objc_getClassList(classes, numClasses);
    
    // Tổng hợp từ khóa nhạy cảm cần vô hiệu hóa
    NSArray *keywords = @[
        // Checksum / Integrity / SHA256
        @"sha256", @"integrity", @"checksum", @"hash", @"verify", @"validate",
        // Report / Tố cáo / Feedback
        @"report", @"complaint", @"feedback",
        // Anti-Cheat / Chống gian lận
        @"anticheat", @"cheat", @"jailbreak", @"hook", @"debugger", @"tamper",
        // Anti-Ban / Khóa tài khoản
        @"ban", @"block", @"punish", @"blacklist", @"violation", @"banned"
    ];
    
    int hookedCount = 0;
    
    for (int i = 0; i < numClasses; i++) {
        Class currentClass = classes[i];
        
        unsigned int methodCount = 0;
        Method *methods = class_copyMethodList(currentClass, &methodCount);
        
        for (unsigned int j = 0; j < methodCount; j++) {
            SEL selector = method_getName(methods[j]);
            NSString *selectorName = NSStringFromSelector(selector).lowercaseString;
            
            for (NSString *keyword in keywords) {
                if ([selectorName containsString:keyword]) {
                    method_setImplementation(methods[j], (IMP)replacement_BoolShield);
                    hookedCount++;
                    break;
                }
            }
        }
        free(methods);
    }
    
    free(classes);
    NSLog(@"[UniversalShield] ✅ Đã vô hiệu hóa thành công %d hàm kiểm tra/báo cáo/ban!", hookedCount);
}

@end

// Hàm hỗ trợ gọi trực tiếp SHA-256 Check
void applySHA256PaddingCheckIfNeeded() {
    [UniversalShield activateAllProtections];
}

// ==========================================
// HÀM XÓA CACHE CHÍNH
// ==========================================
void cleanCacheOnly() {
    @autoreleasepool {
        // Tự động kích hoạt toàn bộ cơ chế bảo vệ trước khi dọn dẹp cache
        [UniversalShield activateAllProtections];

        NSArray *urls = [[NSFileManager defaultManager]
            URLsForDirectory:NSCachesDirectory
            inDomains:NSUserDomainMask];
        if (urls.count == 0) return;
        
        NSURL *cacheURL = urls.firstObject;
        NSError *err = nil;
        [[NSFileManager defaultManager] removeItemAtURL:cacheURL error:&err];
        if (err) {
            NSLog(@"[Cleaner] Cache clean failed: %@", err);
        } else {
            [[NSFileManager defaultManager] createDirectoryAtURL:cacheURL
                withIntermediateDirectories:YES attributes:nil error:nil];
            NSLog(@"[Cleaner] Cache cleaned & protections activated successfully!");
        }
    }
}
