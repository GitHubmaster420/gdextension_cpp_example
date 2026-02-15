#include <kinect_worker.h>
#include <chrono>

KinectWorker::KinectWorker() :
    kinectSensor(nullptr),
    coordinateMapper(nullptr),
    bodyFrameReader(nullptr),
    startTime(0),
    lastCounter(0),
    framesSinceUpdate(0),
    freq(0.0)
{}

KinectWorker::~KinectWorker() {
    stop();
}

void KinectWorker::start(){
    if(running) return;
    worker_thread = std::thread(&KinectWorker::Run, this);
}

void KinectWorker::stop(){
    running = false;
    if (worker_thread.joinable()) {
        worker_thread.join();
    }
    SafeRelease(bodyFrameReader);
    SafeRelease(coordinateMapper);
    SafeRelease(kinectSensor);

    SafeRelease(bodyFrameReader); bodyFrameReader = nullptr;
    SafeRelease(coordinateMapper); coordinateMapper = nullptr;
    SafeRelease(kinectSensor); kinectSensor = nullptr;

}

void KinectWorker::Run(){

    CoInitializeEx(nullptr, COINIT_MULTITHREADED);

    HRESULT hr = GetDefaultKinectSensor(&kinectSensor);
    if (FAILED(hr) || !kinectSensor) return;

    hr = kinectSensor->Open();
    if (FAILED(hr)) return;

    hr = kinectSensor->get_CoordinateMapper(&coordinateMapper);
    if (FAILED(hr)) return;
    hr = kinectSensor->get_BodyFrameSource(&bodyFrameSource);
    if (FAILED(hr)) return;
    hr = bodyFrameSource->OpenReader(&bodyFrameReader);
    if (FAILED(hr)) return;
    running = true;
    while(running){
        Update();
        std::this_thread::sleep_for(std::chrono::milliseconds(5));
    }

    CoUninitialize();
}

BodyPose KinectWorker::get_latest_pose() const {
    int index = read_index.load(std::memory_order_acquire);
    return buffers[index];
}

void KinectWorker::Update(){
    if(!bodyFrameReader) return;

    IBodyFrame* bodyFrame = NULL;

    HRESULT hr = bodyFrameReader->AcquireLatestFrame(&bodyFrame);

    if(SUCCEEDED(hr)){
        INT64 time = 0;

        hr = bodyFrame->get_RelativeTime(&time);

        IBody* bodies[BODY_COUNT] = {0};

        if (SUCCEEDED(hr))
        {
            hr = bodyFrame->GetAndRefreshBodyData(_countof(bodies), bodies);
        }

        if (SUCCEEDED(hr))
        {
            ProcessBody(time, BODY_COUNT, bodies);
        }

        for (int i = 0; i < _countof(bodies); ++i)
        {
            SafeRelease(bodies[i]);
        }
    }
    SafeRelease(bodyFrame);
}

void KinectWorker::ProcessBody(INT64 nTime, int nBodyCount, IBody** ppBodies)
{

    HRESULT hr;
    int next = 1 - read_index.load(std::memory_order_relaxed);
    BodyPose& write_pose = buffers[next];
    write_pose.tracked = false;
    for (int i = 0; i < nBodyCount; ++i)
    {
        IBody* pBody = ppBodies[i];
        if (pBody)
        {
            BOOLEAN bTracked = false;
            hr = pBody->get_IsTracked(&bTracked);
            
            if (SUCCEEDED(hr) && bTracked)
            {
                write_pose.tracked = true;
                Joint joints[JointType_Count]; 
                hr = pBody->GetJoints(_countof(joints), joints);
                if (SUCCEEDED(hr))
                {
                    
                        
                    for (int j = 0; j < _countof(joints); ++j)
                    {
                        TrackingState state;
                        state = joints[j].TrackingState;
                        float x = joints[j].Position.X;
                        float y = joints[j].Position.Y;
                        float z = joints[j].Position.Z;
                        
                        
                        write_pose.joints[j].x = x;
                        write_pose.joints[j].y = y;
                        write_pose.joints[j].z = z;
                        write_pose.joints[j].tracking_state = state;

                    }
                }
                break;
            }
        }
    }
    read_index.store(next, std::memory_order_release);

    // Below hopefully not needed
/*
    if (!startTime)
    {
        startTime = nTime;
    }

    double fps = 0.0;

    LARGE_INTEGER qpcNow = {0};
    if (freq)
    {
        if (QueryPerformanceCounter(&qpcNow))
        {
            if (lastCounter)
            {
                framesSinceUpdate++;
                fps = freq * framesSinceUpdate / double(qpcNow.QuadPart - lastCounter);
            }
        }
    }


    WCHAR szStatusMessage[64];
    StringCchPrintf(szStatusMessage, _countof(szStatusMessage), L" FPS = %0.2f    Time = %I64d", fps, (nTime - m_nStartTime));

    if (SetStatusMessage(szStatusMessage, 1000, false))
    {
        m_nLastCounter = qpcNow.QuadPart;
        m_nFramesSinceUpdate = 0;
    }
*/
}