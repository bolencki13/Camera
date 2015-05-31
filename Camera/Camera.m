//
//  MOCamera.m
//  Map Out
//
//  Created by Brian Olencki on 5/15/15.
//  Copyright (c) 2015 bolencki13. All rights reserved.
//

#import "Camera.h"

@implementation Camera
@synthesize delegate = _delegate;
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
        onScreen = NO;
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(statusBarDidChangeFrame)
                                                     name:UIApplicationDidChangeStatusBarFrameNotification
                                                   object:nil];
        prefs = [NSUserDefaults standardUserDefaults];
        
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
    cameraHousing.backgroundColor = [UIColor clearColor];
    [overlay addSubview:cameraHousing];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        inputDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
        captureInput = [AVCaptureDeviceInput deviceInputWithDevice:inputDevice error:nil];
        if (!captureInput) {
            [[[UIAlertView alloc] initWithTitle:@"Error" message:@"An error loading the camera has occured." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
                        return;
        }
        AVCaptureVideoDataOutput *captureOutput = [[AVCaptureVideoDataOutput alloc] init];
        NSString* key = (NSString*)kCVPixelBufferPixelFormatTypeKey;
        NSNumber* value = [NSNumber numberWithUnsignedInt:kCVPixelFormatType_32BGRA];
        NSDictionary* videoSettings = [NSDictionary dictionaryWithObject:value forKey:key];
        [captureOutput setVideoSettings:videoSettings];
        captureSession = [[AVCaptureSession alloc] init];
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
        movieFileOutput = [[AVCaptureMovieFileOutput alloc] init];
        NSDictionary *outputSettings = [[NSDictionary alloc] initWithObjectsAndKeys: AVVideoCodecJPEG, AVVideoCodecKey, nil];
        [stillImageOutput setOutputSettings:outputSettings];
        [captureSession addOutput:stillImageOutput];
        [captureSession addOutput:movieFileOutput];
        
        //handle prevLayer
        livePreviewLayer = [AVCaptureVideoPreviewLayer layerWithSession:captureSession];
        
        //if you want to adjust the previewlayer frame, here!
        livePreviewLayer.frame = CGRectMake(0, 0, cameraHousing.frame.size.width, cameraHousing.frame.size.height);
        livePreviewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
        [cameraHousing.layer addSublayer: livePreviewLayer];
        
        [captureSession startRunning];
        
        btnTakePhoto = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        [btnTakePhoto addTarget:self action:@selector(takePhoto) forControlEvents:UIControlEventTouchUpInside];
        btnTakePhoto.showsTouchWhenHighlighted = YES;
        btnTakePhoto.frame = CGRectMake(cameraHousing.center.x, SCREEN.size.width-75, 65, 65);
        btnTakePhoto.center = CGPointMake(cameraHousing.frame.size.width/2, cameraHousing.frame.size.height-(75/2));
        btnTakePhoto.layer.cornerRadius = 65/2;
        btnTakePhoto.layer.borderColor = [UIColor darkGrayColor].CGColor;
        btnTakePhoto.layer.borderWidth = 7.5;
        btnTakePhoto.backgroundColor = [UIColor colorWithRed:1.0 green:0.25 blue:0.25 alpha:1.0];
        [cameraHousing addSubview:btnTakePhoto];
        
        UILongPressGestureRecognizer *lpgRecord = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(recordVideo:)];
        lpgRecord.minimumPressDuration = 1.0;
        [btnTakePhoto addGestureRecognizer:lpgRecord];
        
        UIButton *btnToggleCamera = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        [btnToggleCamera addTarget:self action:@selector(toggleCamera) forControlEvents:UIControlEventTouchUpInside];
        [btnToggleCamera setImage:[UIImage imageNamed:@"flip.png"] forState:UIControlStateNormal];
        [btnToggleCamera setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
        btnToggleCamera.frame = CGRectMake(10,10,30,30);
        btnToggleCamera.showsTouchWhenHighlighted = YES;
        btnToggleCamera.backgroundColor = [UIColor clearColor];
        [cameraHousing addSubview:btnToggleCamera];
        
        if ([inputDevice hasFlash] == YES) {
            btnFlash = [UIButton buttonWithType:UIButtonTypeRoundedRect];
            [btnFlash addTarget:self action:@selector(flash:) forControlEvents:UIControlEventTouchUpInside];
            [inputDevice lockForConfiguration:nil];
            if ([prefs boolForKey:@"flash"] == YES) {
                [btnFlash setImage:[UIImage imageNamed:@"flashOn.png"] forState:UIControlStateNormal];
                inputDevice.flashMode = AVCaptureFlashModeOn;
            } else {
                [btnFlash setImage:[UIImage imageNamed:@"flashOff.png"] forState:UIControlStateNormal];
                inputDevice.flashMode = AVCaptureFlashModeOff;
            }
            [inputDevice unlockForConfiguration];
            btnFlash.frame = CGRectMake(cameraHousing.frame.size.height-40, 10, 30, 30);
            btnFlash.showsTouchWhenHighlighted = YES;
            btnFlash.backgroundColor = [UIColor clearColor];
            [cameraHousing addSubview:btnFlash];
        }

        lblTimer = [[UILabel alloc] initWithFrame:CGRectMake(10, cameraHousing.frame.size.height-40, 50, 30)];
        lblTimer.text = @"0:00";
        lblTimer.textColor = [UIColor colorWithRed:0.2 green:0.522 blue:1 alpha:1] /*#3385ff*/;
        lblTimer.textAlignment = NSTextAlignmentRight;
        [cameraHousing addSubview:lblTimer];
        lblTimer.hidden = YES;
    });
    
}
- (void)setDelegate:(id<CameraDelegate>)aDelegate {
    if (_delegate != aDelegate) {
        _delegate = aDelegate;
        
        
    }
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
    [btnTakePhoto setCenter:CGPointMake(cameraHousing.center.x, frame.size.height-(85/2))];
    [btnFlash setFrame:CGRectMake(frame.size.height-40, 10, 30, 30)];
    [lblTimer setFrame:CGRectMake(10, frame.size.height-40, 50, 30)];
    onScreen = YES;
    [UIView animateWithDuration:ANIMATION_DURATION animations:^{
        [cameraHousing setFrame:frame];
    } completion:^(BOOL finished) {
        [livePreviewLayer setFrame:CGRectMake(0, 0, frame.size.width, frame.size.height)];
    }];
    [_delegate cameraWasPresented];
}
- (void)dismissCamera {
    onScreen = NO;
    [UIView animateWithDuration:ANIMATION_DURATION animations:^{
        [imgHousing removeFromSuperview];
        [cameraHousing setFrame:CGRectMake(inputPoint.x, inputPoint.y, 1, 1)];
    } completion:^(BOOL finished) {
        overlay.hidden = YES;
    }];
    [_delegate cameraWasDismissed];
}

