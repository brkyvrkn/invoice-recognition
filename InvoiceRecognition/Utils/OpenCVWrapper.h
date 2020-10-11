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

@interface OpenCVWrapper: NSObject

-(void) isWorking;
-(BOOL) containsInvoice: (UIImage*) captured;

@end
