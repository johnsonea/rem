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
- (BOOL)allAlarmsInPast;

/* other convenience methods */

// dueDateComponentsString methods
-(NSDate*_Nullable)dueDateFromComponents; // NOTE: MacOS has an undocumented dueDate method so this one is intentionally called something different
-(NSString*_Nullable)dueDateComponentsStringUsingDateFormatter:(NSDateFormatter*_Nonnull)dateFormatter;
-(NSString*_Nullable)dueDateComponentsString; // use NSDateFormatter with current locale, short date style, long time style

// startDateComponentsString methods
-(NSDate*_Nullable)startDateFromComponents; // NOTE: MacOS has an undocumented startDate method so this one is intentionally called something different
-(NSString*_Nullable)startDateComponentsStringUsingDateFormatter:(NSDateFormatter*_Nonnull)dateFormatter;
-(NSString*_Nullable)startDateComponentsString; // use NSDateFormatter with current locale, short date style, long time style

@end

NS_ASSUME_NONNULL_END
