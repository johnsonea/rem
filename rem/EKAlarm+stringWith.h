//
//  EKAlarm+stringWith.h
//  rem
//
//  Created by Erik A Johnson on 10/29/19.
//  Copyright © 2019 kykim, inc. All rights reserved.
//

#import <EventKit/EventKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface EKAlarm (stringWith)

NSString *structuredLocationString(EKStructuredLocation *loc);
- (NSString *)proximityStr;
- (NSString *)typeString;
- (BOOL)hasSnooze;
- (BOOL)noSnooze;
- (BOOL)snoozing;
- (NSString *)stringWithDateFormatter:(NSFormatter*)formatter;

- (EKAlarm *)duplicateAlarm;
- (EKAlarm *)duplicateAlarmChangingTimeTo:(NSDate*)newDate;
- (EKAlarm *)duplicateAlarmChangingTimeToNowPlusSecs:(NSTimeInterval)secs;

@end

NS_ASSUME_NONNULL_END
