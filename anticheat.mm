// language: Objective-C++, file: file.mm, target: iOS ARM64
#import "anticheat.h"
#import <UIKit/UIKit.h>
#include <sys/mman.h>
#include <sys/socket.h>
#include <dlfcn.h>
#include <pthread.h>
#include <vector>
#include <string>
#include <cstring>

struct PatchData {
    const char* className;
    const char* methodName;
    uint32_t offsetAdd;
    std::vector<unsigned char> bytes;
};

static const std::vector<PatchData> kMasterPatches = {
    { "LVActorLinker", "SetVisible", 24, {0x36, 0x00, 0x80, 0xD2} },
    { "CItem", "get_IsCanSell", 0, {0x20, 0x00, 0x80, 0xD2, 0xC0, 0x03, 0x5F, 0xD6} },
    { "CPlayerProfile", "get_IsHostProfile", 0, {0x20, 0x00, 0x80, 0xD2, 0xC0, 0x03, 0x5F, 0xD6} },
    { "CSkillButtonManager", "GetCurRadian", 0, {0x20, 0x00, 0x80, 0xD2, 0xC0, 0x03, 0x5F, 0xD6} },
    { "GameSettings", "get_Supported45FPSMode", 0, {0x20, 0x00, 0x80, 0xD2, 0xC0, 0x03, 0x5F, 0xD6} },
    { "GameSettings", "get_Supported60FPSMode", 0, {0x20, 0x00, 0x80, 0xD2, 0xC0, 0x03, 0x5F, 0xD6} },
    { "GameSettings", "get_Supported90FPSMode", 0, {0x20, 0x00, 0x80, 0xD2, 0xC0, 0x03, 0x5F, 0xD6} },
    { "GameSettings", "get_Supported120FPSMode", 0, {0x20, 0x00, 0x80, 0xD2, 0xC0, 0x03, 0x5F, 0xD6} },
    { "GameSettings", "get_Supported144FPSMode", 0, {0x20, 0x00, 0x80, 0xD2, 0xC0, 0x03, 0x5F, 0xD6} },
    { "GameSettings", "IsIPadDevice", 0, {0x20, 0x00, 0x80, 0xD2, 0xC0, 0x03, 0x5F, 0xD6} },
    { "CameraSystem", "GetZoomRate", 0, {0x00, 0x00, 0xA8, 0x52, 0x00, 0x00, 0x27, 0x1E, 0xC0, 0x03, 0x5F, 0xD6} },
    { "Moba_Camera", "get_currentZoomAmount", 0, {0x00, 0x00, 0xA8, 0x52, 0x00, 0x00, 0x27, 0x1E, 0xC0, 0x03, 0x5F, 0xD6} },
    { "HeroInfoPanel", "ShowHeroInfo", 0, {0x20, 0x00, 0x80, 0xD2, 0xC0, 0x03, 0x5F, 0xD6} },
    { "MiniMapHeroInfo", "ShowSkillStateInfo", 0, {0x20, 0x00, 0x80, 0xD2, 0xC0, 0x03, 0x5F, 0xD6} },
    { "MiniMapHeroInfo", "ShowHeroHpInfo", 0, {0x20, 0x00, 0x80, 0xD2, 0xC0, 0x03, 0x5F, 0xD6} }
};

typedef ssize_t (*send_t)(int socket, const void* buffer, size_t length, int flags);
static send_t orig_send = nullptr;

ssize_t hooked_send(int socket, const void* buffer, size_t length, int flags) {
    if (buffer && length > 0) {
        const char* data = static_cast<const char*>(buffer);
        if (length > 4) {
            if (memcmp(data, "RPT_", 4) == 0 || 
                memcmp(data, "BAN_", 4) == 0 || 
                memcmp(data, "TELE", 4) == 0 ||
                strstr(data, "PlayerReport") != nullptr ||
                strstr(data, "AntiCheatLog") != nullptr) {
                return length; // Triệt tiêu gói tin tố cáo, chặn đứng lệnh ban
            }
        }
    }
    return orig_send(socket, buffer, length, flags);
}

