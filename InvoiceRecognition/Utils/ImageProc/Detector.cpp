//
//  Detector.cpp
//  InvoiceRecognition
//
//  Created by Berkay Vurkan on 11.10.2020.
//

#include "Detector.hpp"
#import "ZBarSDK.h"

#pragma mark - Public

int Detector::containsInvoice(cv::Mat imgMat)
{
    return 0;
}

void Detector::invoiceDetector(cv::Mat &cvMat, cv::Mat &image, std::vector<double> &result)
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

    // Finding contours and will sort ascending order and
    // to get the last element which has the biggest contour area
    Detector::cList contours;
    ImgProcessor processor;
    cv::findContours(cvMatEdged, contours, cv::RETR_EXTERNAL, cv::CHAIN_APPROX_SIMPLE);
    if (contours.size() > 0)
        contours = processor.strechList(processor.sortContoursByArea(contours), 1);

    //Which contours create a polygon? it can examine in here
    Detector::cList contourPolygon = Detector::cList(contours.size());
    for (int i=0; i < contours.size(); i++){
        cv::approxPolyDP(cv::Mat(contours[i]), contourPolygon[i], 40, true);
        if (contourPolygon[i].size() == 4)
            return;
    }
    return;
}

std::vector<std::string> Detector::barcodeDetector(cv::Mat cap)
{
    std::vector<std::string> barcodes;
    // The function connected to endless function so we always have to initialize data
    barcodes.clear();
    cv::Mat gray;
    zbar::ImageScanner scanner;
    scanner.set_config(ZBAR_NONE,ZBAR_CFG_ENABLE, 1);
    cv::cvtColor(cap, gray, cv::COLOR_BGR2GRAY);

    int width = gray.cols;
    int height = gray.rows;

    zbar::Image zbarImg(width, height, "Y800", (uchar *) gray.data, width * height);
    int n = scanner.scan(zbarImg);
    if (n)
        NSLog(@"%d Barcode detected",n);

    for (Image::SymbolIterator symbol = zbarImg.symbol_begin(); symbol != zbarImg.symbol_end(); ++symbol) {
        std::vector<cv::Point> vp;
        // do something useful with results
        std::cout << "decoded " << symbol->get_type_name() << " symbol \"" << symbol->get_data() << '"' << " " << std::endl;
        barcodes.push_back(symbol->get_data());

        // Uncomment below if you want to see the range of barcode or qr!
        /*
         int k = symbol->get_location_size();
         for(int i=0;i<k;i++){
         vp.push_back(cv::Point(symbol->get_location_x(i),symbol->get_location_y(i)));
         }
         cv::RotatedRect r = cv::minAreaRect(vp);
         cv::Point2f pts[4];
         r.points(pts);
         for(int i=0;i<4;i++){
         cv::line(cap,pts[i],pts[(i+1)%4],cv::Scalar(255,0,0),3);
         }
         //cout<<"Angle: "<<r.angle<<endl;
         */
    }
    return barcodes;
}

#pragma mark - Private
