//
//  EKReminder+Snoozing.m
//  rem
//
//  Created by Erik A Johnson on 10/29/19.
//  Copyright © 2019 Erik A Johnson. All rights reserved.
//

#import "EKReminder+Snoozing.h"

@implementation EKReminder (Snoozing)

- (BOOL)isSnoozed {
    if (self.hasAlarms && self.alarms) {
        for (EKAlarm *alarm in self.alarms)
            if ([alarm snoozing])
                return YES;
    }
    return NO;
}
- (BOOL)hasUnsnoozedPastAlarms {
    if (self.hasAlarms && self.alarms) {
        for (EKAlarm *alarm in self.alarms)
            if ([alarm isUnsnoozedAndInPastForReminder:self])
                return YES;
    }
    return NO;
}

@end
