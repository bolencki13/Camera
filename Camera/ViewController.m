//
//  ViewController.m
//  Camera
//
//  Created by Brian Olencki on 5/23/15.
//  Copyright (c) 2015 bolencki13. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    UIButton *btnCamera = [UIButton buttonWithType:UIButtonTypeCustom];
    btnCamera.frame = CGRectMake(50, 50, 50, 50);
    [btnCamera addTarget:self action:@selector(openCamera) forControlEvents:UIControlEventTouchUpInside];
    [btnCamera setTitle:@"Camera" forState:UIControlStateNormal];
    [btnCamera setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [btnCamera sizeToFit];
    [self.view addSubview:btnCamera];

}
- (void)openCamera {
    [Camera sharedInstance].delegate = self;
    [[Camera sharedInstance] presentCameraWithFrame:CGRectMake(0, 100, [UIScreen mainScreen].bounds.size.width,[UIScreen mainScreen].bounds.size.width)];
}

#pragma mark - Camera Delegate
- (void)cameraImageWasTaken:(UIImage*)image {
    NSLog(@"Image was taken");
}
- (void)cameraVideoWasTaken:(NSData*)video {
    NSLog(@"Video was taken");
}
- (void)cameraWasDismissed {
    NSLog(@"Camera was dismissed.");
}
- (void)cameraWasPresented {
    NSLog(@"Camera was presented.");
}
- (void)cameraViewWasFlipedToFrontCamera:(BOOL)isFront {
    NSLog(@"Camera was flipped.");
}
- (void)cameraFlashDidTurnOn:(BOOL)flashOn {
    NSLog(@"Flash state did change");
}
@end
