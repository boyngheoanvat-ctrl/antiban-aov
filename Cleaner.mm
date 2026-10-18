#import "Cleaner.h"
#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#include <filesystem>

namespace fs = std::filesystem;

// ==========================================
// HÀM HOOK THAY THẾ (LUÔN TRẢ VỀ TRUE)
// ==========================================
static bool replacement_checkSHA256Integrity(id self, SEL _cmd) {
    NSLog(@"[IPAFixer] 🛡️ Tự động chặn hàm check SHA-256 qua %@", NSStringFromSelector(_cmd));
    return true; 
}

// ==========================================
// THỰC THI TỰ ĐỘNG TÌM VÀ HOOK
// ==========================================
void applySHA256PaddingCheckIfNeeded() {
    NSLog(@"[IPAFixer] 🔍 Đang quét tự động các lớp để tìm hàm kiểm tra SHA-256...");
    
    int numClasses = objc_getClassList(NULL, 0);
    if (numClasses <= 0) {
        NSLog(@"[IPAFixer] ❌ Không lấy được danh sách lớp.");
        return;
    }
    
    Class *classes = (Class *)malloc(sizeof(Class) * numClasses);
    numClasses = objc_getClassList(classes, numClasses);
    
    BOOL foundAndHooked = NO;
    
    // Các từ khóa nghi vấn thường xuất hiện trong hàm check integrity/SHA256
    NSArray *keywords = @[@"sha256", @"integrity", @"checksum", @"hash", @"verify", @"validate"];
    
    for (int i = 0; i < numClasses; i++) {
        Class currentClass = classes[i];
        
        // Lấy danh sách instance methods của class
        unsigned int methodCount = 0;
        Method *methods = class_copyMethodList(currentClass, &methodCount);
        
        for (unsigned int j = 0; j < methodCount; j++) {
            SEL selector = method_getName(methods[j]);
            NSString *selectorName = NSStringFromSelector(selector).lowercaseString;
            
            // Kiểm tra xem tên method có chứa từ khóa nhạy cảm không
            for (NSString *keyword in keywords) {
                if ([selectorName containsString:keyword]) {
                    // Thường hàm check tính toàn vẹn sẽ trả về bool (hoặc tương tự)
                    NSLog(@"[IPAFixer] 🎯 Tìm thấy khả nghi: [%@ %@] -> Tiến hành hook!", NSStringFromClass(currentClass), selectorName);
                    
                    method_setImplementation(methods[j], (IMP)replacement_checkSHA256Integrity);
                    foundAndHooked = YES;
                    break;
                }
            }
        }
        free(methods);
        
        if (foundAndHooked) {
            // Nếu bạn muốn hook tất cả các hàm khớp hoặc chỉ cần hàm đầu tiên tìm thấy, 
            // có thể bỏ break ở đây để quét toàn bộ. Hiện tại để quét và hook tất cả các hàm nghi vấn.
            foundAndHooked = NO; 
        }
    }
    
    free(classes);
    NSLog(@"[IPAFixer] ✅ Hoàn tất quá trình quét và tự động hook SHA-256.");
}

// ==========================================
// HÀM XÓA CACHE
// ==========================================
void cleanCacheOnly() {
    @autoreleasepool {
        // Tự động quét & bypass SHA-256 khi dọn dẹp
        applySHA256PaddingCheckIfNeeded();

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
            NSLog(@"[Cleaner] Cache cleaned successfully!");
        }
    }
}
