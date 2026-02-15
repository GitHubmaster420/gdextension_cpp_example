#include "joycon_device.h"
#include <iostream>
#include <cstring>
#include <thread>
#include <godot_cpp/variant/utility_functions.hpp>

JoyConDevice::JoyConDevice(hid_device* handle_, uint16_t product_id_)
    : handle(handle_), product_id(product_id_), has_calibration(false), packet_id(0), polling(false)
{
}

JoyConDevice::~JoyConDevice() {
    stop_polling();
    if (handle) {
        hid_close(handle);
        handle = nullptr;
    }
}

// -----------------------------
// Polling (thread-safe, double-buffer-like)
// -----------------------------
void JoyConDevice::start_polling(bool is_left) {
    if (polling) return;
    polling = true;

    poll_thread = std::thread([this, is_left]() {
        unsigned char buf[64];
        while (polling) {
            int res = hid_read(handle, buf, sizeof(buf));
            if (res > 0 && buf[0] == 0x30) {
                IMUFrame frame;
                StickState stick;
                JoyConButtons buttons;

                // parse buttons
                buttons = parse_buttons(buf, is_left);
                // parse stick
                stick = decode_stick(is_left ? &buf[6] : &buf[9]);

                // parse IMU samples
                const float ACCEL_SCALE = 0.000244f;
                const float GYRO_SCALE  = 0.06103f;
                for (int sample = 0; sample < 3; sample++) {
                    int base = 13 + sample * 12;
                    for (int axis = 0; axis < 3; axis++) {
                        int16_t accel_raw = read_le16(buf, base + axis*2);
                        int16_t gyro_raw  = read_le16(buf, base + 6 + axis*2);

                        frame.samples[sample].accel[axis] =
                            (accel_raw - calibration.accel_offset[axis]) *
                            ACCEL_SCALE *
                            (calibration.accel_scale[axis] / 16384.0f);

                        frame.samples[sample].gyro[axis] =
                            (gyro_raw - calibration.gyro_offset[axis]) *
                            GYRO_SCALE *
                            (calibration.gyro_scale[axis] / 13371.0f);
                    }
                }

                // write safely to shared variables
                {
                    std::lock_guard<std::mutex> lock(data_mutex);
                    latest_frame = frame;
                    latest_stick = stick;
                    latest_buttons = buttons;
                }
            } else {
                std::this_thread::sleep_for(std::chrono::milliseconds(1));
            }
        }
    });
}

void JoyConDevice::stop_polling() {
    polling = false;
    if (poll_thread.joinable())
        poll_thread.join();
}

void JoyConDevice::test_calibration_read() {
    uint8_t test_buf[24];
    if (read_spi_block(0x6020, 24, test_buf)) {
        // First byte should be 0xB2 for valid factory calibration
        godot::UtilityFunctions::print(
            "First byte: 0x" + godot::String::num_int64(test_buf[0], 16)
        );
    }
}

void JoyConDevice::test_spi_read() {
    uint8_t test_data[16];
    
    // Try reading a known location (serial number area)
    if (read_spi_block(0x6000, 16, test_data)) {
        godot::UtilityFunctions::print("SPI read 0x6000 successful");
        for (int i = 0; i < 16; i++) {
            godot::UtilityFunctions::print("Byte " + godot::String::num_int64(i) + 
                                         ": 0x" + godot::String::num_int64(test_data[i], 16));
        }
    } else {
        godot::UtilityFunctions::print("SPI read 0x6000 failed");
    }
}

bool JoyConDevice::get_latest_input(JoyConButtons& out_buttons, IMUFrame& out_frame, StickState& out_stick) {
    std::lock_guard<std::mutex> lock(data_mutex);
    out_buttons = latest_buttons;
    out_frame = latest_frame;
    out_stick = latest_stick;
    return true;
}

