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
#import "EKAlarm+stringWith.h"
#import "EKEventStore+Synchronous.h"
#import "errors.h"
#import "EKReminder+Snoozing.h"
#import "NSMutableArray+Queue.h"

/*
 TO DO:
    * add "undone" to change completed back to not completed
    * add "finished" to get completed reminders
    * add: allow additional argument for due date&time
    * allow multiple <item> designations
    * done: save info on now-completed reminder so we can "undo" it and make it incomplete again
    * rm: save reminder info so we can unrm
 */

#define NSLog(format, ...) NSLog([@"%s (%@:%d) " stringByAppendingString:format],__FUNCTION__,[[NSString stringWithUTF8String:__FILE__] lastPathComponent],__LINE__, ## __VA_ARGS__)

// #define debug3(format, ...) fprintf (stderr, format, ## __VA_ARGS__)


#define MYNAME @"rem"
#define SHOW_NEW_DETAILS 1
#define RM_ASK_BEFORE 1

NSString *REMINDER_TITLE_PREFIX = @"--";
NSString *PLUS_PREFIX = @"+";
NSString *MINUS_PREFIX = @"-";
NSString *SWITCH_SHORTDASH = @"-";
NSString *SWITCH_LONGDASH  = @"--";

#define COMMANDS @[ @"ls", @"add", @"rm", @"cat", @"done", @"every", @"snooze", @"help", @"version" ]
typedef enum _CommandType {
    CMD_UNKNOWN = -1,
    CMD_LS = 0,
    CMD_ADD,
    CMD_RM,
    CMD_CAT,
    CMD_DONE,
    CMD_EVERY, // list everything
    CMD_SNOOZE, // snooze a reminder
    CMD_HELP,
    CMD_VERSION
} CommandType;

static CommandType command;
BOOL isUppercaseCommand = NO;
static NSString *calendarTitle;
static NSString *reminder_id_str = nil;
static NSString *snoozeSecondsString = nil;
static BOOL useAdvanced = NO;

static EKEventStore *store;
static NSDictionary *calendars;
static EKReminder *reminder;
static NSArray<EKReminder*> *allReminders;

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
    NSString *SPACES = [@"" stringByPaddingToLength:[MYNAME length]
         withString:@" " startingAtIndex:0];
    _print(stdout, @"Usage:\n");
    _print(stdout, @"\t%@ [ls [<list>]]\n\t\tList reminders (default is all lists)\n",MYNAME);
    _print(stdout, @"\t%@ rm <list> <item> [<item2> ...]\n\t\tRemove reminder(s) from list\n",MYNAME);
    _print(stdout, @"\t%@ add [--due <date> | --due <timeFromNow>] [--note <note>] ...\n\t%@     [--priority <integer0-9>] %@<remindertitle>\n\t\tAdd reminder to your default list\n",MYNAME,SPACES,useAdvanced?[NSString stringWithFormat:@"... \n\t%@     [--DUE   [   <dueDate> | -<secondsBeforeNow> | +<secondsAfterNow>]]... \n\t%@     [--START [ <startDate> | -<secondsBeforeNow> | +<secondsAfterNow>]]... \n\t%@     [--DATE  [<remindDate> | -<secondsBeforeDueDate> | +<secondsAfterDueDate>]] ...\n\t%@     ",SPACES,SPACES,SPACES,SPACES]:@"");
    _print(stdout, @"\t%@ cat <list> <item1> [<item2> ...]\n\t\tShow reminder detail\n",MYNAME);
    _print(stdout, @"\t%@ done <list> <item1> [<item2> ...]\n\t\tMark reminder(s) as complete\n",MYNAME);
    _print(stdout, @"\t%@ every [<list>]\n\t\tList reminders with details (default is all lists)\n",MYNAME);
    _print(stdout, @"\t%@ snooze <list> <seconds> <item1> [<item2> ...]\n\t\tSnooze reminder until <seconds> from now\n",MYNAME);
    _print(stdout, @"\t%@ help\n\t\tShow this text\n",MYNAME);
    _print(stdout, @"\t%@ version\n\t\tShow version information\n",MYNAME);
    _print(stdout, @"\tNote: commands can be like \"ls\" or \"--ls\" or \"-l\".\n",MYNAME);
    _print(stdout, @"\tNote: <item> is an integer, or a dash followed by a reminder title.\n",MYNAME);
}

/*!
    @function parseArguments
    @abstract Command arguement parser
    @returns an exit status (0 for no error)
    @description Parse command-line arguments and populate appropriate variables
 */
