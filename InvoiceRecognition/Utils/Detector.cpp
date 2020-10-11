//
//  Detector.cpp
//  InvoiceRecognition
//
//  Created by Berkay Vurkan on 11.10.2020.
//

#include "Detector.hpp"

int Detector::containsInvoice(cv::Mat imgMat)
{
    return 0;
}

cv::Mat Detector::cropROI(cv::Mat imgMat)
{
    cv::Rect roiBound;
    roiBound = cv::Rect(WIDTH / 7,
                        HEIGHT / 8,
                        WIDTH * 5 / 7,
                        HEIGHT * 3 / 4
                        );
    return imgMat(roiBound);
}
