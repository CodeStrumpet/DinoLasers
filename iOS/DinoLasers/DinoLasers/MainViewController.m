//
//  MainViewController.m
//  DinoLasers
//
//  Created by Paul Mans on 11/19/12.
//  Copyright (c) 2012 DinoLasers. All rights reserved.
//

#import <CoreMotion/CoreMotion.h>
#import <QuartzCore/QuartzCore.h>
#import "MainViewController.h"
#import "GCDAsyncUdpSocket.h"
#import "UDPConnection.h"
#import "LogConnection.h"
#import "MotionController.h"
#import "DinoLaserSettings.h"
#import "MotionEvent.h"
#import "MotionAudioViewController.h"

#define LOG_BUFFER_SIZE 300


@interface MainViewController ()

@property (nonatomic, strong) MotionController *motionController;
@property (nonatomic, strong) UDPConnection *udpConnection;
@property (nonatomic, strong) LogConnection *logConnection;
@property (nonatomic, assign) BOOL isRecording;
@property (nonatomic, strong) NSString *logString;
@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, assign) long tag;
@property (nonatomic, strong) MotionAudioViewController *motionAudioViewController;

@end



@implementation MainViewController
@synthesize markerStringTextField;
@synthesize udpConnection;
@synthesize logConnection;
@synthesize isRecording;
@synthesize logString;
@synthesize timer;
@synthesize tag;
@synthesize motionAudioViewController;

- (void)dealloc {
    [self.udpConnection close];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.isRecording = NO;
    self.tag = 001;
    
    // instantiate MotionController and enable motion tracking
    self.motionController = [[MotionController alloc] init];
    [self.motionController enableMotionTracking];
    
    // Open whatever persistence connections are enabled in settings
    [self updatePersistenceConnections];
    
    // begin timer
    double timeInterval = DEFAULT_UPDATE_INTERVAL;
    self.timer = [NSTimer scheduledTimerWithTimeInterval:timeInterval target:self selector:@selector(timerFired:) userInfo:nil repeats:YES];
    
    
    // Make view adjustments
    [self updateToggleRecordingButton];
    
    self.logString = @"";
    self.logTextView.text = nil;
    self.logTextView.layer.cornerRadius = 4;
    self.logTextView.backgroundColor = [UIColor grayColor];
    
}


- (void)updatePersistenceConnections {
    PersistenceMode currPersistenceMode = [[NSUserDefaults standardUserDefaults] integerForKey:PERSISTENCE_MODES_SETTINGS_KEY];
        
    // setup UDPConnection if enabled
    if (currPersistenceMode & PersistenceModeUDP) {
        if (!self.udpConnection) {
            self.udpConnection = [[UDPConnection alloc] init];
            self.udpConnection.delegate = self;
        }
        
        NSString *hostIP = [[NSUserDefaults standardUserDefaults] objectForKey:HOST_IP_KEY];
        if (hostIP) {
            self.udpConnection.socketHost = hostIP;
        }
        
        [self.udpConnection setupSocket];
    } else {
        // kill existing udpConnection if it exists
        [self.udpConnection close];
        self.udpConnection = nil;
    }
    
    // setup LogConnection if enabled
    if (currPersistenceMode & PersistenceModeLogFile) {
        if (!self.logConnection) {
            self.logConnection = [[LogConnection alloc] init];
        }
    } else {
        // kill existing log connection if it exists
        self.logConnection = nil;
    }
    
    // setup MotionAudioViewController if enabled
    if (currPersistenceMode & PersistenceModeMotionAudio) {
        if (!self.motionAudioViewController) {
            self.motionAudioViewController = [[MotionAudioViewController alloc] initWithNibName:@"MotionAudioViewController" bundle:nil];
        }
    } else {
        // destroy MotionAudioViewController because it is not wanted
        [self.motionAudioViewController killAudio];
        self.motionAudioViewController = nil;
    }
}


#pragma mark - IBActions

- (IBAction)toggleRecording:(id)sender {
    isRecording = !isRecording;
    
    [self updateToggleRecordingButton];
    
    NSLog(@"Updating recording state: %@", isRecording ? @"YES" : @"NO");
}