static int parseArguments(NSMutableArray **itemArgs)
{
    NSMutableArray *args = *itemArgs = [NSMutableArray arrayWithArray:[[NSProcessInfo processInfo] arguments]];
    [args shift]; // pop off application argument

    // args array is empty, command was excuted without arguments
    if (args.count == 0) {
        command = CMD_LS;
        return EXIT_NORMAL;
    }

    NSString *cmd = [args shift];
    isUppercaseCommand = [[cmd uppercaseString] isEqualToString:cmd]; // if so, then no need to warn about "DONE" and "RM"
    cmd = [cmd lowercaseString];
    // allow --ls in addition to ls, etc.
    BOOL longSwitch = [cmd hasPrefix:SWITCH_LONGDASH];
    if (longSwitch) {
        cmd = [cmd substringFromIndex:[SWITCH_LONGDASH length]];
    }
    NSUInteger _command = [COMMANDS indexOfObject:cmd];
    command = _command==NSNotFound ? CMD_UNKNOWN : (CommandType)_command; // old approach assumed NSNotFound is -1 (which it was in 32-bit apps) and just typecast _command as a CommandType; in 64-bit, NSNotFound is no longer -1 so this is needed
    
    // allow -l in addition to ls and --ls
    if (!longSwitch && command == CMD_UNKNOWN && [cmd hasPrefix:SWITCH_SHORTDASH] && [(cmd = [cmd substringFromIndex:[SWITCH_SHORTDASH length]]) length]>0) {
        for (NSUInteger i=0; i<COMMANDS.count; i++) {
            if ([COMMANDS[i] hasPrefix:cmd]) {
                command = (CommandType)i;
                break;
            }
        }
    }
    

    if (command == CMD_UNKNOWN) {
        _print(stderr, @"%@: Error unknown command %@\n", MYNAME, cmd);
        _usage();
        return EXIT_CMD_UNKNOWN;
    }

    // handle help and version requests
    if (command == CMD_HELP) {
        _usage();
        return EXIT_CLEAN;
    }
    else if (command == CMD_VERSION) {
        _version();
        return EXIT_CLEAN;
    }

    // if we're adding a reminder, leave all remaining arguments here
    if (command == CMD_ADD) {
        return EXIT_NORMAL;
    }

    // get the reminder list (calendar) if exists
    if (args.count) {
        calendarTitle = [args shift];
        if ([calendarTitle isEqualToString:@""] || [calendarTitle isEqualToString:@"*"]) {
            calendarTitle = nil; // denotes "all calendars"
        }
    }

    if (command == CMD_SNOOZE) {
        snoozeSecondsString = [args shift];
    }
    
    // remaining args, if any, are reminder ID's or -titles
    
    return EXIT_NORMAL;
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
// TO DO: (1) move this to EKEventStore+...
//        (2) if calendar was specified on command line, search only for that calendar
//        (3) use flags (includeCompleted, includeIncomplete) to decide if [self predicateForRemindersInCalendars:theCalendarsOrNil] or [self predicateForIncompleteRemindersWithDueDateStarting:NOW ending:nil calendars:theCalendarsOrNil] or [self predicateForCompletedRemindersWithCompletionDateStarting:nil ending:NOW calendars:theCalendarsOrNil]
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
    @abstract Verfy the (reminder) list and reminder_id_str command-line arguments
    @returns an exit status (0 for no error)
    @globals used: command, calendarTitle, reminder_id_str
    @globals set: reminder
    @description If provided, verify that the (reminder) list and reminder_id_str
        command-line arguments are valid. Compare the (reminder) list to the keys
        of the calendars dictionary. Verify the integer value of the reminder_id_str
        is within the index range of the appropriate calendar array.
 */
static int validateArguments()
{
    if ((command == CMD_LS || command == CMD_EVERY) && calendarTitle==nil) {
        return EXIT_NORMAL;
    }

    if (command == CMD_ADD) {
        return EXIT_NORMAL;
    }

    if (calendarTitle) {
        NSUInteger calendar_id = [[calendars allKeys] indexOfObject:calendarTitle];
        if (calendar_id == NSNotFound) {
            _print(stderr, @"%@: Error - Unknown Reminder List: \"%@\"\n", MYNAME, calendarTitle);
            return EXIT_INVARG_NOSUCHCALENDAR;
        }
    }

    if (command == CMD_LS || command == CMD_EVERY) // list all reminders in calendar
        return EXIT_NORMAL;
    
    if (command == CMD_SNOOZE && snoozeSecondsString == nil) {
        _print(stderr, @"%@: need # of seconds to snooze\n", MYNAME);
        return EXIT_INVARG_SNOOZEMISSING;
    }
    
    return EXIT_NORMAL;
}

// BOOL showError = YES;
/*
if (showError) {
    _print(stderr, @"%@: Error - no reminder # provided for Reminder List: %@\n", MYNAME, calendarTitle);
    return EXIT_INVARG_NOID;
}
*/

int nextReminderFromArgs(NSMutableArray<NSString*> *args, EKReminder **reminderRef, NSUInteger *reminder_id_ref) {
    *reminderRef = nil; // probably not necessary but just in case
    *reminder_id_ref = 0; // probably not necessary but just in case
    if (args==nil || args.count==0) {
        return EXIT_NORMAL; // no error, only ran out of arguments
    }
    NSString *reminder_id_str = [args pop];
    if ([[reminder_id_str lowercaseString] isEqualToString:@"notified"]) {
        _print(stderr, @"%@: have not written \"notified reminders\" code yet.\n", MYNAME );
        return EXIT_FATAL;
    } else if ([reminder_id_str hasPrefix:REMINDER_TITLE_PREFIX]) {
        NSArray *reminders = calendarTitle ? [calendars objectForKey:calendarTitle] : allReminders;
        if (reminders.count < 1) {
            _print(stderr, @"%@: Error - there are no reminders\n", MYNAME, calendarTitle ? [NSString stringWithFormat:@" in Reminder List: %@",calendarTitle] : @"");
            return EXIT_INVARG_EMPTYCALENDAR;
        }
        // try to find the reminder by title
        __block NSString *title = [reminder_id_str substringFromIndex:[REMINDER_TITLE_PREFIX length]];
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"title == %@",title];
        predicate = [NSPredicate predicateWithBlock:^BOOL(id object, NSDictionary *bindings) {
            return [[(EKReminder*)object title] isEqualToString:title] && (command!=CMD_SNOOZE || [(EKReminder*)object snoozing]);
        }];
        NSArray *filteredReminders = [reminders filteredArrayUsingPredicate:predicate];
        if (filteredReminders == nil || filteredReminders.count == 0) {
            _print(stderr, @"%@: Error - there are no %@reminders titled \"%@\"%@\n", MYNAME, command==CMD_SNOOZE ? @"snoozing " : @"", title, calendarTitle ? [NSString stringWithFormat:@" in List %@",calendarTitle] : @"");
            return EXIT_INVARG_BADTITLE;
        } else if (filteredReminders.count > 1) {
            _print(stderr, @"%@: Error - there are %@ reminders titled \"%@\"%@ -- do not know which one to snooze\n", MYNAME, @(filteredReminders.count), title, calendarTitle ? [NSString stringWithFormat:@" in List %@",calendarTitle] : @"");
            return EXIT_INVARG_BADTITLE;
        }
        *reminderRef = filteredReminders[0];
    } else if (calendarTitle == nil) {
        _print(stderr, @"%@: Error - can only specify a reminder by number when also specifying the reminder List\n", MYNAME);
        return EXIT_INVARG_NOTALLCALENDARS;
    } else {
        NSArray *reminders = [calendars objectForKey:calendarTitle];
        if (reminders.count < 1) {
            _print(stderr, @"%@: Error - there are no reminders in Reminder List: %@\n", MYNAME, calendarTitle);
            return EXIT_INVARG_EMPTYCALENDAR;
        }
        NSInteger r_id = [reminder_id_str integerValue];
        if (r_id < 0) r_id = reminders.count + r_id + 1;
        *reminder_id_ref = r_id;
        if (r_id < 1 || r_id > reminders.count) {
            _print(stderr, @"%@: Error - ID Out of Range [1,%@] for Reminder List: %@\n", MYNAME, @(reminders.count), calendarTitle);
            return EXIT_INVARG_IDRANGE;
        }
        *reminderRef = [reminders objectAtIndex:r_id-1];
    }
    return EXIT_NORMAL;
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
    @function showReminder
    @param showTitle
        should the title be shown or should we indent
    @param lastReminder
        is this the last reminder being diplayed?
    @param lastCalendar
        does this reminder belong to last calendar being displayed?
    @abstract show reminder details
    @description show reminder details: creation date, last modified date (if different than
        creation date), start date (if defined), due date (if defined), completed date (if completed),
        priority, local ID, recurrence rules (if any), alarms (if any), notes (if defined)
 */
static void showReminder(EKReminder *reminder, BOOL showTitle, BOOL lastReminder, BOOL lastCalendar)
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateStyle:NSDateFormatterShortStyle];

    NSDateFormatter *dateFormatterShortDateLongTime = [[NSDateFormatter alloc] init];
    dateFormatterShortDateLongTime = [[NSDateFormatter alloc] init];
    dateFormatterShortDateLongTime.dateStyle = NSDateFormatterShortStyle;
    dateFormatterShortDateLongTime.timeStyle = NSDateFormatterLongStyle;
    dateFormatterShortDateLongTime.locale = [NSLocale autoupdatingCurrentLocale]; // or [NSLocale currentLocale] or [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
    
    NSString *indent = (lastCalendar) ? SPACER : PIPER;
    NSString *prefix = (lastReminder) ? SPACER : PIPER;
    indent = showTitle ? @"\t" : [[indent stringByAppendingString:prefix] stringByAppendingString:@"        "];

    if (showTitle)
        _print(stdout, @"Reminder: %@\n", reminder.title);
    _print(stdout, @"%@List: %@\n", indent, reminder.calendar.title);

    _print(stdout, @"%@Created  On: %@\n", indent, [dateFormatterShortDateLongTime stringFromDate:reminder.creationDate]);

    if (reminder.lastModifiedDate != reminder.creationDate) {
        _print(stdout, @"%@Modified On: %@\n", indent, [dateFormatterShortDateLongTime stringFromDate:reminder.lastModifiedDate]);
    }

    if (reminder.startDateComponents) {
        NSDate *startDate = [[NSCalendar currentCalendar] dateFromComponents:reminder.startDateComponents]; // this does not work: [reminder.startDateComponents date];
        if (startDate) {
            _print(stdout, @"%@Started  On: %@\n", indent, [dateFormatterShortDateLongTime stringFromDate:startDate]);
        }
    }

    if (reminder.dueDateComponents) {
        NSDate *dueDate = [[NSCalendar currentCalendar] dateFromComponents:reminder.dueDateComponents]; // this does not work: [reminder.dueDateComponents date];
        if (dueDate) {
            _print(stdout, @"%@Due      On: %@\n", indent, [dateFormatterShortDateLongTime stringFromDate:dueDate]);
        }
    }

    if (SHOW_NEW_DETAILS) {
        if (reminder.completed) {
            NSString *completedDateStr = reminder.completionDate ? [dateFormatterShortDateLongTime stringFromDate:reminder.completionDate] : @"yes";
            _print(stdout, @"%@Completed: %@\n", indent, completedDateStr);
        }
        _print(stdout, @"%@Priority: %@\n", indent, [NSString stringWithFormat:@"%@",@(reminder.priority)]);
        _print(stdout, @"%@Local ID: %@\n", indent, reminder.calendarItemIdentifier);
        if (reminder.hasRecurrenceRules && reminder.recurrenceRules) {
            for (NSUInteger i=0; i<reminder.recurrenceRules.count; i++) {
                _print(stdout, @"%@Recurrence Rule %@: %@\n", indent, @(i+1), reminder.recurrenceRules[i].description); // NOTE: .description is decent though could make it more humanly readable
            }
        }
        if (reminder.hasAlarms && reminder.alarms) {
            for (NSUInteger i=0; i<reminder.alarms.count; i++) {
                _print(stdout, @"%@Alarm %@: %@\n", indent, @(i+1), [reminder.alarms[i] stringWithDateFormatter:dateFormatterShortDateLongTime]);
            }
        }
    }

    if (reminder.hasNotes) {
        _print(stdout, @"%@Notes: %@\n", indent, reminder.notes);
    }
}

