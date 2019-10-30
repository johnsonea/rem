//
//  EKAlarm+stringWith.m
//  rem
//
//  Created by Erik A Johnson on 10/29/19.
//  Copyright © 2019 kykim, inc. All rights reserved.
//

#import "EKAlarm+stringWith.h"

@interface EKSnoozableAlarm : EKAlarm {
    bool isSnoozed;
}
@property (nonatomic) bool isSnoozed;
@end
@implementation EKSnoozableAlarm
@synthesize isSnoozed;
@end


@implementation EKAlarm (stringWith)

NSString *structuredLocationString(EKStructuredLocation *loc) {
    return loc.description;
}

// note: cannot call this proximityString because self.proximity calls proximityString and this would run into an infinite recursion
- (NSString *)proximityStr {
    return
    self.proximity == EKAlarmProximityNone ? @"" :
    self.proximity == EKAlarmProximityEnter ? [NSString stringWithFormat:@" arriving at %@",structuredLocationString(self.structuredLocation)] :
    self.proximity == EKAlarmProximityLeave ? [NSString stringWithFormat:@" leaving from %@",structuredLocationString(self.structuredLocation)] :
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
    return [self hasSnooze] ? [(EKSnoozableAlarm*)self isSnoozed] : NO;
}

- (NSString *)stringWithDateFormatter:(NSDateFormatter *)formatter {
    if (self==nil) return self.description;
    NSString *snoozed = [self noSnooze] ? @"?" : [(EKSnoozableAlarm*)self isSnoozed] ? @"1" : @"0";
    [formatter stringFromDate:self.absoluteDate];
    [self proximityStr];
    [self typeString];
    return [NSString stringWithFormat:@"type=%@ snoozed=%@ %@=%@%@%@%@",[self typeString], snoozed, self.absoluteDate ? @"absDate" : @"relOffset", self.absoluteDate ? @"\"" : @"", self.absoluteDate ?
            [formatter stringFromDate:self.absoluteDate] : @(self.relativeOffset), self.absoluteDate ? @"\"" : @"", [self proximityStr]];
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
