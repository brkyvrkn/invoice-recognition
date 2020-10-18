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

- (void)saveToDocuments:(UIImage*)img
{
    //Get documents directory
    NSArray *directoryPaths = NSSearchPathForDirectoriesInDomains
    (NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectoryPath = [directoryPaths objectAtIndex:0];
    NSDate *today = [[NSDate alloc] init];
    NSString *name = @"lib_image";

    NSString *folderName = @"Lib";
    NSString *filename = [NSString stringWithFormat:@"%.0f_%@.png", [today timeIntervalSince1970], name];
    NSString *folderPath = [documentsDirectoryPath stringByAppendingPathComponent: folderName];
    NSString *filePath = [folderPath stringByAppendingPathComponent: filename];

    [UIImagePNGRepresentation(img) writeToFile:filePath atomically:YES];
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

-(CGRect*)analyzeFrame:(UIImage *)frame
{
    cv::Mat imgMat;
    UIImageToMat(frame, imgMat);

    cv::Mat imgGrayMat;
    cv::cvtColor(imgMat, imgGrayMat, cv::COLOR_BGR2GRAY);

    Detector detector;
    std::vector<double> result;
    detector.invoiceDetector(imgMat, imgGrayMat, result);
    if (result.size() == 4) {
        CGFloat x = result[0];
        CGFloat y = result[1];
        CGFloat width = result[2];
        CGFloat height = result[3];
        CGRect rect = CGRectMake(x, y, width, height);
        CGRect* ref = &rect;
        return ref;
    }
    return NULL;
}

- (void)detectBarcode:(UIImage *)frame
{
    [self saveToDocuments:frame];
    cv::Mat imgMat;
    UIImageToMat(frame, imgMat);

    Detector detector;
    detector.barcodeDetector(imgMat);
    self.lastProcessedFrame = MatToUIImage(imgMat);
}


#pragma mark CVVideo Delegate

- (void)processImage:(cv::Mat &)image
{
    
}

@end
