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
    cv::Mat output = detector.contourDetector(imgMat, imgGrayMat, result);
    UIImage* outputImage = MatToUIImage(output);
    [LibFolderManager.shared saveImage:outputImage];
    self.lastProcessedFrame = outputImage;
    return;
}

- (void)detectBarcode:(UIImage *)frame
{
    cv::Mat imgMat;
    UIImageToMat(frame, imgMat);

    Detector detector;
    detector.barcodeDetector(imgMat);
    self.lastProcessedFrame = MatToUIImage(imgMat);
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
