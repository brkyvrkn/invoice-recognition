//
//  Processor.hpp
//  InvoiceRecognition
//
//  Created by Berkay Vurkan on 12.10.2020.
//

#ifndef Processor_hpp
#define Processor_hpp

#include <iostream>
#import <vector>
#import <opencv2/opencv.hpp>

#define MORPH 9
#define CANNY 84
#define HOUGH 25
#define WIDTH 1080
#define HEIGHT 1920
#define EPS 0.1

class Processor {

public:
    typedef std::vector<std::vector<cv::Point>> cList;
private:
    cv::Mat cropROI(cv::Mat);
    cList sortContoursByArea(cList);
};

#endif /* Processor_hpp */
