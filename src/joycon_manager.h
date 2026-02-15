#pragma once

#include "joycon_device.h"
#include <vector>
#include <memory>

class JoyConManager {
public:
    JoyConManager();
    ~JoyConManager();

    // Non-copyable
    JoyConManager(const JoyConManager&) = delete;
    JoyConManager& operator=(const JoyConManager&) = delete;

    // Discover and initialize all connected Joy-Cons
    void discover_devices();

    // Access devices
    size_t device_count() const;
    JoyConDevice& get_device(size_t index);

    // Poll all devices and fill a vector of IMU frames
    bool poll_imu_frames(std::vector<IMUFrame>& out_frames);

    bool poll_joycon_inputs(std::vector<std::tuple<JoyConButtons, IMUFrame, StickState>>& out_inputs);

private:
    std::vector<std::unique_ptr<JoyConDevice>> devices;
};
