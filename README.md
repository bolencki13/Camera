#Call the camera from anywhere for iOS.

######To impliment add the files into your project.

To invoke the switcher:
    [[Camera sharedInstance] presentCameraWithFrame:(CGRect)];

To dismiss the camera call manually:
    [[Camera sharedInstance] dismissCamera];

Once an image is taken you can get the image by calling (Will return a UIImage):
    [[Camera sharedInstance] getImageTaken];