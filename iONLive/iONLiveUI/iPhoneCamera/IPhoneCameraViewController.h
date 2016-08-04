

#import <UIKit/UIKit.h>

#import <AssetsLibrary/AssetsLibrary.h>
#import "ALAssetsLibrary+CustomPhotoAlbum.h"
#import <Photos/Photos.h>


@interface IPhoneCameraViewController : UIViewController

-(UIImage *)thumbnaleImage:(UIImage *)image scaledToFillSize:(CGSize)size;
-(void) deleteIphoneCameraSnapShots;
-(void) loggedInDetails:(NSDictionary *) detailArray userImages : (NSArray *) userImages;

@property (weak, nonatomic) IBOutlet UIImageView *latestSharedMediaImage;
@property (weak, nonatomic) IBOutlet UILabel *countLabel;
@property (weak, nonatomic) IBOutlet UILabel *sharedUserCount;
@property (strong, nonatomic) IBOutlet UIImageView *playiIconView;

@end
