//
//  Detector.cpp
//  InvoiceRecognition
//
//  Created by Berkay Vurkan on 11.10.2020.
//

#include "Detector.hpp"
#import "ZBarSDK.h"


#pragma mark - Public

cv::Mat Detector::contourDetector(cv::Mat &cvMat, Detector::cList &result, cv::Rect &bbox)
{
    cv::Mat cvMatGray,cvMatBlur,cvMatEdged,cvMatKernel;
    cv::cvtColor(cvMat, cvMatGray, cv::COLOR_BGR2GRAY);
    cv::GaussianBlur(cvMatGray, cvMatBlur, cv::Size(3,3), 0);

    // This kernel helps us to recognize white on white
    cvMatKernel = cv::getStructuringElement(cv::MORPH_RECT, cv::Size(MORPH, MORPH));
    cv::dilate(cvMatBlur, cvMatEdged, cvMatKernel);

    // Canny Edge Detection Algorithm is used
    cv::Canny(cvMatEdged, cvMatEdged, 4, CANNY);

    // Hough Lines on the image with edged stored in
    std::vector<cv::Vec4i> lines;
    lines.clear();
    cv::HoughLinesP(cvMatEdged, lines, 1, CV_PI/180, HOUGH);
    std::vector<cv::Vec4i>::iterator it = lines.begin();
    for(; it!=lines.end(); ++it) {
        cv::Vec4i l = *it;
        cv::line(cvMatEdged, cv::Point(l[0], l[1]), cv::Point(l[2], l[3]), cv::Scalar(255,0,0), 3, cv::LINE_8);
    }

    // Start detecting
    Detector::cList contours;
    std::vector<cv::Vec4i> hierarchy;
    cv::Mat drawing = cv::Mat::zeros(cvMat.size(), CV_8UC3);
    cv::findContours(cvMatEdged, contours, hierarchy, cv::RETR_EXTERNAL, cv::CHAIN_APPROX_SIMPLE);

    // Contour properties
    int largest_area = 0;
    int largest_contour_index = 0;
    cv::Scalar red_color = cv::Scalar(255,0,0);
    cv::Scalar green_color = cv::Scalar(0,255,0);
    int thick = 3;
    cv::Rect bounding_rect;
    // Which contours create a polygon? it can examine in here
    // Iterate
    for (int i=0; i < contours.size(); i++) {
        double area = cv::contourArea(contours[i], false);  //  Find the area of contour
        if (area > largest_area)
        {
            largest_area = (int) area;
            largest_contour_index = i;
            bounding_rect = cv::boundingRect(contours[i]);
        }
    }
    result = contours;
    bbox = bounding_rect;
    cv::drawContours(drawing, contours, largest_contour_index, red_color, thick, cv::LINE_8, hierarchy, 0);
    cv::rectangle(drawing, bounding_rect, green_color, thick, cv::LINE_8, 0);
    return drawing;
}

cv::Mat Detector::barcodeDetector(cv::Mat &captured, cv::Rect &bbox)
{
    std::vector<std::string> barcodes;
    // The function connected to endless function
    // so we always have to initialize data
    barcodes.clear();
    cv::Mat gray;
    cv::Mat drawing = cv::Mat::zeros(captured.size(), CV_8UC3);
    // if you see the bounding box on the original image
    // uncomment below
//    captured.copyTo(drawing);
    zbar::ImageScanner scanner;
    scanner.set_config(ZBAR_NONE,ZBAR_CFG_ENABLE, 1);
    cv::cvtColor(captured, gray, cv::COLOR_BGR2GRAY);

    int width = gray.cols;
    int height = gray.rows;

    zbar::Image zbarImg(width, height, "Y800", (uchar *) gray.data, width * height);
    int result = scanner.scan(zbarImg);
    if (result)
        std::cout << result << " Barcode detected!" << std::endl;
    for (Image::SymbolIterator symbol = zbarImg.symbol_begin(); symbol != zbarImg.symbol_end(); ++symbol) {
        std::vector<cv::Point> vp;
        // do something useful with results
        //std::cout << "decoded " << symbol->get_type_name() << " symbol \"" << symbol->get_data() << '"' << " " << std::endl;
        barcodes.push_back(symbol->get_data());

        // Uncomment below if you want to see the range of barcode or qr!
        int k = symbol->get_location_size();
        for(int i=0; i<k; i++){
            vp.push_back(cv::Point(symbol->get_location_x(i),symbol->get_location_y(i)));
        }
        cv::RotatedRect r = cv::minAreaRect(vp);
        bbox = r.boundingRect();
        cv::Point2f pts[4];
        r.points(pts);
        for(int i=0; i<4; i++){
            cv::line(drawing, pts[i], pts[(i+1)%4], cv::Scalar(255,0,0), 3);
        }
//        std::cout<< "Angle: " << r.angle << std::endl;
    }
    return drawing;
}

#pragma mark - Private
