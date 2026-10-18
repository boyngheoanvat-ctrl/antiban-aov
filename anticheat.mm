// language: Objective-C++, file: file.mm, target: iOS ARM64
#import "anticheat.h"
#import <UIKit/UIKit.h>
#include <sys/socket.h>
#include <arpa/inet.h>
#include <dlfcn.h>
#include <pthread.h>
#include <cstring>

typedef ssize_t (*send_t)(int socket, const void* buffer, size_t length, int flags);
static send_t orig_send = nullptr;

// Móc nối hàm send socket để lọc và triệt tiêu các gói tin tố cáo / telemetry thời gian thực
ssize_t hooked_send(int socket, const void* buffer, size_t length, int flags) {
    if (buffer && length > 0) {
        const char* data = static_cast<const char*>(buffer);
        
        // Nhận diện và loại bỏ các gói tin chứa từ khóa report, ban, telemetry bất thường
        if (length > 4) {
            if (memcmp(data, "RPT_", 4) == 0 || 
                memcmp(data, "BAN_", 4) == 0 || 
                memcmp(data, "TELE", 4) == 0 ||
                strstr(data, "PlayerReport") != nullptr ||
                strstr(data, "AntiCheatLog") != nullptr) {
                
                // Trả về độ dài giả lập thành công để game không bị nghẽn luồng mạng hay văng ứng dụng, 
                // nhưng thực tế gói tin tố cáo hoàn toàn không được gửi đi máy chủ.
                return length;
            }
        }
    }
    return orig_send(socket, buffer, length, flags);
}

@implementation TelemetryInterceptor

+ (instancetype)sharedInstance {
    static TelemetryInterceptor *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[TelemetryInterceptor alloc] init];
    });
    return sharedInstance;
}

- (void)initializeHooks {
    void* handle = dlopen("libnet.so", RTLD_LAZY);
    if (!handle) handle = dlopen("libc.so", RTLD_LAZY);
    if (!handle) handle = dlopen("libsystem_network.dylib", RTLD_LAZY);
    
    if (handle) {
        orig_send = (send_t)dlsym(handle, "send");
        // Thực hiện thay thế con trỏ hàm send trong bảng GOT/Indirect table hoặc hook trực tiếp
    }
}

@end

__attribute__((constructor)) void initStealth() {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [[TelemetryInterceptor sharedInstance] initializeHooks];
    });
}
