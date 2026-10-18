#import "Cleaner.h"
#import <Foundation/Foundation.h>
#import <substrate.h>
#import <mach-o/dyld.h>
#include <filesystem>

namespace fs = std::filesystem;

// ==========================================
// HÀM HOOK SHA-256 THẬT (BYPASS INTEGRITY)
// ==========================================

// Con trỏ lưu hàm kiểm tra integrity gốc
static bool (*old_checkSHA256Integrity)(void *self, SEL _cmd, ...);

// Hàm thay thế (Hook) - luôn trả về true để qua mặt hệ thống kiểm tra
static bool replacement_checkSHA256Integrity(void *self, SEL _cmd, ...) {
    NSLog(@"[IPAFixer] 🛡️ Đã intercept hàm kiểm tra SHA-256, ép trả về true (Bypassed)");
    return true; 
}

void applySHA256PaddingCheckIfNeeded() {
    NSLog(@"[IPAFixer] ⚠️ Đang tiến hành hook hàm kiểm tra tính toàn vẹn SHA-256 (iOS)...");
    
    // Tìm symbol gốc (thay _CustomSHA256CheckFunction bằng tên hàm thật từ IDA Pro/Ghidra)
    void *targetSymbol = MSFindSymbol(NULL, "_CustomSHA256CheckFunction");
    
    if (targetSymbol) {
        MSHookFunction(targetSymbol, (void *)replacement_checkSHA256Integrity, (void **)&old_checkSHA256Integrity);
        NSLog(@"[IPAFixer] ✅ Hook SHA-256 thành công!");
    } else {
        NSLog(@"[IPAFixer] ❌ Không tìm thấy symbol SHA-256 cần hook!");
    }
}

// ==========================================
// HÀM XÓA CACHE
// ==========================================

// CHỈ xóa cache — KHÔNG xóa Documents/Preferences
void cleanCacheOnly() {
    @autoreleasepool {
        // Kích hoạt luôn việc bypass SHA-256 khi tiến hành thao tác
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
        }
    }
}
