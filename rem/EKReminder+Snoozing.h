//
//  EKReminder+Snoozing.h
//  rem
//
//  Created by Erik A Johnson on 10/29/19.
//  Copyright © 2019 kykim, inc. All rights reserved.
//

#import <EventKit/EventKit.h>
#import "EKAlarm+stringWith+MutableAlarm.h"

NS_ASSUME_NONNULL_BEGIN

@interface EKReminder (Snoozing)

- (BOOL)isSnoozed;
- (BOOL)hasUnsnoozedPastAlarms;

@end

NS_ASSUME_NONNULL_END
