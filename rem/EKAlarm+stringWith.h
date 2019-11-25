//
//  EKAlarm+stringWith.h
//  rem
//
//  Created by Erik A Johnson on 10/29/19.
//  Copyright © 2019 kykim, inc. All rights reserved.
//

#import <EventKit/EventKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface EKSnoozableAlarm : EKAlarm {
    bool isSnoozed;
}
@property (nonatomic) bool isSnoozed;
@end

@interface EKAlarm (stringWith)

NSString *structuredLocationString(EKStructuredLocation *loc);
- (NSString *)proximityStr;
- (NSString *)typeString;
- (BOOL)hasSnooze;
- (BOOL)noSnooze;
- (BOOL)snoozing;
- (void)setSnoozing:(BOOL)newSnoozed;
- (NSString *)stringWithDateFormatter:(NSDateFormatter* _Nullable)formatter;
- (NSString *)stringWithDateFormatter:(NSDateFormatter* _Nullable)formatter forReminder:(EKReminder * _Nullable)reminder;

- (EKAlarm *)duplicateAlarm;
- (EKAlarm *)duplicateAlarmChangingTimeTo:(NSDate*)newDate;
- (EKAlarm *)duplicateAlarmChangingTimeToNowPlusSecs:(NSTimeInterval)secs;

@end

NS_ASSUME_NONNULL_END
