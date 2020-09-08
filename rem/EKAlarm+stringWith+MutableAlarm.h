//
//  EKAlarm+stringWith+MutableAlarm.h
//  rem
//
//  Created by Erik A Johnson on 10/29/19 - 12/09/2019.
//  Copyright © 2019 Erik A Johnson. All rights reserved.
//

#import <EventKit/EventKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface EKMutableAlarm : EKAlarm {
    BOOL isDefault;
    BOOL isSnoozed;
    NSString *sharedUID;
}
@property(readonly, nonatomic) NSString *sharedUID; // @synthesize sharedUID;
@property(nonatomic) BOOL isSnoozed; // @synthesize isSnoozed;
@property(readonly, nonatomic) BOOL isDefault; // @synthesize isDefault;
@end

@interface EKAlarm (stringWith)

// interfaces to EKMutableAlarm
- (BOOL)hasSnooze;
- (BOOL)noSnooze;
- (BOOL)snoozing;
- (void)setSnoozing:(BOOL)newSnoozed;

// location strings
NSString *structuredLocationString(EKStructuredLocation *loc);
- (NSString *)proximityStr;
- (NSString *)typeString;

// alarm to string
+ (void)disableEKAlarmUndocumentedWarning;
- (NSString *)stringWithDateFormatter:(NSDateFormatter* _Nullable)formatter;
- (NSString *)stringWithDateFormatter:(NSDateFormatter* _Nullable)formatter forReminder:(EKReminder * _Nullable)reminder;

// array operation
- (NSArray<EKAlarm *>*_Nonnull)arrayByRemovingFromArray:(NSArray<EKAlarm *>*_Nullable)alarms;

// duplication methods
- (EKAlarm *)duplicateAlarm;
- (EKAlarm *)duplicateAlarmChangingTimeTo:(NSDate*)newDate;
- (EKAlarm *)duplicateAlarmChangingTimeToNowPlusSecs:(NSTimeInterval)secs;

// date operations
- (BOOL)isInPast;
- (BOOL)isInPastForReminder:(EKReminder* _Nullable)reminder;

- (NSDate*_Nullable)alarmDateForReminder:(EKReminder* _Nullable)reminder; // returns nil if there is no identifiable date
- (NSTimeInterval)timeIntervalSinceNowForReminder:(EKReminder* _Nullable)reminder; // returns NAN if there is no identifiable date
- (BOOL)isUnsnoozedAndInPast;
- (BOOL)isUnsnoozedAndInPastForReminder:(EKReminder* _Nullable)reminder;

// dated alarm convenience routines
+ (NSArray<EKAlarm*> *)datedAlarmsFromArray:(NSArray<EKAlarm*> *)alarms forReminder:(EKReminder*)reminder;
+ (NSArray<EKAlarm*> *)pastAlarmsFromArray:(NSArray<EKAlarm*> *)alarms forReminder:(EKReminder*)reminder;
+ (NSArray<EKAlarm*> *)futureAlarmsFromArray:(NSArray<EKAlarm*> *)alarms forReminder:(EKReminder*)reminder;

+ (NSArray<EKAlarm*> *)sortAlarmsByDateFromArray:(NSArray<EKAlarm*> *)alarms forReminder:(EKReminder*)reminder;

+ (EKAlarm *)latestAlarmFromArray:(NSArray<EKAlarm*> *)alarms forReminder:(EKReminder*)reminder;
+ (EKAlarm *)earliestAlarmFromArray:(NSArray<EKAlarm*> *)alarms forReminder:(EKReminder*)reminder;

@end

NS_ASSUME_NONNULL_END
