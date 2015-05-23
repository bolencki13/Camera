//
//  MOCamera.m
//  Map Out
//
//  Created by Brian Olencki on 5/15/15.
//  Copyright (c) 2015 bolencki13. All rights reserved.
//

#import "Camera.h"

@implementation Camera
+ (Camera*)sharedInstance {
    static dispatch_once_t p = 0;
    __strong static id _sharedObject = nil;
    dispatch_once(&p, ^{
        _sharedObject = [[self alloc] init];
    });
    return _sharedObject;
}
- (id)init {
    if (self = [super init]) {
        self.onScreen = NO;
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(statusBarDidChangeFrame)
                                                     name:UIApplicationDidChangeStatusBarFrameNotification
                                                   object:nil];
        
        [self setUpViews];
    }
    return  self;
}
- (void)setUpViews {
    overlay = [[UIWindow alloc] initWithFrame:SCREEN];
    overlay.windowLevel = UIWindowLevelStatusBar - 2;
    [overlay makeKeyAndVisible];
    
    background = [[UIView alloc] initWithFrame:SCREEN];
    background.backgroundColor = [UIColor clearColor];
    [overlay addSubview:background];
    
    UITapGestureRecognizer *dismissView = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissCamera)];
    dismissView.numberOfTapsRequired = 1;
    [background addGestureRecognizer:dismissView];
    
    cameraHousing = [[UIView alloc] initWithFrame: overlay.bounds];
    cameraHousing.layer.borderColor = [UIColor grayColor].CGColor;
    cameraHousing.layer.borderWidth = 1.0;
    cameraHousing.layer.cornerRadius = 10;
    cameraHousing.layer.masksToBounds = YES;
    cameraHousing.backgroundColor = [UIColor lightGrayColor];
    [background addSubview:cameraHousing];

    btnClose = [UIButton buttonWithType:UIButtonTypeCustom];
    [btnClose addTarget:self action:@selector(dismissCamera) forControlEvents:UIControlEventTouchUpInside];
    [btnClose setTitle:@"Close" forState:UIControlStateNormal];
    [btnClose setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    btnClose.frame = CGRectMake(background.bounds.size.width-60, 10, 35, 35);
    [btnClose sizeToFit];
    [background addSubview:btnClose];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        AVCaptureDevice *inputDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
        AVCaptureDeviceInput *captureInput = [AVCaptureDeviceInput deviceInputWithDevice:inputDevice error:nil];
        if (!captureInput) {
            [[[UIAlertView alloc] initWithTitle:@"Error" message:@"An error loading the camera has occured." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
                        return;
        }
        AVCaptureVideoDataOutput *captureOutput = [[AVCaptureVideoDataOutput alloc] init];
        NSString* key = (NSString*)kCVPixelBufferPixelFormatTypeKey;
        NSNumber* value = [NSNumber numberWithUnsignedInt:kCVPixelFormatType_32BGRA];
        NSDictionary* videoSettings = [NSDictionary dictionaryWithObject:value forKey:key];
        [captureOutput setVideoSettings:videoSettings];
        AVCaptureSession *captureSession = [[AVCaptureSession alloc] init];
        NSString* preset = 0;
        if (!preset) {
            preset = AVCaptureSessionPresetMedium;
        }
        captureSession.sessionPreset = preset;
        if ([captureSession canAddInput:captureInput]) {
            [captureSession addInput:captureInput];
        }
        if ([captureSession canAddOutput:captureOutput]) {
            [captureSession addOutput:captureOutput];
        }
        
        stillImageOutput = [[AVCaptureStillImageOutput alloc] init];
        NSDictionary *outputSettings = [[NSDictionary alloc] initWithObjectsAndKeys: AVVideoCodecJPEG, AVVideoCodecKey, nil];
        [stillImageOutput setOutputSettings:outputSettings];
        [captureSession addOutput:stillImageOutput];
        
        //handle prevLayer
        livePreviewLayer = [AVCaptureVideoPreviewLayer layerWithSession:captureSession];
        
        //if you want to adjust the previewlayer frame, here!
        livePreviewLayer.frame = CGRectMake(0, 0, cameraHousing.frame.size.width, cameraHousing.frame.size.height);
        livePreviewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
        [cameraHousing.layer addSublayer: livePreviewLayer];
        
        [captureSession startRunning];
        
        UIButton *btnTakePhoto = [UIButton buttonWithType:UIButtonTypeCustom];
        [btnTakePhoto addTarget:self action:@selector(takePhoto) forControlEvents:UIControlEventTouchUpInside];
        btnTakePhoto.showsTouchWhenHighlighted = YES;
        btnTakePhoto.frame = CGRectMake(cameraHousing.center.x, SCREEN.size.width-75, 65, 65);
        btnTakePhoto.center = CGPointMake(cameraHousing.frame.size.width/2, cameraHousing.frame.size.height-(75/2));
        btnTakePhoto.layer.cornerRadius = 65/2;
        btnTakePhoto.layer.borderColor = [UIColor darkGrayColor].CGColor;
        btnTakePhoto.layer.borderWidth = 7.5;
        btnTakePhoto.backgroundColor = [UIColor colorWithRed:1.0 green:0.25 blue:0.25 alpha:1.0];
        [cameraHousing addSubview:btnTakePhoto];
        
    });
    
}
- (void)statusBarDidChangeFrame {
    /*Can change the frame here if you need different placement per orientation*/
}

#pragma mark - Presentation & Dismissal
- (void)presentCameraWithFrame:(CGRect)frame {
    overlay.hidden = NO;
    inputPoint = CGPointMake(frame.origin.x+frame.size.width/2, frame.origin.y+frame.size.height/2);
    imgFrame = frame;
    [cameraHousing setFrame:CGRectMake(inputPoint.x, inputPoint.y, 1, 1)];
    self.onScreen = YES;
    [UIView animateWithDuration:ANIMATION_DURATION animations:^{
        [cameraHousing setFrame:frame];
    }];
}
- (void)dismissCamera {
    self.onScreen = NO;
    [UIView animateWithDuration:ANIMATION_DURATION animations:^{
        [imgView removeFromSuperview];
        [cameraHousing setFrame:CGRectMake(inputPoint.x, inputPoint.y, 1, 1)];
    } completion:^(BOOL finished) {
        overlay.hidden = YES;
    }];
}

#pragma mark - Photo Handling
- (void)takePhoto {
    AVCaptureConnection *videoConnection = nil;
    for (AVCaptureConnection *connection in stillImageOutput.connections) {
        for (AVCaptureInputPort *port in [connection inputPorts]) {
            if ([[port mediaType] isEqual:AVMediaTypeVideo] ) {
                videoConnection = connection;
                break;
            }
        }
        if (videoConnection) {
            break;
        }
    }
    
    [stillImageOutput captureStillImageAsynchronouslyFromConnection:videoConnection completionHandler: ^(CMSampleBufferRef imageSampleBuffer, NSError *error) {
        NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageSampleBuffer];
        
        UIImage *imgTaken = [[UIImage alloc] initWithData:imageData];
        [self showImage:imgTaken withFrame:imgFrame];
    }];
}
- (void)showImage:(UIImage*)image withFrame:(CGRect)frame {
    imgView =[[UIImageView alloc] initWithFrame:frame];
    imgView.image=image;
    imgView.frame = cameraHousing.frame;
    imgView.contentMode = UIViewContentModeScaleToFill;
    [background addSubview:imgView];
    
    [background bringSubviewToFront:btnClose];
}
- (UIImage*)getImageTaken {
    return imgView.image;
}

#pragma mark - Alert Delegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    [self dismissCamera];
}
@end
