//
//  LibFolderManager.m
//  InvoiceRecognition
//
//  Created by Berkay Vurkan on 26.10.2020.
//

#import "LibFolderManager.h"

@implementation LibFolderManager


#pragma mark Utils

@synthesize videosPath, imagesPath, logsPath;

+ (id)shared
{
    static LibFolderManager *folderManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        folderManager = [[self alloc] init];
    });
    return folderManager;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        NSArray *directoryPaths = NSSearchPathForDirectoriesInDomains
        (NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectoryPath = [directoryPaths objectAtIndex:0];
        self.docsPath = [[NSURL alloc] initWithString:documentsDirectoryPath];

        self->videoFolderName = @"Videos";
        self->imageFolderName = @"Images";
        self->logFolderName = @"Logs";

        // Initialize folder URL
        // and create directories if not exist
        [self preparePaths];
    }
    return self;
}

- (void)dealloc
{
    // Remove paths
    self.videosPath = nil;
    self.imagesPath = nil;
    self.logsPath = nil;
}


#pragma mark Public

- (void)saveImage:(UIImage *)img
{
    if (self.imagesPath != nil)
    {
        NSDate *today = [[NSDate alloc] init];
        NSString *filename = [NSString stringWithFormat:@"%.0f.png", [today timeIntervalSince1970]];
        // Manager
        NSFileManager *defaultManager = [NSFileManager defaultManager];
        NSURL *fullPath = [self.imagesPath URLByAppendingPathComponent:filename];
        if (![defaultManager fileExistsAtPath:[fullPath relativePath]])
            [UIImagePNGRepresentation(img) writeToFile:[fullPath relativePath] atomically:YES];
    }
}


#pragma mark Private

- (NSURL*)createDirIfNotExist:(NSString *)fullPath
{
    if (!(fullPath))
        return nil;
    // Manager
    NSFileManager *defaultManager = [NSFileManager defaultManager];

    BOOL isDir;
    BOOL exists = [defaultManager fileExistsAtPath:fullPath isDirectory:&isDir];
    if (!(exists && isDir))
    {
        NSError *error = nil;
        BOOL success = [defaultManager createDirectoryAtPath:fullPath withIntermediateDirectories:NO attributes:nil error:&error];
        if (!success || error)
            NSLog(@"Error: %@", [error localizedDescription]);
    }
    return [[NSURL alloc] initWithString:fullPath];;
}

- (void)preparePaths
{
    if (!(self.docsPath))
        return;
    NSURL *libPathURL = [self.docsPath URLByAppendingPathComponent:@"Lib"];
    [self createDirIfNotExist:[libPathURL relativePath]];
    self.videosPath = [self createDirIfNotExist:[[libPathURL URLByAppendingPathComponent:self->videoFolderName] relativePath]];
    self.imagesPath = [self createDirIfNotExist:[[libPathURL URLByAppendingPathComponent:self->imageFolderName] relativePath]];
    self.logsPath = [self createDirIfNotExist:[[libPathURL URLByAppendingPathComponent:self->logFolderName] relativePath]];
}

@end
