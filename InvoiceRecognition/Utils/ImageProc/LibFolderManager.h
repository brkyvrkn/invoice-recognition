//
//  LibFolderManager.h
//  InvoiceRecognition
//
//  Created by Berkay Vurkan on 26.10.2020.
//

#ifndef LibFolderManager_h
#define LibFolderManager_h

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface LibFolderManager: NSObject {
    NSString* videoFolderName;
    NSString* imageFolderName;
    NSString* logFolderName;
}

@property (nonatomic, retain) NSURL* videosPath;
@property (nonatomic, retain) NSURL* imagesPath;
@property (nonatomic, retain) NSURL* logsPath;
@property (nonatomic, retain) NSURL* docsPath;

+(id) shared;
-(void) saveImage: (UIImage*)img;

@end


#pragma mark Private

@interface LibFolderManager()

-(NSURL*) createDirIfNotExist: (NSString*)fullPath;
-(void) preparePaths;

@end

#endif /* LibFolderManager_h */
