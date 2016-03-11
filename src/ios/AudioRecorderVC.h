//
//  AudioRecorderVC.h
//  OutSystems
//
//  Created by jppg on 15/01/16.
//
//

#import <AVFoundation/AVFoundation.h>

typedef NS_ENUM(NSUInteger, OSCancelReason) {
    OS_USER_CANCELLED = 1,
    OS_INTERNAL_ERROR = 2,
    OS_INVALID_ARGS = 3,
    OS_PERMISSION_DENIED = 50
};

@protocol OSAudioRecorderDelegate <NSObject>
@required

- (void) finishedRecordingAudio:(NSString*) filePath filename:(NSString*) filename;
- (void) cancelledRecording:(OSCancelReason) reason;

@end

@interface AudioRecorderVC : UIViewController <AVAudioRecorderDelegate, AVAudioPlayerDelegate>


@property (nonatomic, weak) id<OSAudioRecorderDelegate> delegate;

@property (nonatomic, strong) AVAudioRecorder *avAudioRecorder;
@property (nonatomic, strong) AVAudioPlayer *avAudioPlayer;
@property (nonatomic, strong) AVAudioSession *avAudioSession;
@property (nonatomic, strong) NSNumber* duration;

- (id) initWithDuration:(NSNumber*) duration andBackgroundColor:(UIColor*) backgroundColor andViewsColor:(UIColor*) color;
- (void) prepareRecordSession;
- (void) recordAudio;
@end
