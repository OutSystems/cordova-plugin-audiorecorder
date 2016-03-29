//
//  AudioRecorderVC.m
//  OutSystems
//
//  Created by jppg on 15/01/16.
//
//

#import "AudioRecorderVC.h"

typedef NS_ENUM(NSUInteger, OSRecorderState) {
    OS_STATE_NOT_INIT = 0,
    OS_STATE_RECORD = 1,
    OS_STATE_RECORDING = 2,
    OS_STATE_PLAY = 3,
    OS_STATE_PLAYING = 4
};

@interface AudioRecorderVC ()

@property (nonatomic) BOOL isTimed;
@property (nonatomic) OSRecorderState state;
@property (nonatomic, readonly) OSRecorderState previousState;
@property (weak, nonatomic) IBOutlet UILabel *timerLabel;

@property (weak, nonatomic) IBOutlet UIView *playContainerView;
@property (weak, nonatomic) IBOutlet UIView *recordContainerView;
@property (weak, nonatomic) IBOutlet UIButton *recordButton;
@property (weak, nonatomic) IBOutlet UIButton *pcLeftButton;
@property (weak, nonatomic) IBOutlet UIButton *pcMiddleButton;
@property (weak, nonatomic) IBOutlet UIButton *pcRightButton;
@property (weak, nonatomic) IBOutlet UIButton *cancelButton;

//images static
@property (strong, nonatomic) UIImage* stopImage;
@property (strong, nonatomic) UIImage* playImage;
@property (strong, nonatomic) UIImage* micImage;
@property (strong, nonatomic) UIImage* clearImage;
@property (strong, nonatomic) UIImage* doneImage;
@property (strong, nonatomic) UIImage* closeImage;

//images clicked
@property (strong, nonatomic) UIImage* stopImageClicked;
@property (strong, nonatomic) UIImage* playImageClicked;
@property (strong, nonatomic) UIImage* micImageClicked;
@property (strong, nonatomic) UIImage* clearImageClicked;
@property (strong, nonatomic) UIImage* doneImageClicked;
@property (strong, nonatomic) UIImage* closeImageClicked;



@property (strong) UIColor* backgroundColor;
@property (strong) UIColor* viewsColor;

@property (strong, nonatomic) NSTimer* timer;

@end

@implementation AudioRecorderVC

- (void) setState:(OSRecorderState)state {
    _previousState = _state;
    _state = state;
    [self updateViewState];
}

#pragma mark Init

- (id) initWithDuration:(NSNumber*) duration andBackgroundColor:(UIColor*) backgroundColor andViewsColor:(UIColor*) color{
    NSString *path = [[NSBundle mainBundle] pathForResource:@"OSAudioRecorder" ofType:@"bundle"];
    NSBundle *resourcesBundle = [NSBundle bundleWithPath:path];
    self = [super initWithNibName:NSStringFromClass([self class]) bundle:resourcesBundle];
    if (self) {
        self.duration = duration;
        self.isTimed = duration != nil;
        self.backgroundColor = backgroundColor;
        self.viewsColor = color;
        self.state = OS_STATE_NOT_INIT;
        return self;
    }
    return nil;
}

#pragma mark AudioRecorder API

