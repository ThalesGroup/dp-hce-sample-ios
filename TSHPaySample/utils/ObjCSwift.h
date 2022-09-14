//
// Copyright © 2021-2022 THALES. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ObjCSwift : NSObject

//function for catch NSException that is raised Firebase configure
+ (id)catchException:(id(^)(void))tryBlock error:(__autoreleasing NSError **)error;

@end