/*!
    @function _listCalendar
    @abstract output a calaendar and its reminders
    @param cal
        name of calendar (reminder list)
    @param last
        is this the last calendar being displayed?
    @param withDetails
        whether to print the reminder details after the title
    @description given a calendar (reminder list) name, output the calendar via
        _printCalendarLine. Retrieve the calendars reminders and display via _printReminderLine.
        Each reminder is prepended with an index/id for other commands
 */
static void _listCalendar(NSString *calendarTitle, BOOL last, BOOL withDetails)
{
    _printCalendarLine(calendarTitle, last);
    NSArray *reminders = [calendars valueForKey:calendarTitle];
    for (NSUInteger i = 0; i < reminders.count; i++) {
        EKReminder *r = [reminders objectAtIndex:i];
        BOOL isLastReminder = (r == [reminders lastObject]);
        _printReminderLine(i+1, r.title, isLastReminder, last);
        if (withDetails) {
            showReminder(r, NO,isLastReminder,last);
        }
    }
}

/*!
    @function listReminders
    @abstract list reminders
    @param withDetails
        whether to print details after the reminder title
    @description list all reminders if no calendar (reminder list) specified,
        or list reminders in specified calendar
 */
static void listReminders(NSString *calendarTitle, BOOL withDetails)
{
    _print(stdout, @"Reminders\n");
    if (calendarTitle) {
        _listCalendar(calendarTitle, YES, withDetails);
    } else {
        for (calendarTitle in calendars) {
            _listCalendar(calendarTitle, (calendarTitle == [[calendars allKeys] lastObject]), withDetails);
        }
    }
}

