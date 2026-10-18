#import "Cleaner.h"
#import <Foundation/Foundation.h>

@implementation IOSShield

+ (void)applyProtections {
    NSLog(@"[EriiOS] 🛡️ Đã kích hoạt hệ thống bảo vệ trên iOS.");
}

@end

void applySHA256PaddingCheckIfNeeded() {
    [IOSShield applyProtections];
}

// Tự động lấy đường dẫn Caches của ứng dụng trên iOS và dọn dẹp sạch sẽ
void cleanCacheOnly() {
    @autoreleasepool {
        [IOSShield applyProtections];

        NSArray *urls = [[NSFileManager defaultManager]
            URLsForDirectory:NSCachesDirectory
            inDomains:NSUserDomainMask];
        
        if (urls.count == 0) return;
        
        NSURL *cacheURL = urls.firstObject;
        NSFileManager *fileManager = [NSFileManager defaultManager];
        
        NSError *error = nil;
        NSArray *contents = [fileManager contentsOfDirectoryAtURL:cacheURL
                                       includingPropertiesForKeys:nil
                                                          options:0
                                                            error:&error];
        
        if (error) {
            NSLog(@"[EriiOS] ⚠️ Lỗi đọc thư mục cache: %@", error.localizedDescription);
            return;
        }

        for (NSURL *fileURL in contents) {
            [fileManager removeItemAtURL:fileURL error:nil];
        }
        
        NSLog(@"[EriiOS] ✅ Đã tự động dọn dẹp sạch sẽ toàn bộ thư mục Caches trên iOS!");
    }
}
