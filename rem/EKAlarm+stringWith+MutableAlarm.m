//
//  EKAlarm+stringWith+MutableAlarm.m
//  rem
//
//  Created by Erik A Johnson on 10/29/19 - 12/09/2019.
//  Copyright © 2019-20 Erik A Johnson. All rights reserved.
//

#include <math.h>
#import "EKAlarm+stringWith+MutableAlarm.h"
#import "NSObject+performSelectorSafely.h"
#import "NSString+regex.h"
#import "main.h"

@implementation EKMutableAlarm
@synthesize sharedUID;
@synthesize isSnoozed;
@synthesize isDefault;
//- (EKMutableAlarm*) init {
//    // only called if the alarm is created by EKMutableAlarm, but then it doesn't work correctly when added to a reminder
//    self = [super init];
//    NSLog(@"EKMutableAlarm -init");
//    self->sharedUID = @"hi from init"; // -> works but . gives error because of read-only property
//    return self;
//}
//- (EKMutableAlarm*) setTheSharedUIDTo:(NSString* _Nullable)str { // doesn't help
//    // exception thrown when coercing an someAlarm from a reminder to call this (further, using an alarm created by EKMutableAlarm doesn't work correctly when added to a reminder)
//    NSLog(@"EKMutableAlarm -setTheSharedUIDTo:");
//    self->sharedUID = str; // -> works but . gives error because of read-only property
//    return self;
//}
//- (EKMutableAlarm*) setTheDefaultTo:(BOOL)def {
//    NSLog(@"EKMutableAlarm -setTheDefaultTo:");
//    // exception thrown when coercing an someAlarm from a reminder to call this (further, using an alarm created by EKMutableAlarm doesn't work correctly when added to a reminder)
//    self->isDefault = def; // -> works but . gives error because of read-only property
//    return self;
//}
//- (void) setSnoozingByArrowTo:(BOOL)def {
//    // this always throws an exception when I try to coerce an alarm from a reminder to get this message since that alarm really isn't my EKMutableAlarm
//    NSLog(@"EKMutableAlarm -setSnoozingByArrowTo:");
//    self->isSnoozed = def;
//}
@end


@implementation EKAlarm (stringWith)

/*
 *  interfaces to EKMutableAlarm
 */

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
    // sets it but reverts to prior setting after being added to a reminder
    ((EKMutableAlarm*)self).isSnoozed = newSnoozed;
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
/*
- (void)setDefaulting:(BOOL)newDefault { // setIsDefault may cause problems
    [(EKMutableAlarm*)self setTheDefaultTo:newDefault]; // NSLog(@"EKAlarm -setDefaulting: cannot set a read-only property"); // ((EKMutableAlarm*)self).isDefault = newDefault;
}
*/

- (BOOL)hasSharedUID {
    return [self respondsToSelector:@selector(sharedUID)];
}
- (BOOL)noSharedUID {
    return ![self hasSharedUID];
}
- (NSString *)sharedUIDing { // need different name from isSharedUID
    return [self hasSharedUID] ? [(EKMutableAlarm*)self sharedUID] : @"";
}
/*
- (void)setSharedUIDing:(BOOL)newSharedUID { // setIsSharedUID may cause problems
    // doesn't work because I cannot access the sharedUID read-only property; trying via coercing to EKMutableAlarm didn't work either
    NSLog(@"EKAlarm -setSharedUIDing: not yet written");
    exit(254);
    // ((EKMutableAlarm*)self).sharedUID = newSharedUID;
}
*/


/*
 *  location strings
 */