int scanIntegerAlone(NSString *str, NSInteger *ref) {
    NSScanner *scanner = [NSScanner localizedScannerWithString:str];
    return (![scanner scanInteger:ref] ? 0 : scanner.atEnd ? 1 : 2);
}
int scanDoubleAlone(NSString *str, double *ref) {
    NSScanner *scanner = [NSScanner localizedScannerWithString:str];
    return (![scanner scanDouble:ref] ? 0 : scanner.atEnd ? 1 : 2);
}
int parseTimeSeparatedByDHMS(NSString *substr, double *secsRef) {
    NSRange r;
    NSError *error = NULL;
    if (DEBUG) NSLog(@"parseTimeSeparatedByDHMS: substr=%@",substr);
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"^\\s*((\\d+(\\.\\d*)?)\\s*d)?\\s*((\\d+(\\.\\d*)?)\\s*h)?\\s*((\\d+(\\.\\d*)?)\\s*m)?\\s*((\\d+(\\.\\d*)?)\\s*s?)?\\s*$" options:NSRegularExpressionCaseInsensitive error:&error];
    if (DEBUG) NSLog(@"parseTimeSeparatedByDHMS 1, regex = %@",regex);
    if (error != nil) {
        _print(stderr, @"%@: illegal HMS regular expression (this should not happen): #%@ %@\n", MYNAME, @(error.code), error.localizedDescription);
        return EXIT_FATAL;
    }
    if (DEBUG) NSLog(@"parseTimeSeparatedByDHMS 2");
    NSTextCheckingResult *match = [regex firstMatchInString:substr options:0 range:NSMakeRange(0, [substr length])];
    if (match == nil)
        return EXIT_CLEAN;
    if (DEBUG) NSLog(@"parseTimeSeparatedByDHMS 3, match = %@",match);
    if (DEBUG) NSLog(@"parseTimeSeparatedByDHMS 4, match.range = [%@,%@]",@(match.range.location),@(match.range.length));
    if (DEBUG) NSLog(@"parseTimeSeparatedByDHMS 5, match.numberOfRanges = %@",@(match.numberOfRanges));
    r = [match rangeAtIndex:2];
    if (DEBUG) NSLog(@"parseTimeSeparatedByDHMS 6, match.range[2] = [%@,%@]",@(r.location),@(r.length));
    r = [match rangeAtIndex:5];
    if (DEBUG) NSLog(@"parseTimeSeparatedByDHMS 7, match.range[5] = [%@,%@]",@(r.location),@(r.length));
    r = [match rangeAtIndex:8];
    if (DEBUG) NSLog(@"parseTimeSeparatedByDHMS 8, match.range[8] = [%@,%@]",@(r.location),@(r.length));
    r = [match rangeAtIndex:11];
    if (DEBUG) NSLog(@"parseTimeSeparatedByDHMS 9, match.range[11] = [%@,%@]",@(r.location),@(r.length));
    if (DEBUG) NSLog(@"parseTimeSeparatedByDHMS 10");
    *secsRef = 0.0;
    r=[match rangeAtIndex:2]; if (r.location!=NSNotFound) *secsRef+=[[substr substringWithRange:r] doubleValue]*86400.0;
    r=[match rangeAtIndex:5]; if (r.location!=NSNotFound) *secsRef+=[[substr substringWithRange:r] doubleValue]*3600.0;
    r=[match rangeAtIndex:8]; if (r.location!=NSNotFound) *secsRef+=[[substr substringWithRange:r] doubleValue]*60.0;
    r=[match rangeAtIndex:11]; if (r.location!=NSNotFound) *secsRef+=[[substr substringWithRange:r] doubleValue];
    if (DEBUG) NSLog(@"parseTimeSeparatedByDHMS 99, secs = %@",@(*secsRef));
    return EXIT_NORMAL;
}
int parseTimeSeparatedByColons(NSString *substr, double *secsRef) {
    NSRange r;
    NSError *error = NULL;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"^\\s*((((\\d+)\\s*:)?\\s*(\\d+)\\s*:)?\\s*(\\d+)\\s*:)?\\s*(\\d+(\\.\\d*)?)$" options:NSRegularExpressionCaseInsensitive error:&error];
    NSLog(@"parseTimeSeparatedByColons 1, regex = %@",regex);
    if (error != nil) {
        _print(stderr, @"%@: illegal HMS regular expression (this should not happen): #%@ %@\n", MYNAME, @(error.code), error.localizedDescription);
        return EXIT_FATAL;
    }
    NSLog(@"parseTimeSeparatedByColons 2");
    // location==NSNotFound ==> range is blank
    NSTextCheckingResult *match = [regex firstMatchInString:substr options:0 range:NSMakeRange(0, [substr length])];
    if (match == nil)
        return EXIT_CLEAN;
    NSLog(@"parseTimeSeparatedByColons 3, match = %@",match);
    NSLog(@"parseTimeSeparatedByColons 4, match.range = [%@,%@]",@(match.range.location),@(match.range.length));
    NSLog(@"parseTimeSeparatedByColons 5, match.numberOfRanges = %@",@(match.numberOfRanges));
    r = [match rangeAtIndex:4];
    NSLog(@"parseTimeSeparatedByColons 6, match.range[4] = [%@,%@]",@(r.location),@(r.length));
    r = [match rangeAtIndex:5];
    NSLog(@"parseTimeSeparatedByColons 7, match.range[5] = [%@,%@]",@(r.location),@(r.length));
    r = [match rangeAtIndex:6];
    NSLog(@"parseTimeSeparatedByColons 8, match.range[6] = [%@,%@]",@(r.location),@(r.length));
    r = [match rangeAtIndex:7];
    NSLog(@"parseTimeSeparatedByColons 9, match.range[7] = [%@,%@]",@(r.location),@(r.length));
    NSLog(@"parseTimeSeparatedByColons 10");
    // NSRange matchRange = [match range];
    *secsRef = 0.0;
    r=[match rangeAtIndex:4]; if (r.location!=NSNotFound) *secsRef+=[[substr substringWithRange:r] integerValue]*86400.0;
    r=[match rangeAtIndex:5]; if (r.location!=NSNotFound) *secsRef+=[[substr substringWithRange:r] integerValue]*3600.0;
    r=[match rangeAtIndex:6]; if (r.location!=NSNotFound) *secsRef+=[[substr substringWithRange:r] integerValue]*60.0;
    r=[match rangeAtIndex:7]; if (r.location!=NSNotFound) *secsRef+=[[substr substringWithRange:r] doubleValue];
    NSLog(@"parseTimeSeparatedByColons 99, secs = %@",@(*secsRef));
    return EXIT_NORMAL;
}


