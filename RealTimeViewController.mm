//
//  RealTimeViewController.m
//  Invioce_Recognition
//
//  Created by Berkay Vurkan on 08/08/2017.
//  Copyright © 2017 Berkay Vurkan. All rights reserved.
//

#import "RealTimeViewController.h"

@interface RealTimeViewController ()

@end

@implementation RealTimeViewController

//////////// GLOBAL VARIABLES TO REACH EVERYWHERE AND THEY CANNOT OCCUR ANY THREATH FOR SECURITY OF CODE ////////////

typedef std::vector<std::vector<cv::Point>> cList;          //contour storing type! 
cv::Rect rect_of_roi(WIDTH/7,HEIGHT/8,5*WIDTH/7,3*HEIGHT/4);        //Region of interest boundswith global variable!
cv::Rect barcode_band(WIDTH/3,HEIGHT/1.92,5*WIDTH/12,HEIGHT/3);       //Band of barcode
cv::Point tr = cv::Point(rect_of_roi.br().x,rect_of_roi.tl().y);
cv::Point bl = cv::Point(rect_of_roi.tl().x,rect_of_roi.br().y);
float activation = 0.0;
NSTimer *timer;

@synthesize videoCamera,imageView;

////////////////////////////////////***************************////////////////////////////////////

- (void)viewDidLoad {
    [super viewDidLoad];
    NSLog(@"inside the RealTimeViewController");        //info
    [self initInstances];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void) initInstances{
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            //video camera initializes with requirements inda parent view is imageView
            self.videoCamera = [[CvVideoCamera alloc]initWithParentView:imageView];
            self.videoCamera.delegate = self;
            
            self.videoCamera.defaultAVCaptureDevicePosition = AVCaptureDevicePositionBack;
            self.videoCamera.defaultAVCaptureVideoOrientation = AVCaptureVideoOrientationPortrait;
            self.videoCamera.defaultAVCaptureSessionPreset = AVCaptureSessionPresetHigh;
            self.videoCamera.defaultFPS = 30;
            [self.videoCamera start];
            timer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(timerUpper) userInfo:nil repeats:YES];
            
            self->indicator = [[MBProgressHUD alloc] init];
            [self.imageView addSubview:self->indicator];
            self->indicator.mode = MBProgressHUDModeIndeterminate;
            
            self->toast = [MBProgressHUD showHUDAddedTo:self.imageView animated:YES];
            [self.imageView addSubview:toast];
            self->toast.mode = MBProgressHUDModeText;
            self->toast.label.text = @"Processing the Capture...";
            self->toast.margin = 10.f;
            [self->toast setYOffset:HEIGHT*3/4];         //y-offset can be assigned dynamically 0.75 times of its height!
            [self->toast hideAnimated:YES afterDelay:2];
        });
    });
}

-(void) timerUpper{
    activation+=0.1;// timer increments with .1 in another thread
}       

- (void)processImage:(cv::Mat&)image
{
    cv::line(image, rect_of_roi.tl(), tr , cv::Scalar(0,0,255,188),2,cv::LINE_8);
    cv::line(image, bl , rect_of_roi.br(), cv::Scalar(0,0,255,188),2,cv::LINE_8);
    //cv::rectangle(image, barcode_band, cv::Scalar(255,0,0,255));      //Uncomment to see area of scanning barcode
    if ([self detection:image].size() != 0)
    {
        cv::Mat roi;
        roi = image(rect_of_roi);       // Crop the Region of interest for finding the contours
        if ([self blueColor:roi : image] and [self invoiceDetector:roi :image]) {
            NSLog(@"Timer in detection %.1f",activation);
            if (activation >= EPS) {
                NSLog(@"Enough Time %.1f",activation);
                //  If it can recognize the invoice and define all of its instances, pass to 'if' stmnt
                if([self connectToServer: [self detection:image]]){
                    activation = 0.0;
                    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [self performSegueWithIdentifier:@"CaptureSegue" sender:self];      //passing next ViewController
                        });
                    });
                }
            }
        }
        else{
            //If the recognized barcode not any defined range which consists of invoice
            activation = 0.0;
        }
    }
    else{
        //IF not any barcode or QR
        activation = 0;
        self->captured = image.clone();
        return;
    }
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString:@"CaptureSegue"]) {
        //  Main thread is processed on the 'processImage' function
        //  Therefore, changing in the UI must be done in the another thread which have included in the main queue
        
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
            dispatch_async(dispatch_get_main_queue(), ^{
                [timer invalidate];     //Thread deallocation due to the fact that I want to avoid memory leak!
                timer = nil;            //Realasing
                activation = 0.0;       //Timer counter is activation will be zero
                [self.videoCamera stop];
                
                //  Assigning the instance of nextViewController
                CapturedViewController* nextView = [[CapturedViewController alloc]init];
                nextView->indicator = self->indicator;
                nextView = [segue destinationViewController];
                [nextView setInstances: self->contents : [self classifyMatWithROI]];
            });
        });
    }
}

