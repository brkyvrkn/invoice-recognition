//
//  Processor.cpp
//  InvoiceRecognition
//
//  Created by Berkay Vurkan on 12.10.2020.
//

#include "Processor.hpp"

cv::Mat Processor::cropROI(cv::Mat imgMat)
{
    cv::Rect roiBound;
    roiBound = cv::Rect(WIDTH / 7,
                        HEIGHT / 8,
                        WIDTH * 5 / 7,
                        HEIGHT * 3 / 4
                        );
    return imgMat(roiBound);
}

Processor::cList Processor::sortContoursByArea(cList contourList)
{
    for (int i=0; i<contourList.size(); i++) {
        int j = i;
        while(j>0 and cv::contourArea(contourList[j]) < cv::contourArea(contourList[j-1]))
        {
            //Uncomment if u want to see which areas was swapped
            //NSLog(@"swapped areas in the %d %d indices and %.2f %.2f areas",j-1,j,cv::contourArea(contourList[j-1]),cv::contourArea(contourList[j]));
            std::vector<cv::Point> temp = contourList[j];
            contourList[j] = contourList[j-1];
            contourList[j-1] = temp;
            j-=1;
        }
    }
    return contourList;
}
