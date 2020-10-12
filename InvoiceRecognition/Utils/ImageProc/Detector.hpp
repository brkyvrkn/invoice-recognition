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

#include "Processor.hpp"

class Detector {

public:
    int containsInvoice(cv::Mat);
private:
    std::vector<std::string> barcodeReader(cv::Mat cap);
};

#endif /* Detector_hpp */
