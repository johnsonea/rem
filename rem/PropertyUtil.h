//
//  PropertyUtil.m
//  copied from https://stackoverflow.com/questions/754824/get-an-object-properties-list-in-objective-c

#ifndef PropertyUtil_h
#define PropertyUtil_h

#import <Foundation/Foundation.h>

@interface PropertyUtil : NSObject

+ (NSDictionary *)classPropsFor:(Class)klass;

@end

#endif /* PropertyUtil_h */
