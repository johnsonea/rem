//
//  EKReminder+Snoozing.m
//  rem
//
//  Created by Erik A Johnson on 10/29/19.
//  Copyright © 2019 Erik A Johnson. All rights reserved.
//

#import "EKReminder+Snoozing.h"
#import "NSMutableArray+Queue.h"

@implementation EKReminder (Snoozing)

- (BOOL)isSnoozed {
    if (self.hasAlarms && self.alarms) {
        for (EKAlarm *alarm in self.alarms)
            if ([alarm snoozing])
                return YES;
    }
    return NO;
}
- (EKAlarm* _Nullable)firstSnoozedAlarm {
    if (self.hasAlarms && self.alarms) {
        for (EKAlarm *alarm in self.alarms)
            if ([alarm snoozing])
                return alarm;
    }
    return nil;
}
- (NSArray<EKAlarm*>* _Nonnull)snoozedPastAlarms {
    NSMutableArray<EKAlarm*> *alarms = [NSMutableArray arrayWithCapacity:self.hasAlarms?self.alarms.count:0];
    if (self.hasAlarms && self.alarms)
        for (EKAlarm *alarm in self.alarms)
            if (alarm && [alarm snoozing])
                [alarms push:alarm];
    return [alarms copy]; // return an immutable copy
}
- (BOOL)hasUnsnoozedPastAlarms {
    if (self.hasAlarms && self.alarms) {
        for (EKAlarm *alarm in self.alarms)
            if ([alarm isUnsnoozedAndInPastForReminder:self])
                return YES;
    }
    return NO;
}
- (EKAlarm* _Nullable)firstUnsnoozedPastAlarm {
    if (self.hasAlarms && self.alarms) {
        for (EKAlarm *alarm in self.alarms)
            if ([alarm isUnsnoozedAndInPastForReminder:self])
                return alarm;
    }
    return nil;
}
- (NSArray<EKAlarm*>* _Nonnull)unsnoozedPastAlarms {
    NSMutableArray<EKAlarm*> *alarms = [NSMutableArray arrayWithCapacity:self.hasAlarms?self.alarms.count:0];
    if (self.hasAlarms && self.alarms)
        for (EKAlarm *alarm in self.alarms)
            if (alarm && [alarm isUnsnoozedAndInPastForReminder:self])
                [alarms push:alarm];
    return [alarms copy]; // return an immutable copy
}

@end
