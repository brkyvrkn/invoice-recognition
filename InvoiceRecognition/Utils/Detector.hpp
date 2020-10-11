//
//  Detector.hpp
//  InvoiceRecognition
//
//  Created by Berkay Vurkan on 11.10.2020.
//

#ifndef Detector_hpp
#define Detector_hpp

#include <stdio.h>
#import <iostream>
#import <vector>
#import <opencv2/opencv.hpp>

#define MORPH 9
#define CANNY 84
#define HOUGH 25
#define WIDTH 1080
#define HEIGHT 1920
#define EPS 0.1

class Detector {

public:
    typedef std::vector<std::vector<cv::Point>> cList;

    int containsInvoice(cv::Mat);
private:
    cv::Mat processImage(cv::Mat);
    cv::Mat cropROI(cv::Mat);
};

#endif /* Detector_hpp */
