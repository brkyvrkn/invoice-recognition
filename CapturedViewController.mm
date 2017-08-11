//
//  CapturedViewController.mm
//
//  Created by Berkay Vurkan on 08/08/2017.
//  Copyright © 2017 Berkay Vurkan. All rights reserved.
//

#import "CapturedViewController.h"

@interface CapturedViewController ()

@end

@implementation CapturedViewController

typedef std::vector<std::vector<cv::Point>> cList;

@synthesize diagnosticLabel,scanButton,textView;

- (void)viewDidLoad {
    [super viewDidLoad];
    NSLog(@"in Captured View Controller");      //info
    
    self->indicator.removeFromSuperViewOnHide = YES;
    [diagnosticLabel setText:@"Invoice Completely Detected!"];
    
    }

- (void)didReceiveMemoryWarning {   [super didReceiveMemoryWarning];    }

//whole set method in one function, this could be wrong in object-oriented principles :)
-(void) setInstances: (NSString*) contentss : (UIImage*) img {
    [textView setText:contentss];
    self->imgWithBound = img;
    
}

-(void) goToBackView{
    dispatch_async(dispatch_get_main_queue(), ^(void){
        NSLog(@"%@",self.navigationController.viewControllers);         //back trace of hierarchy
        UINavigationController *navg = self.navigationController;
        [navg popViewControllerAnimated:YES];
    });
}

- (IBAction)scanAgainPressed:(id)sender {
    [self goToBackView];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
