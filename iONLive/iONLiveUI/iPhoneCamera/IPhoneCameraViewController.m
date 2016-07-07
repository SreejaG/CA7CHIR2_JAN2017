//
//  IPhoneCameraViewController.m
//  iONLive
//
//  Created by Vinitha on 1/18/16.
//  Copyright © 2016 Gadgeon. All rights reserved.
//
@import AVFoundation;
@import Photos;
@class AppDelegate;

#import <UIKit/UIKit.h>
#import "IPhoneCameraViewController.h"
#import "AAPLPreviewView.h"
#import "CA7CH-Swift.h"
#import "VCSimpleSession.h"
#import <MediaPlayer/MediaPlayer.h>
#import <AVFoundation/AVFoundation.h>
#import <AVFoundation/AVAsset.h>
#import <CoreMedia/CoreMedia.h>
#import <QuartzCore/QuartzCore.h>
#import "screencap.h"


static void * CapturingStillImageContext = &CapturingStillImageContext;
static void * SessionRunningContext = &SessionRunningContext;

NSString* selectedFlashOption = @"selectedFlashOption";
int thumbnailSize = 50;
int deleteCount = 0;
int flashFlag = 0;

typedef NS_ENUM( NSInteger, AVCamSetupResult ) {
    AVCamSetupResultSuccess,
    AVCamSetupResultCameraNotAuthorized,
    AVCamSetupResultSessionConfigurationFailed
};

@interface IPhoneCameraViewController ()<AVCaptureFileOutputRecordingDelegate , StreamingProtocol,  VCSessionDelegate, NSURLSessionDelegate,NSURLSessionTaskDelegate,NSURLSessionDataDelegate>

{
    SnapCamSelectionMode _snapCamMode;
    
}

//Video Core Session
@property (nonatomic, retain) VCSimpleSession* liveSteamSession;

// For use in the storyboards.
@property (nonatomic, weak) IBOutlet AAPLPreviewView *previewView;
@property (nonatomic, weak) IBOutlet UIButton *cameraButton;
@property (nonatomic, weak) IBOutlet UIButton *startCameraActionButton;
@property (weak, nonatomic) IBOutlet UIImageView *thumbnailImageView;
@property (weak, nonatomic) IBOutlet UIButton *flashButton;

// Session management.
@property (nonatomic) dispatch_queue_t sessionQueue;
@property (nonatomic) AVCaptureSession *session;
@property (nonatomic) AVCaptureDeviceInput *videoDeviceInput;
@property (nonatomic) AVCaptureMovieFileOutput *movieFileOutput;
@property (nonatomic) AVCaptureStillImageOutput *stillImageOutput;

@property (strong, nonatomic) IBOutlet UIView *topView;

// Utilities.
@property (nonatomic) AVCamSetupResult setupResult;
@property (nonatomic, getter=isSessionRunning) BOOL sessionRunning;
@property (nonatomic) UIBackgroundTaskIdentifier backgroundRecordingID;
@property (strong, nonatomic) IBOutlet UIView *bottomView;

//Flash settings
@property (nonatomic) AVCaptureFlashMode currentFlashMode;

@property (strong, nonatomic) IBOutlet UIImageView *activityImageView;
@property (strong, nonatomic) IBOutlet UILabel *noDataFound;
@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *_activityIndicatorView;
@property (strong, nonatomic) IBOutlet UIView *activitView;
@property (strong, nonatomic) IBOutlet UIButton *iphoneCameraButton;

@property (strong, nonatomic) IBOutlet UIButton *firstButton;
@property (strong, nonatomic) IBOutlet UIButton *secondButton;
@property (strong, nonatomic) IBOutlet UIButton *thirdButton;

@end

int orientationFlag = 0;

@implementation IPhoneCameraViewController

IPhoneLiveStreaming * liveStreaming;
FileManagerViewController *fileManager;
int cameraChangeFlag = 0;
NSInteger shutterActionMode;
bool takePictureFlag = false;

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self addApplicationObserversInIphone];
    
    //device orientation
    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    [[NSNotificationCenter defaultCenter]
     addObserver:self selector:@selector(orientationChanged:)
     name:UIDeviceOrientationDidChangeNotification
     object:[UIDevice currentDevice]];
    //end
    
    self.navigationController.navigationBarHidden = true;
    [self.topView setBackgroundColor:[[UIColor blackColor] colorWithAlphaComponent:0.4]];
    [self deleteIphoneCameraSnapShots];
}

- (void) orientationChanged:(NSNotification *)note
{
    UIDevice *device = note.object;
    switch(device.orientation)
    {
        case UIDeviceOrientationPortrait:
            orientationFlag = 1;
            NSLog(@"Portrait,flag: %d",orientationFlag);
            break;
            
        case UIDeviceOrientationPortraitUpsideDown:
            orientationFlag = 2;
            NSLog(@"PortraitUpsideDown,flag: %d",orientationFlag);
            break;
            
        case UIDeviceOrientationLandscapeLeft:
            orientationFlag = 3;
            NSLog(@"LandscapeLeft,flag: %d",orientationFlag);
            break;
            
        case UIDeviceOrientationLandscapeRight:
            orientationFlag = 4;
            NSLog(@"LandscapeRight,flag: %d",orientationFlag);
            break;
            
        default:
            orientationFlag = 0;
            NSLog(@"Device Orientation Unknown,flag: %d",orientationFlag);
            break;
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loadInitialView) name:@"refreshLogin" object:nil];
       
    [self loadingView];
    dispatch_async( dispatch_get_main_queue(), ^{
        
        [_startCameraActionButton setImage:[UIImage imageNamed:@"Camera_Button_OFF"] forState:UIControlStateNormal];
        [_startCameraActionButton setImage:[UIImage imageNamed:@"camera_Button_ON"] forState:UIControlStateHighlighted];
    });
    [self initialise];
}

-(void)addApplicationObserversInIphone
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationDidEnterBackgrounds:)
                                                 name:UIApplicationDidEnterBackgroundNotification
                                               object:nil];
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationDidActives:)
                                                 name:UIApplicationDidBecomeActiveNotification
                                               object:nil];
}

-(void)applicationDidEnterBackgrounds: (NSNotification *)notification
{
    UIViewController *viewContr = self.navigationController.visibleViewController;
    if([viewContr.restorationIdentifier  isEqual: @"IPhoneCameraViewController"])
    {
    
        [self loadingView];
        if (shutterActionMode == SnapCamSelectionModeVideo)
        {
            dispatch_async( dispatch_get_main_queue(), ^{
                if ([self.videoDeviceInput.device hasFlash]&&[self.videoDeviceInput.device hasTorch]) {
                    if (self.videoDeviceInput.device.torchMode == AVCaptureTorchModeOff) {
                    }else {
                        [self.videoDeviceInput.device lockForConfiguration:nil];
                        [self.videoDeviceInput.device setTorchMode:AVCaptureTorchModeOff];
                        [self.videoDeviceInput.device unlockForConfiguration];
                    }
                }
                _cameraButton.hidden = false;
                if(flashFlag == 0){
                    _flashButton.hidden = false;
                }
                else if(flashFlag == 1){
                    _flashButton.hidden = true;
                }
                
                [_startCameraActionButton setImage:[UIImage imageNamed:@"Camera_Button_OFF"] forState:UIControlStateNormal];
            
          
                [self.previewView.session stopRunning];
            
            });
            [self.movieFileOutput stopRecording];
        }
        else if(shutterActionMode == SnapCamSelectionModeLiveStream){
            [liveStreaming stopStreamingClicked];
            [_liveSteamSession.previewView removeFromSuperview];
            _liveSteamSession.delegate = nil;
            [[NSUserDefaults standardUserDefaults] setValue:false forKey:@"StartedStreaming"];
            [_iphoneCameraButton setImage:[UIImage imageNamed:@"iphone"] forState:UIControlStateNormal];
            
        }
    }
}