int stringToAbsoluteDateOrRelativeOffset(NSString *str, NSString *label, NSDate **absoluteDateRef, NSTimeInterval *relativeOffsetRef) {
    BOOL hasNegative;
    if (absoluteDateRef == nil) {
        _print(stderr, @"%@: stringToAbsoluteDateOrRelativeOffset's absoluteDateRef is nil (which should not happen).\n", MYNAME);
        return EXIT_INVARG_ABSORREL;
    } else if (relativeOffsetRef == nil) {
        _print(stderr, @"%@: stringToAbsoluteDateOrRelativeOffset's relativeOffsetRef is nil (which should not happen).\n", MYNAME);
        return EXIT_INVARG_ABSORREL;
    } else if ((hasNegative=[str hasPrefix:MINUS_PREFIX]) || [str hasPrefix:PLUS_PREFIX]) {
        NSString *substr = [str substringFromIndex:hasNegative?[MINUS_PREFIX length]:[PLUS_PREFIX length]];
        double secs = 0;
        int res;
        // res = scanDoubleAlone(substr, &secs); // no longer need this as the RegExps below should work
        // NSLog(@"res = %@",@(res));
        // if (res != 1) { // don't care if there were 0 or >=2
            // try something other than seconds
            res = parseTimeSeparatedByDHMS(substr,&secs);
            if (res == EXIT_CLEAN)
                res = parseTimeSeparatedByColons(substr,&secs);
            if (res == EXIT_CLEAN) { // couldn't match either pattern
                _print(stderr, @"%@: %@bad relative offset seconds \"%@\".\n", MYNAME, label?[NSString stringWithFormat:@"for the %@ date, ",label]:@"", str);
                return EXIT_INVARG_BADPRIORITY;
            } else if (res != EXIT_NORMAL)
                return res;
        // }
        if (hasNegative)
            secs = - secs;
        NSLog(@"stringToAbsoluteDateOrRelativeOffset: secs = %@",@(secs));
        *relativeOffsetRef = (NSTimeInterval)secs;
        *absoluteDateRef = nil; // shouldn't be necessary but just in case
    } else {
        NSError *error = nil;
        NSDataDetector *detector = [NSDataDetector dataDetectorWithTypes:(NSTextCheckingTypes)NSTextCheckingTypeDate error:&error];
        if (detector == nil) {
            _print(stderr, @"%@: unable to (allocate a DataDetector to) parse a %@date from \"%@\": #%@ %@\n", MYNAME, label?[label stringByAppendingString:@" "]:@"", str, @(error.code), error.localizedDescription);
            return EXIT_INVARG_BADDATADETECTOR;
        }
        NSUInteger nMatches = [detector numberOfMatchesInString:str options:0 range:NSMakeRange(0, [str length])];
        NSTextCheckingResult *firstMatch =  [detector firstMatchInString:str options:0 range:NSMakeRange(0, [str length])];
        // NSLog(@"firstmatch: %@",firstMatch);
        // NSLog(@"range of match: [%@,%@)",@(firstMatch.range.location),@(firstMatch.range.length));

        if (nMatches == 0 || [firstMatch resultType]!=NSTextCheckingTypeDate) {
            _print(stderr, @"%@: unable to parse a %@date from \"%@\"\n", MYNAME, label?[label stringByAppendingString:@" "]:@"", str);
            return EXIT_INVARG_BADDATE;
        }

        NSString *leftovers = [str stringByReplacingCharactersInRange:firstMatch.range withString:@" "];
        if ([[leftovers stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] length] > 0) {
            _print(stderr, @"%@: %@found more than just a date in \"%@\"\n", MYNAME, label?[NSString stringWithFormat:@"for the %@ date, ",label]:@"", str);
            return EXIT_INVARG_BADDATE;
        }
        
        *absoluteDateRef = [firstMatch date];
        *relativeOffsetRef = 0;

        // components->date: NSDate *dueDate = [[NSCalendar currentCalendar] dateFromComponents:reminder.dueDateComponents];

        // currentCalendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
        // currentCalendar = [NSCalendar currentCalendar];
        // [[NSCalendar currentCalendar] components:(NSCalendarUnit)NSUIntegerMax fromDate:dueDate];

    }
    return EXIT_NORMAL;
}

