//
//  main.m
//  rem
//
//  Created by Kevin Y. Kim on 10/15/12.
//  Copyright (c) 2012 kykim, inc. All rights reserved.
//
//  Modified by Erik A. Johnson on 10/29/2019.
//

#import <Foundation/Foundation.h>
#import <EventKit/EventKit.h>

#define MYNAME @"rem"

#define COMMANDS @[ @"ls", @"add", @"rm", @"cat", @"done", @"help", @"version" ]
typedef enum _CommandType {
    CMD_UNKNOWN = -1,
    CMD_LS = 0,
    CMD_ADD,
    CMD_RM,
    CMD_CAT,
    CMD_DONE,
    CMD_HELP,
    CMD_VERSION
} CommandType;

static CommandType command;
static NSString *calendar;
static NSString *reminder_id;

static EKEventStore *store;
static NSDictionary *calendars;
static EKReminder *reminder;

#define TACKER @"├──"
#define CORNER @"└──"
#define PIPER  @"│  "
#define SPACER @"   "

/*!
    @function _print
    @abstract Wrapper for fprintf with NSString format
    @param stream
        Output stream to write to
    @param format
        (f)printf style format string
    @param ...
        optional arguments as defined by format string
    @discussion Wraps call to fprintf with an NSString format argument, permitting use of the
        object formatter '%@'
 */
static void _print(FILE *file, NSString *format, ...)
{
    va_list args;
    va_start(args, format);
    NSString *string = [[NSString alloc] initWithFormat:format arguments:args];
    fprintf(file, "%s", [string UTF8String]);
    va_end(args);
}

/*!
    @function _version
    @abstract Output version information
 */
static void _version()
{
    _print(stdout, @"%@ Version 0.01eaj\n",MYNAME);
}

/*!
    @function _usage
    @abstract Output command usage
 */
static void _usage()
{
    _print(stdout, @"Usage:\n");
    _print(stdout, @"\t%@ [ls] <list>\n\t\tList reminders\n",MYNAME);
    _print(stdout, @"\t%@ rm <list> <reminder>\n\t\tRemove reminder from list\n",MYNAME);
    _print(stdout, @"\t%@ add <reminder>\n\t\tAdd reminder to your default list\n",MYNAME);
    _print(stdout, @"\t%@ cat <list> <item>\n\t\tShow reminder detail\n",MYNAME);
    _print(stdout, @"\t%@ done <list> <item>\n\t\tMark reminder as complete\n",MYNAME);
    _print(stdout, @"\t%@ help\n\t\tShow this text\n",MYNAME);
    _print(stdout, @"\t%@ version\n\t\tShow version information\n",MYNAME);
    _print(stdout, @"\t(Note: commands can be like \"ls\" or \"--ls\" or \"-l\".)\n",MYNAME);
}

/*!
    @function parseArguments
    @abstract Command arguement parser
    @description Parse command-line arguments and populate appropriate variables
 */
static void parseArguments()
{
    command = CMD_LS;

    NSMutableArray *args = [NSMutableArray arrayWithArray:[[NSProcessInfo processInfo] arguments]];
    [args removeObjectAtIndex:0];    // pop off application argument

    // args array is empty, command was excuted without arguments
    if (args.count == 0)
        return;

    NSString *cmd = [args objectAtIndex:0];
    
    // allow --ls in addition to ls, etc.
    if ([cmd hasPrefix:@"--"]) {
        cmd = [cmd substringFromIndex:[@"--" length]];
    }
    command = (CommandType)[COMMANDS indexOfObject:cmd];
    
    // allow -l in addition to ls and --ls
    if (command == CMD_UNKNOWN && [cmd hasPrefix:@"-"] && [(cmd = [cmd substringFromIndex:[@"-" length]]) length]>0) {
        for (NSString *aCommand in COMMANDS) {
            if ([aCommand hasPrefix:cmd]) {
                command = (CommandType)[COMMANDS indexOfObject:aCommand];
                break;
            }
        }
    }
    
    if (command == CMD_UNKNOWN) {
        _print(stderr, @"%@: Error unknown command %@", MYNAME, cmd);
        _usage();
        exit(-1);
    }

    // handle help and version requests
    if (command == CMD_HELP) {
        _usage();
        exit(0);
    }
    else if (command == CMD_VERSION) {
        _version();
        exit(0);
    }

    // if we're adding a reminder, overload reminder_id to hold the reminder text (title)
    if (command == CMD_ADD) {
        reminder_id = [[args subarrayWithRange:NSMakeRange(1, [args count]-1)] componentsJoinedByString:@" "];
        return;
    }

    // get the reminder list (calendar) if exists
    if (args.count >= 2) {
        calendar = [args objectAtIndex:1];
    }

    // get the reminder id if exists
    if (args.count >= 3) {
        reminder_id = [args objectAtIndex:2];
    }

    return;
}

