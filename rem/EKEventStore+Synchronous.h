//
//  EKEventStore+Synchronous.h
//  rem
//
//  Created by Erik A Johnson on 10/29/19.
//  Copyright © 2019 Erik A Johnson. All rights reserved.
//

#import <EventKit/EventKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface EKEventStore (Synchronous)

- (EKEventStore *)initWithAccessToRemindersReturningError:(NSError**)errorRef;
- (NSError*)requestAccessToEntityTypeSynchronous:(EKEntityType)entityType withTimeout:(NSTimeInterval)timeout;
- (NSError*)requestAccessToEntityTypeSynchronous:(EKEntityType)entityType;

@end

NS_ASSUME_NONNULL_END
