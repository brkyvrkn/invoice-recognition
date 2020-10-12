//
//  Detector.cpp
//  InvoiceRecognition
//
//  Created by Berkay Vurkan on 11.10.2020.
//

#include "Detector.hpp"
#import "ZBarSDK.h"

// MARK: - Public

int Detector::containsInvoice(cv::Mat imgMat)
{
    return 0;
}

// MARK: - Private

std::vector<std::string> barcodeReader(cv::Mat cap)
{
    std::vector<std::string> barcodes;      //To reach the barcodes and QRs we stored
    barcodes.clear();           //The function connected to endless function so that we always have to initialize datas
    cv::Mat gray;
    zbar::ImageScanner scanner;
    scanner.set_config(ZBAR_NONE,ZBAR_CFG_ENABLE, 1);
    cv::cvtColor(cap, gray, cv::COLOR_BGR2GRAY);

    int width = gray.cols;
    int height = gray.rows;
    uchar *raw = (uchar *)(gray.data);

    zbar::Image zbarImg(width, height, "Y800", raw, width * height);
    int n = scanner.scan(zbarImg);
    if(n)
        NSLog(@"%d Barcode detected",n);

    for(Image::SymbolIterator symbol = zbarImg.symbol_begin(); symbol != zbarImg.symbol_end(); ++symbol) {
        std::vector<cv::Point> vp;
        // do something useful with results
        std::cout << "decoded " << symbol->get_type_name()  << " symbol \"" << symbol->get_data() << '"' <<" "<< std::endl;
        barcodes.push_back(symbol->get_data());

        //////////////////////// Uncomment if you want to see the range of barcode or qr! ////////////////////////
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
