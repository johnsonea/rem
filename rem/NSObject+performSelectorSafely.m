//
//  NSObject+performSelectorSafely.m
//  rem
//
//  Created by Erik A Johnson on 11/26/19.
//  Copyright © 2019-20 Erik A Johnson. All rights reserved.
//

#import "NSObject+performSelectorSafely.h"

@implementation NSObject (performSelector)

- (BOOL)respondsWithoutExceptionToSelector:(SEL)selector {
    if ([self respondsToSelector:selector]) {
        @try {
            // [self performSelector:selector] can cause error due to unknown response value
            NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[self methodSignatureForSelector:selector]];
            [invocation setSelector:selector];
            [invocation setTarget:self];
            [invocation invoke];
            id returnValue;
            [invocation getReturnValue:&returnValue];
            return YES;
        } @catch (NSException *exception) {
            // don't care
        }
    }
    return NO;
}
- (BOOL)respondsWithoutExceptionToSelector:(SEL)selector withObject:(id)obj{
    if ([self respondsToSelector:selector]) {
        @try {
            // [self performSelector:selector withObject:obj] can cause error due to unknown response value
            NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[self methodSignatureForSelector:selector]];
            [invocation setSelector:selector];
            [invocation setTarget:self];
            [invocation setArgument:&obj atIndex:2];
            [invocation invoke];
            id returnValue;
            [invocation getReturnValue:&returnValue];
            return YES;
        } @catch (NSException *exception) {
            // don't care
        }
    }
    return NO;
}

- (id) returnErrorMessageOrPerformSelector:(SEL)selector {
    @try {
        // [self performSelector:selector] can cause error due to unknown response value
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[self methodSignatureForSelector:selector]];
        [invocation setSelector:selector];
        [invocation setTarget:self];
        [invocation invoke];
        id returnValue;
        [invocation getReturnValue:&returnValue];
        return returnValue;
    } @catch (NSException *exception) {
        return [NSString stringWithFormat:@"error={name=%@, reason=%@, userInfo=%@}",exception.name,exception.reason,exception.userInfo];
    }
}
- (id) returnErrorMessageOrPerformSelector:(SEL)selector withObject:(id)obj {
    @try {
        // [self performSelector:selector withObject:obj] can cause error due to unknown response value
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[self methodSignatureForSelector:selector]];
        [invocation setSelector:selector];
        [invocation setTarget:self];
        [invocation setArgument:&obj atIndex:2];
        [invocation invoke];
        id returnValue;
        [invocation getReturnValue:&returnValue];
        return returnValue;
    } @catch (NSException *exception) {
        return [NSString stringWithFormat:@"error={name=%@, reason=%@, userInfo=%@}",exception.name,exception.reason,exception.userInfo];
    }
}

// https://stackoverflow.com/questions/313400/nsinvocation-for-dummies
// https://developer.apple.com/documentation/foundation/nsinvocation

- (NSString*)errorMessageWhenBOOLFromPerformingSelector:(SEL)selector {
    @try{
        // [self performSelector:selector] cannot be used because of the BOOL response
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[self methodSignatureForSelector:selector]];
        [invocation setSelector:selector];
        [invocation setTarget:self];
        [invocation invoke];
        BOOL returnValue;
        [invocation getReturnValue:&returnValue];
        return nil;
    } @catch (NSException *exception) {
        return [NSString stringWithFormat:@"error={name=%@, reason=%@, userInfo=%@}",exception.name,exception.reason,exception.userInfo];
    }
}

- (BOOL)BOOLFromPerformingSelector:(SEL)selector {
    if ([self respondsToSelector:selector]) {
        // [self performSelector:selector] cannot be used because of the BOOL response
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[self methodSignatureForSelector:selector]];
        [invocation setSelector:selector];
        [invocation setTarget:self];
        [invocation invoke];
        BOOL returnValue;
        [invocation getReturnValue:&returnValue];
        return returnValue;
    }
    return 0;
}
- (BOOL)BOOLFromPerformingSelector:(SEL)selector withObject:(id)obj {
    if ([self respondsToSelector:selector]) {
        // [self performSelector:selector withObject:obj] cannot be used because of the BOOL response
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[self methodSignatureForSelector:selector]];
        [invocation setSelector:selector];
        [invocation setTarget:self];
        [invocation setArgument:&obj atIndex:2];
        [invocation invoke];
        BOOL returnValue;
        [invocation getReturnValue:&returnValue];
        return returnValue;
    }
    return 0;
}

- (long long)longlongFromPerformingSelector:(SEL)selector {
    if ([self respondsToSelector:selector]) {
        // [self performSelector:selector] cannot be used because of the long long response
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[self methodSignatureForSelector:selector]];
        [invocation setSelector:selector];
        [invocation setTarget:self];
        [invocation invoke];
        long long returnValue;
        [invocation getReturnValue:&returnValue];
        return returnValue;
    }
    return 0;
}
- (long long)longlongFromPerformingSelector:(SEL) selector withObject:(id)obj {
    if ([self respondsToSelector:selector]) {
        // [self performSelector:selector withObject:obj] cannot be used because of the long long response
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[self methodSignatureForSelector:selector]];
        [invocation setSelector:selector];
        [invocation setTarget:self];
        [invocation setArgument:&obj atIndex:2];
        [invocation invoke];
        long long returnValue;
        [invocation getReturnValue:&returnValue];
        return returnValue;
    }
    return 0;
}

/*
 Note: one can also use the following to get 
    Method m = class_getInstanceMethod([self class], @selector(selector));
    Method n = class_getClassMethod([self class], @selector(selector));
    char ret[ 256 ];
    method_getReturnType( m, ret, 256 );
    NSLog( @"instance return type: %s", ret );
    method_getReturnType( n, ret, 256 );
    NSLog( @"class return type: %s", ret );
 */


@end