-(void)applicationDidActives: (NSNotification *)notification
{
    UIViewController *viewContr = self.navigationController.visibleViewController;
    if([viewContr.restorationIdentifier  isEqual: @"IPhoneCameraViewController"])
    {
        [self setGUIBasedOnMode];
        dispatch_async( dispatch_get_main_queue(), ^{
        
            [_startCameraActionButton setImage:[UIImage imageNamed:@"Camera_Button_OFF"] forState:UIControlStateNormal];
            [_startCameraActionButton setImage:[UIImage imageNamed:@"camera_Button_ON"] forState:UIControlStateHighlighted];
        });
        if(shutterActionMode == SnapCamSelectionModeLiveStream){
//         
//                        [_liveSteamSession.previewView removeFromSuperview];
//                        _liveSteamSession.delegate = nil;
            
        }
    }
    
}

-(void) loadInitialView
{
      dispatch_async( dispatch_get_main_queue(), ^{
          NSURL *documentsPath  = [[FileManagerViewController sharedInstance] getParentDirectoryPath];
          NSString *path = documentsPath.absoluteString;
          
          if([[NSFileManager defaultManager] fileExistsAtPath:path]){
              [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
          }
          [[FileManagerViewController sharedInstance] createParentDirectory];
          NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
          NSString *accessToken = [defaults valueForKey:@"deviceToken"];
          NSString *iden = [[NSBundle mainBundle] bundleIdentifier];
          [defaults removePersistentDomainForName:iden];
          [defaults setValue:accessToken forKey:@"deviceToken"];
          [defaults setInteger:1 forKey:@"shutterActionMode"];
          UIStoryboard  *login = [UIStoryboard storyboardWithName:@"Authentication" bundle:nil];
          UIViewController *authenticate = [login instantiateViewControllerWithIdentifier:@"AuthenticateNavigationController"];
          authenticate.navigationController.navigationBarHidden = true;
          [[self navigationController] presentViewController:authenticate animated:false completion:^{
              [[ErrorManager sharedInstance] tockenExpired];
          }];
      });
}

-(void) initialise{
    shutterActionMode = [[NSUserDefaults standardUserDefaults] integerForKey:@"shutterActionMode"];
    [self setButtonCornerRadius];
    [self checkCountForLabel];
    [self setGUIBasedOnMode];
    [self setGUIModifications];
    fileManager = [[FileManagerViewController alloc]init];
    liveStreaming = [[IPhoneLiveStreaming alloc]init];
    PhotoViewerInstance.iphoneCam = self;
    SetUpView *viewSet = [[SetUpView alloc]init];
    [viewSet getValue];
}

-(void)loadingView
{
    dispatch_async( dispatch_get_main_queue(), ^{
        self.activitView.hidden =false;
        self.startCameraActionButton.enabled = false;
        _activityImageView.image =  [UIImage animatedImageNamed:@"loader-" duration:1.0f];
        _activityImageView.hidden = false;
        [__activityIndicatorView startAnimating];
        __activityIndicatorView.hidden = false;
        _noDataFound.text = @"Loading Camera...";
        _noDataFound.hidden = false;
    });
}

-(void)hidingView
{
    dispatch_async( dispatch_get_main_queue(), ^{
        self.activitView.hidden = true;
        self.startCameraActionButton.enabled = true;
        _activityImageView.hidden = true;
        [__activityIndicatorView stopAnimating];
        __activityIndicatorView.hidden = true;
        _noDataFound.text = @"";
        _noDataFound.hidden = true;
    });
}

-(void) setButtonCornerRadius{
    _firstButton.imageView.layer.cornerRadius = _firstButton.frame.size.width/2;
    _firstButton.layer.cornerRadius = _firstButton.frame.size.width/2;
    _firstButton.layer.masksToBounds = YES;
    _secondButton.imageView.layer.cornerRadius = _firstButton.frame.size.width/2;
    _secondButton.layer.cornerRadius = _firstButton.frame.size.width/2;
    _secondButton.layer.masksToBounds = YES;
    _thirdButton.imageView.layer.cornerRadius = _firstButton.frame.size.width/2;
    _thirdButton.layer.cornerRadius = _firstButton.frame.size.width/2;
    _thirdButton.layer.masksToBounds = YES;
    _countLabel.layer.cornerRadius = 5;
    _countLabel.layer.masksToBounds = true;
}

-(void) setGUIModifications{
   
    
    _currentFlashMode = [[NSUserDefaults standardUserDefaults] integerForKey:@"flashMode"];
    if(_currentFlashMode == 0){
        [self.flashButton setImage:[UIImage imageNamed:@"flash_off"] forState:UIControlStateNormal];
    }
    else if(_currentFlashMode == 1){
        [self.flashButton setImage:[UIImage imageNamed:@"flash_On"] forState:UIControlStateNormal];
    }
     _snapCamMode = SnapCamSelectionModeiPhone;
    flashFlag = 0;
    _activitView.hidden = YES;
    _playiIconView.hidden = YES;
}

-(void) checkCountForLabel
{
    NSArray *mediaArray = [[NSUserDefaults standardUserDefaults] objectForKey:@"Shared"];
    if([mediaArray count] <= 0)
    {
        [[NSUserDefaults standardUserDefaults] setObject:@"FirstEntry" forKey:@"First"];
    }
    NSInteger count = 0;
    for (int i=0;i< mediaArray.count;i++)
    {
        count = count + [ mediaArray[i][@"total_no_media_shared"] integerValue];
    }
    if(count==0)
    {
        _countLabel.hidden= true;
    }
    else
    {
        _countLabel.hidden= false;
        _countLabel.text = [NSString stringWithFormat:@"%ld",(long)count];
    }
}

-(BOOL) isStreamStarted
{
    NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
    return [defaults boolForKey:@"StartedStreaming"];
}

-(void)configureCameraSettings
{
    self.sessionQueue = dispatch_queue_create( "session queue", DISPATCH_QUEUE_SERIAL );
    self.setupResult = AVCamSetupResultSuccess;
    switch ( [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo] )
    {
        case AVAuthorizationStatusAuthorized:
        {
            break;
        }
        case AVAuthorizationStatusNotDetermined:
        {
            dispatch_suspend( self.sessionQueue);
            [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^( BOOL granted ) {
                if ( ! granted ) {
                    self.setupResult = AVCamSetupResultCameraNotAuthorized;
                }
                dispatch_resume( self.sessionQueue );
            }];
            break;
        }
        default:
        {
            self.setupResult = AVCamSetupResultCameraNotAuthorized;
            break;
        }
    }
    
    dispatch_async( self.sessionQueue, ^{
        if ( self.setupResult != AVCamSetupResultSuccess ) {
            return;
        }
        
        self.backgroundRecordingID = UIBackgroundTaskInvalid;
        NSError *error = nil;
        
        AVCaptureDevice *videoDevice = [IPhoneCameraViewController deviceWithMediaType:AVMediaTypeVideo preferringPosition:AVCaptureDevicePositionBack];
        AVCaptureDeviceInput *videoDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:videoDevice error:&error];
        
        if ( ! videoDeviceInput ) {
            NSLog( @"Could not create video device input: %@", error );
        }
        
        [self.session beginConfiguration];
        
        
        if ( [self.session canAddInput:videoDeviceInput] ) {
            [self.session addInput:videoDeviceInput];
            self.videoDeviceInput = videoDeviceInput;
            
            dispatch_async( dispatch_get_main_queue(), ^{
                UIInterfaceOrientation statusBarOrientation = [UIApplication sharedApplication].statusBarOrientation;
                AVCaptureVideoOrientation initialVideoOrientation = AVCaptureVideoOrientationPortrait;
                if ( statusBarOrientation != UIInterfaceOrientationUnknown ) {
                    initialVideoOrientation = (AVCaptureVideoOrientation)statusBarOrientation;
                }
                AVCaptureVideoPreviewLayer *previewLayer = (AVCaptureVideoPreviewLayer *)self.previewView.layer;
                previewLayer.connection.videoOrientation = initialVideoOrientation;
            } );
        }
        else {
            self.setupResult = AVCamSetupResultSessionConfigurationFailed;
        }
        
        AVCaptureDevice *audioDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
        AVCaptureDeviceInput *audioDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:audioDevice error:&error];
        
        if ( ! audioDeviceInput ) {
        }
        
        if ( [self.session canAddInput:audioDeviceInput] ) {
            [self.session addInput:audioDeviceInput];
        }
        else {
            NSLog( @"Could not add audio device input to the session" );
        }
        
        AVCaptureMovieFileOutput *movieFileOutput = [[AVCaptureMovieFileOutput alloc] init];
        if ( [self.session canAddOutput:movieFileOutput] ) {
            [self.session addOutput:movieFileOutput];
            AVCaptureConnection *connection = [movieFileOutput connectionWithMediaType:AVMediaTypeVideo];
            if ( connection.isVideoStabilizationSupported ) {
                connection.preferredVideoStabilizationMode = AVCaptureVideoStabilizationModeAuto;
            }
            self.movieFileOutput = movieFileOutput;
        }
        else {
            NSLog( @"Could not add movie file output to the session" );
            self.setupResult = AVCamSetupResultSessionConfigurationFailed;
        }
        
        AVCaptureStillImageOutput *stillImageOutput = [[AVCaptureStillImageOutput alloc] init];
        if ( [self.session canAddOutput:stillImageOutput] ) {
            stillImageOutput.outputSettings = @{AVVideoCodecKey : AVVideoCodecJPEG};
            [self.session addOutput:stillImageOutput];
            self.stillImageOutput = stillImageOutput;
        }
        else {
            NSLog( @"Could not add still image output to the session" );
            self.setupResult = AVCamSetupResultSessionConfigurationFailed;
        }
        
        [self.session commitConfiguration];
    } );
}

