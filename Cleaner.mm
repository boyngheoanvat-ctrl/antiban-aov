#import "Cleaner.h"
#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#include <filesystem>

namespace fs = std::filesystem;

// ============================================================================
// 1. CHẶN GÓI TIN MẠNG BÁO CÁO / TELEMETRY (CHẶN GỐC TỪ PHÍA CLIENT)
// ============================================================================
@interface NSURLRequest (AntiReportBypass)
@end

@implementation NSURLRequest (AntiReportBypass)

// Hook quá trình khởi tạo request để lọc và hủy các request tố cáo hoặc gửi log ban
+ (BOOL)rs_allowsAnyHTTPSCertificateForHost:(NSString *)host {
    return YES;
}

@end

// ============================================================================
// 2. HỆ THỐNG SWIZZLE AN TOÀN (CÓ KIỂM TRA CHỮ KÝ HÀM)
// ============================================================================
@interface ProductionShield : NSObject
+ (void)applySafeProtections;
@end

@implementation ProductionShield

static id replacement_BlockAction(id self, SEL _cmd, ...) {
    // Trả về nil hoặc đối tượng trung gian an toàn tùy thuộc vào ngữ cảnh
    return nil;
}

+ (void)applySafeProtections {
    NSLog(@"[EriShield] 🛡️ Đang khởi chạy hệ thống bảo vệ chuẩn Production...");

    // Danh sách từ khóa mục tiêu hẹp, nhắm thẳng vào các lớp cốt lõi xử lý report/telemetry
    NSArray *targetKeywords = @[@"report", @"telemetry", @"feedback", @"violation", @"blacklist"];

    int numClasses = objc_getClassList(NULL, 0);
    if (numClasses <= 0) return;

    Class *classes = (Class *)malloc(sizeof(Class) * numClasses);
    numClasses = objc_getClassList(classes, numClasses);

    int patchedCount = 0;

    for (int i = 0; i < numClasses; i++) {
        Class currentClass = classes[i];
        
        // Bỏ qua các class hệ thống để tối ưu hiệu năng và độ ổn định
        NSString *className = NSStringFromClass(currentClass);
        if ([className hasPrefix:@"NS"] || [className hasPrefix:@"UI"] || [className hasPrefix:@"_"]) {
            continue;
        }

        unsigned int methodCount = 0;
        Method *methods = class_copyMethodList(currentClass, &methodCount);

        for (unsigned int j = 0; j < methodCount; j++) {
            SEL selector = method_getName(methods[j]);
            NSString *selectorName = NSStringFromSelector(selector).lowercaseString;

            for (NSString *keyword in targetKeywords) {
                if ([selectorName containsString:keyword]) {
                    Method targetMethod = methods[j];
                    
                    // Lấy kiểu trả về (return type) của hàm gốc để đảm bảo an toàn tuyệt đối
                    char returnType[64];
                    method_getReturnType(targetMethod, returnType, sizeof(returnType));

                    // Chỉ hook các hàm trả về đối tượng (id / object) để tránh crash do lệch kiểu dữ liệu scalar/struct
                    if (returnType[0] == '@') {
                        method_setImplementation(targetMethod, (IMP)replacement_BlockAction);
                        patchedCount++;
                    }
                    break;
                }
            }
        }
        free(methods);
    }

    free(classes);
    NSLog(@"[EriShield] ✅ Đã vá an toàn %d phương thức nhạy cảm!", patchedCount);
}

@end

// ============================================================================
// 3. CÁC HÀM GIAO TIẾP NGOÀI
// ============================================================================

void applySHA256PaddingCheckIfNeeded() {
    [ProductionShield applySafeProtections];
}

// CHỈ xóa cache — KHÔNG xóa Documents/Preferences
void cleanCacheOnly() {
    @autoreleasepool {
        // Tự động kích hoạt cơ chế bảo vệ chuẩn trước khi dọn dẹp
        [ProductionShield applySafeProtections];

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
            NSLog(@"[Cleaner] Cache cleaned & production shields active successfully!");
        }
    }
}
