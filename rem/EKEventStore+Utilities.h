//
//  EKEventStore+Utilities.h
//  rem
//
//  Created by Erik A Johnson on 04/30/20.
//  Copyright © 2020 Erik A Johnson. All rights reserved.
//

#import <EventKit/EventKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface EKEventStore (Utilities)

- (NSArray<EKCalendar *> *) reminderCalendarsWithTitle:(NSString *)title;
- (EKCalendar *) firstReminderCalendarWithTitle:(NSString *)title;
- (EKCalendar *) lastReminderCalendarWithTitle:(NSString *)title;

@end

NS_ASSUME_NONNULL_END
