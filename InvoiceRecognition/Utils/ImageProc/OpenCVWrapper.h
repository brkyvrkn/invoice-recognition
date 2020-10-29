//
//  OpenCVWrapper.h
//  InvoiceRecognition
//
//  Created by Berkay Vurkan on 11.10.2020.
//

#ifndef OpenCVWrapper_h
#define OpenCVWrapper_h

#endif /* OpenCVWrapper_h */

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <CoreGraphics/CoreGraphics.h>

#include "LibFolderManager.h"

@interface OpenCVWrapper: NSObject

@property (nonatomic, retain) UIImage* lastProcessedFrame;
@property (nonatomic) CGRect lastBoundingBox;

#pragma mark Methods

-(void) isWorking;
-(void) zbarIsWorking;
-(void) bufferToMat: (CVPixelBufferRef*) ref;

#pragma mark CV Camera
-(void) connectToCVCamera: (UIView*) inView;
-(void) disconnectFromCVCamera: (UIView*) inView;

#pragma mark Event APIs

-(void) analyzeFrame: (UIImage*) frame;
-(void) detectBarcode: (UIImage*) frame;

@end

#ifdef __cplusplus
// Built-in
#include <iostream>
#include <vector>
// OpenCV
#import <opencv2/opencv.hpp>
#import <opencv2/core/core.hpp>
#import <opencv2/imgcodecs/ios.h>
#import <opencv2/videoio/cap_ios.h>
// ZBar
#import "ZBarSDK.h"
// Custom
#include "Detector.hpp"

@interface OpenCVWrapper() <CvVideoCameraDelegate>

+(cv::Mat) bufferToMat: (CVPixelBufferRef&) ref;

#pragma mark CVVideo Delegate

-(void) processImage: (cv::Mat&) image;

@end
#endif
