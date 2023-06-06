import imageio
from pypylon import pylon
import os
import sys

TIMEOUT_LIMIT = 1000
FRAME_RATE = '60'
N_CAMERAS = 1
MOV_QUALITY = 7 # 10

# where to save files
SAVE_DIR = r'C:\Users\Margrie_lab1\Documents\raw_data'

# od = ['-c:v', 'libx264', '-qp', '0', '-f', 'mp4']

def run_camera_acquisition(save_dir, n_cameras=1):

    tlFactory = pylon.TlFactory.GetInstance()
    devices = tlFactory.EnumerateDevices()
    cameras = pylon.InstantCameraArray(min(len(devices), n_cameras))

    print(len(devices))
    
    cam_writer = []
    
    for i, cam in enumerate(cameras):
        fname = get_fout_path(save_dir, i)
        print("Writing to: {}".format(fname), cam.GetDeviceInfo().GetModelName())
        cam_writer.append(imageio.get_writer(fname, fps=int(FRAME_RATE), quality=MOV_QUALITY))

    for i, cam in enumerate(cameras):
        cam.Attach(tlFactory.CreateDevice(devices[i]))
        print("Using device ", cam.GetDeviceInfo().GetModelName())
        cam.Open()
        set_triggerable_camera_properties(cam)
        cam.StartGrabbing()  # waits for TTL to acquire, timeout if no trigger comes

    GrabResult = []

    for cam in cameras:
        GrabResult.append(cam.RetrieveResult(TIMEOUT_LIMIT*10000))

    while GrabResult[0].GrabSucceeded:
        try:
            
            for i, cw in enumerate(cam_writer):
                cw.append_data(GrabResult[i].Array)
                GrabResult[i].Release()
            
            for i, cam in enumerate(cameras):
                GrabResult[i] = cam.RetrieveResult(TIMEOUT_LIMIT)

        except pylon.TimeoutException as e:
            print(e)
            for cw in cam_writer:
                cw.close()
            break


def set_triggerable_camera_properties(cam):
    cam.RegisterConfiguration(pylon.ConfigurationEventHandler(),
                              pylon.RegistrationMode_ReplaceAll,
                              pylon.Cleanup_Delete)
    cam.TriggerSelector.FromString('FrameStart')
    cam.TriggerMode.FromString('On')
    cam.LineSelector.FromString('Line3')
    cam.LineMode.FromString('Input')
    cam.TriggerSource.FromString('Line3')
    cam.TriggerActivation.FromString('RisingEdge')


def get_fout_path(save_dir, camera_number):
    return "{}\\camera{}.avi".format(save_dir, camera_number)


if __name__ == '__main__':
    this_save_dir = os.path.join(SAVE_DIR, sys.argv[1])
    if os.path.isdir(this_save_dir):
        print("directory already exists")
        exit()
    os.mkdir(this_save_dir)

    run_camera_acquisition(this_save_dir, N_CAMERAS)