-(void) setGUIBasedOnMode{
    if (![self isStreamStarted]) {
       
        if (shutterActionMode == SnapCamSelectionModeLiveStream)
        {
            _flashButton.hidden = true;
            _cameraButton.hidden = true;
            _liveSteamSession = [[VCSimpleSession alloc] initWithVideoSize:[[UIScreen mainScreen]bounds].size frameRate:30 bitrate:1000000 useInterfaceOrientation:YES];
            [_liveSteamSession.previewView removeFromSuperview];
            AVCaptureVideoPreviewLayer  *ptr;
            [_liveSteamSession getCameraPreviewLayer:(&ptr)];
            _liveSteamSession.previewView.frame = self.view.bounds;
            _liveSteamSession.delegate = self;
        }
        else{
            [_liveSteamSession.previewView removeFromSuperview];
            _liveSteamSession.delegate = nil;
            [self removeObservers];
            self.session = [[AVCaptureSession alloc] init];
            self.previewView.hidden = false;
            self.previewView.session = self.session;
            [self configureCameraSettings];
            
            dispatch_async( self.sessionQueue, ^{
                switch ( self.setupResult )
                {
                    case AVCamSetupResultSuccess:
                    {
                        [self addObservers];
                        [self.session startRunning];
                        
                        self.sessionRunning = self.session.isRunning;
                        [self hidingView];
                        break;
                    }
                    case AVCamSetupResultCameraNotAuthorized:
                    {
                        dispatch_async( dispatch_get_main_queue(), ^{
                            NSString *message = NSLocalizedString( @"CA7CH doesn't have permission to use the camera, please change privacy settings", @"Alert message when the user has denied access to the camera");
                            UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"AVCam" message:message preferredStyle:UIAlertControllerStyleAlert];
                            UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString( @"OK", @"Alert OK button" ) style:UIAlertActionStyleCancel handler:nil];
                            [alertController addAction:cancelAction];
                            
                            UIAlertAction *settingsAction = [UIAlertAction actionWithTitle:NSLocalizedString( @"Settings", @"Alert button to open Settings" ) style:UIAlertActionStyleDefault handler:^( UIAlertAction *action ) {
                                [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
                            }];
                            [alertController addAction:settingsAction];
                            [self presentViewController:alertController animated:YES completion:nil];
                        } );
                        break;
                    }
                    case AVCamSetupResultSessionConfigurationFailed:
                    {
                        dispatch_async( dispatch_get_main_queue(), ^{
                            NSString *message = NSLocalizedString( @"Unable to capture media", @"Alert message when something goes wrong during capture session configuration" );
                            UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"CA7CH" message:message preferredStyle:UIAlertControllerStyleAlert];
                            UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString( @"OK", @"Alert OK button" ) style:UIAlertActionStyleCancel handler:nil];
                            [alertController addAction:cancelAction];
                            [self presentViewController:alertController animated:YES completion:nil];
                        } );
                        break;
                    }
                }
            });
        }
    }
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    if (self.videoDeviceInput.device.torchMode == AVCaptureTorchModeOff) {
        
    }else {
        [self.videoDeviceInput.device lockForConfiguration:nil];
        [self.videoDeviceInput.device setTorchMode:AVCaptureTorchModeOff];
        [self.videoDeviceInput.device unlockForConfiguration];
    }
//    [self removeObservers];
}

-(void) loggedInDetails:(NSDictionary *) detailArray userImages : (NSArray *) userImages{
    NSString * sharedUserCount = detailArray[@"sharedUserCount"];
    NSString * mediaSharedCount =  detailArray[@"mediaSharedCount"];
    NSString * latestSharedMediaThumbnail =   detailArray[@"latestSharedMediaThumbnail"];
    NSString * latestCapturedMediaThumbnail =detailArray[@"latestCapturedMediaThumbnail"];
    NSString *latestSharedMediaType =   detailArray[@"latestSharedMediaType"];
    NSString *latestCapturedMediaType  =  detailArray[@"latestCapturedMediaType"];
    
    [[NSUserDefaults standardUserDefaults] setObject:mediaSharedCount forKey:@"mediaSharedCount"] ;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        _sharedUserCount.text = sharedUserCount;
    //    NSLog(@"%@",userImages);
        if(userImages.count > 0){
            for(int i=0;i<userImages.count;i++){
                if(i==0){
                    if(userImages[0] != nil){
                        [_firstButton setImage:userImages[0] forState:UIControlStateNormal];
                    }
                    else{
                        [_firstButton setImage:[UIImage imageNamed:@"dummyUser"] forState:UIControlStateNormal];
                    }
                }
                else if(i==1){
                    if(userImages[1] != nil){
                        [_secondButton setImage:userImages[1] forState:UIControlStateNormal];
                    }
                    else{
                        [_secondButton setImage:[UIImage imageNamed:@"dummyUser"] forState:UIControlStateNormal];
                    }
                }
                else if(i==2){
                    if(userImages[2] != nil){
                        [_thirdButton setImage:userImages[2] forState:UIControlStateNormal];
                    }
                    else{
                        [_thirdButton setImage:[UIImage imageNamed:@"dummyUser"] forState:UIControlStateNormal];
                    }
                }
            }
        }
    });
    
    if(takePictureFlag == false){
        dispatch_async(dispatch_get_global_queue(0,0), ^{
            NSData * data = [[NSData alloc] initWithContentsOfURL: [NSURL URLWithString: latestCapturedMediaThumbnail]];
            if ( data == nil )
                return;
            dispatch_async(dispatch_get_main_queue(), ^{
                if([latestCapturedMediaType  isEqual: @"video"])
                {
                    self.playiIconView.hidden = false;
                }
                self.thumbnailImageView.image= [UIImage imageWithData: data];
            });
        });
    }
    
    if([mediaSharedCount  isEqual: @"0"])
    {
        dispatch_async(dispatch_get_global_queue(0,0), ^{
            NSData * data = [[NSData alloc] initWithContentsOfURL: [NSURL URLWithString: latestSharedMediaThumbnail]];
            if ( data == nil )
                return;
            dispatch_async(dispatch_get_main_queue(), ^{
                if([latestSharedMediaType  isEqual: @"video"])
                {
                    self.playiIconView.hidden = false;
                }
                self.latestSharedMediaImage.image= [UIImage imageWithData: data];
            });
        });
    }
    else{
        NSString *status = [[NSUserDefaults standardUserDefaults] objectForKey:@"First"];
        if([status isEqualToString:@"FirstEntry"])
        {
            _countLabel.hidden= false;
            _countLabel.text = mediaSharedCount;
            [[NSUserDefaults standardUserDefaults] setObject:@"default" forKey:@"First"] ;
        }
        NSArray *mediaArray = [[NSUserDefaults standardUserDefaults] objectForKey:@"Shared"];
        NSInteger count = 0;
        for (int i=0;i< mediaArray.count;i++)
        {
            count = count + [ mediaArray[i][@"total_no_media_shared"] integerValue];
        }
        if(count==0)
        {
             _countLabel.hidden= true;
            [self.view bringSubviewToFront:self.latestSharedMediaImage];
            dispatch_async(dispatch_get_global_queue(0,0), ^{
                NSData * data = [[NSData alloc] initWithContentsOfURL: [NSURL URLWithString: latestSharedMediaThumbnail]];
                if ( data == nil )
                    return;
                dispatch_async(dispatch_get_main_queue(), ^{
                    if([latestSharedMediaType  isEqual: @"video"])
                    {
                        self.playiIconView.hidden = false;
                    }
                    self.latestSharedMediaImage.image = [UIImage imageWithData: data];
                });
            });
        }
    }
}

