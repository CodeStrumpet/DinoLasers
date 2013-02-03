//
//  MotionAudioViewController.m
//  DinoLasers
//
//  Created by Paul Mans on 2/3/13.
//  Copyright (c) 2013 DinoLasers. All rights reserved.
//

#import "MotionAudioViewController.h"
#import "PdAudioController.h"
#import "PdBase.h"

@interface MotionAudioViewController ()
@property (nonatomic, strong) PdAudioController *audioController;

@end

@implementation MotionAudioViewController

@synthesize audioController = audioController_;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        
        NSLog(@"Audio is Turned on");
        self.audioController = [[PdAudioController alloc] init];
        [self.audioController configurePlaybackWithSampleRate:44100 numberChannels:2 inputEnabled:YES mixingEnabled:NO];
        [PdBase openFile:@"test.pd" path:[[NSBundle mainBundle] resourcePath]];
        [self.audioController setActive:YES];
        [self.audioController print];
        
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