#pragma mark - ConnectionToServer

-(BOOL) connectToServer: (std::vector<std::string>) barcodes
{
    //Chahnging on UI will execute in another thread which pushs to queue
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        dispatch_async(dispatch_get_main_queue(), ^(void){
            self->indicator = [MBProgressHUD showHUDAddedTo:self.imageView animated:YES];
            [self->indicator setOpacity:0.7];
            self->indicator.label.text = @"Invoice Detected!";
            self->indicator.detailsLabel.text = @"Invoice is sending to the server...";
        });
    });
    
    //  Detected image sends to the server via RestAPI NSObject
    RestAPI *restApi = [[RestAPI alloc] init];
    NSDictionary *respJSON = [restApi getResponseFromServer:[self classifyMatWithROI]];
    
    //  if Request status code be 200,202, will hold below stmnt
    if (respJSON != nil && [self parseInstances:respJSON :barcodes]){
        NSLog(@"Server has read it");
        //Labels are assigned as the information of recognized image
        return true;
    }
    else{
        NSLog(@"It could not read");
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
            dispatch_async(dispatch_get_main_queue(), ^(void){
                //necessary one of them is not recognized
                self->indicator.detailsLabel.text = @"";
                [self->indicator setOpacity:0.7];
                self->indicator.label.text = @"Reprocessing is begining...";
                [self->indicator hideAnimated:YES afterDelay:1.5];
                activation = 0.0f;      //timer activation init
            });
        });
        return false;
    }
}

#pragma mark - CropImage
/*  At the time we recognized, actually don't crop the image, it just scan the specific bound which defined above
 *  In this function, it crops the image based on the rect_of_roi after detection
 */
-(UIImage*) classifyMatWithROI{
    UIImage* img = MatToUIImage(self->captured);
    int xCoord = rect_of_roi.tl().x;   //x coordinate of Top-left
    int yCoord = rect_of_roi.tl().y;    //y coordinate of Top-Left
    int width = rect_of_roi.width;
    int height = rect_of_roi.height;
    CGRect bound = CGRectMake(xCoord, yCoord, width, height);
    CGImageRef imgRef = CGImageCreateWithImageInRect([img CGImage], bound);
    UIImage* cropped = [UIImage imageWithCGImage:imgRef];
    return cropped;
    //return MatToUIImage(self->captured(rect_of_roi));         //This is not recommend due to the noisy in the image can happen and it corrupts the quality of image.
    
}

#pragma mark - BarcodeQRreader

