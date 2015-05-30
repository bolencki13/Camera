#Call the camera from anywhere for iOS.

######To impliment add the files Camera.h & Camera.m into your project and #import "Camera.h"

To invoke the camera:
    
    [[Camera sharedInstance] presentCameraWithFrame:(CGRect)];

To dismiss the camera manually (the camera will be dismiss while open by tapping on the blank area of the screen):
    
    [[Camera sharedInstance] dismissCamera];

Once an image is taken you can get the image by calling (will return a UIImage):
    
    [[Camera sharedInstance] getImageTaken];


The delegate can be set to recieve the images once taken (must be set first):

    [Camera sharedInstance].delegate = self;