/*!
    @function addReminder
    @abstract add a reminder
    @returns an exit status (0 for no error)
    @param reminder_title
        title of new reminder
    @description add a reminder to the default calendar
 */
static int addReminder(NSMutableArray<NSString*> *itemArgs)
{
    // parse command line arguments for dueDate, note, priority
    NSString *noteString;
    NSDate *alarmDate, *dueDate, *startDate;
    BOOL useAlarmOffset = NO;
    NSTimeInterval alarmOffset;
    NSUInteger priority = 0;
    BOOL normal_due = NO;
    // NSLog(@"addReminder: itemArgs=%@",[itemArgs componentsJoinedByString:@","]);
    while ([[itemArgs firstObject] hasPrefix:SWITCH_LONGDASH]) {
        NSString *swtch = [[itemArgs shift] substringFromIndex:[SWITCH_LONGDASH length]];
        if ([swtch isEqualToString:@"advanced"]) {
            useAdvanced = YES;
        } else if ([swtch isEqualToString:@"date"]//||[swtch isEqualToString:@"due"]
            || ([swtch isEqualToString:@"DUE"]&&useAdvanced)
            || ([swtch isEqualToString:@"ALARM"]&&useAdvanced)
            || ([swtch isEqualToString:@"START"]&&useAdvanced)
            ) {
            NSString *str = [itemArgs shift];
            // if ([swtch isEqualToString:@"due"]) swtch = @"date"; // "due" is a synonym for "date" in the non-advanced switches
            NSString *label = [swtch isEqualToString:@"date"] ? @"reminder" : swtch;
            NSDate *absoluteDate;  NSTimeInterval relativeOffset;
            int res = stringToAbsoluteDateOrRelativeOffset(str,label,&absoluteDate,&relativeOffset);
            if (res != EXIT_NORMAL)
                return EXIT_NORMAL;
            if ([swtch isEqualToString:@"date"]) {
                alarmDate = absoluteDate ? absoluteDate : [NSDate dateWithTimeIntervalSinceNow:relativeOffset];
                normal_due = YES;
            } else if ([swtch isEqualToString:@"DUE"]) {
                dueDate = absoluteDate ? absoluteDate : [NSDate dateWithTimeIntervalSinceNow:relativeOffset];
            } else if ([swtch isEqualToString:@"ALARM"]) {
                if (absoluteDate)
                    alarmDate = absoluteDate;
                else {
                    useAlarmOffset = YES;
                    alarmOffset = relativeOffset;
                }
            } else if ([swtch isEqualToString:@"START"]) {
                startDate = absoluteDate ? absoluteDate : [NSDate dateWithTimeIntervalSinceNow:relativeOffset];
            } else { // should not happen
                _print(stderr, @"%@: fatal error: unknown addReminder switch \"-%@\".\n", MYNAME,swtch);
                return EXIT_FATAL;
            }
        } else if ([swtch isEqualToString:@"note"]) {
            noteString = [itemArgs shift];
            // NSLog(@"set note to: %@", noteString);
        } else if ([swtch isEqualToString:@"priority"]) {
            NSString *priorityString = [itemArgs shift];
            if (0) {
                priority = [priorityString integerValue];
            } else {
                NSInteger priorityInteger;
                int res = scanIntegerAlone(priorityString, &priorityInteger);
                if (res==0 || priorityInteger<0) {
                    _print(stderr, @"%@: bad priority \"%@\" (should be an integer 0-9).\n", MYNAME, priorityString);
                    return EXIT_INVARG_BADPRIORITY;
                } else if (res > 1) {
                    _print(stderr, @"%@: bad priority \"%@\" (should only be an integer 0-9).\n", MYNAME, priorityString);
                    return EXIT_INVARG_BADPRIORITY;
                }
                priority = (NSUInteger) priorityInteger;
            }
            // NSLog(@"set priority to: %@", @(priority));
        } else {
            _print(stderr, @"%@: unknown \"add\" switch \"--%@\".\n", MYNAME, swtch);
            return EXIT_INVARG_BADSWITCH;
        }
    }
    
    // assume rest of arguments are the title of the new reminder
    NSString *reminderTitle = [[itemArgs subarrayWithRange:NSMakeRange(0, [itemArgs count])] componentsJoinedByString:@" "];
    [itemArgs removeAllObjects];
    
    // create the reminder
    reminder = [EKReminder reminderWithEventStore:store];
    reminder.calendar = [store defaultCalendarForNewReminders];
    reminder.title = reminderTitle;
    reminder.priority = priority;
    if (noteString) reminder.notes=noteString;
    if (alarmDate) {
        if (normal_due) {
            if (dueDate   == nil)   dueDate = alarmDate;
            if (startDate == nil) startDate = alarmDate;
        }
        // NSLog(@"loc 1");
        /* // this part isn't needed
        // if alarmDate is before now, add a second alarm that is snoozing for, say, 5 seconds from now
        if (0 && [alarmDate compare:[NSDate dateWithTimeIntervalSinceNow:1.5]] == NSOrderedDescending) { // if alarmDate is before now
            NSLog(@"loc 2");
            NSTimeInterval delayFromNow = 1.0;
            NSLog(@"loc 3");
            EKAlarm *snoozingAlarm = [EKAlarm alarmWithAbsoluteDate:[NSDate dateWithTimeIntervalSinceNow:delayFromNow]];
            // NSLog(@"can snooze = %@",@([snoozingAlarm respondsToSelector:@selector(isSnoozed)]));
            NSLog(@"loc 4, snoozingAlarm = %@",snoozingAlarm);
            if (! [snoozingAlarm respondsToSelector:@selector(isSnoozed)]) { // shouldn't be necessary but just in case
                NSLog(@"loc 5, snoozingAlarm = %@",snoozingAlarm);
                snoozingAlarm = (EKAlarm*)[EKSnoozableAlarm alarmWithAbsoluteDate:[NSDate dateWithTimeIntervalSinceNow:delayFromNow]];
                // NSLog(@"can snooze = %@",@([snoozingAlarm respondsToSelector:@selector(isSnoozed)]));
                NSLog(@"loc 6, snoozingAlarm = %@",snoozingAlarm);
            }
            NSLog(@"loc 10, snoozingAlarm = %@",snoozingAlarm);
            [snoozingAlarm setSnoozing:YES];
            NSLog(@"loc 11, snoozingAlarm = %@",snoozingAlarm);
            [reminder addAlarm:snoozingAlarm];
            NSLog(@"loc 12");
        }
        */
        [reminder addAlarm:[EKAlarm alarmWithAbsoluteDate:alarmDate]];
        // NSLog(@"loc 13, reminder = %@", reminder);
        // NSLog(@"loc 13, reminder.alarms.count = %@", @(reminder.alarms.count));
        // NSLog(@"loc 13, reminder.alarms[0] = %@", reminder.alarms[0]);
        // NSLog(@"loc 13, reminder.alarms[0].absoluteDate = %@", reminder.alarms[0].absoluteDate);
    } else if (useAlarmOffset) {
        if (normal_due) {
            alarmDate = [NSDate dateWithTimeIntervalSinceNow:alarmOffset];
            [reminder addAlarm:[EKAlarm alarmWithAbsoluteDate:alarmDate]];
            if (dueDate   == nil)   dueDate = alarmDate;
            if (startDate == nil) startDate = alarmDate;
        } else {
            [reminder addAlarm:[EKAlarm alarmWithRelativeOffset:alarmOffset]];
            if (dueDate == nil) {
                // offset is relative to dueDate so set the dueDate to now if not set
                dueDate = [NSDate date];
            }
        }
    }
    // NSLog(@"loc 14");
    if (dueDate) {
        reminder.dueDateComponents = [[NSCalendar currentCalendar] components:(NSCalendarUnit)NSUIntegerMax fromDate:dueDate];
        // note: also sets the start date
    }
    // NSLog(@"loc 15");
    if (startDate) {
        reminder.startDateComponents = [[NSCalendar currentCalendar] components:(NSCalendarUnit)NSUIntegerMax fromDate:startDate];
    }
    // NSLog(@"loc 16");
    
    // save the resulting reminder
    NSError *error;
    BOOL success = [store saveReminder:reminder commit:YES error:&error];
    // NSLog(@"loc 17");
    if (!success) {
        _print(stderr, @"%@: Error adding Reminder \"%@\": \t%@\n", MYNAME, reminder_id_str, [error localizedDescription]);
        return EXIT_FAIL_ADD;
    }
    return EXIT_NORMAL;
}