-(std::vector<std::string>) barcodeReader: (cv::Mat) cap {
    std::vector<std::string> barcodes;      //To reach the barcodes and QRs we stored
    barcodes.clear();           //The function connected to endless function so that we always have to initialize datas
    cv::Mat gray;
    zbar::ImageScanner scanner;
    scanner.set_config(ZBAR_NONE,ZBAR_CFG_ENABLE, 1);
    cv::cvtColor(cap, gray, CV_BGR2GRAY);
    
    int width = gray.cols;
    int height = gray.rows;
    uchar *raw = (uchar *)(gray.data);
    
    zbar::Image zbarImg(width, height, "Y800", raw, width * height);
    int n = scanner.scan(zbarImg);
    if(n)
        NSLog(@"%d Barcode detected",n);
    
    for(Image::SymbolIterator symbol = zbarImg.symbol_begin();
        symbol != zbarImg.symbol_end();
        ++symbol) {
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

//* Just simple initialize function
-(std::vector<std::string>) detection: (cv::Mat&) image{
    cv::Mat mat = image(barcode_band);
    return [self barcodeReader:mat];
}

-(BOOL) blueColor: (cv::Mat&) cap : (cv::Mat&)image{
    cv::Mat cameraFeed = cap;
    cv::Mat HSV, threshold;
    cv::cvtColor(cameraFeed, HSV, CV_BGR2HSV);
    cv::inRange(HSV, cv::Scalar(90,50,50), cv::Scalar(130,255,255), threshold);       //blue-color detector
    //cv::inRange(HSV,cv::Scalar(255,255,255),cv::Scalar(255,222,173),threshold);
    
    cv::Mat erodeElement = getStructuringElement( cv::MORPH_RECT,    cvSize(3,3));
    //dilate with larger element so make sure object is nicely visible
    cv::Mat dilateElement = getStructuringElement(  cv::MORPH_RECT,cvSize(3,3));
    
    erode(threshold,threshold,erodeElement);
    erode(threshold,threshold,erodeElement);
    
    dilate(threshold,threshold,dilateElement);
    dilate(threshold,threshold,dilateElement);
    
    cv::Mat temp;
    threshold.copyTo(temp);
    cList contours;
    std::vector<cv::Vec4i> hierarchy;
    
    findContours( temp, contours, hierarchy, CV_RETR_EXTERNAL,  CV_CHAIN_APPROX_SIMPLE, cv::Point(0, 0) );
    
    bool objectFound = false;
    if (hierarchy.size() > 0) {
        
        for (int index = 0; index >= 0; index = hierarchy[index][0]) {
            
            cv::Moments moment = moments((cv::Mat)contours[index]);
            double area = moment.m00;
            if(area > 5000)
                objectFound = true;
            else
                objectFound = false;
        }
        
    }
    return objectFound;
}

#pragma mark - InvoiceDetection
-(BOOL) invoiceDetector:(cv::Mat&)cvMat :(cv::Mat&)image
{
    cv::Mat cvMatGray,cvMatBlur,cvMatEdged,cvMatKernel;
    cv::cvtColor(cvMat, cvMatGray, CV_BGR2GRAY);
    cv::GaussianBlur(cvMatGray, cvMatBlur, cv::Size(3,3), 0);
    
    //This kernel helps us to recognize white on white
    cvMatKernel = cv::getStructuringElement(cv::MORPH_RECT, cv::Size(MORPH,MORPH));
    cv::dilate(cvMatBlur, cvMatEdged, cvMatKernel);
    
    //Canny Edge Detection Algorithm is used
    cv::Canny(cvMatEdged, cvMatEdged, 4, CANNY);
    
    std::vector<cv::Vec4i> lines;       //Hough Lines on the image with edged stored in
    lines.clear();
    cv::HoughLinesP(cvMatEdged, lines, 1, CV_PI/180, HOUGH);
    std::vector<cv::Vec4i>::iterator it = lines.begin();
    for(; it!=lines.end(); ++it) {
        cv::Vec4i l = *it;
        cv::line(cvMatEdged, cv::Point(l[0], l[1]), cv::Point(l[2], l[3]), cv::Scalar(255,0,0), 3, cv::LINE_8);
    }
    
    //Finding contours and will sort ascending order and to get the last element which has the biggest contour area
    cList contours;
    cv::findContours(cvMatEdged, contours, CV_RETR_EXTERNAL, CV_CHAIN_APPROX_SIMPLE);
    
    if (contours.size()>0)
        contours =[self strechList:[self sortContoursByArea:contours] :1];
    
    //Which contours create a polygon? it can examine in here
    cList contourPolygon = cList(contours.size());
    for (int i=0; i < contours.size(); i++){
        cv::approxPolyDP(cv::Mat(contours[i]), contourPolygon[i], 40, true);
        if (contourPolygon[i].size() == 4)
            return true;
    }
    return false;
}

#pragma mark - SupportFunctions

-(BOOL) parseInstances: (NSDictionary*) json : (std::vector<std::string>) barcode{
    self->contents = @"";
    if ([[json objectForKey:@"type"] isEqualToString:@""] and [[[json objectForKey:@"details"][0] objectForKey:@"value"] isEqualToString:@""] and [[[json objectForKey:@"details"][1] objectForKey:@"value"] isEqualToString:@""])
        return false;
    else
    {
        if(![[json objectForKey:@"type"] isEqualToString:@""]){
            self->contents = [self->contents stringByAppendingString:[NSString stringWithFormat:@"%@ : \t\t %@\n",@"Invoice Type",[json objectForKey:@"type"]]];
        }
        for (NSDictionary *inst in [json objectForKey:@"details"])
        {
            if (![[inst objectForKey:@"value"] isEqualToString:@""])
                self->contents = [self->contents stringByAppendingString:[NSString stringWithFormat:@"%@  \t\t %@\n",[inst objectForKey:@"name"],[inst objectForKey:@"value"]]];
        }
        for (int i=0; i<barcode.size(); i++)
        self->contents = [self-> contents stringByAppendingString:[NSString stringWithFormat:@"%d. Barcode value :  %s\n",i+1,barcode.at(i).c_str()]];
        NSLog(@"TextView shown as : %@",self->contents);
        return true;
    }
}

-(cList) sortContoursByArea: (cList) contourList
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

-(cList) strechList: (cList) contourList : (NSInteger) elem
{
    //So as to eliminate contours
    NSInteger c = contourList.size()-1;   int t=1;
    cList nwContourList = cList(elem);
    while (elem != 0)
    {
        //NSLog(@"The %d. biggest area: %.2f",t,cv::contourArea(contourList[c]));   To see area of biggest reactangle
        nwContourList.push_back(contourList[c]);
        elem-=1;    t+=1;
        c-=1;
    }
    return nwContourList;
}

@end