#pragma mark - Camera Handling
- (void)toggleCamera {
    NSArray * inputs = captureSession.inputs;
    for ( AVCaptureDeviceInput *INPUT in inputs ) {
        AVCaptureDevice *Device = INPUT.device ;
        if ([Device hasMediaType : AVMediaTypeVideo] ) {
            AVCaptureDevicePosition position = Device.position; AVCaptureDevice *newCamera = nil;
            AVCaptureDeviceInput *newInput = nil;
            
            if (position == AVCaptureDevicePositionFront) {
                newCamera = [self cameraWithPosition:AVCaptureDevicePositionBack];
                [_delegate cameraViewWasFlipedToFrontCamera:NO];
            } else {
                newCamera = [self cameraWithPosition:AVCaptureDevicePositionFront];
                [_delegate cameraViewWasFlipedToFrontCamera:YES];
            }
            newInput = [AVCaptureDeviceInput deviceInputWithDevice:newCamera error:nil];
            
            //beginConfiguration ensures that pending changes are not applied immediately
            [captureSession beginConfiguration];
            
            [captureSession removeInput : INPUT];
            [captureSession addInput : newInput];
            
            //Changes take effect once the outermost commitConfiguration is invoked.
            [captureSession commitConfiguration];
            break;
        }
    }

}
- (AVCaptureDevice *)cameraWithPosition:(AVCaptureDevicePosition)position {
    NSArray * Devices = [ AVCaptureDevice devicesWithMediaType : AVMediaTypeVideo ] ;
    for ( AVCaptureDevice * Device in Devices )
        if (Device.position == position )
            return Device ;
    return nil ;
}