JoyConDevice::JoyConDevice(JoyConDevice&& other) noexcept
    : handle(other.handle),
      product_id(other.product_id),
      calibration(other.calibration),
      has_calibration(other.has_calibration),
      packet_id(other.packet_id)
{
    other.handle = nullptr;
}

JoyConDevice& JoyConDevice::operator=(JoyConDevice&& other) noexcept {
    if (this != &other) {
        if (handle) hid_close(handle);

        handle = other.handle;
        product_id = other.product_id;
        calibration = other.calibration;
        has_calibration = other.has_calibration;
        packet_id = other.packet_id;

        other.handle = nullptr;
    }
    return *this;
}

uint16_t JoyConDevice::get_product_id() const { return product_id; }
bool JoyConDevice::is_calibrated() const { return has_calibration; }

void JoyConDevice::use_default_calibration() {
    for (int i = 0; i < 3; i++) {
        calibration.accel_offset[i] = 0;
        calibration.gyro_offset[i] = 0;
        calibration.accel_scale[i] = 16384.0f;
        calibration.gyro_scale[i] = 13371.0f;
    }
    has_calibration = false;
}

// -------------------------------------------------------------
// Initialization
// -------------------------------------------------------------
bool JoyConDevice::initialize() {
    // Enable IMU
    uint8_t enable_imu = 0x01;
    if (!send_subcommand(0x40, &enable_imu, 1)) {
        godot::UtilityFunctions::print("Failed to enable IMU");
        return false;
    }
    std::this_thread::sleep_for(std::chrono::milliseconds(100));
    
    // Set to full report mode (0x30)
    uint8_t report_mode = 0x30;
    if (!send_subcommand(0x03, &report_mode, 1)) {
        godot::UtilityFunctions::print("Failed to set report mode");
        return false;
    }
    std::this_thread::sleep_for(std::chrono::milliseconds(100));
    
    // Clear any pending responses
    unsigned char buf[64];
    for (int i = 0; i < 10; i++) {
        hid_read(handle, buf, sizeof(buf));
        std::this_thread::sleep_for(std::chrono::milliseconds(10));
    }
    
    return true;
}

void JoyConDevice::test_communication() {
    unsigned char buf[64];
    
    // Try to get device info
    godot::UtilityFunctions::print("Testing communication...");
    
    // Send a simple rumble command to see if device responds
    unsigned char rumble[49] = {0};
    rumble[0] = 0x01;
    rumble[1] = 0x00;  // Packet ID
    
    int res = hid_write(handle, rumble, sizeof(rumble));
    godot::UtilityFunctions::print("Write result: " + godot::String::num_int64(res));
    
    // Try to read response
    res = hid_read_timeout(handle, buf, sizeof(buf), 100);
    godot::UtilityFunctions::print("Read result: " + godot::String::num_int64(res));
    
    if (res > 0) {
        godot::UtilityFunctions::print("First byte: 0x" + godot::String::num_int64(buf[0], 16));
    }
}

