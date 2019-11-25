//
//  EKAlarm+stringWith+MutableAlarm.m
//  rem
//
//  Created by Erik A Johnson on 10/29/19.
//  Copyright © 2019 Erik A Johnson. All rights reserved.
//

#import "EKAlarm+stringWith+MutableAlarm.h"

@implementation EKMutableAlarm
@synthesize sharedUID;
@synthesize isSnoozed;
@synthesize isDefault;
@end


@implementation EKAlarm (stringWith)

NSString *structuredLocationString(EKStructuredLocation *loc) {
    return loc.description;
}

// note: cannot call this proximityString because self.proximity calls proximityString and this would run into an infinite recursion
- (NSString *)proximityStr {
    return
    self.proximity == EKAlarmProximityNone ? @"" :
    self.proximity == EKAlarmProximityEnter ? [NSString stringWithFormat:@" arriving=%@",structuredLocationString(self.structuredLocation)] :
    self.proximity == EKAlarmProximityLeave ? [NSString stringWithFormat:@" leaving=%@",structuredLocationString(self.structuredLocation)] :
    [NSString stringWithFormat:@" %@", @(self.proximity)];
}

- (NSString *)typeString {
    return !self ? @"<none>" :
    self.type==EKAlarmTypeAudio ? [NSString stringWithFormat:@"sound:%@",(self.emailAddress?self.emailAddress:@"?")] :
    self.type==EKAlarmTypeDisplay ? @"display" :
    self.type==EKAlarmTypeEmail ? [NSString stringWithFormat:@"mailto:%@",(self.emailAddress?self.emailAddress:@"?")] :
    self.type==EKAlarmTypeProcedure ? @"procedure" :
    [NSString stringWithFormat:@"%@",@(self.type)];
}

- (BOOL)hasSnooze {
    return [self respondsToSelector:@selector(isSnoozed)];
}
- (BOOL)noSnooze {
    return ![self hasSnooze];
}
- (BOOL)snoozing { // need different name from isSnoozed
    return [self hasSnooze] ? [(EKMutableAlarm*)self isSnoozed] : NO;
}
- (void)setSnoozing:(BOOL)newSnoozed { // setIsSnoozed caused problems
    ((EKMutableAlarm*)self).isSnoozed = newSnoozed;
}

- (NSString *)stringWithDateFormatter:(NSDateFormatter * _Nullable)formatter {
    return [self stringWithDateFormatter:formatter forReminder:nil];
}
- (NSString *)stringWithDateFormatter:(NSDateFormatter * _Nullable)formatter forReminder:(EKReminder * _Nullable)reminder {
    if (self==nil) return self.description; // don't think this can happen but just in case
    if (formatter==nil) {
        formatter = [[NSDateFormatter alloc] init];
        formatter.dateStyle = NSDateFormatterShortStyle;
        formatter.timeStyle = NSDateFormatterLongStyle;
        formatter.locale = [NSLocale autoupdatingCurrentLocale]; // or [NSLocale currentLocale] or [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
    }
    NSString *snoozed = [self noSnooze] ? @"?" : [(EKMutableAlarm*)self isSnoozed] ? @"1" : @"0";
    NSString *ans = [NSString stringWithFormat:@"type=%@ snoozed=%@", [self typeString], snoozed];
    if (self.absoluteDate)
        ans = [NSString stringWithFormat:@"%@ when=\"%@\"",ans,[formatter stringFromDate:self.absoluteDate]];
    else if (reminder && reminder.dueDateComponents)
        ans = [NSString stringWithFormat:@"%@ when=%@%@+\"%@\"",ans
               , self.relativeOffset>=0 ? @"+" : @""
               , @(self.relativeOffset)
               , [formatter stringFromDate:[[NSCalendar currentCalendar] dateFromComponents:reminder.dueDateComponents]]
               ];
    ans = [NSString stringWithFormat:@"%@%@",ans,[self proximityStr]];
    return ans;
    // NSDate *absoluteDate
    // NSTimeInterval(=double) relativeOffset;
    // proximity
    // type {}
    //      emailAddress
    //      soundName
    // * EKAlarm <0x22dc0040>, isSnoozed:0, isDefault:0, sharedUID:E1A860B7-61B4-486E-9B7E-F28002DEFFB5
    // self.isSnoozed;
}

- (EKAlarm *)duplicateAlarm {
    return [self copy];
}
- (EKAlarm *)duplicateAlarmChangingTimeTo:(NSDate*)newDate {
    EKAlarm *newAlarm = [self duplicateAlarm];
    newAlarm.absoluteDate = newDate;
    return newAlarm;
}
- (EKAlarm *)duplicateAlarmChangingTimeToNowPlusSecs:(NSTimeInterval)secs {
    return [self duplicateAlarmChangingTimeTo:[NSDate dateWithTimeIntervalSinceNow:secs]];
}

@end
