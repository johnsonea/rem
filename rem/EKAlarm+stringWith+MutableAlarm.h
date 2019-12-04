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

NSString *structuredLocationString(EKStructuredLocation *loc);
- (NSString *)proximityStr;
- (NSString *)typeString;
- (BOOL)hasSnooze;
- (BOOL)noSnooze;
- (BOOL)snoozing;
- (void)setSnoozing:(BOOL)newSnoozed;

- (NSTimeInterval)timeIntervalSinceNowForReminder:(EKReminder* _Nullable)reminder;
- (BOOL)isUnsnoozedAndInPast;
- (BOOL)isUnsnoozedAndInPastForReminder:(EKReminder* _Nullable)reminder;

- (NSString *)stringWithDateFormatter:(NSDateFormatter* _Nullable)formatter;
- (NSString *)stringWithDateFormatter:(NSDateFormatter* _Nullable)formatter forReminder:(EKReminder * _Nullable)reminder;

- (EKAlarm *)duplicateAlarm;
- (EKAlarm *)duplicateAlarmChangingTimeTo:(NSDate*)newDate;
- (EKAlarm *)duplicateAlarmChangingTimeToNowPlusSecs:(NSTimeInterval)secs;

@end

NS_ASSUME_NONNULL_END