- (void) prepareRecordSession {

    // init AudioSession
    
    NSError* error = nil;
    if (self.avAudioSession == nil) {
        // create audio session
        self.avAudioSession = [AVAudioSession sharedInstance];
        if (error) {
            // return error if can't create recording audio session
            NSLog(@"error creating audio session: %@", [[error userInfo] description]);

            [[self delegate] cancelledRecording:OS_INTERNAL_ERROR];
            [self dismissAudioView:nil];
        }
    }
    
    // Prepare AudioRecorder
    NSString* docsPath = [NSTemporaryDirectory() stringByStandardizingPath];   // use file system temporary directory
    NSError* err = nil;
    NSFileManager* fileMgr = [[NSFileManager alloc] init];
    
    // Create a sub-folder to contain the recordings...
    NSString* containerFolder = @"OSAudioRecordings";
    NSString* containerPath = [NSString stringWithFormat:@"%@/%@", docsPath, containerFolder];

    [fileMgr createDirectoryAtURL:[NSURL fileURLWithPath:containerPath isDirectory:YES] withIntermediateDirectories:NO attributes:nil error: &err];
    
    bool containerExists = [fileMgr fileExistsAtPath:containerPath];
    
    // generate unique file name
    NSString* filePath;
    int i = 1;
    do {
        if(containerExists){
            filePath = [NSString stringWithFormat:@"%@/temp_%03d.mp4", containerPath, i++];
        } else {
            filePath = [NSString stringWithFormat:@"%@/temp_%03d.mp4", docsPath, i++];
        }
    } while ([fileMgr fileExistsAtPath:filePath]);
    
    NSURL* fileURL = [NSURL fileURLWithPath:filePath isDirectory:NO];
    
    // create AVAudioRecorder with AAC encoding
    NSDictionary *recordSetting = [NSDictionary dictionaryWithObjectsAndKeys:
                                   [NSNumber numberWithInt: kAudioFormatMPEG4AAC ], AVFormatIDKey,
                                   [NSNumber numberWithFloat:24000.0], AVSampleRateKey,
                                   [NSNumber numberWithInt:1], AVNumberOfChannelsKey,
                                   nil];
    
    self.avAudioRecorder = [[AVAudioRecorder alloc] initWithURL:fileURL settings:recordSetting error:&err];
    
    
    if (err) {
        NSLog(@"Failed to initialize AVAudioRecorder: %@\n", [err localizedDescription]);
        
        self.avAudioRecorder = nil;
        // Return error
        [[self delegate] cancelledRecording:OS_INTERNAL_ERROR];
        [self dismissAudioView:nil];
        
    } else {
        self.avAudioRecorder.delegate = self;
        [self.avAudioRecorder prepareToRecord];
        self.state = OS_STATE_RECORD;
    }
    
}

- (void) recordAudio {
    if (!self.avAudioRecorder.recording) {
        
        __block NSError* error = nil;
        
        __weak AudioRecorderVC* weakSelf = self;
        
        void (^startRecording)(void) = ^{
            [weakSelf.avAudioSession setCategory:AVAudioSessionCategoryRecord error:&error];
            [weakSelf.avAudioSession setActive:YES error:&error];
            if (error) {
                // Return error
                [[weakSelf delegate] cancelledRecording:OS_INTERNAL_ERROR];
                [weakSelf dismissAudioView:nil];
            } else {
                if (weakSelf.duration) {
                    weakSelf.isTimed = true;
                    [weakSelf.avAudioRecorder recordForDuration:[weakSelf.duration doubleValue]];
                } else {
                    [weakSelf.avAudioRecorder record];
                }
                
                weakSelf.state = OS_STATE_RECORDING;
                weakSelf.timer = [NSTimer scheduledTimerWithTimeInterval:0.5f target:weakSelf selector:@selector(updateTime) userInfo:nil repeats:YES];

            }
        };
        
        SEL rrpSel = NSSelectorFromString(@"requestRecordPermission:");
        if ([self.avAudioSession respondsToSelector:rrpSel])
        {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
            [self.avAudioSession performSelector:rrpSel withObject:^(BOOL granted){
                if (granted) {
                    startRecording();
                } else {
                    NSLog(@"Error creating audio session, microphone permission denied.");
                    // Return error
                    [[weakSelf delegate] cancelledRecording:OS_PERMISSION_DENIED];
                    [weakSelf dismissAudioView:nil];
                }
            }];
#pragma clang diagnostic pop
        } else {
            startRecording();
        }
    }
}

- (void) acceptRecording{
    if(self.state == OS_STATE_PLAYING) {
        [[self avAudioPlayer] stop];
    }
    
    NSString* filepath = [[self.avAudioRecorder url] path];
    NSArray<NSString*>* comps = [filepath componentsSeparatedByString:@"/"];
    NSString* filename = comps[[comps count] - 1];
    [[self delegate] finishedRecordingAudio:filepath filename:filename];
    [self dismissAudioView:nil];
    [self.view removeFromSuperview];
}

- (void) discardRecording {
    // if the AudioPlayer is playing, stop it!
    if(self.state == OS_STATE_PLAYING) {
        [self stopPlay];
    }
    
    if([[self avAudioRecorder] isRecording]) {
        [[self avAudioRecorder] stop];
    }
    // Destroy (muahahah) the AudioPlayer
    if([self avAudioPlayer]) {
        self.avAudioPlayer = nil;
    }
    
    // we can delete the recording because we dont want it anymore...
    [[self avAudioRecorder] deleteRecording];
    
    // reset view to record state
    self.state = OS_STATE_RECORD;
}

- (void) stopRecording {
    [self.avAudioRecorder stop];
    //self.isTimed = NO;  // recording was stopped via button so reset isTimed
}

