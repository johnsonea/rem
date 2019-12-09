//
//  EKReminder+Snoozing.h
//  rem
//
//  Created by Erik A Johnson on 10/29/19.
//  Copyright © 2019 Erik A Johnson. All rights reserved.
//

#import <EventKit/EventKit.h>
#import "EKAlarm+stringWith+MutableAlarm.h"

NS_ASSUME_NONNULL_BEGIN

@interface EKReminder (Snoozing)

- (BOOL)isSnoozed;
- (EKAlarm* _Nullable)firstSnoozedAlarm;
- (NSArray<EKAlarm*>* _Nonnull)snoozedPastAlarms;

- (BOOL)hasUnsnoozedPastAlarms;
- (EKAlarm* _Nullable)firstUnsnoozedPastAlarm;
- (NSArray<EKAlarm*>* _Nonnull)unsnoozedPastAlarms;



@end

NS_ASSUME_NONNULL_END
