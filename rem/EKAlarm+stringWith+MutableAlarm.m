//
//  EKAlarm+stringWith+MutableAlarm.m
//  rem
//
//  Created by Erik A Johnson on 10/29/19.
//  Copyright © 2019 Erik A Johnson. All rights reserved.
//

#include <math.h>
#import "EKAlarm+stringWith+MutableAlarm.h"
#import "NSObject+performSelectorSafely.h"
#import "main.h"

@implementation EKMutableAlarm
@synthesize sharedUID;
@synthesize isSnoozed;
@synthesize isDefault;
@end


@implementation EKAlarm (stringWith)

NSString *structuredLocationString(EKStructuredLocation *loc) {
    return loc.description ? loc.description : [NSString stringWithFormat:@"%@",loc];
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

- (NSTimeInterval)timeIntervalSinceNowForReminder:(EKReminder* _Nullable)reminder {
    NSDate *alarmDate = self.absoluteDate ? self.absoluteDate : reminder && reminder.dueDateComponents ? [NSDate dateWithTimeInterval:self.relativeOffset sinceDate:[[NSCalendar currentCalendar] dateFromComponents:reminder.dueDateComponents]] : nil;
    return alarmDate==nil ? NAN : [alarmDate timeIntervalSinceNow];
}
- (BOOL)isUnsnoozedAndInPast {
    return [self isUnsnoozedAndInPastForReminder:nil];
}
- (BOOL)isUnsnoozedAndInPastForReminder:(EKReminder* _Nullable)reminder {
    if ([self hasSnooze] && [(EKMutableAlarm*)self isSnoozed]) return NO;
    NSTimeInterval secsInFuture = [self timeIntervalSinceNowForReminder:reminder];
    if isnan(secsInFuture) // cannot determine
        return NO;
    return (secsInFuture < 0.0);
}

- (BOOL)hasDefault {
    return [self respondsToSelector:@selector(isDefault)];
}
- (BOOL)noDefault {
    return ![self hasDefault];
}
- (BOOL)defaulting { // need different name from isDefault
    return [self hasDefault] ? [(EKMutableAlarm*)self isDefault] : NO;
}
- (void)setDefaulting:(BOOL)newDefault { // setIsDefault may cause problems
    NSLog(@"EKAlarm -setDefaulting: cannot set a read-only property");
    // ((EKMutableAlarm*)self).isDefault = newDefault;
}

- (BOOL)hasSharedUID {
    return [self respondsToSelector:@selector(sharedUID)];
}
- (BOOL)noSharedUID {
    return ![self hasSharedUID];
}
- (NSString *)sharedUIDing { // need different name from isSharedUID
    return [self hasSharedUID] ? [(EKMutableAlarm*)self sharedUID] : @"";
}
- (void)setSharedUIDing:(BOOL)newSharedUID { // setIsSharedUID may cause problems
    NSLog(@"EKAlarm -setSharedUIDing: not yet written");
    exit(254);
    // ((EKMutableAlarm*)self).sharedUID = newSharedUID;
}

static BOOL showWarning = YES;
- (NSString*)undocumentedProperties {
    if (showWarning) {
        NSLog(@"Showing undocumented EKAlarm properties");
        showWarning = NO;
    }
    NSString *ans = @"";
    if ([self respondsWithoutExceptionToSelector:@selector(snoozedAlarms)]) ans = [NSString stringWithFormat:@"%@ snoozedAlarms=%@",ans,[self returnErrorMessageOrPerformSelector:@selector(snoozedAlarms)]];
    if ([self respondsWithoutExceptionToSelector:@selector(originalAlarm)]) ans = [NSString stringWithFormat:@"%@ originalAlarm=%@",ans,[self returnErrorMessageOrPerformSelector:@selector(originalAlarm)]];
    if ([self respondsWithoutExceptionToSelector:@selector(calendarItemOwner)]) ans = [NSString stringWithFormat:@"%@ calendarItemOwner=%@",ans,[self returnErrorMessageOrPerformSelector:@selector(calendarItemOwner)]];
    if ([self respondsWithoutExceptionToSelector:@selector(calendarOwner)]) ans = [NSString stringWithFormat:@"%@ calendarOwner=%@",ans,[self returnErrorMessageOrPerformSelector:@selector(calendarOwner)]];
    if ([self respondsWithoutExceptionToSelector:@selector(ownerUUID)]) ans = [NSString stringWithFormat:@"%@ ownerUUID=%@",ans,[self returnErrorMessageOrPerformSelector:@selector(ownerUUID)]];
    if ([self respondsWithoutExceptionToSelector:@selector(owner)]) ans = [NSString stringWithFormat:@"%@ owner=%@",ans,[self returnErrorMessageOrPerformSelector:@selector(owner)]];
    if ([self respondsWithoutExceptionToSelector:@selector(externalID)]) ans = [NSString stringWithFormat:@"%@ externalID=%@",ans,[self returnErrorMessageOrPerformSelector:@selector(externalID)]];
    if ([self respondsWithoutExceptionToSelector:@selector(UUID)]) ans = [NSString stringWithFormat:@"%@ UUID=%@",ans,[self returnErrorMessageOrPerformSelector:@selector(UUID)]];
    if (0 && [self respondsToSelector:@selector(compare:)]) {
        id s, t, u;
        @try {
            s = @([self longlongFromPerformingSelector:@selector(compare:) withObject:self]);
        } @catch (NSException *exception) {
            s = @"error";
        }
        EKAlarm *junkAlarm = [EKAlarm alarmWithAbsoluteDate:[NSDate dateWithTimeIntervalSinceNow:-864000]];
        @try {
            t = @([self longlongFromPerformingSelector:@selector(compare:) withObject:junkAlarm]);
        } @catch (NSException *exception) {
            t = @"error";
        }
        junkAlarm = [EKAlarm alarmWithAbsoluteDate:[NSDate dateWithTimeIntervalSinceNow:0]];
        @try {
            u = @([self longlongFromPerformingSelector:@selector(compare:) withObject:junkAlarm]);
        } @catch (NSException *exception) {
            u = @"error";
        }
        ans = [NSString stringWithFormat:@"%@ canCompare=%@ compareWithSelf=%@ compareWithAlarm10DaysAgo=%@ compareWithAlarmNow=%@",ans,@(YES),s,t,u];
    }
    if ([self respondsWithoutExceptionToSelector:@selector(isDefaultAlarm)]) ans = [NSString stringWithFormat:@"%@ isDefaultAlarm=%@",ans,@([self BOOLFromPerformingSelector:@selector(isDefaultAlarm)])];
    if ([self respondsWithoutExceptionToSelector:@selector(isDefault)]) ans = [NSString stringWithFormat:@"%@ isDefault=%@",ans,@([self BOOLFromPerformingSelector:@selector(isDefault)])];
    // ans = [NSString stringWithFormat:@"%@ isFrozen=%@", ans, ![self respondsToSelector:@selector(isFrozen)] ? @"<unimplemented>" : ! [self respondsWithoutExceptionToSelector:@selector(isFrozen)] ? [self returnErrorMessageOrPerformSelector:@selector(isFrozen)] : @([self BOOLFromPerformingSelector:@selector(isFrozen)])]; // NO
    // if ([[self class] respondsToSelector:@selector(frozenClass)]) ans = [NSString stringWithFormat:@"%@ frozenClass=%@",ans,[[self class] returnErrorMessageOrPerformSelector:@selector(frozenClass)]];
    // if ([[self class] respondsToSelector:@selector(meltedClass)]) ans = [NSString stringWithFormat:@"%@ meltedClass=%@",ans,[[self class] returnErrorMessageOrPerformSelector:@selector(meltedClass)]];
    return ans;
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
    NSString *defaulted = [self noDefault] ? @"" : [(EKMutableAlarm*)self isDefault] ? @" default=1" : @" default=0";
    NSString *sharedUID = [self noSharedUID] ? @"" : [NSString stringWithFormat:@" sharedUID=%@",[(EKMutableAlarm*)self sharedUID]];
    NSString *ans = [NSString stringWithFormat:@"type=%@ snoozed=%@%@%@", [self typeString], snoozed, defaulted, sharedUID];
    if (SHOW_UNDOCUMENTED)
        ans = [NSString stringWithFormat:@"%@%@",ans,[self undocumentedProperties]];
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
