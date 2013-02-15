//
//  MotionEvent.h
//  DinoLasers
//
//  Created by Paul Mans on 2/3/13.
//  Copyright (c) 2013 DinoLasers. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MotionEvent : NSObject

@property (nonatomic, assign) double timestamp;
@property (nonatomic, assign) double accelX;
@property (nonatomic, assign) double accelY;
@property (nonatomic, assign) double accelZ;
@property (nonatomic, assign) double rotationX;
@property (nonatomic, assign) double rotationY;
@property (nonatomic, assign) double rotationZ;
@property (nonatomic, strong) NSString *markerString;

- (id)initWithMotionString:(NSString *)motionString;
    
@end