#pragma mark button action

- (IBAction)didTapChangeCamera:(id)sender
{
    [UIView transitionWithView:_previewView duration:0.5 options:UIViewAnimationOptionTransitionFlipFromLeft animations:nil completion:^(BOOL finished) {
    }];
    dispatch_async( self.sessionQueue, ^{
        AVCaptureDevice *currentVideoDevice = self.videoDeviceInput.device;
        AVCaptureDevicePosition preferredPosition = AVCaptureDevicePositionUnspecified;
        AVCaptureDevicePosition currentPosition = currentVideoDevice.position;
        
        switch ( currentPosition )
        {
            case AVCaptureDevicePositionUnspecified:
            case AVCaptureDevicePositionFront:
                preferredPosition = AVCaptureDevicePositionBack;
                [self showFlashImage:true];
                break;
            case AVCaptureDevicePositionBack:
                preferredPosition = AVCaptureDevicePositionFront;
                [self showFlashImage:false];
                break;
        }
        
        AVCaptureDevice *videoDevice = [IPhoneCameraViewController deviceWithMediaType:AVMediaTypeVideo preferringPosition:preferredPosition];
        AVCaptureDeviceInput *videoDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:videoDevice error:nil];
        [self.session beginConfiguration];
        [self.session removeInput:self.videoDeviceInput];
        
        if ( [self.session canAddInput:videoDeviceInput] ) {
            [[NSNotificationCenter defaultCenter] removeObserver:self name:AVCaptureDeviceSubjectAreaDidChangeNotification object:currentVideoDevice];
            
            [IPhoneCameraViewController setFlashMode:self.currentFlashMode forDevice:videoDevice];
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(subjectAreaDidChange:) name:AVCaptureDeviceSubjectAreaDidChangeNotification object:videoDevice];
            
            [self.session addInput:videoDeviceInput];
            self.videoDeviceInput = videoDeviceInput;
        }
        else {
            [self.session addInput:self.videoDeviceInput];
        }
        
        AVCaptureConnection *connection = [self.movieFileOutput connectionWithMediaType:AVMediaTypeVideo];
        if ( connection.isVideoStabilizationSupported ) {
            connection.preferredVideoStabilizationMode = AVCaptureVideoStabilizationModeAuto;
        }
        [self.session commitConfiguration];
    } );
}

-(void)showFlashImage:(BOOL)show
{
    if (show) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.flashButton.hidden = false;
            flashFlag = 0;
        });
    }
    else
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.flashButton.hidden = true;
            flashFlag = 1;
        });
    }
}

- (IBAction)didTapFlashImage:(id)sender {
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if (_currentFlashMode == AVCaptureFlashModeOn) {
        [self.flashButton setImage:[UIImage imageNamed:@"flash_off"] forState:UIControlStateNormal];
        _currentFlashMode = AVCaptureFlashModeOff;
        [defaults setInteger:_currentFlashMode forKey:@"flashMode"];
    }
    else{
        [self.flashButton setImage:[UIImage imageNamed:@"flash_On"] forState:UIControlStateNormal];
        _currentFlashMode = AVCaptureFlashModeOn;
        [defaults setInteger:_currentFlashMode forKey:@"flashMode"];
    }
}

- (IBAction)didTapsCameraActionButton:(id)sender
{
    if (shutterActionMode == SnapCamSelectionModePhotos) {
        dispatch_async(dispatch_get_main_queue(), ^{
            _cameraButton.hidden = false;
            _playiIconView.hidden = true;
            if(_flashButton.isHidden) {
                _flashButton.hidden = true;
            }
            else{
                _flashButton.hidden = false;
            }
        });
        [self takePicture];
    }
    else if (shutterActionMode == SnapCamSelectionModeVideo)
    {
        [self startMovieRecording];
    }
    else if (shutterActionMode == SnapCamSelectionModeLiveStream)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            _flashButton.hidden = true;
            _cameraButton.hidden = true;
        });
        
        switch(_liveSteamSession.rtmpSessionState) {
            case VCSessionStateNone:
            case VCSessionStatePreviewStarted:
            case VCSessionStateEnded:
            case VCSessionStateError:
            {
                [liveStreaming startLiveStreaming:_liveSteamSession];
                [self showProgressBar];
                break;
            }
            default:
                [UIApplication sharedApplication].idleTimerDisabled = NO;
                [liveStreaming stopStreamingClicked];
                [_liveSteamSession endRtmpSession];
                break;
        }
    }
}


#pragma mark take photo

-(void)takePicture
{
    dispatch_async( self.sessionQueue, ^{
        AVCaptureConnection *connection = [self.stillImageOutput connectionWithMediaType:AVMediaTypeVideo];
        AVCaptureVideoPreviewLayer *previewLayer = (AVCaptureVideoPreviewLayer *)self.previewView.layer;
        connection.videoOrientation = previewLayer.connection.videoOrientation;
        
        UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
        
        if(orientationFlag == 1) //Default Orientation (portrait mode)
        {
            if(orientation ==1) //Checking device orientation as per status bar position
            {
        
            }
        }
        else
        {
            if(orientationFlag == 3) //Device Orientation LandscapeLeft
            {
                connection.videoOrientation = UIImageOrientationRight;
            }
            if(orientationFlag == 4) //Device Orientation LandscapeRight
            {
                connection.videoOrientation = UIImageOrientationUpMirrored;
            }
            if (orientationFlag == 2) //Device Orientation Portrait upside down
            {
                connection.videoOrientation = UIImageOrientationUpMirrored;
                connection.videoOrientation = UIImageOrientationLeft;
            }
        }
        
        [IPhoneCameraViewController setFlashMode:self.currentFlashMode forDevice:self.videoDeviceInput.device];
        [self.stillImageOutput captureStillImageAsynchronouslyFromConnection:connection completionHandler:^( CMSampleBufferRef imageDataSampleBuffer, NSError *error ) {
            if ( imageDataSampleBuffer ) {
                NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
                [PHPhotoLibrary requestAuthorization:^( PHAuthorizationStatus status ) {
                    if (status == PHAuthorizationStatusAuthorized ) {
                        dispatch_async( dispatch_get_main_queue(), ^{
                            self.thumbnailImageView.image = [self thumbnaleImage:[UIImage imageWithData:imageData] scaledToFillSize:CGSizeMake(thumbnailSize, thumbnailSize)];
                            takePictureFlag = true;
                            UIImageWriteToSavedPhotosAlbum([UIImage imageWithData:imageData], nil, nil, nil);
                            [self saveImage:imageData];
                            [self loaduploadManagerForImage];
                        });
                    }
                }];
            }
            else {
               
            }
        }];
    });
}

