//
//  OpenCVWrapper.m
//  InvoiceRecognition
//
//  Created by Berkay Vurkan on 11.10.2020.
//

#import "OpenCVWrapper.h"

#include <iostream>
#include <vector>

#import <opencv2/opencv.hpp>
#import <opencv2/core/core.hpp>
#import <opencv2/imgcodecs/ios.h>
#import "ZBarSDK.h"
#include "Detector.hpp"

@implementation OpenCVWrapper

-(void) isWorking
{
    std::cout << "OpenCV working with v" << CV_VERSION << std::endl;
}

-(void) zbarIsWorking
{
    unsigned int major, minor;
    zbar::zbar_version(&major, &minor);
    std::cout << "ZBarSDK working with v" << major << "." << minor << std::endl;
}

-(CGRect*) analyzeFrame: (UIImage *)frame
{
    cv::Mat imgMat;
    UIImageToMat(frame, imgMat);

    cv::Mat imgGrayMat;
    cv::cvtColor(imgMat, imgGrayMat, cv::COLOR_BGR2GRAY);

    Detector detector;
    std::vector<double> result;
    detector.invoiceDetector(imgMat, imgGrayMat, result);
    if (result.size() == 4) {
        CGFloat x = result[0];
        CGFloat y = result[1];
        CGFloat width = result[2];
        CGFloat height = result[3];
        CGRect rect = CGRectMake(x, y, width, height);
        CGRect* ref = &rect;
        return ref;
    }
    return NULL;
}

- (void)detectBarcode:(UIImage *)frame
{
    cv::Mat imgMat;
    UIImageToMat(frame, imgMat);

    Detector detector;
    detector.barcodeDetector(imgMat);
}

@end
