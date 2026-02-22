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

void JoyConDevice::stop_polling() {
    if (polling) {
        polling = false;
        if (poll_thread.joinable()) {
            poll_thread.join();
        }
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

                        if (calibration.accel_scale[axis] == 16384) {  // detect default
                            frame.samples[sample].accel[axis] =
                                static_cast<float>(accel_raw) * 0.000244f;  // ≈ 1/4096 × 4 → ±2 g
                        } else {
                            // use factory
                            frame.samples[sample].accel[axis] =
                                static_cast<float>(accel_raw - calibration.accel_offset[axis]) /
                                static_cast<float>(calibration.accel_scale[axis]);
                        }
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
using namespace godot;
void JoyConDevice::auto_calibrate_stationary(float seconds)
{
    const int target_samples = seconds * 200; // JoyCon IMU ~200Hz

    Vector3 accel_sum = Vector3();
    Vector3 gyro_sum  = Vector3();
    int count = 0;

    while (count < target_samples)
    {
        IMUFrame f;
        if (!read_imu_frame(f)) continue;

        for (int s = 0; s < 3; s++)
        {
            accel_sum += Vector3(
                f.samples[s].accel[0],
                f.samples[s].accel[1],
                f.samples[s].accel[2]
            );

            gyro_sum += Vector3(
                f.samples[s].gyro[0],
                f.samples[s].gyro[1],
                f.samples[s].gyro[2]
            );

            count++;
        }
    }

    Vector3 accel_mean = accel_sum / count;
    Vector3 gyro_mean  = gyro_sum  / count;

    // gyro bias
    for (int i = 0; i < 3; i++)
        calibration.gyro_offset[i] = gyro_mean[i];

    // accel bias (preserve gravity direction)
    Vector3 expected = accel_mean.normalized();
    Vector3 bias = accel_mean - expected;

    for (int i = 0; i < 3; i++)
        calibration.accel_offset[i] = bias[i];
    godot::UtilityFunctions::print("Calibration complete", "offset: " + Vector3(calibration.accel_offset[0], calibration.accel_offset[1], calibration.accel_offset[2])  + ", " + Vector3(calibration.gyro_offset[0], calibration.gyro_offset[1], calibration.gyro_offset[2]));
}
// stop using godot namespace
using namespace std;
void JoyConDevice::test_calibration_read() {
    uint8_t test_buf[24];
    if (read_spi_block(0x6020, 12, test_buf)) {
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
    return true;  // Can't figure out how to get correct vaues, default works pretty well
    bool has_accel = false, has_gyro = false;

    const uint32_t accel_addresses[] = {0x6020, 0x60F0};
    const uint32_t gyro_addresses[] = {0x6030, 0x6100};

    uint8_t cal_data[24];

    for (uint32_t addr : accel_addresses) {
        if (read_spi_block(addr, 12, cal_data)) {
            if (parse_factory_accel(cal_data, calibration)) {
                has_accel = true;
                godot::UtilityFunctions::print("Loaded accel calibration from 0x" + 
                    godot::String::num_int64(addr, 16));
                break;
            }
        }
    }

    // Only try to load gyro if we have accel (to avoid using garbage data)
    if (has_accel) {
        for (uint32_t addr : gyro_addresses) {
            if (read_spi_block(addr, 12, cal_data)) {
                if (parse_factory_gyro(cal_data, calibration)) {
                    has_gyro = true;
                    godot::UtilityFunctions::print("Loaded gyro calibration from 0x" + 
                        godot::String::num_int64(addr, 16));
                    break;
                }
            }
        }
    }

    // If we got accel, that's good enough. Fill in missing gyro with defaults.
    if (has_accel && !has_gyro) {
        godot::UtilityFunctions::print("Accel calibration found, gyro not available - using default gyro");
        calibration.gyro_offset[0] = 0.0f;
        calibration.gyro_offset[1] = 0.0f;
        calibration.gyro_offset[2] = 0.0f;
        calibration.gyro_scale[0] = 13371.0f;
        calibration.gyro_scale[1] = 13371.0f;
        calibration.gyro_scale[2] = 13371.0f;
    }
    else if (!has_accel) {
        godot::UtilityFunctions::print("No accel calibration found, using all defaults");
        use_default_calibration();
    }

    has_calibration = true;

    godot::UtilityFunctions::print("Final Accel offsets: " + godot::String::num(calibration.accel_offset[0]) + 
        ", " + godot::String::num(calibration.accel_offset[1]) + 
        ", " + godot::String::num(calibration.accel_offset[2]));
    godot::UtilityFunctions::print("Final Accel scales: " + godot::String::num(calibration.accel_scale[0]) + 
        ", " + godot::String::num(calibration.accel_scale[1]) + 
        ", " + godot::String::num(calibration.accel_scale[2]));
    godot::UtilityFunctions::print("Final Gyro offsets: " + godot::String::num(calibration.gyro_offset[0]) + 
        ", " + godot::String::num(calibration.gyro_offset[1]) + 
        ", " + godot::String::num(calibration.gyro_offset[2]));
    godot::UtilityFunctions::print("Final Gyro scales: " + godot::String::num(calibration.gyro_scale[0]) + 
        ", " + godot::String::num(calibration.gyro_scale[1]) + 
        ", " + godot::String::num(calibration.gyro_scale[2]));

    return has_accel;
}

// helpers added near the bottom of the file:

bool JoyConDevice::parse_user_cal_block(const uint8_t *data, JoyConCalibration &out)
{
    out.accel_scale[0]  = static_cast<float>(read_le16(data, 0));
    out.accel_scale[1]  = static_cast<float>(read_le16(data, 2));
    out.accel_scale[2]  = static_cast<float>(read_le16(data, 4));
    out.accel_offset[0] = static_cast<float>(read_le16(data, 6));
    out.accel_offset[1] = static_cast<float>(read_le16(data, 8));
    out.accel_offset[2] = static_cast<float>(read_le16(data,10));
    out.gyro_scale[0]   = static_cast<float>(read_le16(data,12));
    out.gyro_scale[1]   = static_cast<float>(read_le16(data,14));
    out.gyro_scale[2]   = static_cast<float>(read_le16(data,16));
    out.gyro_offset[0]  = static_cast<float>(read_le16(data,18));
    out.gyro_offset[1]  = static_cast<float>(read_le16(data,20));
    out.gyro_offset[2]  = static_cast<float>(read_le16(data,22));

    // simple sanity check
    return out.accel_scale[0] > 0 && out.gyro_scale[0] > 0;
}

bool JoyConDevice::parse_factory_accel(const uint8_t *data, JoyConCalibration &out)
{
    godot::UtilityFunctions::print("=== parse_factory_accel debug ===");
    for (int i = 0; i < 12; i++) {
        godot::UtilityFunctions::print("  byte[" + godot::String::num_int64(i) + "] = 0x" + 
            godot::String::num_int64(data[i], 16));
    }
    
    uint16_t sx = read_le16(data, 0);
    uint16_t sy = read_le16(data, 2);
    uint16_t sz = read_le16(data, 4);
    
    godot::UtilityFunctions::print("Parsed scales: sx=0x" + godot::String::num_int64(sx, 16) +
        " sy=0x" + godot::String::num_int64(sy, 16) + " sz=0x" + godot::String::num_int64(sz, 16));
    
    if (sx == 0 || sy == 0 || sz == 0 || sx > 0x8000) {
        godot::UtilityFunctions::print("Factory accel validation failed");
        return false;
    }

    out.accel_scale[0]  = (float)sx;
    out.accel_scale[1]  = (float)sy;
    out.accel_scale[2]  = (float)sz;
    out.accel_offset[0] = (float)read_le16(data, 6);
    out.accel_offset[1] = (float)read_le16(data, 8);
    out.accel_offset[2] = (float)read_le16(data, 10);
    
    godot::UtilityFunctions::print("Factory accel accepted!");
    return true;
}

bool JoyConDevice::parse_factory_gyro(const uint8_t *data, JoyConCalibration &out)
{
    int16_t sx = (int16_t)read_le16(data, 0);
    int16_t sy = (int16_t)read_le16(data, 2);
    int16_t sz = (int16_t)read_le16(data, 4);

    godot::UtilityFunctions::print("Gyro scales: sx=" + godot::String::num_int64(sx) +
        " sy=" + godot::String::num_int64(sy) + " sz=" + godot::String::num_int64(sz));

    // Gyro scales should be reasonably large positive values (typically 8000–20000)
    // Reject if any scale is too small, zero, or negative
    if (sx < 1000 || sx > 30000 || sy < 1000 || sy > 30000 || sz < 1000 || sz > 30000) {
        godot::UtilityFunctions::print("Gyro scales out of valid range, rejecting");
        return false;
    }

    out.gyro_scale[0]   = (float)sx;
    out.gyro_scale[1]   = (float)sy;
    out.gyro_scale[2]   = (float)sz;
    out.gyro_offset[0]  = (float)read_le16(data, 6);
    out.gyro_offset[1]  = (float)read_le16(data, 8);
    out.gyro_offset[2]  = (float)read_le16(data, 10);

    godot::UtilityFunctions::print("Gyro calibration accepted");
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
    uint8_t cmd_data[5] = {0x10,
                           (uint8_t)(address & 0xFF),
                           (uint8_t)((address >> 8) & 0xFF),
                           (uint8_t)((address >> 16) & 0xFF),
                           length};

    godot::UtilityFunctions::print("Sending SPI read: addr 0x" + godot::String::num_int64(address,16) +
    " bytes: " + godot::String::num_int64(cmd_data[1],16) + " " +
    godot::String::num_int64(cmd_data[2],16) + " " +
    godot::String::num_int64(cmd_data[3],16) + " len " + godot::String::num_int64(length));

    if (!send_subcommand(0x10, cmd_data, 5)) {
        godot::UtilityFunctions::print("Failed to send SPI read");
        return false;
    }

    unsigned char dummy[64];
    while (hid_read_timeout(handle, dummy, sizeof(dummy), 0) > 0) {}

    int timeout_ms = 500;
    auto start = std::chrono::steady_clock::now();

    while (true) {
        unsigned char buf[64];
        int res = hid_read_timeout(handle, buf, sizeof(buf), 20);

        if (res > 0) {
            if (buf[0] == 0x21 && buf[14] == 0x10 && (buf[13] == 0x90 || buf[13] == 0x80)) {
                // SPI data starts at offset 20 in the response
                memcpy(out_data, &buf[20], length);
                godot::UtilityFunctions::print("Raw SPI data:");
                for (int i = 0; i < length; i++) {
                    godot::UtilityFunctions::print("  [" + godot::String::num_int64(i) + "]: 0x" + 
                        godot::String::num_int64(out_data[i], 16));
                }
                return true;
            }
        }

        if (res < 0) {
            godot::UtilityFunctions::print("Read error");
            return false;
        }

        auto now = std::chrono::steady_clock::now();
        if (std::chrono::duration_cast<std::chrono::milliseconds>(now - start).count() > timeout_ms) {
            godot::UtilityFunctions::print("SPI read timeout");
            return false;
        }
    }
}

bool JoyConDevice::is_valid_cal_block(const uint8_t* data, int len) {
    int non_ff_count = 0;
    for (int i = 0; i < len; i++) {
        if (data[i] != 0xFF) non_ff_count++;
    }
    // Require at least e.g. 12 non-FF bytes (half block meaningful)
    if (non_ff_count < 12) return false;

    // Optional: check scales positive/large (for accel/gyro sens)
    int16_t scale_x = read_le16(data, 6);   // accel scale X
    if (scale_x <= 0 || scale_x > 32767) return false;  // rough filter

    return true;
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