#pragma mark save image to db

-(void)saveImage:(NSData *)imageData
{
    NSArray *paths= NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths firstObject];
    NSString *filePath=@"";
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"dd_MM_yyyy_HH_mm_ss"];
    NSString *dateString = [dateFormatter stringFromDate:[NSDate date]];
    filePath = [documentsDirectory stringByAppendingPathComponent:dateString];
    [imageData writeToFile:filePath atomically:YES];
    [self saveIphoneCameraSnapShots:dateString path:filePath];
}

-(void) saveIphoneCameraSnapShots :(NSString *)imageName path:(NSString *)path{
    AppDelegate *appDel = [[UIApplication sharedApplication]delegate];
    NSManagedObjectContext *context = appDel.managedObjectContext;
    NSManagedObject *newSnapShots =[NSEntityDescription insertNewObjectForEntityForName:@"SnapShots" inManagedObjectContext:context];
    [newSnapShots setValue:imageName forKey:@"imageName"];
    [newSnapShots setValue:path forKey:@"path"];
    [context save:nil];
}

-(void) loaduploadManagerForImage
{
    NSString *path = [self readIphoneCameraSnapShotsFromDB];
    uploadMediaToGCS *obj = [[uploadMediaToGCS alloc]init];
    obj.path = path;
    obj.media = @"image";
    [obj initialise];
}

-(NSString *) readIphoneCameraSnapShotsFromDB {
    
    AppDelegate *appDel = [[UIApplication sharedApplication]delegate];
    NSManagedObjectContext *context = appDel.managedObjectContext;
    
    NSFetchRequest *request = [[NSFetchRequest alloc]initWithEntityName:@"SnapShots"];
    request.returnsObjectsAsFaults=false;
    
    NSArray *snapShotsArray = [[NSArray alloc]init];
    NSString *snapImagePath;
    snapShotsArray = [context executeFetchRequest:request error:nil];
    
    if([snapShotsArray count] > 0){
        for(NSString *snapShotValue in snapShotsArray)
        {
            snapImagePath = [snapShotValue valueForKey:@"path"];
        }
    }
    return snapImagePath;
}


#pragma mark video recording

- (void)startMovieRecording
{
    dispatch_async( self.sessionQueue, ^{
        if ( ! self.movieFileOutput.isRecording ) {
            if ( [UIDevice currentDevice].isMultitaskingSupported ) {
                self.backgroundRecordingID = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:nil];
            }
            dispatch_async( dispatch_get_main_queue(), ^{
                _cameraButton.hidden = true;
                _flashButton.hidden = true;
                [_startCameraActionButton setImage:[UIImage imageNamed:@"camera_Button_ON"] forState:UIControlStateNormal];
                if(self.currentFlashMode == 1){
                    if ([self.videoDeviceInput.device hasFlash]&&[self.videoDeviceInput.device hasTorch]) {
                        if (self.videoDeviceInput.device.torchMode == AVCaptureTorchModeOff) {
                            [self.videoDeviceInput.device lockForConfiguration:nil];
                            [self.videoDeviceInput.device setTorchMode:AVCaptureTorchModeOn];
                            [self.videoDeviceInput.device unlockForConfiguration];
                        }
                    }
                }
                [IPhoneCameraViewController setFlashMode:self.currentFlashMode forDevice:self.videoDeviceInput.device];
            });
            
            // Update the orientation on the movie file output video connection before starting recording.
            AVCaptureConnection *connection = [self.movieFileOutput connectionWithMediaType:AVMediaTypeVideo];
            AVCaptureVideoPreviewLayer *previewLayer = (AVCaptureVideoPreviewLayer *)self.previewView.layer;
            connection.videoOrientation = previewLayer.connection.videoOrientation;
            // Start recording to a temporary file.
            NSString *outputFileName = [NSProcessInfo processInfo].globallyUniqueString;
            NSString *outputFilePath = [NSTemporaryDirectory() stringByAppendingPathComponent:[outputFileName stringByAppendingPathExtension:@"mov"]];
            [self.movieFileOutput startRecordingToOutputFileURL:[NSURL fileURLWithPath:outputFilePath] recordingDelegate:self];
        }
        else {
            
            dispatch_async( dispatch_get_main_queue(), ^{  
                if ([self.videoDeviceInput.device hasFlash]&&[self.videoDeviceInput.device hasTorch]) {
                    if (self.videoDeviceInput.device.torchMode == AVCaptureTorchModeOff) {
                    }else {
                        [self.videoDeviceInput.device lockForConfiguration:nil];
                        [self.videoDeviceInput.device setTorchMode:AVCaptureTorchModeOff];
                        [self.videoDeviceInput.device unlockForConfiguration];
                    }
                }
                _cameraButton.hidden = false;
                if(flashFlag == 0){
                    _flashButton.hidden = false;
                }
                else if(flashFlag == 1){
                    _flashButton.hidden = true;
                }
                
                [_startCameraActionButton setImage:[UIImage imageNamed:@"Camera_Button_OFF"] forState:UIControlStateNormal];
            });
            [self.movieFileOutput stopRecording];
        }
    } );
}

-(void)showProgressBar
{
    dispatch_async( dispatch_get_main_queue(), ^{
        [_iphoneCameraButton setImage:[UIImage imageNamed:@"Live_now_off_mode"] forState:UIControlStateNormal];
        _flashButton.hidden = true;
        _cameraButton.hidden = true;
        _activityImageView.image =  [UIImage animatedImageNamed:@"loader-" duration:1.0f];
        _activityImageView.hidden = false;
        [__activityIndicatorView startAnimating];
        __activityIndicatorView.hidden = false;
        _noDataFound.text = @"Initializing Stream";
        _noDataFound.hidden = false;
        _liveSteamSession.previewView.hidden = true;
    });
    [self setUpInitialBlurView];
}

#pragma mark : VCSessionState Delegate

- (void) connectionStatusChanged:(VCSessionState) state
{
    switch(state) {
        case VCSessionStateStarting:
            NSLog(@"Starting");
            break;
        case VCSessionStateStarted:
            [self hideProgressBar];
            NSLog(@"Started");
            [self performSelector:@selector(screenCapture) withObject:nil afterDelay:2.0];
            break;
        case VCSessionStateEnded:
            [[NSUserDefaults standardUserDefaults] setValue:false forKey:@"StartedStreaming"];
            [_iphoneCameraButton setImage:[UIImage imageNamed:@"iphone"] forState:UIControlStateNormal];
            NSLog(@"End Stream");
            break;
        case VCSessionStateError:
            [[NSUserDefaults standardUserDefaults] setValue:false forKey:@"StartedStreaming"];
            [_iphoneCameraButton setImage:[UIImage imageNamed:@"iphone"] forState:UIControlStateNormal];
            [liveStreaming stopStreamingClicked];
            NSLog(@"VCSessionStateError");
            break;
        default:
            NSLog(@"Connect");
            [self hidingView];
            dispatch_async( dispatch_get_main_queue(), ^{
                self.previewView.session = nil;
                self.previewView.hidden = true;
                [self.view addSubview:_liveSteamSession.previewView];
                [self.view bringSubviewToFront:self.bottomView];
                [self.view bringSubviewToFront:self.topView];
            });
            break;
    }
}

-(void)hideProgressBar
{
    dispatch_async( dispatch_get_main_queue(), ^{
        [_iphoneCameraButton setImage:[UIImage imageNamed:@"Live_now_mode"] forState:UIControlStateNormal];
        _activityImageView.hidden = true;
        [__activityIndicatorView stopAnimating];
        __activityIndicatorView.hidden = true;
        _noDataFound.hidden = true;
        self.activitView.hidden = true;
        _liveSteamSession.previewView.hidden = false;
        [self.bottomView setUserInteractionEnabled:YES];
    } );
}