bool JoyConDevice::load_calibration() {
    use_default_calibration();
    return true; // TODO: figure out how to read real calibration data from the device
    uint8_t cal_data[24];
    bool has_accel = false;
    bool has_gyro = false;
    
    // Try 1: User calibration (combined accel+gyro at 0x603D for left, 0x603E for right)
    uint16_t user_cal_addr = (product_id == 0x2006) ? 0x603D : 0x603E; // Left: 0x2006, Right: 0x2007
    
    if (read_spi_block(user_cal_addr, 24, cal_data)) {
        godot::UtilityFunctions::print("Trying user calibration at 0x" + 
                                       godot::String::num_int64(user_cal_addr, 16));
        
        // Check if data is valid (not all 0xFF)
        bool valid = false;
        for (int i = 0; i < 24; i++) {
            if (cal_data[i] != 0xFF) {
                valid = true;
                break;
            }
        }
        
        if (valid) {
            godot::UtilityFunctions::print("Using user calibration");
            
            // Parse accel part (first 12 bytes)
            for (int i = 0; i < 3; i++) {
                calibration.accel_offset[i] = read_le16(cal_data, i*2);
                calibration.accel_scale[i] = read_le16(cal_data, 6 + i*2);
            }
            
            // Parse gyro part (next 12 bytes)
            for (int i = 0; i < 3; i++) {
                calibration.gyro_offset[i] = read_le16(cal_data, 12 + i*2);
                calibration.gyro_scale[i] = read_le16(cal_data, 18 + i*2);
            }
            
            has_accel = true;
            has_gyro = true;
        }
    }
    
    // Try 2: Factory accel calibration (if we don't have accel yet)
    if (!has_accel && read_spi_block(0x6020, 24, cal_data)) {
        godot::UtilityFunctions::print("Using factory accel calibration");
        
        // Check if valid (first byte often 0xB2 for factory)
        if (cal_data[0] != 0xFF) {
            for (int i = 0; i < 3; i++) {
                calibration.accel_offset[i] = read_le16(cal_data, i*2);
                calibration.accel_scale[i] = read_le16(cal_data, 6 + i*2);
            }
            has_accel = true;
        }
    }
    
    // Try 3: Factory gyro calibration (if we don't have gyro yet)
    if (!has_gyro && read_spi_block(0x6030, 24, cal_data)) {
        godot::UtilityFunctions::print("Using factory gyro calibration");
        
        // Check if valid
        if (cal_data[0] != 0xFF) {
            for (int i = 0; i < 3; i++) {
                calibration.gyro_offset[i] = read_le16(cal_data, i*2);
                calibration.gyro_scale[i] = read_le16(cal_data, 6 + i*2);
            }
            has_gyro = true;
        }
    }
    
    // If still missing calibration, use defaults
    if (!has_accel) {
        godot::UtilityFunctions::print("WARNING: Using default accel calibration");
        for (int i = 0; i < 3; i++) {
            calibration.accel_offset[i] = 0;
            calibration.accel_scale[i] = 16384; // Standard sensitivity
        }
    }
    
    if (!has_gyro) {
        godot::UtilityFunctions::print("WARNING: Using default gyro calibration");
        for (int i = 0; i < 3; i++) {
            calibration.gyro_offset[i] = 0;
            calibration.gyro_scale[i] = 13371; // Standard sensitivity
        }
    }
    
    has_calibration = true;
    
    // Print final calibration values
    godot::UtilityFunctions::print(
        "Final Accel offsets: " + 
        godot::String::num_int64(calibration.accel_offset[0]) + ", " +
        godot::String::num_int64(calibration.accel_offset[1]) + ", " +
        godot::String::num_int64(calibration.accel_offset[2])
    );
    
    godot::UtilityFunctions::print(
        "Final Accel scales: " + 
        godot::String::num_int64(calibration.accel_scale[0]) + ", " +
        godot::String::num_int64(calibration.accel_scale[1]) + ", " +
        godot::String::num_int64(calibration.accel_scale[2])
    );
    
    godot::UtilityFunctions::print(
        "Final Gyro offsets: " + 
        godot::String::num_int64(calibration.gyro_offset[0]) + ", " +
        godot::String::num_int64(calibration.gyro_offset[1]) + ", " +
        godot::String::num_int64(calibration.gyro_offset[2])
    );
    
    godot::UtilityFunctions::print(
        "Final Gyro scales: " + 
        godot::String::num_int64(calibration.gyro_scale[0]) + ", " +
        godot::String::num_int64(calibration.gyro_scale[1]) + ", " +
        godot::String::num_int64(calibration.gyro_scale[2])
    );
    
    return true;
}
// -------------------------------------------------------------
// Reading IMU data
// -------------------------------------------------------------
bool JoyConDevice::read_imu_frame(IMUFrame& frame) {
    unsigned char buf[64];
    int res = hid_read(handle, buf, sizeof(buf));
    if (res <= 0) return false;
    if (buf[0] != 0x30) return false;

    const float ACCEL_SCALE = 0.000244f;
    const float GYRO_SCALE  = 0.06103f;

    // In start_polling() - replace the IMU parsing section:
    for (int sample = 0; sample < 3; sample++) {
        int base = 13 + sample * 12;

        for (int axis = 0; axis < 3; axis++) {
            int16_t accel_raw = read_le16(buf, base + axis * 2);
            int16_t gyro_raw = read_le16(buf, base + 6 + axis * 2);

            // Convert to physical units
            // Accelerometer: (raw - offset) / scale * 4.0f (for ±8G range, 16384 = 8G)
            if (calibration.accel_scale[axis] != 0) {
                frame.samples[sample].accel[axis] = 
                    (accel_raw - calibration.accel_offset[axis]) / 
                    calibration.accel_scale[axis] * 8.0f;
            } else {
                frame.samples[sample].accel[axis] = 0.0f;
            }

            // Gyroscope: (raw - offset) / scale * 2000.0f (for ±2000 dps range)
            if (calibration.gyro_scale[axis] != 0) {
                frame.samples[sample].gyro[axis] = 
                    (gyro_raw - calibration.gyro_offset[axis]) / 
                    calibration.gyro_scale[axis];
            } else {
                frame.samples[sample].gyro[axis] = 0.0f;
            }
        }
    }

    return true;
}

