//
// Copyright © 2021-2022 THALES. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ObjCSwift.h"

@implementation ObjCSwift

+ (id)catchException:(id(^)(void))tryBlock error:(__autoreleasing NSError **)error {
    @try {
        id result = tryBlock();
        return result;
    }
    @catch (NSException *exception) {
        if (error) {
            *error = [[NSError alloc] initWithDomain:exception.name code:0 userInfo:exception.userInfo];
        }
        return nil;
    }
}

@end

