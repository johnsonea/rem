//
//  NSObject+performSelectorSafely.h
//  rem
//
//  Created by Erik A Johnson on 11/26/19.
//  Copyright © 2019-20 Erik A Johnson. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSObject (performSelector)

- (BOOL)respondsWithoutExceptionToSelector:(SEL)selector;
- (BOOL)respondsWithoutExceptionToSelector:(SEL)selector withObject:(id)obj;

- (id) returnErrorMessageOrPerformSelector:(SEL)selector;
- (id) returnErrorMessageOrPerformSelector:(SEL)selector withObject:(id)obj;

- (NSString*)errorMessageWhenBOOLFromPerformingSelector:(SEL)selector;
- (BOOL)BOOLFromPerformingSelector:(SEL)selector;
- (BOOL)BOOLFromPerformingSelector:(SEL)selector withObject:(id)obj;

- (long long)longlongFromPerformingSelector:(SEL)selector;
- (long long)longlongFromPerformingSelector:(SEL) selector withObject:(id)obj;

@end

NS_ASSUME_NONNULL_END
