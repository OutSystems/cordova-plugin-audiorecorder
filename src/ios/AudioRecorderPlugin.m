//
//  AudioRecorderPlugin.h
//  OutSystems - Mobility Experts
//
//  Created by João Gonçalves on 14/01/2015.
//
//

#import "AudioRecorderPlugin.h"

@interface AudioRecorderPlugin ()

@property (nonatomic, strong) AudioRecorderVC* audioRecorderVc;
@property (strong, nonatomic) NSString* callbackId;
@end

@implementation AudioRecorderPlugin

- (void) recordAudio:(CDVInvokedUrlCommand *)command {
    self.callbackId = command.callbackId;
    NSNumber* duration = [command argumentAtIndex:0];
    NSString* viewsHexColor = [command argumentAtIndex:1 withDefault:@"#FFFFFF" andClass:[NSString class]];
    NSString* backgroundHexColor = [command argumentAtIndex:2 withDefault:@"#000000" andClass:[NSString class]];

    UIColor* viewsColor = [self colorFromHexString:viewsHexColor];
    UIColor* backgroundColor = [self colorFromHexString:backgroundHexColor];
    
    [self.commandDelegate runInBackground:^(){
        self.audioRecorderVc = [[AudioRecorderVC alloc] initWithDuration:duration andBackgroundColor:backgroundColor andViewsColor:viewsColor];
        self.audioRecorderVc.delegate = self;

        dispatch_async(dispatch_get_main_queue(), ^{
            if([self.viewController navigationController]) {
                [self.audioRecorderVc.view setFrame:self.viewController.navigationController.view.frame];
                [self.viewController.navigationController.view addSubview:self.audioRecorderVc.view];
            } else {
                [self.audioRecorderVc.view setFrame:self.viewController.view.frame];
                [self.viewController.view addSubview:self.audioRecorderVc.view];
            }
        });
    }];
}

- (void) deleteAudioFile:(CDVInvokedUrlCommand*)command {
    self.callbackId = command.callbackId;
    NSString* filepath = [command argumentAtIndex:0];
    
    if(!filepath || [filepath length] == 0 ) {
        [self respondErrorTo:self.callbackId withErroCode:OS_INVALID_ARGS andErrorMessage:@"filepath can't be empty."];
        return;
    }
    
    NSArray* filepathComps = [filepath componentsSeparatedByString:@"/"];
    
    // Validate that filepath points to a file inside "OSAudioRecordings" directory
    NSString* dirName = [filepathComps objectAtIndex:[filepathComps count] - 2];
    if([dirName compare:@"OSAudioRecordings"] != NSOrderedSame) {
        [self respondErrorTo:self.callbackId withErroCode:OS_INTERNAL_ERROR andErrorMessage:@"Trying to delete a file outside OSAudioRecordings folder."];
        return;
    }
    
    NSFileManager* fileMgr = [NSFileManager defaultManager];
    NSError* error;
    if([fileMgr removeItemAtPath:filepath error:&error] == NO) {
        [self respondErrorTo:self.callbackId withErroCode:OS_INTERNAL_ERROR andErrorMessage:@"Failed to delete file."];
    } else {
        CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:self.callbackId];
    }
}

- (void) finishedRecordingAudio:(NSString*) filePath filename:(NSString*) filename {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSLog(@"Accepted file: %@",filePath);
        
        NSMutableDictionary* result = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
                                       filePath, @"full_path",
                                       filename, @"file_name",
                                       nil];
        
        [self respondSuccessTo:self.callbackId withData:result];
    });
}

- (void) cancelledRecording:(OSCancelReason)reason {
    dispatch_async(dispatch_get_main_queue(), ^{
        switch (reason) {
            case OS_USER_CANCELLED:
                [self respondErrorTo:self.callbackId withErroCode:reason andErrorMessage:@"User cancelled recording."];
                break;
            case OS_INTERNAL_ERROR:
                [self respondErrorTo:self.callbackId withErroCode:reason andErrorMessage:@"AudioRecorderPlugin internal error."];
                break;
            case OS_PERMISSION_DENIED:
                [self respondErrorTo:self.callbackId withErroCode:reason andErrorMessage:@"Permission denied."];
                break;
            default:
                break;
        }
    });
}

#pragma mark Helper Functions

- (void) respondSuccessTo:(NSString*)callbackId withData:(NSMutableDictionary*) dict {
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dict options:0 error:&error];
    NSString *jsonString = @"";
    if (! jsonData) {
        NSLog(@"Got an error: %@", error);
    } else {
        jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    }
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:jsonString];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:self.callbackId];
}

- (void) respondErrorTo:(NSString*)callbackId withErroCode:(int)code andErrorMessage: (NSString*) msg{
    NSMutableDictionary *obj = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
                                [NSNumber numberWithInt:code], @"error_code", msg, @"error_message", nil];
    
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:obj
                                                       options:0
                                                         error:&error];
    NSString *jsonString = @"";
    if (! jsonData) {
        NSLog(@"Got an error: %@", error);
    } else {
        jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    }
    CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:jsonString];
    [self.commandDelegate sendPluginResult:result callbackId:callbackId];
}

- (UIColor *)colorFromHexString:(NSString *)hexString {
    unsigned rgbValue = 0;
    NSScanner *scanner = [NSScanner scannerWithString:hexString];
    [scanner setScanLocation:1]; // bypass '#' character
    [scanner scanHexInt:&rgbValue];
    return [UIColor colorWithRed:((rgbValue & 0xFF0000) >> 16)/255.0 green:((rgbValue & 0xFF00) >> 8)/255.0 blue:(rgbValue & 0xFF)/255.0 alpha:1.0];
}

@end