#pragma mark save livestream images

-(void)screenCapture
{
    CGSize size = CGSizeMake(_liveSteamSession.previewView.bounds.size.width,_liveSteamSession.previewView.bounds.size.height);
    
    UIGraphicsBeginImageContextWithOptions(size, NO, 7);
    CGRect rec = CGRectMake(0,0,_liveSteamSession.previewView.bounds.size.width,_liveSteamSession.previewView.bounds.size.height);
    [self.view drawViewHierarchyInRect:rec afterScreenUpdates:YES];
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    UIImage *image1 = [self thumbnaleImage:image scaledToFillSize:CGSizeMake(70, 70)];
    [self saveThumbnailImageLive:image1];
    [self uploadThumbToCloud:image1];
}

-(void) saveThumbnailImageLive:(UIImage *)liveThumbImage{
    deleteCount = 0;
    NSString *userName = [[NSUserDefaults standardUserDefaults] objectForKey:@"userLoginIdKey"];
    NSString *finalPath = [NSString stringWithFormat:@"%@LiveThumb",userName];
    [[FileManagerViewController sharedInstance]saveImageToFilePath:finalPath mediaImage:liveThumbImage];
}

-(void) uploadThumbToCloud:(UIImage *)image
{
    NSString *urlStr = [[NSUserDefaults standardUserDefaults] objectForKey:@"liveStreamURL"];
    NSData *imageData = UIImageJPEGRepresentation(image, 0.5);
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc]initWithURL:[NSURL URLWithString:urlStr]];
    request.HTTPMethod = @"PUT";
    NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:[NSOperationQueue mainQueue]];
    request.HTTPBody = imageData;
    NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        
        if(error != nil){
            
        }
        else{
            [self deleteThumbnailImageLive];
        }
    }];
    [dataTask resume];
}

-(void) deleteThumbnailImageLive{
    NSString *userName = [[NSUserDefaults standardUserDefaults] objectForKey:@"userLoginIdKey"];
    NSURL *parentPathStr = [[FileManagerViewController sharedInstance] getParentDirectoryPath];
    NSString *finalPath = [NSString stringWithFormat:@"%@/%@%@",parentPathStr,userName,@"LiveThumb"];
    int deletFlag = [[FileManagerViewController sharedInstance] deleteImageFromFilePath:finalPath];
}

#pragma mark KVO and Notifications

- (void)addObservers
{
    [self.session addObserver:self forKeyPath:@"running" options:NSKeyValueObservingOptionNew context:SessionRunningContext];
    [self.stillImageOutput addObserver:self forKeyPath:@"capturingStillImage" options:NSKeyValueObservingOptionNew context:CapturingStillImageContext];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(subjectAreaDidChange:) name:AVCaptureDeviceSubjectAreaDidChangeNotification object:self.videoDeviceInput.device];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sessionRuntimeError:) name:AVCaptureSessionRuntimeErrorNotification object:self.session];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sessionWasInterrupted:) name:AVCaptureSessionWasInterruptedNotification object:self.session];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sessionInterruptionEnded:) name:AVCaptureSessionInterruptionEndedNotification object:self.session];
}

- (void)removeObservers
{
   // [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [self.session removeObserver:self forKeyPath:@"running" context:SessionRunningContext];
    [self.stillImageOutput removeObserver:self forKeyPath:@"capturingStillImage" context:CapturingStillImageContext];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ( context == CapturingStillImageContext ) {
        BOOL isCapturingStillImage = [change[NSKeyValueChangeNewKey] boolValue];
        
        if ( isCapturingStillImage ) {
            dispatch_async( dispatch_get_main_queue(), ^{
                self.previewView.layer.opacity = 0.0;
                [UIView animateWithDuration:0.25 animations:^{
                    self.previewView.layer.opacity = 1.0;
                }];
            } );
        }
    }
    else if ( context == SessionRunningContext ) {
        BOOL isSessionRunning = [change[NSKeyValueChangeNewKey] boolValue];
        
        dispatch_async( dispatch_get_main_queue(), ^{
            self.cameraButton.enabled = isSessionRunning && ( [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo].count > 1 );
        } );
    }
    else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (void)sessionRuntimeError:(NSNotification *)notification
{
    NSError *error = notification.userInfo[AVCaptureSessionErrorKey];
    NSLog( @"Capture session runtime error: %@", error );
    
    if ( error.code == AVErrorMediaServicesWereReset ) {
        dispatch_async( self.sessionQueue, ^{
            if ( self.isSessionRunning ) {
                [self.session startRunning];
                self.sessionRunning = self.session.isRunning;
            }
            else {
                dispatch_async( dispatch_get_main_queue(), ^{
                } );
            }
        } );
    }
    else {
    }
}

- (void)dealloc {
    AVCaptureInput* input = [_session.inputs objectAtIndex:0];
    [_session removeInput:input];
    AVCaptureVideoDataOutput* output = [_session.outputs objectAtIndex:0];
    [_session removeOutput:output];
    [_session stopRunning];
}


- (void)sessionWasInterrupted:(NSNotification *)notification
{
    BOOL showResumeButton = NO;
    
    if ( &AVCaptureSessionInterruptionReasonKey ) {
        AVCaptureSessionInterruptionReason reason = [notification.userInfo[AVCaptureSessionInterruptionReasonKey] integerValue];
        if ( reason == AVCaptureSessionInterruptionReasonAudioDeviceInUseByAnotherClient ||
            reason == AVCaptureSessionInterruptionReasonVideoDeviceInUseByAnotherClient ) {
            showResumeButton = YES;
        }
        else if ( reason == AVCaptureSessionInterruptionReasonVideoDeviceNotAvailableWithMultipleForegroundApps ) {
            [UIView animateWithDuration:0.25 animations:^{
            }];
        }
    }
    else {
        showResumeButton = ( [UIApplication sharedApplication].applicationState == UIApplicationStateInactive );
    }
    
    if ( showResumeButton ) {
        [UIView animateWithDuration:0.25 animations:^{
        }];
    }
}

- (void)sessionInterruptionEnded:(NSNotification *)notification
{
}


#pragma mark File Output Recording Delegate

- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didStartRecordingToOutputFileAtURL:(NSURL *)fileURL fromConnections:(NSArray *)connections
{
}

- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL fromConnections:(NSArray *)connections error:(NSError *)error
{
    UIBackgroundTaskIdentifier currentBackgroundRecordingID = self.backgroundRecordingID;
    self.backgroundRecordingID = UIBackgroundTaskInvalid;
    BOOL success = YES;
    
    if ( error ) {
        success = [error.userInfo[AVErrorRecordingSuccessfullyFinishedKey] boolValue];
    }
    if ( success ) {
        [PHPhotoLibrary requestAuthorization:^( PHAuthorizationStatus status ) {
            if ( status == PHAuthorizationStatusAuthorized ) {
                [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
                    dispatch_async(dispatch_get_main_queue(), ^{
                        NSData *imageData = [[NSData alloc]init];
                        imageData = [self getThumbNail:outputFileURL];
                        self.thumbnailImageView.image = [self thumbnaleImage:[UIImage imageWithData:imageData] scaledToFillSize:CGSizeMake(thumbnailSize, thumbnailSize)];
                        [_playiIconView setHidden:NO];
                        if(imageData != nil){
                            [self saveImage:imageData];
                            [self moveVideoToDocumentDirectory:outputFileURL];
                        }
                    });
                    if ( [PHAssetResourceCreationOptions class] ) {
                        PHAssetResourceCreationOptions *options = [[PHAssetResourceCreationOptions alloc] init];
                        options.shouldMoveFile = YES;
                        PHAssetCreationRequest *changeRequest = [PHAssetCreationRequest creationRequestForAsset];
                        [changeRequest addResourceWithType:PHAssetResourceTypeVideo fileURL:outputFileURL options:options];
                    }
                    else {
                        [PHAssetChangeRequest creationRequestForAssetFromVideoAtFileURL:outputFileURL];
                    }
                } completionHandler:^( BOOL success, NSError *error ) {
                    if ( ! success ) {
                    }
                }];
            }
            else {
                //  cleanup();
            }
        }];
    }
    else {
        // cleanup();
    }
    
    dispatch_async( dispatch_get_main_queue(), ^{
        self.cameraButton.enabled = ( [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo].count > 1 );
    });
}

