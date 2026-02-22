#include "joycon_manager_gd.h"

void JoyConManagerGD::_bind_methods() {
    ClassDB::bind_method(D_METHOD("discover_devices"), &JoyConManagerGD::discover_devices);
    ClassDB::bind_method(D_METHOD("get_device_count"), &JoyConManagerGD::get_device_count);
    ClassDB::bind_method(D_METHOD("get_imu_frames"), &JoyConManagerGD::get_imu_frames);
    ClassDB::bind_method(D_METHOD("get_is_right"), &JoyConManagerGD::get_is_right);
    ClassDB::bind_method(D_METHOD("calibrate_device_stationary", "index", "seconds"), &JoyConManagerGD::calibrate_device_stationary);
}

void JoyConManagerGD::discover_devices() {
    manager.discover_devices();
    is_right_array.clear();
    for (size_t i = 0; i < manager.device_count(); ++i) {
        is_right_array.append(manager.get_device(i).get_product_id() == 0x2007); // 0x2006 = left, 0x2007 = right
    }
}

int JoyConManagerGD::get_device_count() const {
    return static_cast<int>(manager.device_count());
}

Array JoyConManagerGD::get_is_right() {
    return is_right_array;
}


Array JoyConManagerGD::get_imu_frames() {
    std::vector<IMUFrame> frames;
    std::vector<std::tuple<JoyConButtons, IMUFrame, StickState>> inputs;
    Array result;

    if (manager.poll_joycon_inputs(inputs)) {
        for (size_t i = 0; i < inputs.size(); ++i) {
            Dictionary dev_dict;
            dev_dict["index"] = i;
            Array samples;

            for (int s = 0; s < 3; ++s) {
                Dictionary sample;
                auto& f = std::get<1>(inputs[i]).samples[s];

                Array gyro;
                gyro.append(f.gyro[0]);
                gyro.append(f.gyro[1]);
                gyro.append(f.gyro[2]);

                Array accel;
                accel.append(f.accel[0]);
                accel.append(f.accel[1]);
                accel.append(f.accel[2]);

                sample["gyro"] = gyro;
                sample["accel"] = accel;
                
                Dictionary buttons;
                buttons["a"] = std::get<0>(inputs[i]).a;
                buttons["b"] = std::get<0>(inputs[i]).b;
                buttons["x"] = std::get<0>(inputs[i]).x;
                buttons["y"] = std::get<0>(inputs[i]).y;
                buttons["l"] = std::get<0>(inputs[i]).l;
                buttons["r"] = std::get<0>(inputs[i]).r;
                buttons["zl"] = std::get<0>(inputs[i]).zl;
                buttons["zr"] = std::get<0>(inputs[i]).zr;
                buttons["plus"] = std::get<0>(inputs[i]).plus;
                buttons["minus"] = std::get<0>(inputs[i]).minus;
                buttons["l_stick"] = std::get<0>(inputs[i]).l_stick;
                buttons["r_stick"] = std::get<0>(inputs[i]).r_stick;

                sample["buttons"] = buttons;

                Vector2 stick;
                stick.x = std::get<2>(inputs[i]).x;
                stick.y = std::get<2>(inputs[i]).y;
                sample["stick"] = stick;

                samples.append(sample);
            }

            dev_dict["samples"] = samples;
            result.append(dev_dict);
        }
    }

    return result;
}
