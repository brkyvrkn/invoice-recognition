//
//  OpenCVWrapper.h
//  InvoiceRecognition
//
//  Created by Berkay Vurkan on 11.10.2020.
//

#ifndef OpenCVWrapper_h
#define OpenCVWrapper_h

#endif /* OpenCVWrapper_h */

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <CoreGraphics/CoreGraphics.h>

@interface OpenCVWrapper: NSObject

#pragma mark Event APIs

-(void) isWorking;
-(void) zbarIsWorking;
-(CGRect*) analyzeFrame: (UIImage*) frame;
-(void) detectBarcode: (UIImage*) frame;

@end
