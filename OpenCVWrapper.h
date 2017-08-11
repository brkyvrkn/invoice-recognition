//
//  OpenCVWrapper.h
//  Invioce_Recognition
//
//  Created by Berkay Vurkan on 08/08/2017.
//  Copyright © 2017 Berkay Vurkan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MBProgressHUD/MBProgressHUD.h"
#import "LibzBar/Headers/ZBarSDK/ZBarSDK.h"

#ifdef __cplusplus
#import <opencv2/opencv.hpp>
#import <opencv2/core/core.hpp>
#import <opencv2/imgcodecs/ios.h>
#import <opencv2/videoio/cap_ios.h>
#import <opencv2/highgui/highgui.hpp>
#import <opencv2/features2d/features2d.hpp>

#import <vector>
#import <iomanip>
#import <iostream>
#endif

@interface OpenCVWrapper : NSObject

-(void) isWorking;

@end
