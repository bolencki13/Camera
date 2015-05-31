#Call the camera from anywhere for iOS.

######To impliment add the files Camera.h & Camera.m into your project and #import "Camera.h". For the delegate add <CameraDelegate> to your .h file

Camera is an easy way to invoke a camera anywhere within your program to take photos or videos. There is a delegate for convenience. This can be used to get updates of all kinds:
    - (void)cameraImageWasTaken:(UIImage*)image;
    - (void)cameraVideoWasTaken:(NSData*)video;
    - (void)cameraWasDismissed;
    - (void)cameraWasPresented;
    - (void)cameraViewWasFlipedToFrontCamera:(BOOL)isFront;
    - (void)cameraFlashDidTurnOn:(BOOL)flashOn;

In order to invoke Camera first assign the delegate if needed and then call as follows (the frame will be the area that the camera actually takes up. A different frame will most likely be needed depending on orientation of the device):
    [Camera sharedInstance].delegate = self;
    [[Camera sharedInstance] presentCameraWithFrame:(CGRect)];

To dismiss the camera manually (the camera will be dismissed while open by tapping on the blank area of the screen):
    
    [[Camera sharedInstance] dismissCamera];

If you need to get the image manually you can call this function (will return a UIImage):
    
    [[Camera sharedInstance] getImageTaken];