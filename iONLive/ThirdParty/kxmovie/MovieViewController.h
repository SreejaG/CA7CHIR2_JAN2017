
#import <UIKit/UIKit.h>
#import <AVKit/AVKit.h>

@class KxMovieDecoder;

extern NSString * const KxMovieParameterMinBufferedDuration;    // Float
extern NSString * const KxMovieParameterMaxBufferedDuration;    // Float
extern NSString * const KxMovieParameterDisableDeinterlacing;   // BOOL

@interface MovieViewController : UIViewController < NSURLSessionDelegate, NSURLSessionTaskDelegate, NSURLSessionDataDelegate, NSURLSessionDownloadDelegate, UIGestureRecognizerDelegate, AVPlayerViewControllerDelegate ,UICollectionViewDelegate, UICollectionViewDataSource, CAAnimationDelegate>

+ (id) movieViewControllerWithContentPath: (NSString *) path
                               parameters: (NSDictionary *) parameters
                                liveVideo:(BOOL) live;

+ (id) movieViewControllerWithImageVideo: (NSString *) channelName
                               channelId: (NSString *) channelId
                                userName: (NSString *) userName
                               mediaType: (NSString *) mediaType
                            profileImage: (UIImage *) profileImage
                           VideoImageUrl: (NSString *) VideoImageUrl
                               notifType: (NSString *) notifType
                                 mediaId: (NSString *) mediaId
                                timeDiff: (NSString *) timeDiff
                            likeCountStr: (NSString *) likeCountStr
                            selectedItem: (int) selectedItem
                           pageIndicator: (int) pageIndicator
                            videoDuration: (NSString *) videoDuration;

-(void) successFromSetUpView:( NSString *) count;
-(void) closeView;
-(void) mediaDeletedErrorMessage;
-(void) successFromSetUpViewProfileImage :(UIImage *)profImage;
-(void) checkToCloseViewWhileMediaDelete :(NSString *)mediaId;
-(void) checkToCloseWhileMyDayCleanUp :(NSString *) channelId;
-(void) cleanMyDayComplete :(NSString *) chanel;
@property (readonly) BOOL playing;

@property (weak, nonatomic) IBOutlet UICollectionView *photoCollectionView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bottomConstraintForHeartView;

@end