#pragma mark save video

-(void) moveVideoToDocumentDirectory : (NSURL *) path
{
    [self loaduploadManager : path ];
    UISaveVideoAtPathToSavedPhotosAlbum([path path], nil, nil, nil);
}

-(void) loaduploadManager : (NSURL *)filePath
{
    NSString *path = [self readIphoneCameraSnapShotsFromDB];
    uploadMediaToGCS *obj = [[uploadMediaToGCS alloc]init];
    obj.path = path;
    obj.media = @"video";
    obj.videoSavedURL = filePath;
    [obj initialise];
}

#pragma mark Device Configuration

- (void)focusWithMode:(AVCaptureFocusMode)focusMode exposeWithMode:(AVCaptureExposureMode)exposureMode atDevicePoint:(CGPoint)point monitorSubjectAreaChange:(BOOL)monitorSubjectAreaChange
{
    dispatch_async( self.sessionQueue, ^{
        AVCaptureDevice *device = self.videoDeviceInput.device;
        NSError *error = nil;
        if ( [device lockForConfiguration:&error] ) {
            if ( device.isFocusPointOfInterestSupported && [device isFocusModeSupported:focusMode] ) {
                device.focusPointOfInterest = point;
                device.focusMode = focusMode;
            }
            
            if ( device.isExposurePointOfInterestSupported && [device isExposureModeSupported:exposureMode] ) {
                device.exposurePointOfInterest = point;
                device.exposureMode = exposureMode;
            }
            
            device.subjectAreaChangeMonitoringEnabled = monitorSubjectAreaChange;
            [device unlockForConfiguration];
        }
        else {
            NSLog( @"Could not lock device for configuration: %@", error );
        }
    } );
}

+ (void)setFlashMode:(AVCaptureFlashMode)flashMode forDevice:(AVCaptureDevice *)device
{
    if ( device.hasFlash && [device isFlashModeSupported:flashMode] ) {
        NSError *error = nil;
        if ( [device lockForConfiguration:&error] ) {
            device.flashMode = flashMode;
            [device unlockForConfiguration];
          
        }
        else {
        }
    }
}

+ (AVCaptureDevice *)deviceWithMediaType:(NSString *)mediaType preferringPosition:(AVCaptureDevicePosition)position
{
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:mediaType];
    AVCaptureDevice *captureDevice = devices.firstObject;
    
    for ( AVCaptureDevice *device in devices ) {
        if ( device.position == position ) {
            captureDevice = device;
            break;
        }
    }
    return captureDevice;
}


-(UIImage*) drawImage:(UIImage*) fgImage
              inImage:(UIImage*) bgImage
              atPoint:(CGPoint)  point
{
    UIGraphicsBeginImageContextWithOptions(bgImage.size, NO, 0.0);
    [bgImage drawInRect:CGRectMake(0, 0, bgImage.size.width, bgImage.size.height)];
    [fgImage drawInRect:CGRectMake(bgImage.size.width - fgImage.size.width, bgImage.size.height - fgImage.size.height, fgImage.size.width, fgImage.size.height)];
    UIImage *result = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return result;
}

#pragma mark save Image to DataBase

-(void) deleteIphoneCameraSnapShots{
    AppDelegate *appDel = [[UIApplication sharedApplication]delegate];
    NSManagedObjectContext *context = appDel.managedObjectContext;
    NSFetchRequest *request = [[NSFetchRequest alloc]initWithEntityName:@"SnapShots"];
    request.returnsObjectsAsFaults=false;
    NSArray *snapShotsArray = [[NSArray alloc]init];
    snapShotsArray = [context executeFetchRequest:request error:nil];
    NSFileManager *defaultManager = [[NSFileManager alloc]init];
    for(int i=0;i<[snapShotsArray count];i++){
        if(![defaultManager fileExistsAtPath:[snapShotsArray[i] valueForKey:@"path"]]){
            NSManagedObject * obj = snapShotsArray[i];
            [context deleteObject:obj];
        }
    }
    [context save:nil];
}

-(void)setUpInitialBlurView
{
    UIGraphicsBeginImageContext(CGSizeMake(self.view.bounds.size.width, (self.view.bounds.size.height+67.0)));
    [[UIImage imageNamed:@"live_stream_blur.png"] drawInRect:CGRectMake(self.view.bounds.origin.x, self.view.bounds.origin.y, self.view.bounds.size.width, (self.view.bounds.size.height+67.0))];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    self.view.backgroundColor = [UIColor colorWithPatternImage:image];
    self.activitView.hidden =false;
    [self.bottomView setUserInteractionEnabled:NO];
}

- (IBAction)didTapCamSelectionButton:(id)sender
{
    if ([self isStreamStarted])
    {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Streaming In Progress" message:@"Do you want to stop streaming?" preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString( @"No", @"Alert No") style:UIAlertActionStyleCancel handler:nil];
        [alertController addAction:cancelAction];
        
        UIAlertAction *OkAction = [UIAlertAction actionWithTitle:NSLocalizedString( @"Yes", @"Alert Yes") style:UIAlertActionStyleDefault handler:^( UIAlertAction *action ) {
            
            [UIApplication sharedApplication].idleTimerDisabled = NO;
            [liveStreaming stopStreamingClicked];
            [_liveSteamSession endRtmpSession];
            [[NSUserDefaults standardUserDefaults] setInteger:0 forKey:@"shutterActionMode"];
            [[NSUserDefaults standardUserDefaults] setBool:false forKey:@"StartedStreaming"];
            [self settingsPageView];
        }];
        [alertController addAction:OkAction];
        [self presentViewController:alertController animated:YES completion:nil];
    }
    else{
        [self settingsPageView];
    }
}

#pragma mark Load views

-(void) settingsPageView{
    
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Settings" bundle:nil];
    SnapCamSelectViewController *snapCamSelectVC = (SnapCamSelectViewController*)[storyboard instantiateViewControllerWithIdentifier:@"SnapCamSelectViewController"];
    snapCamSelectVC.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    snapCamSelectVC.streamingDelegate = self;
    snapCamSelectVC.snapCamMode = [self getCameraSelectionMode];
    snapCamSelectVC.toggleSnapCamIPhoneMode = SnapCamSelectionModeiPhone;
    [self presentViewController:snapCamSelectVC animated:YES completion:nil];

}

- (IBAction)didTapSharingListIcon:(id)sender
{
    if ([self isStreamStarted])
    {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Streaming In Progress" message:@"Do you want to stop streaming?" preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString( @"No", @"Alert No") style:UIAlertActionStyleCancel handler:nil];
        [alertController addAction:cancelAction];
        
        UIAlertAction *OkAction = [UIAlertAction actionWithTitle:NSLocalizedString( @"Yes", @"Alert Yes") style:UIAlertActionStyleDefault handler:^( UIAlertAction *action ) {
            
            [UIApplication sharedApplication].idleTimerDisabled = NO;
            [liveStreaming stopStreamingClicked];
            [_liveSteamSession endRtmpSession];
            [[NSUserDefaults standardUserDefaults] setInteger:0 forKey:@"shutterActionMode"];
            [[NSUserDefaults standardUserDefaults] setBool:false forKey:@"StartedStreaming"];
            [self loadSharingView];
        }];
        [alertController addAction:OkAction];
        [self presentViewController:alertController animated:YES completion:nil];
    }
    else{
        [self loadSharingView];
    }
}

