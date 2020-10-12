//
//  OpenCVWrapper.m
//  InvoiceRecognition
//
//  Created by Berkay Vurkan on 11.10.2020.
//

#import "OpenCVWrapper.h"

#include <iostream>

#import <opencv2/opencv.hpp>
#import <opencv2/core/core.hpp>
#import <opencv2/imgcodecs/ios.h>
#include "Detector.hpp"

@implementation OpenCVWrapper

-(void) isWorking
{
    std::cout << "OpenCV working with v." << CV_VERSION << std::endl;
}

-(BOOL) containsInvoice:(UIImage *)captured
{
    cv::Mat imgMat;
    UIImageToMat(captured, imgMat);

    cv::Mat imgGrayMat;
    cv::cvtColor(imgMat, imgGrayMat, cv::COLOR_BGR2GRAY);

    Detector detector;
    return detector.containsInvoice(imgGrayMat);
}

@end