#define GEOLOC_DEBUG 0
NSString *structuredLocationString(EKStructuredLocation *loc) {
    if (GEOLOC_DEBUG) NSLog(@"loc 1");
    if (GEOLOC_DEBUG) NSLog(@"loc 2, loc.description=\"%@\"",loc.description);
    if (GEOLOC_DEBUG) NSLog(@"loc 3a");
    if (GEOLOC_DEBUG) NSLog(@"loc 3b loc.title=%@",loc.title);
    if (GEOLOC_DEBUG) NSLog(@"loc 3c");
    if (GEOLOC_DEBUG) NSLog(@"loc 3d, loc.geoLocation=%@",loc.geoLocation);
    if (GEOLOC_DEBUG) NSLog(@"loc 3e");
    if (GEOLOC_DEBUG) NSLog(@"loc 3f, loc.geoLocation.coordinate=%ld",loc.geoLocation.coordinate);
    if (GEOLOC_DEBUG) NSLog(@"loc 3g");
    if (GEOLOC_DEBUG) NSLog(@"loc 3h, loc.geoLocation.coordinate=(%@,%@)",@(loc.geoLocation.coordinate.latitude),@(loc.geoLocation.coordinate.longitude));
    if (GEOLOC_DEBUG) NSLog(@"loc 3i");
    if (GEOLOC_DEBUG) NSLog(@"loc 3j, loc.geoLocation.altitude=%@ m",@(loc.geoLocation.altitude));
    if (GEOLOC_DEBUG) NSLog(@"loc 3k");
    if (GEOLOC_DEBUG) NSLog(@"loc 3l, loc.geoLocation.horizontalAccuracy=%@ m",@(loc.geoLocation.horizontalAccuracy));
    if (GEOLOC_DEBUG) NSLog(@"loc 3m");
    if (GEOLOC_DEBUG) NSLog(@"loc 3n, loc.geoLocation.verticalAccuracy=%@ m",@(loc.geoLocation.verticalAccuracy));
    if (GEOLOC_DEBUG) NSLog(@"loc 3o");
    if (GEOLOC_DEBUG) NSLog(@"loc 3p, loc.geoLocation.timestamp=%@",loc.geoLocation.timestamp);
    if (GEOLOC_DEBUG) NSLog(@"loc 3q");
    if (GEOLOC_DEBUG) NSLog(@"loc 3r, loc.geoLocation.speed=%@ m/s",@(loc.geoLocation.speed));
    if (GEOLOC_DEBUG) NSLog(@"loc 3s");
    if (GEOLOC_DEBUG) NSLog(@"loc 3t, loc.geoLocation.course=%@ deg",@(loc.geoLocation.course));
    if (GEOLOC_DEBUG) NSLog(@"loc 3u");
    #pragma clang diagnostic push
    #pragma clang diagnostic ignored "-Wundeclared-selector"
    if (GEOLOC_DEBUG) NSLog(@"loc 3v, loc.geoURLString=%@",[loc respondsToSelector:@selector(geoURLString)] ? [loc performSelector:@selector(geoURLString)] : @"<not implemented>");
    #pragma clang diagnostic pop
    if (GEOLOC_DEBUG) NSLog(@"loc 3w");
    if (GEOLOC_DEBUG) NSLog(@"loc 4, loc=\"%@\"",loc);
    if (GEOLOC_DEBUG) NSLog(@"loc 5");
    NSString *str = loc.description ? loc.description : [NSString stringWithFormat:@"%@",loc];
    #pragma clang diagnostic push
    #pragma clang diagnostic ignored "-Wundeclared-selector"
    if ([loc respondsToSelector:@selector(geoURLString)]) {
        NSString *geoURLString = [loc performSelector:@selector(geoURLString)];
        str = [str stringByReplacingMatchesOfRegex:@"(geo\\s*=\\s*)\\(null\\)" with:[@"$1" stringByAppendingString:[NSRegularExpression escapedTemplateForString:geoURLString]]];
     }
    #pragma clang diagnostic pop
    return str;
}

// note: cannot call this "proximityString" because self.proximity calls "proximityString" and this would run into an infinite recursion
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


/*
 *  alarm to string
 */

static BOOL showWarning = YES;
+ (void)disableEKAlarmUndocumentedWarning {
    showWarning = NO;
}
- (NSString*)undocumentedProperties {
    if (showWarning) {
        NSLog(@"Showing undocumented EKAlarm properties");
        showWarning = NO;
    }
    NSString *ans = @"";
    #pragma clang diagnostic push
    #pragma clang diagnostic ignored "-Wundeclared-selector"
    if ([self  respondsWithoutExceptionToSelector:@selector(snoozedAlarms)]) ans = [NSString stringWithFormat:@"%@ snoozedAlarms=%@",ans,[self returnErrorMessageOrPerformSelector:@selector(snoozedAlarms)]];
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
    #pragma clang diagnostic pop
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


/*
 *  array operation
 */

- (NSArray<EKAlarm *>*_Nonnull)arrayByRemovingFromArray:(NSArray<EKAlarm *>*_Nullable)alarms {
    if (!alarms || !alarms.count) return @[]; // empty array
     NSMutableArray *alarmsMutable = [NSMutableArray arrayWithArray:alarms];
     [alarmsMutable removeObject:self];
     return [alarmsMutable copy];
}


/*
 *  duplication methods
 */

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


/*
 *  date operations
 */

- (BOOL)isInPast {
    return [self isInPastForReminder:nil];
}
- (BOOL)isInPastForReminder:(EKReminder* _Nullable)reminder {
    NSTimeInterval secsInFuture = [self timeIntervalSinceNowForReminder:reminder];
    if isnan(secsInFuture) // cannot determine
        return NO;
    return (secsInFuture < 0.0);
}

- (NSDate*_Nullable)alarmDateForReminder:(EKReminder* _Nullable)reminder { // returns nil if there is no identifiable date
    return self.absoluteDate ? self.absoluteDate : reminder && reminder.dueDateComponents ? [NSDate dateWithTimeInterval:self.relativeOffset sinceDate:[[NSCalendar currentCalendar] dateFromComponents:reminder.dueDateComponents]] : nil;
}
- (NSTimeInterval)timeIntervalSinceNowForReminder:(EKReminder* _Nullable)reminder { // returns NAN if there is no identifiable date
    NSDate *alarmDate = [self alarmDateForReminder:reminder];
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


/*
 *  dated alarm convenience routines
 */

+ (NSArray<EKAlarm*> *)datedAlarmsFromArray:(NSArray<EKAlarm*> *)alarms forReminder:(EKReminder*)reminder {
    NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(id  _Nullable object, NSDictionary<NSString *,id> * _Nullable bindings) {
        EKAlarm *alarm = (EKAlarm*)object;
        NSTimeInterval alarmTimeSinceNow = [alarm timeIntervalSinceNowForReminder:reminder];
        return ! isnan(alarmTimeSinceNow);
    }];
    return [alarms filteredArrayUsingPredicate:predicate];
}
+ (NSArray<EKAlarm*> *)pastAlarmsFromArray:(NSArray<EKAlarm*> *)alarms forReminder:(EKReminder*)reminder {
    NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(id  _Nullable object, NSDictionary<NSString *,id> * _Nullable bindings) {
        EKAlarm *alarm = (EKAlarm*)object;
        NSTimeInterval alarmTimeSinceNow = [alarm timeIntervalSinceNowForReminder:reminder];
        return isnan(alarmTimeSinceNow) ? NO : alarmTimeSinceNow<=0;
    }];
    return [alarms filteredArrayUsingPredicate:predicate];
}
+ (NSArray<EKAlarm*> *)futureAlarmsFromArray:(NSArray<EKAlarm*> *)alarms forReminder:(EKReminder*)reminder {
    NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(id  _Nullable object, NSDictionary<NSString *,id> * _Nullable bindings) {
        EKAlarm *alarm = (EKAlarm*)object;
        NSTimeInterval alarmTimeSinceNow = [alarm timeIntervalSinceNowForReminder:reminder];
        return isnan(alarmTimeSinceNow) ? NO : alarmTimeSinceNow>0;
    }];
    return [alarms filteredArrayUsingPredicate:predicate];
}