/*!
    @function fetchReminders
    @returns NSArray of EKReminders
    @abstract Fetch all reminders from Event Store
    @description use EventKit API to define a predicate to fetch all reminders from the
        Event Store. Loop over current Run Loop until asynchronous reminder fetch is
        completed.
 */
static NSArray* fetchReminders()
{
    __block NSArray *reminders = nil;
    __block BOOL fetching = YES;
    NSPredicate *predicate = [store predicateForRemindersInCalendars:nil];
    [store fetchRemindersMatchingPredicate:predicate completion:^(NSArray *ekReminders) {
        reminders = ekReminders;
        fetching = NO;
    }];

    while (fetching) {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.01]];
    }

    return reminders;
}

/*!
    @function sortReminders
    @abstract Sort an array of reminders into a dictionary.
    @returns NSDictionary
    @param reminders
        NSArray of EKReminder instances
    @description Sort an array of EKReminder instances into a dictionary.
        The keys of the dictionary are reminder list (calendar) names, which is a property of each
        EKReminder. The values are arrays containing EKReminders that share a common calendar.
 */
static NSDictionary* sortReminders(NSArray *reminders)
{
    NSMutableDictionary *results = nil;
    if (reminders != nil && reminders.count > 0) {
        results = [NSMutableDictionary dictionary];
        for (EKReminder *r in reminders) {
            if (r.completed)
                continue;

            EKCalendar *calendar = [r calendar];
            if ([results objectForKey:calendar.title] == nil) {
                [results setObject:[NSMutableArray array] forKey:calendar.title];
            }
            NSMutableArray *calendarReminders = [results objectForKey:calendar.title];
            [calendarReminders addObject:r];
        }
    }
    return results;
}

/*!
    @function validateArguments
    @abstract Verfy the (reminder) list and reminder_id command-line arguments
    @description If provided, verify that the (reminder) list and reminder_id
        command-line arguments are valid. Compare the (reminder) list to the keys
        of the calendars dictionary. Verify the integer value of the reminder_id
        is within the index range of the appropriate calendar array.
 */
static void validateArguments()
{
    if (command == CMD_LS && calendar == nil)
        return;

    if (command == CMD_ADD)
        return;

    NSUInteger calendar_id = [[calendars allKeys] indexOfObject:calendar];
    if (calendar_id == NSNotFound) {
        _print(stderr, @"%@: Error - Unknown Reminder List: \"%@\"\n", MYNAME, calendar);
        exit(-1);
    }

    if (command == CMD_LS && reminder_id == nil)
        return;

    NSInteger r_id = [reminder_id integerValue] - 1;
    NSArray *reminders = [calendars objectForKey:calendar];
    if (r_id < 0 || r_id > reminders.count-1) {
        _print(stderr, @"%@: Error - ID Out of Range for Reminder List: %@\n", MYNAME, calendar);
        exit(-1);
    }
    reminder = [reminders objectAtIndex:r_id];
}

/*!
    @function _printCalendarLine
    @abstract format and output line containing calendar (reminder list) name
    @param line
        line to output
    @param last
        is this the last calendar being diplayed?
    @description format and output line containing calendar (reminder list) name.
        If it is the last calendar being displayed, prefix the name with a corner
        unicode character. If it is not the last calendar, prefix the name with a
        right-tack unicode character. Both prefix unicode characters are followed
        by two horizontal lines, also unicode.
 */
static void _printCalendarLine(NSString *line, BOOL last)
{
    NSString *prefix = (last) ? CORNER : TACKER;
    _print(stdout, @"%@ %@\n", prefix, line);
}

/*!
    @function _printReminderLine
    @abstract format and output line containing reminder information
    @param line
        line to output
    @param last
        is this the last reminder being diplayed?
    @param lastCalendar
        does this reminder belong to last calendar being displayed?
    @description format and output line containing reminder information.
        If it is the last reminder being displayed, prefix the name with a corner
        unicode character. If it is not the last reminder, prefix the name with a
        right-tack unicode character. Both prefix unicode characters are followed
        by two horizontal lines, also unicode. Also, indent the reminder with either
        blank space, if part of last calendar; or vertical bar followed by blank space.
 */
static void _printReminderLine(NSUInteger id, NSString *line, BOOL last, BOOL lastCalendar)
{
    NSString *indent = (lastCalendar) ? SPACER : PIPER;
    NSString *prefix = (last) ? CORNER : TACKER;
    _print(stdout, @"%@%@ %ld. %@\n", indent, prefix, id, line);
}

