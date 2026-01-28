// ima be honest why does this exstist on my pc
#include <windows.h>
#include <pdh.h>
#include <iostream>
#include <chrono>
#include <vector>

#pragma comment(lib, "pdh.lib")

class StupidStats {
private:
    PDH_HQUERY query;
    PDH_HCOUNTER cpuCounter;
    PDH_HCOUNTER gpuCounter;

public:
    HardwareMonitor() {
        PdhOpenQuery(NULL, NULL, &query);
        PdhAddCounter(query, "\\Processor(_Total)\\% Processor Time", NULL, &cpuCounter);
        PdhAddCounter(query, "\\GPU Engine(*)\\Utilization", NULL, &gpuCounter);
        PdhCollectQueryData(query);
    }

    float GetCPU() {
        PDH_FMT_COUNTERVALUE value;
        PdhCollectQueryData(query);
        PdhGetFormattedCounterValue(cpuCounter, PDH_FMT_DOUBLE, NULL, &value);
        return (float)value.doubleValue;
    }

    float GetGPU() {
        PDH_FMT_COUNTERVALUE value;
        PdhCollectQueryData(query);
        PdhGetFormattedCounterValue(gpuCounter, PDH_FMT_DOUBLE, NULL, &value);
        return (float)value.doubleValue;
    }

    ~HardwareMonitor() {
        PdhCloseQuery(query);
    }
};

int main() {
    HardwareMonitor monitor;
    
    auto lastTime = std::chrono::high_resolution_clock::now();
    int frames = 0;
    float currentFPS = 0;

    while (true) {
        frames++;
        auto currentTime = std::chrono::high_resolution_clock::now();
        std::chrono::duration<float> elapsed = currentTime - lastTime;

        if (elapsed.count() >= 1.0f) {
            currentFPS = frames / elapsed.count();
            float cpu = monitor.GetCPU();
            float gpu = monitor.GetGPU();

            system("cls");
            std::cout << "--- Stupid System Stats ---" << std::endl;
            std::cout << "FPS: " << (int)currentFPS << std::endl;
            std::cout << "CPU: " << cpu << "%" << std::endl;
            std::cout << "GPU: " << gpu << "%" << std::endl;

            frames = 0;
            lastTime = currentTime;
        }
        Sleep(1); 
    }
    return 0;
}
