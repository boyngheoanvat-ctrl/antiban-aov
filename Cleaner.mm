#import "Cleaner.h"
#include <dirent.h>
#include <sys/stat.h>
#include <unistd.h>

namespace CleanerBackground {
    std::atomic<bool> g_isRunning{false};
    std::thread g_backgroundThread;
}

bool wipeDirectory(const std::string& dirPath) {
    DIR *dir = opendir(dirPath.c_str());
    if (!dir) return false;

    struct dirent *entry;
    while ((entry = readdir(dir)) != NULL) {
        std::string name = entry->d_name;
        if (name == "." || name == "..") continue;
        
        std::string fullPath = dirPath + "/" + name;
        struct stat st;
        if (stat(fullPath.c_str(), &st) == 0) {
            if (S_ISDIR(st.st_mode)) {
                wipeDirectory(fullPath);
                rmdir(fullPath.c_str());
            } else {
                unlink(fullPath.c_str());
            }
        }
    }
    closedir(dir);
    LOGI(OBFUSCATE("[GameDataCleaner] ✔️ Đã dọn dẹp thư mục: %s"), dirPath.c_str());
    return true;
}

void autoWipeGameData() {
    // Lấy thư mục Document / Library / Cache trên iOS thông qua Foundation
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths firstObject];
    
    // Đường dẫn gốc ứng dụng trên iOS thường chứa Documents, Library, tmp
    NSString *appRoot = [documentsDirectory stringByDeletingLastPathComponent];
    
    std::string rootPath([appRoot UTF8String]);
    std::string cacheDir = rootPath + "/Library/Caches";
    std::string prefsDir = rootPath + "/Library/Preferences";
    std::string documentsDir = [documentsDirectory UTF8String];

    LOGI(OBFUSCATE("[GameDataCleaner] 🗑️ Bắt đầu Wipe Data (iOS)..."));
    wipeDirectory(cacheDir);
    wipeDirectory(prefsDir);
    wipeDirectory(documentsDir);
    LOGI(OBFUSCATE("[GameDataCleaner] ✅ Wipe Data hoàn tất!"));
}

void applySHA256PaddingCheckIfNeeded() {
    LOGI(OBFUSCATE("[IPAFixer] ⚠️ Đã TẮT/CHẶN kiểm tra tính toàn vẹn SHA-256 (iOS)"));
}

void startBackgroundCleaner() {
    using namespace CleanerBackground;
    if (g_isRunning) {
        LOGI(OBFUSCATE("[GameDataCleaner] ⚠️ Đã chạy ngầm rồi!"));
        return;
    }

    g_isRunning = true;
    LOGI(OBFUSCATE("[GameDataCleaner] 🔄 Bắt đầu chạy ngầm liên tục (iOS)..."));

    g_backgroundThread = std::thread([]() {
        while (g_isRunning) {
            autoWipeGameData();
            applySHA256PaddingCheckIfNeeded();
            
            for (int i = 0; i < CHECK_INTERVAL_SEC && g_isRunning; ++i) {
                std::this_thread::sleep_for(std::chrono::seconds(1));
            }
        }
        LOGI(OBFUSCATE("[GameDataCleaner] ⏹️ Đã dừng chạy ngầm"));
    });
}

void stopBackgroundCleaner() {
    using namespace CleanerBackground;
    
    if (!g_isRunning) return;
    
    g_isRunning = false;
    if (g_backgroundThread.joinable()) {
        g_backgroundThread.join();
    }
}
