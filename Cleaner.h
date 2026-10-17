#import <Foundation/Foundation.h>
#include <string>
#include <thread>
#include <atomic>
#include <mutex>
#include <chrono>

#ifndef LOGI
#define LOGI(...)
#endif

#ifndef OBFUSCATE
#define OBFUSCATE(str) (str)
#endif

namespace CleanerBackground {
    extern std::atomic<bool> g_isRunning;
    extern std::thread g_backgroundThread;
    extern constexpr int CHECK_INTERVAL_SEC = 30;
}

bool wipeDirectory(const std::string& dirPath);
void autoWipeGameData();
void applySHA256PaddingCheckIfNeeded();
void startBackgroundCleaner();
void stopBackgroundCleaner();