+ (NSArray<EKAlarm*> *)sortAlarmsByDateFromArray:(NSArray<EKAlarm*> *)alarms forReminder:(EKReminder*)reminder {
    return [alarms sortedArrayUsingComparator:^NSComparisonResult(id a, id b) {
        NSTimeInterval A = [(EKAlarm*)a timeIntervalSinceNowForReminder:reminder];
        NSTimeInterval B = [(EKAlarm*)b timeIntervalSinceNowForReminder:reminder];
        // will be NAN if there is no identifiable date
        // let's put NAN's after real dates
        return (isnan(A)&&isnan(B))||A==B ? NSOrderedSame // need the isnan checks because NAN is never equal to NAN
            : isnan(A) ? NSOrderedDescending
            : isnan(B) ? NSOrderedAscending
            : A>B ? NSOrderedDescending
            : NSOrderedAscending;
    }];
}
+ (NSArray<EKAlarm*> *)sortDatedAlarmsByDateFromArray:(NSArray<EKAlarm*> *)alarms forReminder:(EKReminder*)reminder {
    NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(id  _Nullable object, NSDictionary<NSString *,id> * _Nullable bindings) {
        EKAlarm *alarm = (EKAlarm*)object;
        return ! isnan([alarm timeIntervalSinceNowForReminder:reminder]);
    }];
    NSArray<EKAlarm*> *datedAlarms = [alarms filteredArrayUsingPredicate:predicate];
    return [EKAlarm sortDatedAlarmsByDateFromArray:datedAlarms forReminder:reminder];
}

+ (EKAlarm *)latestAlarmFromArray:(NSArray<EKAlarm*> *)alarms forReminder:(EKReminder*)reminder {
    EKAlarm *latestAlarm;
    NSTimeInterval latestAlarmTimeSinceNow;
    for (EKAlarm *alarm in alarms) {
        NSTimeInterval timeSinceNow = [alarm timeIntervalSinceNowForReminder:reminder]; // returns NAN if there is no identifiable date
        if (isnan(latestAlarmTimeSinceNow)) {
            // ignore
        } else if (!latestAlarm || timeSinceNow>latestAlarmTimeSinceNow) {
            latestAlarm = alarm;
            latestAlarmTimeSinceNow = timeSinceNow;
        }
    }
    return latestAlarm;
}
+ (EKAlarm *)earliestAlarmFromArray:(NSArray<EKAlarm*> *)alarms forReminder:(EKReminder*)reminder {
    EKAlarm *earliestAlarm;
    NSTimeInterval earliestAlarmTimeSinceNow;
    for (EKAlarm *alarm in alarms) {
        NSTimeInterval timeSinceNow = [alarm timeIntervalSinceNowForReminder:reminder]; // returns NAN if there is no identifiable date
        if (isnan(earliestAlarmTimeSinceNow)) {
            // ignore
        } else if (!earliestAlarm || timeSinceNow<earliestAlarmTimeSinceNow) {
            earliestAlarm = alarm;
            earliestAlarmTimeSinceNow = timeSinceNow;
        }
    }
    return earliestAlarm;
}



@end
