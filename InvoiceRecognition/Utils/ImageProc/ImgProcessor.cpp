//
//  ImgProcessor.cpp
//  InvoiceRecognition
//
//  Created by Berkay Vurkan on 12.10.2020.
//

#include "ImgProcessor.hpp"

/// Returns the cropped image in the type of cv::Mat
/// @param imgMat Given raw image
cv::Mat ImgProcessor::cropROI(cv::Mat imgMat)
{
    cv::Rect roiBound;
    roiBound = cv::Rect(WIDTH/7,
                        HEIGHT/8,
                        WIDTH*5/7,
                        HEIGHT*3/4
                        );
    return imgMat(roiBound);
}

ImgProcessor::cList ImgProcessor::sortContoursByArea(cList contourList)
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

ImgProcessor::cList ImgProcessor::strechList(cList contourList, int elem)
{
    //So as to eliminate contours
    int c = (int) contourList.size() - 1;
    int t = 1;
    cList newContourList = cList(elem);
    while (elem != 0)
    {
        // To see area of biggest reactangle
        //NSLog(@"The %d. biggest area: %.2f",t,cv::contourArea(contourList[c]));
        newContourList.push_back(contourList[c]);
        elem-=1;    t+=1;
        c-=1;
    }
    return newContourList;
}

bool ImgProcessor::blueColor(cv::Mat &cap, cv::Mat &image)
{
    cv::Mat cameraFeed = cap;
    cv::Mat HSV, threshold;
    cv::cvtColor(cameraFeed, HSV, cv::COLOR_BGR2HSV);

    //blue-color detector
    cv::inRange(HSV, cv::Scalar(90,50,50), cv::Scalar(130,255,255), threshold);
    //cv::inRange(HSV,cv::Scalar(255,255,255),cv::Scalar(255,222,173),threshold);


    cv::Mat erodeElement = getStructuringElement(cv::MORPH_RECT, cv::Size(3,3));

    //dilate with larger element so make sure object is nicely visible
    cv::Mat dilateElement = getStructuringElement(cv::MORPH_RECT, cv::Size(3,3));

    erode(threshold,threshold,erodeElement);
    erode(threshold,threshold,erodeElement);

    dilate(threshold,threshold,dilateElement);
    dilate(threshold,threshold,dilateElement);

    cv::Mat temp;
    threshold.copyTo(temp);
    cList contours;
    std::vector<cv::Vec4i> hierarchy;

    findContours(temp, contours, hierarchy, cv::RETR_EXTERNAL, cv::CHAIN_APPROX_SIMPLE, cv::Point(0,0));

    bool objectFound = false;
    if (hierarchy.size() > 0)
    {
        for (int index = 0; index >= 0; index = hierarchy[index][0])
        {
            cv::Moments moment = moments((cv::Mat) contours[index]);
            double area = moment.m00;
            if (area > BLUE_AREA_BOUND)
                objectFound = true;
            else
                objectFound = false;
        }
    }
    return objectFound;
}