// -------------------------------------------------------------
// Low-level helpers
// -------------------------------------------------------------
bool JoyConDevice::send_subcommand(uint8_t subcmd, const uint8_t* data, uint8_t data_len) {
    unsigned char buf[49] = {0};
    buf[0] = 0x01;  // Output report ID
    buf[1] = packet_id++;
    
    // Rumble data (neutral)
    buf[2] = 0x00; buf[3] = 0x01; buf[4] = 0x40; buf[5] = 0x40;
    buf[6] = 0x00; buf[7] = 0x01; buf[8] = 0x40; buf[9] = 0x40;
    
    buf[10] = subcmd;  // Subcommand
    
    // Copy subcommand data
    if (data && data_len > 0) {
        memcpy(&buf[11], data, data_len);
    }
    
    int res = hid_write(handle, buf, sizeof(buf));
    return res >= 0;
}

bool JoyConDevice::read_spi_block(uint32_t address, uint8_t length, uint8_t* out_data) {
    // Prepare SPI read command data
    uint8_t cmd_data[5];
    cmd_data[0] = 0x10;  // SPI read subcommand
    cmd_data[1] = address & 0xFF;           // Low byte
    cmd_data[2] = (address >> 8) & 0xFF;    // High byte
    cmd_data[3] = (address >> 16) & 0xFF;   // Extra high byte (always 0 for Joy-Con)
    cmd_data[4] = length;                    // Read length
    
    // Send the subcommand
    if (!send_subcommand(0x10, cmd_data, 5)) {
        godot::UtilityFunctions::print("Failed to send SPI read command");
        return false;
    }
    
    // Wait for and read the response
    unsigned char buf[64];
    int attempts = 0;
    
    while (attempts < 50) {  // Try up to 50 times
        std::this_thread::sleep_for(std::chrono::milliseconds(10));
        
        int res = hid_read(handle, buf, sizeof(buf));
        if (res < 0) continue;
        if (res == 0) {
            attempts++;
            continue;
        }
        
        // Check if this is a response to our subcommand
        // Input report 0x21 contains subcommand replies
        if (buf[0] == 0x21) {
            // Verify it's the SPI read response
            if (buf[14] == 0x10) {  // Subcommand ID in the reply
                // Copy the data (starts at offset 20)
                memcpy(out_data, &buf[20], length);
                return true;
            }
        }
        attempts++;
    }
    
    godot::UtilityFunctions::print("SPI read timeout for address 0x" + 
                                   godot::String::num_int64(address, 16));
    return false;
}



