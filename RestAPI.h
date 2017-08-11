//
//  RestAPI.h
//  Invioce_Recognition
//
//  Created by Berkay Vurkan on 08/08/2017.
//  Copyright © 2017 Berkay Vurkan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

/*
 * Image sending and getting response
 * Response in Json Format
 */
@interface RestAPI : NSObject<NSURLConnectionDataDelegate>{
    NSDictionary* dataWithJSON;
}

@property (strong,nonatomic) NSMutableURLRequest *request;
@property (nonatomic, strong) NSData *jpgData;

-(NSDictionary*) getResponseFromServer:(UIImage*) invoice;

@end