bool WriteMemory(uintptr_t address, const std::vector<unsigned char>& patchBytes, uint32_t offsetAdd) {
    if (!address) return false;
    uintptr_t target = address + offsetAdd;
    unsigned long pageSize = sysconf(_SC_PAGESIZE);
    void* pageStart = (void*)(target & ~(pageSize - 1));
    
    if (mprotect(pageStart, pageSize, PROT_READ | PROT_WRITE | PROT_EXEC) != 0) {
        return false;
    }
    
    memcpy((void*)target, patchBytes.data(), patchBytes.size());
    mprotect(pageStart, pageSize, PROT_READ | PROT_EXEC);
    return true;
}

@implementation AntibanEriManager

+ (instancetype)sharedInstance {
    static AntibanEriManager *shared = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [[AntibanEriManager alloc] init];
    });
    return shared;
}

- (void)startInjection {
    // 1. Kích hoạt chặn mạng ngầm chống report
    void* netHandle = dlopen("libsystem_network.dylib", RTLD_LAZY);
    if (!netHandle) netHandle = dlopen("libc.so", RTLD_LAZY);
    if (netHandle) {
        orig_send = (send_t)dlsym(netHandle, "send");
    }

    // 2. Chờ il2cpp load và tiến hành vá toàn bộ menu
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        void* il2cppHandle = nullptr;
        while (!il2cppHandle) {
            il2cppHandle = dlopen("__Frameworks/libil2cpp.dylib", RTLD_NOLOAD | RTLD_LAZY);
            if (!il2cppHandle) {
                il2cppHandle = dlopen("libil2cpp.dylib", RTLD_NOLOAD | RTLD_LAZY);
            }
            if (!il2cppHandle) usleep(500000);
        }

        typedef void* (*domain_get_t)();
        typedef void* (*class_from_name_t)(void* image, const char* ns, const char* name);
        typedef void* (*get_method_t)(void* klass, const char* name, int args);
        typedef void** (*get_assemblies_t)(const void* domain, size_t* size);
        typedef void* (*get_image_t)(const void* asm_ptr);

        auto domain_get = (domain_get_t)dlsym(il2cppHandle, "il2cpp_domain_get");
        auto get_assemblies = (get_assemblies_t)dlsym(il2cppHandle, "il2cpp_domain_get_assemblies");
        auto get_image = (get_image_t)dlsym(il2cppHandle, "il2cpp_assembly_get_image");
        auto class_from_name = (class_from_name_t)dlsym(il2cppHandle, "il2cpp_class_from_name");
        auto get_method = (get_method_t)dlsym(il2cppHandle, "il2cpp_class_get_method_from_name");

        if (domain_get && class_from_name && get_method) {
            void* domain = domain_get();
            if (domain && get_assemblies && get_image) {
                size_t size = 0;
                void** assemblies = get_assemblies(domain, &size);
                for (size_t i = 0; i < size; i++) {
                    void* image = get_image(assemblies[i]);
                    if (!image) continue;

                    for (const auto& conf : kMasterPatches) {
                        void* klass = class_from_name(image, "", conf.className);
                        if (!klass) klass = class_from_name(image, "Assembly-CSharp", conf.className);
                        if (!klass) continue;

                        struct MethodInfo* method = (struct MethodInfo*)get_method(klass, conf.methodName, -1);
                        if (method) {
                            uintptr_t methodPtr = *(uintptr_t*)method;
                            if (methodPtr) {
                                WriteMemory(methodPtr, conf.bytes, conf.offsetAdd);
                            }
                        }
                    }
                }
            }
        }
    });
}

@end

__attribute__((constructor)) void initLoader() {
    [[AntibanEriManager sharedInstance] startInjection];
}