-(void) loadSharingView{
    UIStoryboard *sharingStoryboard = [UIStoryboard storyboardWithName:@"sharing" bundle:nil];
    UIViewController *mysharedChannelVC = [sharingStoryboard instantiateViewControllerWithIdentifier:@"MySharedChannelsViewController"];
    
    UINavigationController *navController = [[UINavigationController alloc]initWithRootViewController:mysharedChannelVC];
    navController.navigationBarHidden = true;
    
    navController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    [self.navigationController presentViewController:navController animated:true completion:^{
    }];
}

- (IBAction)didTapPhotoViewer:(id)sender {
    if ([self isStreamStarted])
    {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Streaming In Progress" message:@"Do you want to stop streaming?" preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString( @"No", @"Alert No") style:UIAlertActionStyleCancel handler:nil];
        [alertController addAction:cancelAction];
        
        UIAlertAction *OkAction = [UIAlertAction actionWithTitle:NSLocalizedString( @"Yes", @"Alert Yes") style:UIAlertActionStyleDefault handler:^( UIAlertAction *action ) {
            
            [UIApplication sharedApplication].idleTimerDisabled = NO;
            [liveStreaming stopStreamingClicked];
            [_liveSteamSession endRtmpSession];
            [[NSUserDefaults standardUserDefaults] setInteger:0 forKey:@"shutterActionMode"];
            [[NSUserDefaults standardUserDefaults] setBool:false forKey:@"StartedStreaming"];
             [self loadPhotoViewer];
        }];
        [alertController addAction:OkAction];
        [self presentViewController:alertController animated:YES completion:nil];
    }
    else{
       [self loadPhotoViewer];
    }
}

-(void) loadPhotoViewer
{
    UIStoryboard *streamingStoryboard = [UIStoryboard storyboardWithName:@"PhotoViewer" bundle:nil];
    
    PhotoViewerViewController *photoViewerViewController =( PhotoViewerViewController*)[streamingStoryboard instantiateViewControllerWithIdentifier:@"PhotoViewerViewController"];
    UINavigationController *navController = [[UINavigationController alloc]initWithRootViewController:photoViewerViewController];
    navController.navigationBarHidden = true;
    navController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    [self presentViewController:navController animated:true completion:^{
        
    }];
}

- (IBAction)didTapStreamThumb:(id)sender {
    
    if ([self isStreamStarted])
    {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Streaming In Progress" message:@"Do you want to stop streaming?" preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString( @"No", @"Alert No") style:UIAlertActionStyleCancel handler:nil];
        [alertController addAction:cancelAction];
        
        UIAlertAction *OkAction = [UIAlertAction actionWithTitle:NSLocalizedString( @"Yes", @"Alert Yes") style:UIAlertActionStyleDefault handler:^( UIAlertAction *action ) {
            
            [UIApplication sharedApplication].idleTimerDisabled = NO;
            [liveStreaming stopStreamingClicked];
            [_liveSteamSession endRtmpSession];
            [[NSUserDefaults standardUserDefaults] setInteger:0 forKey:@"shutterActionMode"];
            [[NSUserDefaults standardUserDefaults] setBool:false forKey:@"StartedStreaming"];
            [self loadStreamsGalleryView];
        }];
        [alertController addAction:OkAction];
        [self presentViewController:alertController animated:YES completion:nil];
    }
    else{
        [self loadStreamsGalleryView];
    }
}

-(void) loadStreamsGalleryView
{
    UIStoryboard *streamingStoryboard = [UIStoryboard storyboardWithName:@"Streaming" bundle:nil];
    StreamsGalleryViewController *streamsGalleryViewController = [streamingStoryboard instantiateViewControllerWithIdentifier:@"StreamsGalleryViewController"];
    [self.navigationController pushViewController:streamsGalleryViewController animated:false];
}

#pragma mark :- StreamingProtocol delegates

-(void)cameraSelectionMode:(SnapCamSelectionMode)selectionMode
{
    _snapCamMode = selectionMode;
}

-(SnapCamSelectionMode)getCameraSelectionMode
{
    return _snapCamMode;
}

#pragma mark :- Private Methods

-(void)startLiveStreaming
{
    [UIApplication sharedApplication].idleTimerDisabled = YES;
    NSString * url  = @"rtsp://192.168.16.33:1935/live";
    [_liveSteamSession startRtmpSessionWithURL:url andStreamKey:@"iPhoneliveStreaming"];
}

-(void)stopLiveStreaming
{
    NSInteger shutterActionMode = [[NSUserDefaults standardUserDefaults] integerForKey:@"shutterActionMode"];
    if (shutterActionMode == SnapCamSelectionModeLiveStream)
    {
        switch(_liveSteamSession.rtmpSessionState) {
            case VCSessionStateNone:
            case VCSessionStatePreviewStarted:
            case VCSessionStateEnded:
            case VCSessionStateError:
                break;
            default:
                [UIApplication sharedApplication].idleTimerDisabled = NO;
                [_liveSteamSession endRtmpSession];
                break;
        }
    }
}

- (void)subjectAreaDidChange:(NSNotification *)notification
{
    CGPoint devicePoint = CGPointMake( 0.5, 0.5 );
    [self focusWithMode:AVCaptureFocusModeContinuousAutoFocus exposeWithMode:AVCaptureExposureModeContinuousAutoExposure atDevicePoint:devicePoint monitorSubjectAreaChange:NO];
}

# pragma mark:- Thumbnail generator

- (UIImage *)thumbnaleImage:(UIImage *)image scaledToFillSize:(CGSize)size
{
    //crop uper and lower part
    CGFloat scale = MAX(size.width/image.size.width, size.height/image.size.height);
    CGFloat width = image.size.width * scale;
    CGFloat height = image.size.height * scale;
    CGRect imageRect = CGRectMake((size.width - width)/2.0f,
                                  (size.height - height)/2.0f,
                                  width,
                                  height);
    
    UIGraphicsBeginImageContextWithOptions(size, NO, 0);
    [image drawInRect:imageRect];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

- (NSData *)thumbnailFromVideoAtURL:(NSURL *)contentURL {
    UIImage *theImage = nil;
    AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:contentURL options:nil];
    AVAssetImageGenerator *generator = [[AVAssetImageGenerator alloc] initWithAsset:asset];
    generator.appliesPreferredTrackTransform = YES;
    NSError *err = NULL;
    CMTime time = CMTimeMake(1, 60);
    CGImageRef imgRef = [generator copyCGImageAtTime:time actualTime:NULL error:&err];
    theImage = [[UIImage alloc] initWithCGImage:imgRef];
    CGImageRelease(imgRef);
    NSData *imageData = [[NSData alloc] init];
    imageData = UIImageJPEGRepresentation(theImage, 1.0);
    return imageData;
}

-(NSData *)getThumbNail:(NSURL*)stringPath
{
    UIImage *firstImage =[[UIImage alloc] init];
    NSURL *videoURL = [NSURL fileURLWithPath:[stringPath path]];
    AVPlayerItem *SelectedItem = [AVPlayerItem playerItemWithURL:stringPath];
    CMTime duration = SelectedItem.duration;
    float seconds = CMTimeGetSeconds(duration);
    AVURLAsset *asset1 = [[AVURLAsset alloc] initWithURL:stringPath options:nil];
    AVAssetImageGenerator *generate1 = [[AVAssetImageGenerator alloc] initWithAsset:asset1];
    generate1.appliesPreferredTrackTransform = YES;
    NSError *err = NULL;
    CMTime time = CMTimeMake(0.0,600);
    CGImageRef oneRef = [generate1 copyCGImageAtTime:time actualTime:NULL error:&err];
    UIImage *one = [[UIImage alloc] initWithCGImage:oneRef];
    
    UIImage *result  =  [self drawImage:[UIImage imageNamed:@"Circled Play"] inImage:one atPoint:CGPointMake(50, 50)];
    NSData *imageData = [[NSData alloc] init];
    imageData = UIImageJPEGRepresentation(result,1.0);
    return imageData;
}

@end