/*!
    @function _listCalendar
    @abstract output a calaendar and its reminders
    @param cal
        name of calendar (reminder list)
    @param last
        is this the last calendar being displayed?
    @description given a calendar (reminder list) name, output the calendar via
        _printCalendarLine. Retrieve the calendars reminders and display via _printReminderLine.
        Each reminder is prepended with an index/id for other commands
 */
static void _listCalendar(NSString *cal, BOOL last)
{
    _printCalendarLine(cal, last);
    NSArray *reminders = [calendars valueForKey:cal];
    for (NSUInteger i = 0; i < reminders.count; i++) {
        EKReminder *r = [reminders objectAtIndex:i];
        _printReminderLine(i+1, r.title, (r == [reminders lastObject]), last);
    }
}

/*!
    @function listReminders
    @abstract list reminders
    @description list all reminders if no calendar (reminder list) specified,
        or list reminders in specified calendar
 */
static void listReminders()
{
    _print(stdout, @"Reminders\n");
    if (calendar) {
        _listCalendar(calendar, YES);
    }
    else {
        for (NSString *cal in calendars) {
            _listCalendar(cal, (cal == [[calendars allKeys] lastObject]));
        }
    }
}

/*!
    @function addReminder
    @abstract add a reminder
    @description add a reminder to the default calendar
 */
static void addReminder()
{
    reminder = [EKReminder reminderWithEventStore:store];
    reminder.calendar = [store defaultCalendarForNewReminders];
    reminder.title = reminder_id;

    NSError *error;
    BOOL success = [store saveReminder:reminder commit:YES error:&error];
    if (!success) {
        _print(stderr, @"%@: Error adding Reminder (%@)\n\t%@", MYNAME, reminder_id, [error localizedDescription]);
    }
}

/*!
    @function removeReminder
    @abstract remove a specified reminder
    @description remove a specified reminder
 */
static void removeReminder()
{
    NSError *error;
    BOOL success = [store removeReminder:reminder commit:YES error:&error];
    if (!success) {
        _print(stderr, @"%@: Error removing Reminder (%@) from list %@\n\t%@", MYNAME, reminder_id, calendar, [error localizedDescription]);
    }
}

/*!
    @function showReminder
    @abstract show reminder details
    @description show reminder details: creation date, last modified date (if different than
        creation date), start date (if defined), due date (if defined), notes (if defined)
 */
static void showReminder()
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateStyle:NSDateFormatterShortStyle];

    _print(stdout, @"Reminder: %@\n", reminder.title);
    _print(stdout, @"\tList: %@\n", calendar);

    _print(stdout, @"\tCreated On: %@\n", [dateFormatter stringFromDate:reminder.creationDate]);

    if (reminder.lastModifiedDate != reminder.creationDate) {
        _print(stdout, @"\tLast Modified On: %@\n", [dateFormatter stringFromDate:reminder.lastModifiedDate]);
    }

    NSDate *startDate = [reminder.startDateComponents date];
    if (startDate) {
        _print(stdout, @"\tStarted On: %@\n", [dateFormatter stringFromDate:startDate]);
    }

    NSDate *dueDate = [reminder.dueDateComponents date];
    if (dueDate) {
        _print(stdout, @"\tDue On: %@\n", [dateFormatter stringFromDate:dueDate]);
    }

    if (reminder.hasNotes) {
        _print(stdout, @"\tNotes: %@\n", reminder.notes);
    }
}

/*!
    @function completeReminder
    @abstract mark specified reminder as complete
    @description mark specified reminder as complete
 */
static void completeReminder()
{
    reminder.completed = YES;
    NSError *error;
    BOOL success = [store saveReminder:reminder commit:YES error:&error];
    if (!success) {
        _print(stderr, @"%@: Error marking Reminder (%@) from list %@\n\t%@", MYNAME, reminder_id, calendar, [error localizedDescription]);
    }
}

/*!
    @function handleCommand
    @abstract dispatch to correct function based on command-line argument
    @description dispatch to correct function based on command-line argument
 */
static void handleCommand()
{
    switch (command) {
        case CMD_LS:
            listReminders();
            break;
        case CMD_ADD:
            addReminder();
            break;
        case CMD_RM:
            removeReminder();
            break;
        case CMD_CAT:
            showReminder();
            break;
        case CMD_DONE:
            completeReminder();
            break;
        case CMD_HELP:
        case CMD_VERSION:
        case CMD_UNKNOWN:
            break;
    }

}

int main(int argc, const char * argv[])
{

    @autoreleasepool {
        parseArguments();

        store = [[EKEventStore alloc] initWithAccessToEntityTypes:EKEntityMaskReminder];

        if (command != CMD_ADD) {
            NSArray *reminders = fetchReminders();
            calendars = sortReminders(reminders);
        }

        validateArguments();
        handleCommand();
    }
    return 0;
}