- (IBAction)showInfo:(id)sender {
    
    DinoLaserSettings *settings = [DinoLaserSettings new];
    settings.persistenceModes = [[NSUserDefaults standardUserDefaults] integerForKey:PERSISTENCE_MODES_SETTINGS_KEY];
    
    NSString *ip = [[NSUserDefaults standardUserDefaults] objectForKey:HOST_IP_KEY];
    if (!ip) {
        ip = DEFAULT_HOST;
    }
    
    [[NSUserDefaults standardUserDefaults] setObject:ip forKey:HOST_IP_KEY];
    [[NSUserDefaults standardUserDefaults] synchronize];
    settings.hostIP = ip;
    
    
    FlipsideViewController *controller = [[FlipsideViewController alloc] initWithDinoLaserSettings:settings];
    controller.delegate = self;
    controller.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
    [self presentViewController:controller animated:YES completion:nil];
}

- (IBAction)markString:(id)sender {
    if ([self.markerStringTextField.text isEqualToString:@""]) {
        self.motionController.markerString = nil;
    } else {
        self.motionController.markerString = self.markerStringTextField.text;
    }
    NSLog(@"Updated Marker String to: %@", self.motionController.markerString);
    [self.markerStringTextField resignFirstResponder];
    
    // start a new logconnection file
    self.logConnection.fileNamePrefix = self.motionController.markerString;
    
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Start new log file?" message:nil delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"Yes", nil, nil];
    [alertView show];
}

- (IBAction)showAudioController:(id)sender {

    PersistenceMode currentMode = [[NSUserDefaults standardUserDefaults] integerForKey:PERSISTENCE_MODES_SETTINGS_KEY];
    
    currentMode = currentMode | PersistenceModeMotionAudio;
    
    [[NSUserDefaults standardUserDefaults] setInteger:currentMode forKey:PERSISTENCE_MODES_SETTINGS_KEY];
    
    [self updatePersistenceConnections];
    
    [self presentViewController:self.motionAudioViewController animated:YES completion:^{}];
}


#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1) {
        [self.logConnection beginNewFile];
    }
}


#pragma mark - Timer & Data Processing

// Timer callback
-(void)timerFired:(NSTimer *)theTimer {
    if (isRecording) {
        [self updateMotionData];
    }
}

- (void)updateMotionData {
    NSString *motionString = [self.motionController currentMotionString];
    
    [self appendToLog:[NSString stringWithFormat:@"IMU:  %@", motionString]];
    
    [self processMotionData:motionString];
    
}

- (void)processMotionData:(NSString *)motionString {
    if (!motionString) {
        return;
    }
    
    // pass update to udpConnection if it exists
    [self.udpConnection sendMessage:motionString withTag:tag];
    
    // pass update to logConnection if it exists
    [self.logConnection printLineToLog:motionString];
   
    // create motion event and pass it to MotionAudioViewController if it exists
    if (self.motionAudioViewController) {
        MotionEvent *motionEvent = [[MotionEvent alloc] initWithMotionString:motionString];
        [self.motionAudioViewController handleMotionEvent:motionEvent];
    }
    
    // increment the tag
    self.tag++;
}

#pragma mark - FlipsideViewDelegate

- (void)flipsideViewControllerDidFinish:(FlipsideViewController *)controller {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)flipsideViewController:(FlipsideViewController *)controller didUpdateSettings:(DinoLaserSettings *)settings {
    
    // Save new settings info in defaults
    [[NSUserDefaults standardUserDefaults] setInteger:settings.persistenceModes forKey:PERSISTENCE_MODES_SETTINGS_KEY];
    if (settings.hostIP) {
        [[NSUserDefaults standardUserDefaults] setObject:settings.hostIP forKey:HOST_IP_KEY];
    }
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    // update the persistent connections with the changes
    [self updatePersistenceConnections];
}


#pragma mark UDPConnectionDelegate

- (void)UDPConnection:(UDPConnection *)theUDPConnection didReceiveMessage:(NSString *)message fromHost:(NSString *)theHost onPort:(int)thePort {
    
    [self appendToLog:[NSString stringWithFormat:@"UDP:  %@", message]];
    
    [self processMotionData:message];
    
}


#pragma mark - Scrolling OnScreen Log 

- (void)appendToLog:(NSString *)suffix {
    logString = [logString stringByAppendingString:@"\n"];
    logString = [logString stringByAppendingString:suffix];
    if (logString.length >= LOG_BUFFER_SIZE) {
        logString = [logString substringFromIndex:logString.length - LOG_BUFFER_SIZE];
    }
    
    self.logTextView.text = logString;
    
    NSRange range = NSMakeRange(self.logTextView.text.length - 1, 1);
    [self.logTextView scrollRangeToVisible:range];
}


#pragma mark - Misc View setup

- (void)updateToggleRecordingButton {
    NSString *text = isRecording ? @"Pause" : @"Play";
    [self.toggleLoggingButton setTitle:text forState:UIControlStateNormal];
}

@end
