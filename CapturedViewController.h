//
//  CapturedViewController.h
//  Invioce_Recognition
//
//  Created by Berkay Vurkan on 08/08/2017.
//  Copyright © 2017 Berkay Vurkan. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "OpenCVWrapper.h"
#import "RestAPI.h"

@interface CapturedViewController : UIViewController{
    @private UIImage* imgWithBound;
    @public MBProgressHUD* indicator;
    @private int counter;
    @private NSTimer* timer;
    @public NSString *invoiceType,*clientNumber,*cost;
}
/*
 *  Declarates the instances of invoice which are below
 */
@property (strong, nonatomic) IBOutlet UITextView *textView;
@property (strong, nonatomic) IBOutlet UILabel *diagnosticLabel;
@property (strong, nonatomic) IBOutlet UIButton *scanButton;

- (IBAction)scanAgainPressed:(id)sender;
- (void)goToBackView;
-(void) setInstances: (NSString*) contentss : (UIImage*) img;
@end
