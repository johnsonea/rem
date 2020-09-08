//
//  EKReminder+Snoozing.m
//  rem
//
//  Created by Erik A Johnson on 10/29/19.
//  Copyright © 2019-20 Erik A Johnson. All rights reserved.
//

#import "EKReminder+Snoozing.h"
#import "NSMutableArray+Queue.h"

// NOTE 09/07/2020: in macOS 10.15 Catalina, it seems that:
//  * the undocumented "snoozing" property exists but is not set when snoozing via the Notification Center (in some prior macOS, this was set)
//  * snoozing (via Notification Center) a new reminder adds an alarm for the new snooze time but leaves the original one as is (probably the same behavior as prior macOS versions)
//  * snoozing (via Notification Center) a reminder that was previously snoozed deletes the newer alarm and adds a new one with the new time, as evidenced by an altered sharedUID property (probably the same behavior as prior macOS versions)

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
- (BOOL)allAlarmsInPast {
    if (self.hasAlarms && self.alarms) {
        for (EKAlarm *alarm in self.alarms)
            if (![alarm isInPastForReminder:self])
                return NO;
    }
    return YES;
}

/* other convenience methods */

// dueDateComponentsString methods
-(NSDate*_Nullable)dueDateFromComponents { // NOTE: MacOS has an undocumented dueDate method so this one is intentionally called something different
    // this does not work: [self.dueDateComponents date];
    return self.dueDateComponents ? [[NSCalendar currentCalendar] dateFromComponents:self.dueDateComponents] : nil;
}
-(NSString*_Nullable)dueDateComponentsStringUsingDateFormatter:(NSDateFormatter*_Nonnull)dateFormatter {
    NSDate *dueDate = [self dueDateFromComponents];
    assert(dateFormatter!=nil);
    return dueDate ? [dateFormatter stringFromDate:dueDate] : nil;
}
-(NSString*_Nullable)dueDateComponentsString { // use NSDateFormatter with current locale, short date style, long time style
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateStyle = NSDateFormatterShortStyle;
    dateFormatter.timeStyle = NSDateFormatterLongStyle;
    dateFormatter.locale = [NSLocale autoupdatingCurrentLocale]; // or [NSLocale currentLocale] or [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
    return [self dueDateComponentsStringUsingDateFormatter:dateFormatter];
}

// startDateComponentsString methods
-(NSDate*_Nullable)startDateFromComponents { // NOTE: MacOS has an undocumented startDate method so this one is intentionally called something different
    return self.startDateComponents ? [[NSCalendar currentCalendar] dateFromComponents:self.startDateComponents] : nil;
}
-(NSString*_Nullable)startDateComponentsStringUsingDateFormatter:(NSDateFormatter*_Nonnull)dateFormatter {
    NSDate *startDate = [self startDateFromComponents];
    assert(dateFormatter!=nil);
    return startDate ? [dateFormatter stringFromDate:startDate] : nil;
}
-(NSString*_Nullable)startDateComponentsString { // use NSDateFormatter with current locale, short date style, long time style
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateStyle = NSDateFormatterShortStyle;
    dateFormatter.timeStyle = NSDateFormatterLongStyle;
    dateFormatter.locale = [NSLocale autoupdatingCurrentLocale]; // or [NSLocale currentLocale] or [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
    return [self startDateComponentsStringUsingDateFormatter:dateFormatter];
}

// reminder array sorting
+ (NSArray<EKReminder*> *)extractSortedCompleted:(NSArray<EKReminder*> *)reminders {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(completed == YES) && (completionDate != nil)"]; // [NSPredicate predicateWithBlock:^BOOL(id object, NSDictionary *bindings) { ((EKReminder*)object).completed; }];
    NSArray<EKReminder*> *completedReminders = [reminders filteredArrayUsingPredicate:predicate];
    return [completedReminders sortedArrayUsingComparator:^NSComparisonResult(id a, id b) {
        NSDate *A = [(EKReminder*)a completionDate];
        NSDate *B = [(EKReminder*)b completionDate];
        // since we filtered to only completed reminders, neither A nor B should be nil
        return [A compare:B];
    }];
}




@end
