//
//  MotionEvent.m
//  DinoLasers
//
//  Created by Paul Mans on 2/3/13.
//  Copyright (c) 2013 DinoLasers. All rights reserved.
//

#import "MotionEvent.h"

@interface MotionEvent ()


@end

@implementation MotionEvent
@synthesize timestamp;
@synthesize accelX;
@synthesize accelY;
@synthesize accelZ;
@synthesize rotationX;
@synthesize rotationY;
@synthesize rotationZ;
@synthesize markerString;


- (id)initWithMotionString:(NSString *)motionString {
    if ((self = [super init])) {
        NSArray *components = [motionString componentsSeparatedByString:@","];
        
        if (components.count == 8) { // check if we have the right number of values
            timestamp = [((NSString *)[components objectAtIndex:0]) doubleValue];
            accelX = [((NSString *)[components objectAtIndex:1]) doubleValue];
            accelY = [((NSString *)[components objectAtIndex:2]) doubleValue];
            accelZ = [((NSString *)[components objectAtIndex:3]) doubleValue];
            rotationX = [((NSString *)[components objectAtIndex:4]) doubleValue];
            rotationY = [((NSString *)[components objectAtIndex:5]) doubleValue];
            rotationZ = [((NSString *)[components objectAtIndex:6]) doubleValue];
            markerString = [components objectAtIndex:7];
        }        
    }
    return self;
}
@end
