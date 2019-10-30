//
//  EKReminder+Snoozing.m
//  rem
//
//  Created by Erik A Johnson on 10/29/19.
//  Copyright © 2019 Erik A Johnson. All rights reserved.
//

#import "EKReminder+Snoozing.h"

@implementation EKReminder (Snoozing)

- (BOOL)snoozing { // need different name from isSnoozed
    if (self.hasAlarms && self.alarms) {
        for (NSUInteger i=0; i<self.alarms.count; i++) {
            if ([self.alarms[i] snoozing])
                return YES;
        }
    }
    return NO;
}

@end
