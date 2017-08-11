//
//  RestAPI.m
//  Invioce_Recognition
//
//  Created by Berkay Vurkan on 08/08/2017.
//  Copyright © 2017 Berkay Vurkan. All rights reserved.
//

#import "RestAPI.h"

@implementation RestAPI

@synthesize request,jpgData;

-(NSDictionary*) getResponseFromServer: (UIImage*) invoice {
    //UIImage converting to JPEG representation due to allowing of server just that format!
    self.jpgData = UIImageJPEGRepresentation(invoice, 1.0);
    
    request = [NSMutableURLRequest new];
    request.timeoutInterval = 30.0;
    [request setURL:[NSURL URLWithString:@"http://api.snapbuyapp.com/fatura"]];
    [request setHTTPMethod:@"POST"];
    
    NSString *boundary = @"---------------------------14737809831466499882746641449";
    
    NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@",boundary];
    [request addValue:contentType forHTTPHeaderField: @"Content-Type"];
    
    NSMutableData *body = [NSMutableData data];
    
    //Body format will create as the type which server wants
    [body appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"image\"; filename=\"%@.jpeg\"\r\n",@"Uploaded_File"] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[@"Content-Type: application/octet-stream\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[NSData dataWithData:jpgData]];
    [body appendData:[[NSString stringWithFormat:@"\r\n--%@--\r\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    
    //Request creates with x-api-key
    [request addValue:[NSString stringWithFormat:@"%lu", (unsigned long)[body length]] forHTTPHeaderField:@"Content-Length"];
    [request addValue:@"42546d5fca228d75ffdaffcb7be799b8c1f39ab3b27f0efb6d69ba4c8362" forHTTPHeaderField:@"x-api-key"];
    [request setHTTPBody:body];     //includes body to http request
    
    NSLog(@"REQ: %@",request);      //We can see the request in the log
    
    //Getting Response from server and states whether status code is 200,202 or not?
    NSError *error = nil;
    NSHTTPURLResponse *urlResponse = nil;
    NSData *syncResData = [NSURLConnection sendSynchronousRequest:request returningResponse:&urlResponse error:&error];
    if ([urlResponse statusCode] >= 200 && [urlResponse statusCode]<=299) {
        NSDictionary *returnDict = [NSJSONSerialization JSONObjectWithData:syncResData options:NSJSONReadingAllowFragments error:&error];
        NSLog(@"ERROR %@", error);
        NSLog(@"RES %@", urlResponse);
        NSLog(@"RETURNING %@", returnDict);
        return returnDict;
    }
    //if not such 400,404,500 etc. it s gonna execute 'else' statement
    else{
        NSLog(@"Error %@",error);
        NSLog(@"HTTP Request error %@", urlResponse);
        return nil;
    }
}

@end
