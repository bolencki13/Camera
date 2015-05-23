//
//  MOCamera.h
//  Map Out
//
//  Created by Brian Olencki on 5/15/15.
//  Copyright (c) 2015 bolencki13. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <QuartzCore/QuartzCore.h>
#import <CoreVideo/CoreVideo.h>
#import <CoreMedia/CoreMedia.h>
#import <ImageIO/ImageIO.h>

@interface Camera : NSObject <UIAlertViewDelegate> {
    UIWindow *overlay;
    UIView *cameraHousing;
    UIView *background;
    UIButton *btnClose;
    
    CGPoint inputPoint;
    CGRect imgFrame;
    
    AVCaptureVideoPreviewLayer *livePreviewLayer;
    AVCaptureStillImageOutput *stillImageOutput;
    
    UIImageView *imgView;
}
#define SCREEN ([[UIScreen mainScreen] bounds])
#define CENTER (CGPointMake(SCREEN.size.width/2, SCREEN.size.height/2))
#define ANIMATION_DURATION (0.5)

@property BOOL onScreen;
+ (Camera*)sharedInstance;
- (void)presentCameraWithFrame:(CGRect)frame;
- (void)dismissCamera;
- (UIImage*)getImageTaken;
@end