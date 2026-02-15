#pragma once

#define Vector4 GodotVector4
#include <godot_cpp/classes/node.hpp>
#include <godot_cpp/core/class_db.hpp>
#undef Vector4

#include "kinect_worker.h"

class KinectBridge : public godot::Node {
    GDCLASS(KinectBridge, Node);

private:
    KinectWorker worker;
    static const int joint_count = JointType_Count;
    static const int floats_per_joint = 4;
    static const int required_size = joint_count * floats_per_joint;

protected:
    static void _bind_methods();

public:
    KinectBridge();
    ~KinectBridge();

    void start();
    void stop();

    
    float arr[required_size];
    void fill_joint_positions();

    float get_array_value(int i){
        return arr[i];
    }

};

