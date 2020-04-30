//
//  EKEventStore+Utilities.m
//  rem
//
//  Created by Erik A Johnson on 04/30/20.
//  Copyright © 2020 Erik A Johnson. All rights reserved.
//

#import "EKEventStore+Utilities.h"
#import "errors.h"

@implementation EKEventStore (Utilities)

- (NSArray<EKCalendar *> *) reminderCalendarsWithTitle:(NSString *)title {
    NSArray<EKCalendar *> *allCalendars = [self calendarsForEntityType:EKEntityTypeReminder];
    return (title==nil) ? allCalendars : [allCalendars filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"title == %@",title]];
}
- (EKCalendar *) firstReminderCalendarWithTitle:(NSString *)title {
    return [[self reminderCalendarsWithTitle:title] firstObject];
}
- (EKCalendar *) lastReminderCalendarWithTitle:(NSString *)title {
    return [[self reminderCalendarsWithTitle:title] lastObject];
}



@end
