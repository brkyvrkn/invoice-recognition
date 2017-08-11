//
//  RealTimeViewController.h
//  Invioce_Recognition
//
//  Created by Berkay Vurkan on 08/08/2017.
//  Copyright © 2017 Berkay Vurkan. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <AVKit/AVKit.h>
#import <MediaPlayer/MediaPlayer.h>
#import <AssetsLibrary/AssetsLibrary.h>

#ifdef __cplusplus
#import <string>
#import "OpenCVWrapper.h"
#import "CapturedViewController.h"

@interface RealTimeViewController : UIViewController<CvVideoCameraDelegate>
{
    MBProgressHUD *indicator,*toast;
    cv::Mat captured;
    NSString *invoiceType,*clientNumber,*cost;
    NSString* contents;
}
@property (nonatomic, strong) CvVideoCamera* videoCamera;
@property (nonatomic, strong) IBOutlet UIImageView* imageView;

-(void) timerUpper;
-(void) initInstances;

//////////////// delegate method for processing image frames
- (void)processImage:(cv::Mat&)image;
////////////////

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender;
-(UIImage*) classifyMatWithROI;
-(BOOL) connectToServer;
-(std::vector<std::string>) barcodeReader: (cv::Mat) cap;

@end

#define MORPH 9
#define CANNY 84
#define HOUGH 25
#define WIDTH 1080      //Bounds of high quality video recording
#define HEIGHT 1920
#define EPS 0.1    //time wasting in terms of second

#endif
