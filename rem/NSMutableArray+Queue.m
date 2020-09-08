//
//  NSMutableArray+Queue.m
//  rem
//
//  Created by Erik A Johnson on 10/31/19.
//  Copyright © 2019-20 Erik A Johnson. All rights reserved.
//

#import "NSMutableArray+Queue.h"

@implementation NSMutableArray (Queue)

- (id)shift {
    id obj = [self firstObject];
    if (self.count) // necessary because removing from empty array throws NSRangeException; strangely, removeLastObject does not throw an exception on an empty array
        [self removeObjectAtIndex:0];
    return obj;
}
- (NSMutableArray *)unshift:(id _Nonnull)obj {
    [self insertObject:obj atIndex:0];
    return self;
}
- (id)pop {
    id obj = [self lastObject];
    [self removeLastObject];
    return obj;
}
- (NSMutableArray *)push:(id _Nonnull)obj {
    [self insertObject:obj atIndex:self.count];
    return self;
}

@end
