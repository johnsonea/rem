//
//  EKAlarm+stringWith+MutableAlarm.h
//  rem
//
//  Created by Erik A Johnson on 10/29/19.
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

- (BOOL)hasSnooze;
- (BOOL)noSnooze;
- (BOOL)snoozing;
- (void)setSnoozing:(BOOL)newSnoozed;

- (NSTimeInterval)timeIntervalSinceNowForReminder:(EKReminder* _Nullable)reminder; // returns NAN if there is no identifiable date
- (BOOL)isUnsnoozedAndInPast;
- (BOOL)isUnsnoozedAndInPastForReminder:(EKReminder* _Nullable)reminder;

NSString *structuredLocationString(EKStructuredLocation *loc);
- (NSString *)proximityStr;
- (NSString *)typeString;
- (NSString *)stringWithDateFormatter:(NSDateFormatter* _Nullable)formatter;
- (NSString *)stringWithDateFormatter:(NSDateFormatter* _Nullable)formatter forReminder:(EKReminder * _Nullable)reminder;

+ (EKAlarm *)mostRecentAlarmFromArray:(NSArray<EKAlarm*> *)alarms forReminder:(EKReminder*)reminder;
- (NSArray<EKAlarm *>*_Nonnull)arrayByRemovingFromArray:(NSArray<EKAlarm *>*_Nullable)alarms;

- (EKAlarm *)duplicateAlarm;
- (EKAlarm *)duplicateAlarmChangingTimeTo:(NSDate*)newDate;
- (EKAlarm *)duplicateAlarmChangingTimeToNowPlusSecs:(NSTimeInterval)secs;

@end

NS_ASSUME_NONNULL_END
