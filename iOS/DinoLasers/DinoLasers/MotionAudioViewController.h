//
//  MotionAudioViewController.h
//  DinoLasers
//
//  Created by Paul Mans on 2/3/13.
//  Copyright (c) 2013 DinoLasers. All rights reserved.
//


#import <UIKit/UIKit.h>

@class MotionEvent;

@interface MotionAudioViewController : UIViewController

- (void)handleMotionEvent:(MotionEvent *)motionEvent;
- (void)killAudio;

@end