#pragma mark - UIButton Photo Handling
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
        [_delegate cameraImageWasTaken:imgTaken];
    }];
}
- (void)recordVideo:(id)sender {
    UILongPressGestureRecognizer *recognizer = sender;
    if (recognizer.state == UIGestureRecognizerStateBegan) {
        //Create temporary URL to record to
        NSString *outputPath = [[NSString alloc] initWithFormat:@"%@%@", NSTemporaryDirectory(), @"snapback.mov"];
        NSURL *outputURL = [[NSURL alloc] initFileURLWithPath:outputPath];
        NSFileManager *fileManager = [NSFileManager defaultManager];
        if ([fileManager fileExistsAtPath:outputPath]) {
            NSError *error;
            if ([fileManager removeItemAtPath:outputPath error:&error] == NO) {
                [[[UIAlertView alloc] initWithTitle:@"Camera" message:@"An Error occured with Movie" delegate:nil cancelButtonTitle:@"Got it." otherButtonTitles:nil, nil] show];
            }
        }
        stepper = 1;
        minutes = 0;
        seconds = 0;
        timer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(updateTimerLabel:) userInfo:nil repeats:YES];
        lblTimer.hidden = NO;
        //Start recording
        [movieFileOutput startRecordingToOutputFileURL:outputURL recordingDelegate:self];
    } else if (recognizer.state == UIGestureRecognizerStateEnded) {
        [movieFileOutput stopRecording];
        [timer invalidate];
        timer = nil;
    }
}
- (void)updateTimerLabel:(NSTimer*)timer {
    NSString *text;
    
    if (stepper == 60) {
        minutes++;
        seconds = 0;
        stepper = 0;
    } else {
        seconds = stepper;
    }
    
    if (stepper < 10) {
        text = [NSString stringWithFormat:@"%i:0%i", minutes,seconds];
    } else {
        text = [NSString stringWithFormat:@"%i:%i", minutes,seconds];
    }
    
    lblTimer.text = text;
    //[lblTimer sizeToFit];

    stepper++;
}
- (void)flash:(id)sender {
    [inputDevice lockForConfiguration:nil];
    if (inputDevice.flashMode == AVCaptureFlashModeOff) {
        inputDevice.flashMode = AVCaptureFlashModeOn;
        [sender setImage:[UIImage imageNamed:@"flashOn.png"] forState:UIControlStateNormal];
        [prefs setBool:YES forKey:@"flash"];
    } else {
        inputDevice.flashMode = AVCaptureFlashModeOff;
        [sender setImage:[UIImage imageNamed:@"flashOff.png"] forState:UIControlStateNormal];
        [prefs setBool:NO forKey:@"flash"];
    }
    [prefs synchronize];
    [_delegate cameraFlashDidTurnOn:[prefs boolForKey:@"flash"]];
    [inputDevice unlockForConfiguration];
}

#pragma mark - Image & Video Handling
- (void)showImage:(UIImage*)image withFrame:(CGRect)frame {
    imgHousing = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleExtraLight]];
    imgHousing.frame = frame;
    imgHousing.layer.cornerRadius = cameraHousing.layer.cornerRadius;
    imgHousing.layer.masksToBounds = YES;
    [overlay addSubview:imgHousing];
    
    imgView =[[UIImageView alloc] initWithFrame:CGRectMake(0, 0, frame.size.height, frame.size.height)];
    imgView.image=image;
    imgView.contentMode = UIViewContentModeScaleAspectFit;
    imgView.userInteractionEnabled = YES;
    [imgHousing addSubview:imgView];
    
    btnClose = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [btnClose addTarget:self action:@selector(retakePhoto) forControlEvents:UIControlEventTouchUpInside];
    [btnClose setImage:[UIImage imageNamed:@"close.png"] forState:UIControlStateNormal];
    btnClose.frame = CGRectMake(imgView.bounds.size.width-40, 10, 30, 30);
    [imgView addSubview:btnClose];
}
- (void)retakePhoto {
    [imgHousing removeFromSuperview];
}
- (UIImage*)getImageTaken {
    return imgView.image;
}

#pragma mark - Alert Delegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    [self dismissCamera];
}

#pragma mark - Movie Delegate
- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL fromConnections:(NSArray *)connections error:(NSError *)error {
    [_delegate cameraVideoWasTaken:[[NSFileManager defaultManager] contentsAtPath:[outputFileURL path]]];
    
    MPMoviePlayerViewController *mp = [[MPMoviePlayerViewController alloc] initWithContentURL:outputFileURL];
    
    mp.moviePlayer.scalingMode = MPMovieScalingModeAspectFill;
    
    [overlay setRootViewController:mp];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(movieDidFinish) name:MPMoviePlayerPlaybackDidFinishNotification object:nil];

}
- (void)movieDidFinish {
    NSLog(@"VideoFinished");
    lblTimer.text = @"0:00";
    lblTimer.hidden = YES;
    [overlay setRootViewController:nil];
}
@end
