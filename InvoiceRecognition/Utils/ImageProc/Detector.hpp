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

    int containsInvoice(cv::Mat);
private:
    std::vector<std::string> barcodeDetector(cv::Mat);
    bool invoiceDetector(cv::Mat&, cv::Mat&);
};

#endif /* Detector_hpp */
