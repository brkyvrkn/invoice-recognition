//
//  ImgProcessor.hpp
//  InvoiceRecognition
//
//  Created by Berkay Vurkan on 12.10.2020.
//

#ifndef ImgProcessor_hpp
#define ImgProcessor_hpp

#include <iostream>
#import <vector>
#import <opencv2/opencv.hpp>

#define MORPH 9
#define CANNY 84
#define HOUGH 25
#define WIDTH 1080
#define HEIGHT 1920
#define EPS 0.1
#define BLUE_AREA_BOUND 5000

class ImgProcessor {

public:
    typedef std::vector<std::vector<cv::Point>> cList;

    cv::Mat cropROI(cv::Mat);
    cList strechList(cList, int);
    cList sortContoursByArea(cList);
private:
    bool blueColor(cv::Mat&, cv::Mat&);
};

#endif /* ImgProcessor_hpp */
