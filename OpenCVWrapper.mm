//
//  OpenCVWrapper.mm
//
//  Created by Berkay Vurkan on 08/08/2017.
//  Copyright © 2017 Berkay Vurkan. All rights reserved.
//

#import "OpenCVWrapper.h"

@implementation OpenCVWrapper

-(void) isWorking
{
    std::cout << CV_VERSION << std::endl;
}

@end