static BOOL continueWithReminder(NSString *label, EKReminder *reminder, NSUInteger reminder_id) {
    int c;
    int ans = -1;
    _print(stdout, @"%@ reminder \"%@\" (y/N)? ",label,reminder.title);
    while ((c=getchar()) && c!=10) {
        // _print(stdout, @"char = %d (%c)\n", c, c);
        if (c!=32 && c!=9 && ans<0) {
            ans = c==(int)'y' || c==(int)'Y';
            // _print(stdout, @"ans = %d\n", ans);
        }
    }
    if (ans < 0)
        ans = 0;
    return ans != 0;
}


/*!
    @function removeReminder
    @abstract remove a specified reminder
    @returns an exit status (0 for no error)
    @param reminder
        the reminder to be removed
    @description remove a specified reminder
 */
static int removeReminder(EKReminder *reminder, NSUInteger reminder_id)
{
    if (!isUppercaseCommand && !continueWithReminder(@"Remove",reminder,reminder_id)) {
        _print(stdout, @"not removed.\n");
        return EXIT_NORMAL;
    }
    NSString *title = reminder.title;
    NSError *error;
    BOOL success = [store removeReminder:reminder commit:YES error:&error];
    if (success) {
        _print(stdout, @"removed reminder \"%@\"\n", title);
    } else {
        _print(stderr, @"%@: Error removing Reminder #%@ \"%@\" from list %@\n\t%@", MYNAME, @(reminder_id), reminder.title, reminder.calendar.title, [error localizedDescription]);
        return EXIT_FAIL_RM;
    }
    return EXIT_NORMAL;
}

/*!
    @function completeReminder
    @abstract mark specified reminder as complete
    @returns an exit status (0 for no error)
    @param reminder
        the reminder to mark as completed
    @description mark specified reminder as complete
 */
