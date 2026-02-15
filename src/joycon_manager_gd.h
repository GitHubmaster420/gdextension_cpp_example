#pragma once

#include <godot_cpp/classes/ref_counted.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/array.hpp>
#include <godot_cpp/variant/dictionary.hpp>

#include "joycon_manager.h"

using namespace godot;

class JoyConManagerGD : public RefCounted {
    GDCLASS(JoyConManagerGD, RefCounted);

private:
    JoyConManager manager;

protected:
    static void _bind_methods();

public:
    // Constructor
    JoyConManagerGD() = default;
    ~JoyConManagerGD() = default;

    // Discover JoyCons
    void discover_devices();

    // Get the number of devices
    int get_device_count() const;

    // Poll IMU frames and return as an Array of Dictionaries
    Array get_imu_frames();
};
