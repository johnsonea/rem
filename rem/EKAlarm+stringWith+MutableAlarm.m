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

- (NSTimeInterval)timeIntervalSinceNowForReminder:(EKReminder* _Nullable)reminder // returns NAN if there is no identifiable date
{
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
//- (void)setDefaulting:(BOOL)newDefault { // setIsDefault may cause problems
//    [(EKMutableAlarm*)self setTheDefaultTo:newDefault]; // NSLog(@"EKAlarm -setDefaulting: cannot set a read-only property"); // ((EKMutableAlarm*)self).isDefault = newDefault;
//}

- (BOOL)hasSharedUID {
    return [self respondsToSelector:@selector(sharedUID)];
}
- (BOOL)noSharedUID {
    return ![self hasSharedUID];
}
- (NSString *)sharedUIDing { // need different name from isSharedUID
    return [self hasSharedUID] ? [(EKMutableAlarm*)self sharedUID] : @"";
}
//- (void)setSharedUIDing:(BOOL)newSharedUID { // setIsSharedUID may cause problems
//    // doesn't work because I cannot access the sharedUID read-only property; trying via coercing to EKMutableAlarm didn't work either
//    NSLog(@"EKAlarm -setSharedUIDing: not yet written");
//    exit(254);
//    // ((EKMutableAlarm*)self).sharedUID = newSharedUID;
//}

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


+ (EKAlarm *)mostRecentAlarmFromArray:(NSArray<EKAlarm*> *)alarms forReminder:(EKReminder*)reminder {
    EKAlarm *mostRecent;
    NSTimeInterval mostRecentTimeSinceNow;
    for (EKAlarm *alarm in alarms) {
        NSTimeInterval timeSinceNow = [alarm timeIntervalSinceNowForReminder:reminder]; // returns NAN if there is no identifiable date
        if (isnan(mostRecentTimeSinceNow)) {
            // ignore
        } else if (!mostRecent || timeSinceNow>mostRecentTimeSinceNow) {
            mostRecent = alarm;
            mostRecentTimeSinceNow = timeSinceNow;
        }
    }
    return mostRecent;
}
- (NSArray<EKAlarm *>*_Nonnull)arrayByRemovingFromArray:(NSArray<EKAlarm *>*_Nullable)alarms {
    if (!alarms || !alarms.count) return @[]; // empty array
     NSMutableArray *alarmsMutable = [NSMutableArray arrayWithArray:alarms];
     [alarmsMutable removeObject:self];
     return [alarmsMutable copy];
}

extern NSInteger dupMethod, dupSetSharedUID, dupSetSnoozing, dupUse;
- (EKAlarm *)duplicateAlarm {
    NSLog(@"dup = %@.%@, %@",@(dupMethod),@(dupSetSharedUID),@(dupUse));
    EKAlarm *newAlarm;
    newAlarm
    = (dupMethod==1) ? [self copy]
    : (dupMethod==2) ? [[self class] performSelector:@selector(alarmWithAlarm:) withObject:self]
    : (dupMethod==3) ? (self.absoluteDate ? [EKAlarm alarmWithAbsoluteDate:self.absoluteDate] : [EKAlarm alarmWithRelativeOffset:self.relativeOffset])
    : (dupMethod==4) ? ((EKAlarm*) (self.absoluteDate ? [EKMutableAlarm alarmWithAbsoluteDate:self.absoluteDate] : [EKMutableAlarm alarmWithRelativeOffset:self.relativeOffset]))
    : dupMethod==5 ? self
    : [self copy];

    // if (dupSetSharedUID%2) { // odd dupSetSharedUID ==> change the sharedUID
    //     [(EKMutableAlarm*)newAlarm setTheSharedUIDTo:@"changedSharedUID"];
    // }
    if (dupSetSnoozing==1) {
        [newAlarm setSnoozing:YES]; // sets it but reverts to prior setting after being added to a reminder
    } else if (dupSetSnoozing==2) {
        // [(EKMutableAlarm*)newAlarm setSnoozingByArrowTo:YES]; // this always throws an exception since newAlarm really isn't my EKMutableAlarm
        // self->isSnoozed = newSnoozed;
    }

    if (dupMethod==3 || dupMethod==4) {
        newAlarm.soundName = @"ignore"; newAlarm.soundName = nil; // not doing this may give an error when commiting a reminder with this alarm
        BOOL hasURL = NO;
        // handle type
        @try {
            if (self.url) hasURL = YES; // deprecated as of macos 10.8
        } @catch (NSException *exception) {
            // ignore the error
        }
        if (hasURL)
            newAlarm.url = self.url;
        if (self.emailAddress)
            newAlarm.emailAddress = self.emailAddress;
        if (self.soundName)
            newAlarm.soundName = self.soundName;
        // handle proximity
        newAlarm.proximity = self.proximity;
        if (self.structuredLocation)
            newAlarm.structuredLocation = [self.structuredLocation copy]; // might be okay just to do "newAlarm.structuredLocation=self.structuredLocation" but not sure.
        
        // handle EKMutableAlarm properties
        // if ([newAlarm hasDefault] && [self hasDefault] && self.defaulting) {
        //     @try {
        //         [newAlarm setDefaulting:YES];
        //         NSLog(@"setDefaulting successfull");
        //     } @catch (NSException *exception) {
        //         NSLog(@"setDefaulting exception: %@%@",exception.reason,exception.userInfo?[NSString stringWithFormat:@" (userInfo=%@)",exception.userInfo]:@"");
        //     }
        // }
        
        // if ([newAlarm hasSnooze]) {
        //     [newAlarm setSnoozing:[self hasSnooze] ? self.snoozing : NO]; // commented out since we can set isSnoozed but it never stays when added to the reminder
        //  }
    }
    return newAlarm;
    // pre-testing stuff is below
    if ([self noSnooze]) {
        newAlarm = [self copy];
    } else { // new version that avoids duplicating the sharedUID (if it has one)
        NSLog(@"original alarm's class=\"%@\"",[self class]);
        NSLog(@"original alarm's class responds to alarmWithAlarm: = %@",@([[self class] respondsToSelector:@selector(alarmWithAlarm:)]));
        NSLog(@"original alarm = %@",[self stringWithDateFormatter:nil]);
        if (0) {
            newAlarm = [self copy];
            ((EKMutableAlarm*)newAlarm).isSnoozed = YES; // sets it but reverts to prior setting after being added to a reminder
            
            NSLog(@"EKMutableAlarm -duplicateAlarm loc 0a duplicate.sharedUID = \"%@\"",((EKMutableAlarm*)newAlarm).sharedUID);
            if ([newAlarm respondsToSelector:@selector(setSharedUID:)]) {
                NSLog(@"new alarm responds to setSharedUID:");
                [newAlarm performSelector:@selector(setSharedUID:) withObject:@"eaj loc 1"];
            } else {
                NSLog(@"new alarm does NOT respond to setSharedUID:");
                // [((EKMutableAlarm*)newAlarm) setTheSharedUIDTo:@"eaj loc 2"];
            }
            NSLog(@"EKMutableAlarm -duplicateAlarm loc 0b duplicate.sharedUID = \"%@\"",((EKMutableAlarm*)newAlarm).sharedUID);
        } else if (0) {
            newAlarm = [[self class] performSelector:@selector(alarmWithAlarm:) withObject:self];
            ((EKMutableAlarm*)newAlarm).isSnoozed = YES; // sets it but reverts to prior setting after being added to a reminder
            
            NSLog(@"EKMutableAlarm -duplicateAlarm loc 0a duplicate.sharedUID = \"%@\"",((EKMutableAlarm*)newAlarm).sharedUID);
            if ([newAlarm respondsToSelector:@selector(setSharedUID:)]) {
                NSLog(@"new alarm responds to setSharedUID:");
                [newAlarm performSelector:@selector(setSharedUID:) withObject:@"eaj loc 1"];
            } else {
                NSLog(@"new alarm does NOT respond to setSharedUID:");
                // [((EKMutableAlarm*)newAlarm) setTheSharedUIDTo:@"eaj loc 2"];
                // ((EKMutableAlarm*)newAlarm).sharedUID=@"eaj loc 3";
                // ((EKMutableAlarm*)newAlarm)->sharedUID=@"eaj loc 4";
            }
            NSLog(@"EKMutableAlarm -duplicateAlarm loc 0b duplicate.sharedUID = \"%@\"",((EKMutableAlarm*)newAlarm).sharedUID);
        } else {
            if (1) {
                newAlarm = (EKAlarm*) (self.absoluteDate ? [EKAlarm alarmWithAbsoluteDate:self.absoluteDate] : [EKAlarm alarmWithRelativeOffset:self.relativeOffset]);
            } else {
                newAlarm = (EKAlarm*) (self.absoluteDate ? [EKMutableAlarm alarmWithAbsoluteDate:self.absoluteDate] : [EKMutableAlarm alarmWithRelativeOffset:self.relativeOffset]);
            }
            NSLog(@"EKMutableAlarm -duplicateAlarm loc 1 original.sharedUID = \"%@\"",((EKMutableAlarm*)self).sharedUID);
            NSLog(@"EKMutableAlarm -duplicateAlarm loc 1 duplicate.sharedUID = \"%@\"",((EKMutableAlarm*)newAlarm).sharedUID);
            newAlarm.soundName = @"ignore"; newAlarm.soundName = nil; // not doing this may give an error when commiting a reminder with this alarm
            BOOL hasURL = NO;
            // handle type
            @try {
                if (self.url) hasURL = YES; // deprecated as of macos 10.8
            } @catch (NSException *exception) {
                // ignore the error
            }
            if (hasURL)
                newAlarm.url = self.url;
            if (self.emailAddress)
                newAlarm.emailAddress = self.emailAddress;
            if (self.soundName)
                newAlarm.soundName = self.soundName;
            // handle proximity
            newAlarm.proximity = self.proximity;
            if (self.structuredLocation)
                newAlarm.structuredLocation = [self.structuredLocation copy]; // might be okay just to do "newAlarm.structuredLocation=self.structuredLocation" but not sure.
            // handle EKMutableAlarm properties
            if ([newAlarm hasDefault])
                // [((EKMutableAlarm*)newAlarm) setDefaulting:[self hasDefault] ? self.defaulting : NO];
            if ([newAlarm hasSnooze]) {
                NSLog(@"loc 123");
                [((EKMutableAlarm*)newAlarm) setSnoozing:[self hasSnooze] ? self.snoozing : NO]; // sets it but reverts to prior setting after being added to a reminder
            }
            // ignore sharedUID
            NSLog(@"EKMutableAlarm -duplicateAlarm loc 2 duplicate.sharedUID = \"%@\"",((EKMutableAlarm*)newAlarm).sharedUID);
            // [((EKMutableAlarm*)newAlarm) setTheSharedUIDTo:@"hi from elsewhere"];
            NSLog(@"EKMutableAlarm -duplicateAlarm loc 3 duplicate.sharedUID = \"%@\"",((EKMutableAlarm*)newAlarm).sharedUID);
        }
    }
    return newAlarm;
}
- (EKAlarm *)duplicateAlarmChangingTimeTo:(NSDate*)newDate {
    EKAlarm *newAlarm = [self duplicateAlarm];
    NSLog(@"EKMutableAlarm -duplicateAlarmChangingTimeTo: loc 1 duplicate.sharedUID = \"%@\"",((EKMutableAlarm*)newAlarm).sharedUID);
    newAlarm.absoluteDate = newDate;
    NSLog(@"EKMutableAlarm -duplicateAlarmChangingTimeTo: loc 2 duplicate.sharedUID = \"%@\"",((EKMutableAlarm*)newAlarm).sharedUID);
    return newAlarm;
}
- (EKAlarm *)duplicateAlarmChangingTimeToNowPlusSecs:(NSTimeInterval)secs {
    EKAlarm *newAlarm = [self duplicateAlarmChangingTimeTo:[NSDate dateWithTimeIntervalSinceNow:secs]];
    NSLog(@"EKMutableAlarm -duplicateAlarmChangingTimeToNowPlusSecs: loc 1 duplicate.sharedUID = \"%@\"",((EKMutableAlarm*)newAlarm).sharedUID);
    return newAlarm;
}

@end
