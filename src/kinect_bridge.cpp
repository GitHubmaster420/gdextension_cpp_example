#include "kinect_bridge.h"

void KinectBridge::_bind_methods() {
    godot::ClassDB::bind_method(godot::D_METHOD("start"), &KinectBridge::start);
    godot::ClassDB::bind_method(godot::D_METHOD("stop"), &KinectBridge::stop);
    godot::ClassDB::bind_method(godot::D_METHOD("fill_joint_positions"), &KinectBridge::fill_joint_positions);
    
    godot::ClassDB::bind_method(godot::D_METHOD("get_array_value", "i"), &KinectBridge::get_array_value);
}

KinectBridge::KinectBridge() {
    
}

KinectBridge::~KinectBridge() {
    worker.stop();
}

void KinectBridge::start() {
    worker.start();
}

void KinectBridge::stop() {
    worker.stop();
}


using namespace godot;

void KinectBridge::fill_joint_positions() {
    const int joint_count = JointType_Count;
    BodyPose pose = worker.get_latest_pose();

    for (int i = 0; i < joint_count; i++) {
        const JointPose &j = pose.joints[i];

        arr[i*4 + 0] = j.x;
        arr[i*4 + 1] = j.y;
        arr[i*4 + 2] = j.z;
        arr[i*4 + 3] = (float)j.tracking_state;
    }

}


