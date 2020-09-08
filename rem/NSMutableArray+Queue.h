//
//  NSMutableArray+Queue.h
//  rem
//
//  Created by Erik A Johnson on 10/31/19.
//  Copyright © 2019-20 Erik A Johnson. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSMutableArray (Queue)

- (id)shift;
- (NSMutableArray *)unshift:(id _Nonnull)obj;
- (id)pop;
- (NSMutableArray *)push:(id _Nonnull)obj;

@end

NS_ASSUME_NONNULL_END
