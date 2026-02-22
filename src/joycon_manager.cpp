#include "joycon_manager.h"
#include <hidapi/hidapi.h>
#include <iostream>
#include <algorithm>

JoyConManager::JoyConManager() {
    hid_init();
}

JoyConManager::~JoyConManager() {
    // devices are automatically destroyed because of unique_ptr, but we can also call hid_exit() if needed
    hid_exit();
}

void JoyConManager::discover_devices() {
    devices.clear();

    hid_device_info* devs = hid_enumerate(0x057E, 0); // Nintendo vendor ID
    hid_device_info* cur = devs;

    while (cur) {
        bool isJoyCon = cur->product_id == 0x2006 || // Left
                        cur->product_id == 0x2007 || // Right
                        cur->product_id == 0x2009;   // Grip

        if (isJoyCon) {
            hid_device* handle = hid_open_path(cur->path);
            if (handle) {
                auto device = std::make_unique<JoyConDevice>(handle, cur->product_id);

                if (!device->initialize()) {
                    std::cout << "Failed to initialize JoyCon " << std::hex << cur->product_id << std::endl;
                    continue;
                }
                device->test_calibration_read(); // Debug: check if we can read calibration data
                device->test_spi_read(); // Debug: check SPI read functionality
                device->test_communication(); // Debug: check basic communication
                if (!device->load_calibration()) {
                    std::cout << "Failed to load calibration, using defaults for JoyCon " 
                              << std::hex << cur->product_id << std::endl;
                    device->use_default_calibration();
                }

                std::cout << "Found JoyCon " << std::hex << cur->product_id << std::endl;
                bool is_left = (cur->product_id == 0x2006);
                device->start_polling(is_left);

                devices.push_back(std::move(device));
            }
        }

        cur = cur->next;
    }

    hid_free_enumeration(devs);
}

size_t JoyConManager::device_count() const {
    return devices.size();
}

JoyConDevice& JoyConManager::get_device(size_t index) {
    return *devices.at(index);
}

bool JoyConManager::poll_imu_frames(std::vector<IMUFrame>& out_frames) {
    out_frames.clear();
    bool success = false;

    for (auto& dev : devices) {
        IMUFrame frame;
        if (dev->read_imu_frame(frame)) {
            out_frames.push_back(frame);
            success = true;
        }
    }

    return success;
}

bool JoyConManager::poll_joycon_inputs(std::vector<std::tuple<JoyConButtons, IMUFrame, StickState>>& out_inputs) {
    out_inputs.clear();
    bool success = false;

    for (auto& dev : devices) {
        JoyConButtons buttons;
        IMUFrame frame;
        StickState stick;

        if (dev->get_latest_input(buttons, frame, stick)) {
            out_inputs.emplace_back(buttons, frame, stick);
            success = true;
        }
    }

    return success;
}