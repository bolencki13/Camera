#Call the camera from anywhere for iOS.

######To impliment add the files Camera.h & Camera.m into your project and      #import Camera.h.

To invoke the camera:
    
    [[Camera sharedInstance] presentCameraWithFrame:(CGRect)];

To dismiss the camera call manually:
    
    [[Camera sharedInstance] dismissCamera];

Once an image is taken you can get the image by calling (Will return a UIImage):
    
    [[Camera sharedInstance] getImageTaken];