- (void)audioRecorderDidFinishRecording:(AVAudioRecorder*)recorder successfully:(BOOL)flag
{
    // Using a weak reference so that the callback doesn't reference
    // an object that might already have been released...
    __weak AudioRecorderVC* weakSelf = self;
    
    void (^handleRecordDidFinishRecording)(void) = ^{
    
        NSLog(@"audioRecorderDidFinishRecording");
        [weakSelf.timer invalidate];
        
        if(flag) {
            [weakSelf stopRecordingCleanup];
            
            if(weakSelf.state == OS_STATE_RECORDING){
                weakSelf.state = OS_STATE_PLAY;
            }
        }
            
    };
    
    handleRecordDidFinishRecording();
}

- (void)audioRecorderEncodeErrorDidOccur:(AVAudioRecorder*)recorder error:(NSError*)error
{
    [self.timer invalidate];
    [self stopRecordingCleanup];

    NSLog(@"Error recording audio. %@", [error description]);
    [[self delegate] cancelledRecording:OS_INTERNAL_ERROR];
    [self dismissAudioView:nil];
}

- (void)stopRecordingCleanup
{
    if ([[self avAudioRecorder] isRecording] ) {
        [self.avAudioRecorder stop];
    }

    if ([self avAudioSession]) {
        // deactivate session so sounds can come through
        [self.avAudioSession setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
        [self.avAudioSession setActive:NO error:nil];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}


#pragma mark Audio Player

- (void) playRecordedAudio {
    
    if(![self avAudioPlayer]) {

        self.avAudioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:[self.avAudioRecorder url] error:nil];
        [self.avAudioPlayer setDelegate:self];
    }
    
    if(self.state == OS_STATE_PLAY) {
        // start playing the audio file
        [self.avAudioPlayer play];
        self.state = OS_STATE_PLAYING;
//        [self updateViewState];
    }
}

- (void) audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag {
    if(flag) {
        if(self.state == OS_STATE_PLAYING) {
            self.state = OS_STATE_PLAY;
            //[self updateViewState];
        }
    }
}

- (void) stopPlay {
    [self.avAudioPlayer stop];
    [self.avAudioPlayer setCurrentTime:0];
    if(self.state == OS_STATE_PLAYING) {
        self.state = OS_STATE_PLAY;
    }
}

#pragma mark View

- (void) updateViewState {
    
    if(self.previousState == OS_STATE_RECORD && self.state == OS_STATE_RECORDING) {
        [self.recordButton setImage:self.stopImage forState:UIControlStateNormal];
        [self.recordButton setImage:self.stopImageClicked forState:UIControlStateHighlighted];
    }
    
    if(self.previousState == OS_STATE_RECORDING && self.state == OS_STATE_PLAY) {
        [self.recordContainerView setHidden:YES];
        [self.playContainerView setHidden:NO];
    }

    if(self.previousState == OS_STATE_PLAY && self.state == OS_STATE_RECORD){
        [self.recordContainerView setHidden:NO];
        [self.playContainerView setHidden:YES];
        [self.recordButton setImage:self.micImage forState:UIControlStateNormal];
        [self.timerLabel setText:@"0:00"];
    }
    
    if(self.previousState == OS_STATE_PLAY && self.state == OS_STATE_PLAYING) {
        [self.pcMiddleButton setImage:self.stopImage forState:UIControlStateNormal];
        [self.recordButton setImage:self.stopImageClicked forState:UIControlStateHighlighted];
    }
    
    if(self.previousState == OS_STATE_PLAYING && self.state == OS_STATE_PLAY) {
        [self.pcMiddleButton setImage:self.playImage forState:UIControlStateNormal];
    }
}

- (void)dismissAudioView:(id)sender {
    // Release AVAudioSession when closing the view.

    [self.avAudioSession setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
    [self.avAudioSession setActive:NO error:nil];
    self.avAudioSession = nil;    
    self.state = OS_STATE_NOT_INIT;
}

- (void)viewDidAppear:(BOOL)animatedAppear
{
   [super viewDidAppear:YES];
    self.clearImage = [UIImage imageNamed:@"OSAudioRecorder.bundle/reject"];
    self.doneImage = [UIImage imageNamed:@"OSAudioRecorder.bundle/accept"];
    self.closeImage =  [UIImage imageNamed:@"OSAudioRecorder.bundle/close"];
    //missing play button here
    self.playImage = [UIImage imageNamed:@"OSAudioRecorder.bundle/play_record"];
    self.stopImage = [UIImage imageNamed:@"OSAudioRecorder.bundle/stop_recording"];
    self.micImage = [UIImage imageNamed:@"OSAudioRecorder.bundle/record"];
    
    [self.cancelButton setImage:self.closeImage forState:UIControlStateNormal];
    [self.pcLeftButton setImage:self.clearImage forState:UIControlStateNormal];
    [self.pcMiddleButton setImage:self.playImage forState:UIControlStateNormal];
    [self.pcRightButton setImage:self.doneImage forState:UIControlStateNormal];
    [self.recordButton setImage:self.micImage forState:UIControlStateNormal];
    
    //set for images for clicked
    self.clearImageClicked = [UIImage imageNamed:@"OSAudioRecorder.bundle/reject_pressed"];
    self.doneImageClicked = [UIImage imageNamed:@"OSAudioRecorder.bundle/accept_pressed"];
    self.closeImageClicked =  [UIImage imageNamed:@"OSAudioRecorder.bundle/Close pressed"];
    //missing play button here
    self.playImageClicked = [UIImage imageNamed:@"OSAudioRecorder.bundle/play_record_pressed"];
    self.stopImageClicked = [UIImage imageNamed:@"OSAudioRecorder.bundle/Stop Recording pressed"];
    self.micImageClicked = [UIImage imageNamed:@"OSAudioRecorder.bundle/Record pressed"];
    
    
    //set the state
    [self.cancelButton setImage:self.closeImageClicked forState:UIControlStateHighlighted];
    [self.pcLeftButton setImage:self.clearImageClicked forState:UIControlStateHighlighted];
    [self.pcMiddleButton setImage:self.playImageClicked forState:UIControlStateHighlighted];
    [self.pcRightButton setImage:self.doneImageClicked forState:UIControlStateHighlighted];
    [self.recordButton setImage:self.micImageClicked forState:UIControlStateHighlighted];
}

- (void)viewDidLoad {

    [self.timerLabel setText:@"0:00"];

    
    
    [self.timerLabel  setTextColor:self.viewsColor];
    [self.cancelButton setTintColor:self.viewsColor];
    [self.pcLeftButton setTintColor:self.viewsColor];
    [self.pcMiddleButton setTintColor:self.viewsColor];
    [self.pcRightButton setTintColor:self.viewsColor];
    [self.recordButton setTintColor:self.viewsColor];
    
    [self.playContainerView setBackgroundColor:self.backgroundColor];
    [self.recordContainerView setBackgroundColor:self.backgroundColor];
    
    if(self.state == OS_STATE_NOT_INIT) {
        [self prepareRecordSession];
    }
    [super viewDidLoad];
    [self viewDidAppear:YES];
}

- (void)updateTime
{
    [self.timerLabel setText:[self formatTime:self.avAudioRecorder.currentTime]];
}

- (NSString*)formatTime:(int)interval
{
    int secs = interval % 60;
    int min = interval / 60;
    
    if (interval < 60) {
        return [NSString stringWithFormat:@"0:%02d", interval];
    } else {
        return [NSString stringWithFormat:@"%d:%02d", min, secs];
    }
}

#pragma mark button callbacks

- (IBAction)recordButtonTouched:(id)sender {
    
    if (self.avAudioRecorder.recording) {
        [self stopRecording];
    } else {
        // begin recording
        [self recordAudio];
    }
    
    //[self updateViewState];
}

- (IBAction)cancelButtonTouched:(id)sender {
    NSLog(@"cancel button touched");
    //[self discardRecording];
    
    if([[self avAudioRecorder] isRecording]) {
        [[self avAudioRecorder] stop];
    }
    // Destroy (muahahah) the AudioPlayer
    if([self avAudioPlayer]) {
        self.avAudioPlayer = nil;
    }
    
    // If we call deleteRecording from here and the user does:
    // Record -> stop -> discard -> cancel
    // we get a nasty fatal error...
    // [[self avAudioRecorder] deleteRecording];
    
    [self dismissAudioView:nil];
    // Return error
    [[self delegate] cancelledRecording:OS_USER_CANCELLED];
    NSLog(@"remove from super view");
    [self.view removeFromSuperview];
}

- (IBAction)discardButtonTouched:(id)sender {
    // Discard the recorded file
        NSLog(@"discard button touched");
    [self discardRecording];
}

- (IBAction)acceptButtonTouched:(id)sender {
    // Accept the recorded file
    [self acceptRecording];
}

- (IBAction)playButtonTouched:(id)sender {
    // Play/Stop Sound
    if([self.avAudioPlayer isPlaying]) {
        [self stopPlay];
    } else {
        [self playRecordedAudio];
    }

}
@end

