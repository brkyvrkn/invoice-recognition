//
//  OpenCVWrapper.m
//  InvoiceRecognition
//
//  Created by Berkay Vurkan on 11.10.2020.
//

#import "OpenCVWrapper.h"

@implementation OpenCVWrapper
{
    CvVideoCamera* videoCamera;
}

@synthesize lastProcessedFrame;
@synthesize lastBoundingBox;


#pragma mark Methods

-(void)isWorking
{
    std::cout << "OpenCV working with v" << CV_VERSION << std::endl;
}

-(void)zbarIsWorking
{
    unsigned int major, minor;
    zbar::zbar_version(&major, &minor);
    std::cout << "ZBarSDK working with v" << major << "." << minor << std::endl;
}


#pragma mark CV Camera

- (void)connectToCVCamera:(UIView *)inView
{
    self->videoCamera = [[CvVideoCamera alloc] initWithParentView:inView];
    self->videoCamera.delegate = self;
    self->videoCamera.defaultAVCaptureSessionPreset = AVCaptureSessionPreset1920x1080;
    self->videoCamera.defaultAVCaptureDevicePosition = AVCaptureDevicePositionBack;
    self->videoCamera.defaultAVCaptureVideoOrientation = AVCaptureVideoOrientationPortrait;
    self->videoCamera.defaultFPS = 30;
    self->videoCamera.grayscaleMode = NO;
}

- (void)disconnectFromCVCamera:(UIView *)inView
{
    if (self->videoCamera.parentView != inView)
    {
        return;
    }
    self->videoCamera.delegate = nil;
}


#pragma mark Event APIs

-(void)analyzeFrame:(UIImage *)frame
{
    cv::Mat imgMat;
    UIImageToMat(frame, imgMat);

    cv::Mat imgGrayMat;
    cv::cvtColor(imgMat, imgGrayMat, cv::COLOR_BGR2GRAY);

    Detector detector;
    Detector::cList result;
    cv::Rect bounding_box;
    cv::Mat output = detector.contourDetector(imgMat, result, bounding_box);
    UIImage* outputImage = MatToUIImage(output);
    [LibFolderManager.shared saveImage:outputImage];
    self.lastProcessedFrame = outputImage;
    self.lastBoundingBox = CGRectMake(bounding_box.tl().x, bounding_box.tl().y, bounding_box.width, bounding_box.height);
    return;
}

- (void)detectBarcode:(UIImage *)frame
{
    cv::Mat imgMat;
    UIImageToMat(frame, imgMat);

    Detector detector;
    cv::Rect bbox;
    cv::Mat output = detector.barcodeDetector(imgMat, bbox);
    UIImage* outputImage = MatToUIImage(output);
    [LibFolderManager.shared saveImage:outputImage];
    self.lastProcessedFrame = outputImage;
    self.lastBoundingBox = CGRectMake(bbox.tl().x, bbox.tl().y, bbox.width, bbox.height);
}

- (void)bufferToMat:(CVPixelBufferRef *)ref
{
    
}

+ (cv::Mat)bufferToMat:(CVPixelBufferRef &)ref
{
    CVPixelBufferLockBaseAddress(ref, 0);
    void *baseaddress = CVPixelBufferGetBaseAddressOfPlane(ref, 0);
    CGFloat width = CVPixelBufferGetWidth(ref);
    CGFloat height = CVPixelBufferGetHeight(ref);
    cv::Mat imgMat = cv::Mat(height, width, CV_8UC1, baseaddress, 0);
    CVPixelBufferUnlockBaseAddress(ref, 0);
    return imgMat;
}


#pragma mark CVVideo Delegate

- (void)processImage:(cv::Mat &)image
{
    
}

@end