static int completeReminder(EKReminder *reminder, NSUInteger reminder_id)
{
    if (!isUppercaseCommand && !continueWithReminder(@"Complete",reminder,reminder_id)) {
        _print(stdout, @"not completed.\n");
        return EXIT_NORMAL;
    }
    reminder.completed = YES;
    NSString *title = reminder.title;
    NSError *error;
    BOOL success = [store saveReminder:reminder commit:YES error:&error];
    if (success) {
        _print(stdout, @"completed reminder \"%@\"\n", title);
    } else {
        _print(stderr, @"%@: Error marking Reminder #%@ \"%@\" from list %@\n\t%@", MYNAME, @(reminder_id), reminder.title, reminder.calendar.title, [error localizedDescription]);
        return EXIT_FAIL_COMPLETE;
    }
    return EXIT_NORMAL;
}

/*!
    @function snoozeReminder
    @abstract delay the snooze on a not-completed reminder
    @returns an exit status (0 for no error)
    @param reminder
        the reminder to snooze
    @description change snooze on specified reminder to specific time
 */
static int snoozeReminder(EKReminder *reminder, NSUInteger reminder_id, NSString *snoozeSecondsString)
{
    if (reminder.completed) {
        _print(stderr, @"%@: Reminder #%@ \"%@\" from list %@ is already completed\n", MYNAME, @(reminder_id), reminder.title, reminder.calendar.title);
        return EXIT_SNOOZE_ALREADYCOMPLETED;
    }
    if (!reminder.hasAlarms || reminder.alarms==0 || reminder.alarms.count==0) {
        _print(stderr, @"%@: Reminder #%@ \"%@\" from list %@ is already completed\n", MYNAME, @(reminder_id), reminder.title, reminder.calendar.title);
        return EXIT_SNOOZE_NOALARMS;
    }
    NSUInteger nChanged = 0;
    NSMutableArray<EKAlarm*> *alarms = [reminder.alarms mutableCopy];
    NSTimeInterval secs = [snoozeSecondsString integerValue];
    // NSLog(@"secs = %@",@(secs));
    for (NSUInteger i=0; i<alarms.count; i++) {
        if ([alarms[i] snoozing]) {
            alarms[i] = [alarms[i] duplicateAlarmChangingTimeToNowPlusSecs:secs];
            nChanged++;
        }
    }
    if (nChanged > 0) {
        alarms = [alarms copy]; // make it immutable again
        reminder.alarms = alarms;
        NSError *error;
        BOOL success = [store saveReminder:reminder commit:YES error:&error];
        if (!success) {
            _print(stderr, @"%@: Error snoozing Reminder #%@ \"%@\" from list %@\n\t%@", MYNAME, @(reminder_id), reminder.title, reminder.calendar.title, [error localizedDescription]);
            return EXIT_FAIL_SNOOZE;
        }
    } else {
        _print(stderr, @"%@: Reminder #%@ \"%@\" from list %@ is not snoozing\n", MYNAME, @(reminder_id), reminder.title, reminder.calendar.title);
        return EXIT_SNOOZE_NOTSNOOZING;
    }
    return EXIT_NORMAL;
}

/*!
    @function handleCommand
    @abstract dispatch to correct function based on command-line argument
    @returns an exit status (0 for no error)
    @description dispatch to correct function based on command-line argument
 */
static int handleCommand(NSMutableArray *itemArgs)
{
    switch (command) {
        case CMD_LS:
        case CMD_EVERY:
            listReminders(calendarTitle, command==CMD_EVERY);
            return EXIT_NORMAL;
            break;
        case CMD_ADD:
            return addReminder(itemArgs);
            break;
        case CMD_HELP:
        case CMD_VERSION:
        case CMD_UNKNOWN:
            return EXIT_NORMAL;
            break;
        default:
            break;
    }
    while (1) {
        EKReminder *reminder = nil;
        NSUInteger reminder_id = 0;
        int exitStatus = nextReminderFromArgs(itemArgs, &reminder, &reminder_id);
        if (exitStatus!=EXIT_NORMAL || reminder==nil)
            return exitStatus;
        switch (command) {
            case CMD_RM:
                exitStatus = removeReminder(reminder, reminder_id);
                break;
            case CMD_CAT:
                showReminder(reminder,YES,YES,YES);
                break;
            case CMD_DONE:
                exitStatus = completeReminder(reminder, reminder_id);
                break;
            case CMD_SNOOZE:
                exitStatus = snoozeReminder(reminder, reminder_id, snoozeSecondsString);
                break;
            default:
                break;
        }
        if (exitStatus != EXIT_NORMAL)
            return exitStatus;
    }
    return EXIT_NORMAL;
}

int main(int argc, const char * argv[]) {
    int exitStatus = 0;

    @autoreleasepool {
        
        useAdvanced = [@"johnsone" isEqualToString:NSUserName()];
        
        NSMutableArray *itemArgs;
        exitStatus = parseArguments(&itemArgs);
        if (exitStatus)
            return exitStatus==EXIT_CLEAN ? 0 : exitStatus;
        
        // allocate the event store
        if ((store=[EKEventStore alloc]) == nil) {
            _print(stderr, @"%@: Unable to allocate the Reminders storage access.\n", MYNAME);
            return EXIT_FAIL_ALLOC;
        }
        
        // init with access to Reminders
        NSError *error;
        if ((store=[store initWithAccessToRemindersReturningError:&error]) == nil) {
            _print(stderr, @"%@: %@.\n", MYNAME,[error localizedDescription]);
            return (int) error.code;
        }

        if (command != CMD_ADD) {
            allReminders = fetchReminders();
            calendars = sortReminders(allReminders);
        }

        exitStatus = validateArguments();
        if (! exitStatus)
            exitStatus = handleCommand(itemArgs);
    }
    return exitStatus==EXIT_CLEAN ? 0 : exitStatus;
}