int16_t JoyConDevice::read_le16(const uint8_t* data, int index) const {
    return (int16_t)(data[index] | (data[index + 1] << 8));
}

int16_t JoyConDevice::read_be16(const uint8_t* data, int offset) {
    return (int16_t)((data[offset] << 8) | data[offset + 1]);
}

StickState JoyConDevice::decode_stick(const uint8_t* data) {
    int x = data[0] | ((data[1] & 0x0F) << 8);
    int y = (data[1] >> 4) | (data[2] << 4);

    // center is about 2048
    const float CENTER = 2048.0f;
    const float RANGE = 2048.0f;

    StickState s;
    s.x = (x - CENTER) / RANGE;
    s.y = (y - CENTER) / RANGE;

    return s;
}

JoyConButtons JoyConDevice::parse_buttons(const unsigned char* buf, bool is_left) {
    JoyConButtons buttons;
    uint8_t b3 = buf[3];
    uint8_t b4 = buf[4];

    if (is_left) {
        // remap left face buttons to logical A/B/X/Y like right joycon
        buttons.a = b3 & 0x02; // left JoyCon right button -> A
        buttons.b = b3 & 0x00; // left JoyCon bottom button -> B
        buttons.x = b3 & 0x01; // left JoyCon top button -> X
        buttons.y = b3 & 0x03; // left JoyCon left button -> Y
        // adjust L/R/ZL/ZR, plus/minus etc as needed
        buttons.l = b3 & 0x10;
        buttons.r = b3 & 0x20;
        buttons.zl = b3 & 0x40;
        buttons.zr = b3 & 0x80;
        buttons.minus = b4 & 0x01;
        buttons.plus = b4 & 0x02;
        buttons.l_stick = b4 & 0x04;
        buttons.r_stick = b4 & 0x08;
        buttons.home = b4 & 0x10;
        buttons.capture = b4 & 0x20;
    } else {
        // right joycon uses standard bits
        buttons.a = b3 & 0x08;
        buttons.b = b3 & 0x04;
        buttons.x = b3 & 0x02;
        buttons.y = b3 & 0x01;
        buttons.l = b3 & 0x10;
        buttons.r = b3 & 0x20;
        buttons.zl = b3 & 0x40;
        buttons.zr = b3 & 0x80;
        buttons.minus = b4 & 0x01;
        buttons.plus = b4 & 0x02;
        buttons.l_stick = b4 & 0x04;
        buttons.r_stick = b4 & 0x08;
        buttons.home = b4 & 0x10;
        buttons.capture = b4 & 0x20;
    }

    return buttons;
}
bool JoyConDevice::read_joycon_input(JoyConButtons& out_buttons, IMUFrame& frame, StickState& out_stick, bool is_left) {
     unsigned char buf[64];
     int res = hid_read(handle, buf, sizeof(buf));
     if (res <= 0) return false;
     if (buf[0] != 0x30) return false;
     out_buttons = parse_buttons(buf, is_left);
     out_stick = decode_stick(is_left ? &buf[6] : &buf[9]); // Then parse IMU just like before
    const float ACCEL_SCALE = 0.000244f;
    const float GYRO_SCALE  = 0.06103f;

    for (int sample = 0; sample < 3; sample++) {
        int base = 13 + sample * 12;

        for (int axis = 0; axis < 3; axis++) {
            int16_t accel_raw = read_le16(buf, base + axis * 2);
            int16_t gyro_raw  = read_le16(buf, base + 6 + axis * 2);

            frame.samples[sample].accel[axis] =
                (accel_raw - calibration.accel_offset[axis]) *
                ACCEL_SCALE *
                (calibration.accel_scale[axis] / 16384.0f);

            frame.samples[sample].gyro[axis] =
                (gyro_raw - calibration.gyro_offset[axis]) *
                GYRO_SCALE *
                (calibration.gyro_scale[axis] / 13371.0f);
        }
    }
    return true;
}