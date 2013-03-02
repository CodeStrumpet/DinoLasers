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
#import "MotionEvent.h"


#define RECEIVER_FREQ @"synth-freq"
#define RECEIVER_DFREQ @"synth-dfreq"
#define RECEIVER_MAG @"synth-mag"

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
        [PdBase openFile:@"wavetabler.pd" path:[[NSBundle mainBundle] resourcePath]];
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
    float  accelX =  [motionEvent accelX];
    float  accelY =  [motionEvent accelY];
    float  accelZ =  [motionEvent accelZ];

    float accelMagnitude = sqrtf((accelX*accelX + accelY*accelY + accelZ*accelZ));
    
    float mag = 0.5f;
    float freq = 220;
    float dfreq = accelMagnitude * 100;
    
//    NSLog(@"mag : %f", mag);
//    NSLog(@"freq : %f", freq);
    NSLog(@"dfreq : %f", dfreq);

    [PdBase sendFloat:mag toReceiver:RECEIVER_MAG];
    [PdBase sendFloat:freq toReceiver:RECEIVER_FREQ];
    [PdBase sendFloat:dfreq toReceiver:RECEIVER_DFREQ];

}

- (void)killAudio {
    
}


@end
