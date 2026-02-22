#pragma once

#include <hidapi/hidapi.h>
#include <cstdint>
#include <thread>
#include <atomic>
#include <mutex>

struct JoyConCalibration {
    float accel_offset[3];
    float accel_scale[3];
    float gyro_offset[3];
    float gyro_scale[3];
};

struct IMUSample {
    float gyro[3];
    float accel[3];
};

struct IMUFrame {
    IMUSample samples[3]; // JoyCon sends 3 samples per report
};

struct JoyConButtons {
    bool a = false;
    bool b = false;
    bool x = false;
    bool y = false;
    bool l = false;
    bool r = false;
    bool zl = false;
    bool zr = false;
    bool plus = false;
    bool minus = false;
    bool l_stick = false;
    bool r_stick = false;
    bool home = false;
    bool capture = false;
};

struct StickState {
    float x; // -1 to 1
    float y; // -1 to 1
};

class JoyConDevice {
public:
    JoyConDevice(hid_device* handle, uint16_t product_id);
    ~JoyConDevice();

    // Non-copyable (HID handles should not be duplicated)
    JoyConDevice(const JoyConDevice&) = delete;
    JoyConDevice& operator=(const JoyConDevice&) = delete;

    // Movable
    JoyConDevice(JoyConDevice&& other) noexcept;
    JoyConDevice& operator=(JoyConDevice&& other) noexcept;

    // Initialization
    bool initialize();              // enable IMU + report mode
    void test_communication();
    bool load_calibration();
    bool parse_user_cal_block(const uint8_t *data, JoyConCalibration &out);
    bool parse_factory_accel(const uint8_t *data, JoyConCalibration &out);
    bool parse_factory_gyro(const uint8_t *data, JoyConCalibration &out);
    void use_default_calibration();

    void start_polling(bool is_left);
    void auto_calibrate_stationary(float seconds);
    void stop_polling();

    bool get_latest_input(JoyConButtons& out_buttons, IMUFrame& out_frame, StickState& out_stick);

    void test_calibration_read();
    void test_spi_read();

    // Data reading
    bool read_imu_frame(IMUFrame& frame);

    bool read_joycon_input(JoyConButtons& out_buttons, IMUFrame& frame, StickState& out_stick, bool is_left);

    // Info
    uint16_t get_product_id() const;
    bool is_calibrated() const;

    JoyConButtons parse_buttons(const unsigned char* buf, bool is_left);

    JoyConCalibration calibration;
    private:
    hid_device* handle;
    uint16_t product_id;

    
    bool has_calibration;

    uint8_t packet_id;
    StickState decode_stick(const uint8_t* data);

    std::thread poll_thread;
    std::atomic<bool> polling{false};

    // Latest read input
    IMUFrame latest_frame;
    StickState latest_stick;
    JoyConButtons latest_buttons;
    std::mutex data_mutex; // to protect access from manager thread

    // Low-level helpers
    bool send_subcommand(uint8_t subcmd, const uint8_t* data, uint8_t data_len);
    bool read_spi_block(uint32_t address, uint8_t length, uint8_t *out_data);
    bool is_valid_cal_block(const uint8_t *data, int len);
    int16_t read_le16(const uint8_t *data, int index) const;
    int16_t read_be16(const uint8_t* data, int offset);


};
