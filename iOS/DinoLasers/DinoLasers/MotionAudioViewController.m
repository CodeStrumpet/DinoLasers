//
//  MotionAudioViewController.m
//  DinoLasers
//
//  Created by Paul Mans on 2/3/13.
//  Copyright (c) 2013 DinoLasers. All rights reserved.
//

#import "MotionAudioViewController.h"

@interface MotionAudioViewController ()

@end

@implementation MotionAudioViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        
        NSLog(@"Audio is Turned on");
        
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

- (void)handleMotionEvent:(MotionEvent *)motionEvent {
    NSLog(@"Received motion event in audio controller");
}

- (void)killAudio {
    
}


@end
