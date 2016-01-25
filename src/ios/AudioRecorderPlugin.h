//
//  AudioRecorderPlugin.h
//  OutSystems - Mobility Experts
//
//  Created by João Gonçalves on 14/01/2015.
//
//

#import <Cordova/CDVPlugin.h>
#import "AudioRecorderVC.h"

@interface AudioRecorderPlugin : CDVPlugin <OSAudioRecorderDelegate>

@property (strong, nonatomic) CDVInvokedUrlCommand* commandHelper;

- (void) recordAudio:(CDVInvokedUrlCommand*)command;
- (void) deleteAudioFile:(CDVInvokedUrlCommand*)command;

@end
