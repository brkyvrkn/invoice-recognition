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

#include "ImgProcessor.hpp"

class Detector {

public:
    typedef std::vector<std::vector<cv::Point>> cList;

    cv::Mat contourDetector(cv::Mat&, cList&, cv::Rect&);
    cv::Mat barcodeDetector(cv::Mat&, cv::Rect&);
};

#endif /* Detector_hpp */
