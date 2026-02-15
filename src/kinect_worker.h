#pragma once
#define Vector4 KinectVector4
#include <kinect.h>
#undef Vector4
#include <atomic>
#include <thread>

#ifdef UNICODE

#endif // !UNICODE

struct JointPose{
    float x, y, z;
    UINT8 tracking_state;
};

struct BodyPose {
    JointPose joints[JointType_Count];
    bool tracked = false;
};


class KinectWorker
{
public:
    KinectWorker();
    ~KinectWorker();
    void start();
    void stop();
    BodyPose get_latest_pose() const;


private:
    IKinectSensor* kinectSensor;
    ICoordinateMapper* coordinateMapper;

    INT64 startTime;
    INT64 lastCounter;
    DWORD framesSinceUpdate;
    double freq;

    IBodyFrameReader* bodyFrameReader;
    IBodyFrameSource* bodyFrameSource;
    std::thread worker_thread;
    std::atomic<bool> running = false;

    void Run();
    void Update();
    void ProcessBody(INT64 nTime, int nBodyCount, IBody** ppBodies);

    std::atomic<int> read_index = 0;
    BodyPose buffers[2];

};

template<class Interface>
inline void SafeRelease(Interface *& pInterfaceToRelease)
{
    if (pInterfaceToRelease != NULL)
    {
        pInterfaceToRelease->Release();
        pInterfaceToRelease = NULL;
    }
}
