//
//  main.m
//  rem
//
//  Originally created by Kevin Y. Kim on 10/15/12.
//  Copyright (c) 2012 kykim, inc. and modifications
//  Copyright (c) 2019-20 Erik A. Johnson
//  All rights reserved.
//

#import <Foundation/Foundation.h>
#import <EventKit/EventKit.h>
#import "EKAlarm+stringWith+MutableAlarm.h"
#import "EKEventStore+Synchronous.h"
#import "EKEventStore+Utilities.h"
#import "errors.h"
#import "main.h"
#import "NSObject+performSelectorSafely.h"
#import "EKReminder+Snoozing.h"
#import "NSMutableArray+Queue.h"
#import <CoreLocation/CoreLocation.h>
#import "NSString+regex.h"


/*
 TO DO:
    * add "undone" to change completed back to not completed
    * add "finished" to get completed reminders
    * add: allow additional argument for due date&time
    * done: save info on now-completed reminder so we can "undo" it and make it incomplete again
    * rm: save reminder info so we can unrm
 */



#define MYNAME @"rem"
#define SHOW_NEW_DETAILS 1
#define RM_ASK_BEFORE 1

NSString *VERSION_STRING = @"0.02eaj";
NSString *REMINDER_TITLE_PREFIX = @"--";
NSString *REMINDER_TITLE_REGEXPREF = @"/";
NSString *PLUS_PREFIX = @"+";
NSString *MINUS_PREFIX = @"-";
NSString *SWITCH_SHORTDASH = @"-";
NSString *SWITCH_LONGDASH  = @"--";
NSString *ITEM_NOTIFIED = @"notified";
NSString *ITEM_LASTCOMPLETED = @"lastcompleted";

#define COMMANDS @[ @"ls", @"add", @"rm", @"cat", @"done", @"every", @"ignored", @"snooze", @"help", @"version" ]
typedef enum _CommandType {
    CMD_UNKNOWN = -1,
    CMD_LS = 0,
    CMD_ADD,
    CMD_RM,
    CMD_CAT,
    CMD_DONE,
    CMD_EVERY, // list everything
    CMD_IGNORED, // list those with past alarms
    CMD_SNOOZE, // snooze a reminder
    CMD_HELP,
    CMD_VERSION
} CommandType;

static CommandType command;
BOOL isUppercaseCommand = NO;
static NSString *calendarTitle;
static BOOL fetchCompleted=NO, fetchIncompleted=YES;
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

NSString *localizedUnderlyingError(NSError *error) {
    NSString *extraMessage = nil;
    NSDictionary *userInfo = [error userInfo];
    NSError *underlyingError = [userInfo objectForKey:NSUnderlyingErrorKey];
    if (userInfo && underlyingError)
        extraMessage = underlyingError.localizedDescription;
    return extraMessage && extraMessage.length>0 ? [NSString stringWithFormat:@"%@ (%@)",error.localizedDescription,extraMessage] : error.localizedDescription;
}


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
void _print(FILE *file, NSString *format, ...)
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
    _print(stdout, @"%@ Version %@ build %@ %@\n", MYNAME, VERSION_STRING, @(__DATE__), @(__TIME__));
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
    _print(stdout, @"\t%@ [%@ [<list>]]\n\t\tList reminders (default is all lists)\n", MYNAME,COMMANDS[CMD_LS]);
    _print(stdout, @"\t%@ %@ <list> <item> [<item2> ...]\n\t\tRemove reminder(s) from list\n", MYNAME, COMMANDS[CMD_RM]);
    _print(stdout, @"\t%@ %@ [--date <date> | --date -<secondsBeforeNow> | --date +<secondsAfterNow>] ...\n\t%@     [(--arriving | --leaving) (<address> | <latitude,longitude>)] ...\n\t%@     [--note <note>] [--priority <integer0-9>] %@<remindertitle>\n\t\tAdd reminder to your default list\n", MYNAME, COMMANDS[CMD_ADD], SPACES, SPACES, useAdvanced?[NSString stringWithFormat:@" ... \n\t%@     [--advanced] ... \n\t%@     [--DUE   [   <dueDate> | -<secondsBeforeNow> | +<secondsAfterNow>]] ... \n\t%@     [--START [ <startDate> | -<secondsBeforeNow> | +<secondsAfterNow>]] ... \n\t%@     [--ALARM  [<remindDate> | -<secondsBeforeDueDate> | +<secondsAfterDueDate>]] ...\n\t%@     ", SPACES, SPACES, SPACES, SPACES, SPACES]:@"");
    _print(stdout, @"\t%@ %@ <list> <item1> [<item2> ...]\n\t\tShow reminder detail\n", MYNAME, COMMANDS[CMD_CAT]);
    _print(stdout, @"\t%@ %@ <list> <item1> [<item2> ...]\n\t\tMark reminder(s) as complete\n", MYNAME, COMMANDS[CMD_DONE]);
    _print(stdout, @"\t\t==> to mark default-list reminders complete: %@ <item1> [<item2> ...]\n",COMMANDS[CMD_DONE]);
    _print(stdout, @"\t%@ %@ [<list>]\n\t\tList reminders with details (default is all lists)\n", MYNAME, COMMANDS[CMD_EVERY]);
    _print(stdout, @"\t%@ %@ [<list>]\n\t\tList ignored reminders [that have alarms all in the past] (default is all lists)\n", MYNAME, COMMANDS[CMD_IGNORED]);
    _print(stdout, @"\t%@ %@ <list> <seconds> <item1> [<item2> ...]\n\t\tSnooze reminder until <seconds> from now\n", MYNAME, COMMANDS[CMD_SNOOZE]);
    _print(stdout, @"\t\t==> to snooze default-list reminders: %@ <seconds> <item1> [<item2> ...]\n",COMMANDS[CMD_SNOOZE]);
    _print(stdout, @"\t%@ %@\n\t\tShow this text\n", MYNAME, COMMANDS[CMD_HELP]);
    _print(stdout, @"\t%@ %@\n\t\tShow version information\n", MYNAME, COMMANDS[CMD_VERSION]);
    _print(stdout, @"\tNote: commands can be like \"%@\" or \"%@\" or \"%@\".\n", COMMANDS[CMD_LS], [SWITCH_LONGDASH stringByAppendingString:COMMANDS[CMD_LS]], [SWITCH_SHORTDASH stringByAppendingString:[COMMANDS[CMD_LS] substringToIndex:1]]);
    _print(stdout, @"\tNote: <item> is an integer,\n\t             or \"%@\" followed by a reminder title,\n\t             or \"%@%@\" followed by a title regular expression (no trailing \"/\").\n",REMINDER_TITLE_PREFIX,REMINDER_TITLE_PREFIX,REMINDER_TITLE_REGEXPREF);
    _print(stdout, @"\tNote: <list> may be an empty string \"\" or \"*\" to denote searching all lists\n\t      (invalid if reminder specified by integer index, valid with title/regex)\n");
}

int initializeStoreIfNotAlreadyInitialized() {
    if (store == nil) {
        NSError *error;
        // allocate the event store
        store = [EKEventStore alloc];
        if (store == nil) {
            _print(stderr, @"%@: Unable to allocate the Reminders storage access.\n", MYNAME);
            return EXIT_FAIL_ALLOC;
        } else if ((store=[store initWithAccessToRemindersReturningError:&error]) == nil) { // init with access to Reminders
            _print(stderr, @"%@: %@.\n", MYNAME,localizedUnderlyingError(error));
            return (error.code ? (int) error.code : EXIT_AUTH_UNKNOWNRESPONSE );
        }
    }
    return EXIT_NORMAL;
}

/*!
    @function parseArguments
    @abstract Command arguement parser
    @returns an exit status (0 for no error)
    @description Parse command-line arguments and populate appropriate variables
 */
static int parseArguments(NSMutableArray **itemArgsRef)
{
    NSMutableArray *args = *itemArgsRef = [NSMutableArray arrayWithArray:[[NSProcessInfo processInfo] arguments]];
    NSString *appPath = [args shift]; // pop off application argument
    
    // check for initial switches (none yet)

    NSString *app = [appPath lastPathComponent];
    if ([[app lowercaseString] isEqualToString:COMMANDS[CMD_SNOOZE]] || [[app lowercaseString] isEqualToString:COMMANDS[CMD_DONE]]) { // if called as "snooze" (or "done"), insert "snooze defaultCalendarName" as first arguments
        // assume the default calendar (if one is designated)
        if (args && args.count &&
            ([[args[0] lowercaseString] isEqualToString:COMMANDS[CMD_HELP]] // help
             ||
             [[args[0] lowercaseString] isEqualToString:[SWITCH_LONGDASH stringByAppendingString:COMMANDS[CMD_HELP]]] // --help
             ||
             [[args[0] lowercaseString] isEqualToString:[SWITCH_SHORTDASH stringByAppendingString:[COMMANDS[CMD_HELP] substringToIndex:1]]] // -h
             )) {
                    _usage();
                    return EXIT_CLEAN;
        }
        int res = initializeStoreIfNotAlreadyInitialized();
        if (res)
            return res;
        NSString *defaultCalendarName = [[store defaultCalendarForNewReminders] title];
        if (defaultCalendarName == nil) {
            _print(stderr, @"%@: when the app name is \"%@\", the default calendar is assumed, but there is no calendar has been designated as the default\n", MYNAME, app);
            return EXIT_INVARG_NODEFAULTCALENDAR;
        }
        [args unshift:defaultCalendarName];
        // put the command back
        [args unshift:app];
    }
    
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
    } else if (command == CMD_VERSION) {
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
{
    __block NSArray *reminders = nil;
    __block BOOL fetching = YES;
    NSArray<EKCalendar *> *theCalendars = [store reminderCalendarsWithTitle:calendarTitle];
    NSPredicate *predicate
        = (fetchCompleted && fetchIncompleted) ? [store predicateForRemindersInCalendars:theCalendars]
        : fetchCompleted ? [store predicateForCompletedRemindersWithCompletionDateStarting:nil ending:nil calendars:theCalendars]
        : fetchIncompleted ? [store predicateForIncompleteRemindersWithDueDateStarting:nil ending:nil calendars:theCalendars]
        : nil; // Note: could use predicateForRemindersInCalendars and fetch them all, but it is much faster to fetch only those needed
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
            // if ((r.completed && !fetchCompleted) || (!r.completed && !fetchIncompleted)) continue; // this line was needed when fetchReminders just fetched all reminders

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
    if ((command == CMD_LS || command == CMD_EVERY || command == CMD_IGNORED) && calendarTitle==nil) {
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

    if (command == CMD_LS || command == CMD_EVERY || command == CMD_IGNORED) // list all reminders in calendar
        return EXIT_NORMAL;
    
    if (command == CMD_SNOOZE && snoozeSecondsString == nil) {
        _print(stderr, @"%@: need # of seconds to %@\n", MYNAME, COMMANDS[CMD_SNOOZE]);
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
    NSString *reminder_id_str = [args shift];
    if ([[reminder_id_str lowercaseString] isEqualToString:ITEM_NOTIFIED]) {
        _print(stderr, @"%@: have not written \"%@ reminders\" code yet.\n", MYNAME, ITEM_NOTIFIED);
        return EXIT_FATAL;
    } else if ([[reminder_id_str lowercaseString] isEqualToString:ITEM_LASTCOMPLETED]) {
        _print(stderr, @"%@: have not written \"%@ reminders\" code yet.\n", MYNAME, ITEM_LASTCOMPLETED);
        return EXIT_FATAL;
    } else if ([reminder_id_str hasPrefix:REMINDER_TITLE_PREFIX]) {
        NSArray *reminders = calendarTitle ? [calendars objectForKey:calendarTitle] : allReminders;
        if (reminders.count < 1) {
            _print(stderr, @"%@: Error - there are no reminders\n", MYNAME, calendarTitle ? [NSString stringWithFormat:@" in Reminder List: %@",calendarTitle] : @"");
            return EXIT_INVARG_EMPTYCALENDAR;
        }
        // try to find the reminder by title
        // NOTE: neither "title" nor "isRegularExpression" need __block because they will not be modified after the predicate block is created nor in the predicate block
        NSString *title = [reminder_id_str substringFromIndex:[REMINDER_TITLE_PREFIX length]];
        BOOL isRegularExpression = [title hasPrefix:REMINDER_TITLE_REGEXPREF];
        if (isRegularExpression)
            title = [title substringFromIndex:[REMINDER_TITLE_REGEXPREF length]];
        NSPredicate *predicate;
        // predicate = [NSPredicate predicateWithFormat:@"title == %@",title];
        __block NSError *error; // needs __block because predicate block may modify it
        predicate = [NSPredicate predicateWithBlock:^BOOL(id object, NSDictionary *bindings) {
            EKReminder *reminder = (EKReminder*)object;
            NSError *blockError;
            BOOL titleMatches = isRegularExpression ? [reminder.title substringFirstMatchingRegexString:title options:0 returningCaptureGroups:nil leavingString:nil error:&blockError]!=nil : [reminder.title isEqualToString:title];
            if (isRegularExpression && blockError && !error) {
                error = [blockError copy];
                return NO;
            }
            if (! titleMatches) return NO;
            if (command != CMD_SNOOZE) return YES;
            if (reminder.isSnoozed) return YES;
            if (!reminder.hasAlarms) return NO;
            if ([reminder hasUnsnoozedPastAlarms]) return YES;
            return NO;
        }];
        NSArray *filteredReminders = [reminders filteredArrayUsingPredicate:predicate];
        if (error) { // got an error in the regex search
            _print(stderr, @"%@: error with regular expression \"%@\": #%@ %@\n", MYNAME, title, @(error.code), localizedUnderlyingError(error));
            return EXIT_INVARG_BADTITLEREGEX;
        } else if (filteredReminders == nil || filteredReminders.count == 0) {
            _print(stderr, @"%@: Error - there are no %@reminders %@ \"%@\"%@\n", MYNAME, command==CMD_SNOOZE ? @"snoozing " : @"", isRegularExpression?@"with title matching regular expression":@"titled", title, calendarTitle ? [NSString stringWithFormat:@" in List %@",calendarTitle] : @"");
            return EXIT_INVARG_BADTITLE;
        } else if (filteredReminders.count > 1) {
            _print(stderr, @"%@: Error - there are %@ reminders %@ \"%@\"%@ -- do not know which one to use:\n", MYNAME, @(filteredReminders.count), isRegularExpression?@"with title matching regular expression":@"titled", title, calendarTitle ? [NSString stringWithFormat:@" in List %@",calendarTitle] : @"");
            NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
            dateFormatter.dateStyle = NSDateFormatterShortStyle;
            dateFormatter.timeStyle = NSDateFormatterLongStyle;
            dateFormatter.locale = [NSLocale autoupdatingCurrentLocale]; // or [NSLocale currentLocale] or [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
            for (EKReminder *rem in filteredReminders) {
                NSDate *dueDate = [rem dueDateFromComponents];
                NSDate *alarmDate = rem.hasAlarms ? [[EKAlarm mostRecentAlarmFromArray:rem.alarms forReminder:rem] alarmDateForReminder:rem] : nil;
                if (alarmDate && dueDate && [alarmDate isEqualToDate:dueDate])
                    alarmDate = nil;
                NSString *dueDateString = dueDate ? [NSString stringWithFormat:@"due %@",[dateFormatter stringFromDate:dueDate]] : nil;
                NSString *alarmDateString = alarmDate ? [NSString stringWithFormat:@"alarm %@",[dateFormatter stringFromDate:alarmDate]] : nil;
                NSString *dateStr = (!alarmDate && !dueDate) ? @"" : !alarmDate ? [NSString stringWithFormat:@" (%@)",dueDateString] : !dueDate ? [NSString stringWithFormat:@" (%@)",alarmDateString] : [NSString stringWithFormat:@" (%@; %@)",dueDateString,alarmDateString];
                _print(stderr,@" * %@%@\n",rem.title,dateStr);
            }
            return EXIT_INVARG_BADTITLE;
        }
        *reminderRef = filteredReminders[0];
        NSDictionary *cals = calendarTitle ? @{calendarTitle:reminders} : calendars;
        for (NSString *calendarTitle in cals) { // previously had "for (calendarTitle in cals) {" -- using the global value -- because the global calendarTitle previously had to match reminder.calendar.title for at least one of the functions remove*, show*, complete*, or snooze* (I don't remember which ones) in handleReminders
            reminders = calendars[calendarTitle];
            *reminder_id_ref = [reminders indexOfObject:*reminderRef];
            if (*reminder_id_ref == NSNotFound)
                *reminder_id_ref = 0;
            else
                break;
        }
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
BOOL showReminderUndocumentedPropertiesWarning = YES;
static void showReminder(EKReminder *reminder, BOOL showTitle, BOOL lastReminder, BOOL lastCalendar) {
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
    
    _print(stdout, @"%@Created:  %@\n", indent, [dateFormatterShortDateLongTime stringFromDate:reminder.creationDate]);
    
    if (reminder.lastModifiedDate != reminder.creationDate) {
        _print(stdout, @"%@Modified: %@\n", indent, [dateFormatterShortDateLongTime stringFromDate:reminder.lastModifiedDate]);
    }
    
    NSString *startDateComponentsString = [reminder startDateComponentsStringUsingDateFormatter:dateFormatterShortDateLongTime];
    if (startDateComponentsString) {
        _print(stdout, @"%@Started:  %@\n", indent, startDateComponentsString);
    }
    
    NSString *dueDateComponentsString = [reminder dueDateComponentsStringUsingDateFormatter:dateFormatterShortDateLongTime];
    if (dueDateComponentsString) {
        _print(stdout, @"%@Due:      %@\n", indent, dueDateComponentsString);
    }
    
    if (SHOW_NEW_DETAILS) {
        if (reminder.completed) {
            NSString *completedDateStr = reminder.completionDate ? [dateFormatterShortDateLongTime stringFromDate:reminder.completionDate] : @"yes";
            _print(stdout, @"%@Completed: %@\n", indent, completedDateStr);
        }
        _print(stdout, @"%@Priority: %@\n", indent, @(reminder.priority));
        _print(stdout, @"%@Local ID: %@\n", indent, reminder.calendarItemIdentifier);
        if (reminder.hasRecurrenceRules && reminder.recurrenceRules) {
            #pragma clang diagnostic push
            #pragma clang diagnostic ignored "-Wundeclared-selector"
            if ([reminder respondsToSelector:@selector(humanReadableRecurrenceDescription)]) _print(stdout, @"%@Recurrence Description: %@\n", indent, [reminder performSelector:@selector(humanReadableRecurrenceDescription)]);
            #pragma clang diagnostic pop
            for (NSUInteger i=0; i<reminder.recurrenceRules.count; i++) {
                _print(stdout, @"%@Recurrence Rule %@: %@\n", indent, @(i+1), reminder.recurrenceRules[i].description); // NOTE: .description is decent though could make it more humanly readable
            }
        }
        if (reminder.hasAlarms && reminder.alarms) {
            for (NSUInteger i=0; i<reminder.alarms.count; i++) {
                _print(stdout, @"%@Alarm %@: %@\n", indent, @(i+1), [reminder.alarms[i] stringWithDateFormatter:dateFormatterShortDateLongTime forReminder:reminder]);
            }
        }
        if (SHOW_UNDOCUMENTED) { // undocumented properties
            if (showReminderUndocumentedPropertiesWarning) {
                NSLog(@"showing undocumented reminder properties");
                showReminderUndocumentedPropertiesWarning = NO;
            }
            #pragma clang diagnostic push
            #pragma clang diagnostic ignored "-Wundeclared-selector"
            if ([reminder respondsToSelector:@selector(_sharedUID)])
                _print(stdout, @"%@_sharedUID: %@\n", indent, [reminder performSelector:@selector(_sharedUID)]);
            // if ([[reminder class] respondsToSelector:@selector(actionStringsDisplayName)]) _print(stdout, @"%@actionStringsDisplayName: %@\n", indent, [[reminder class] performSelector:@selector(actionStringsDisplayName)]); // @"Reminder"
            // if ([[reminder class] respondsToSelector:@selector(actionStringsPluralDisplayName)]) _print(stdout, @"%@actionStringsPluralDisplayName: %@\n", indent, [[reminder class] performSelector:@selector(actionStringsPluralDisplayName)]); // @"Reminders"
            // if ([reminder respondsToSelector:@selector(actionStringsDisplayTitle)]) _print(stdout, @"%@actionStringsDisplayTitle: %@\n", indent, [reminder performSelector:@selector(actionStringsDisplayTitle)]); // seems to be the same as reminder.title
            // _print(stdout, @"%@isFrozen: %@\n", indent, ![reminder respondsToSelector:@selector(isFrozen)] ? @"<unimplemented>" : [reminder errorMessageWhenBOOLFromPerformingSelector:@selector(isFrozen)] ? [reminder errorMessageWhenBOOLFromPerformingSelector:@selector(isFrozen)] : @([reminder BOOLFromPerformingSelector:@selector(isFrozen)])); // NO
            // _print(stdout, @"%@meltedClass: %@\n", indent, ![[reminder class] respondsToSelector:@selector(meltedClass)] ? @"<unimplemented>" : [[reminder class] returnErrorMessageOrPerformSelector:@selector(meltedClass)]); //
            // _print(stdout, @"%@frozenClass: %@\n", indent, ![[reminder class] respondsToSelector:@selector(frozenClass)] ? @"<unimplemented>" : [[reminder class] returnErrorMessageOrPerformSelector:@selector(frozenClass)]); //
            #pragma clang diagnostic pop
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
static void _listCalendar(NSString *calendarTitle, BOOL last, BOOL withDetails, BOOL onlyIgnoredAlarms)
{
    _printCalendarLine(calendarTitle, last);
    NSArray *reminders = [calendars valueForKey:calendarTitle];
    BOOL isIgnoredAlarms[reminders.count];
    NSUInteger lastIgnored = reminders.count;
    if (onlyIgnoredAlarms) {
        for (NSUInteger i = 0; i < reminders.count; i++) {
            EKReminder *r = [reminders objectAtIndex:i];
            isIgnoredAlarms[i] = r.hasAlarms && r.alarms && [r allAlarmsInPast];
            if (isIgnoredAlarms[i])
                lastIgnored = i;
        }
    }
    // NSMutableArray *a = NSArray
    for (NSUInteger i = 0; i < reminders.count; i++) {
        EKReminder *r = [reminders objectAtIndex:i];
        if (!onlyIgnoredAlarms || isIgnoredAlarms[i]) {
            BOOL isLastReminder = onlyIgnoredAlarms ? (i == lastIgnored) : (r == [reminders lastObject]);
            _printReminderLine(i+1, r.title, isLastReminder, last);
            if (withDetails) {
                showReminder(r, NO,isLastReminder,last);
            }
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
static void listReminders(NSString *calendarTitle, BOOL withDetails, BOOL onlyIgnoredAlarms)
{
    _print(stdout, @"Reminders%@\n", onlyIgnoredAlarms ? @" (ignored alarmed only)" : @"");
    if (calendarTitle) {
        _listCalendar(calendarTitle, YES, withDetails, onlyIgnoredAlarms);
    } else {
        for (calendarTitle in calendars) {
            _listCalendar(calendarTitle, (calendarTitle == [[calendars allKeys] lastObject]), withDetails, onlyIgnoredAlarms);
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
    if (DEBUG>1) NSLog(@"parseTimeSeparatedByDHMS: substr=%@",substr);
    NSDictionary<NSNumber*,NSString*> *groups;
    @try { groups = [substr substringsFirstMatchingRegexStringI:@"^\\s*(?:(\\d+(?:\\.\\d*)?)\\s*d)?\\s*(?:(\\d+(?:\\.\\d*)?)\\s*h)?\\s*(?:(\\d+(?:\\.\\d*)?)\\s*m)?\\s*(?:(\\d+(?:\\.\\d*)?)\\s*s?)?\\s*$"]; } @catch (NSException *exception) {
        _print(stderr, @"%@: illegal DHMS regular expression (this should not happen): %@%@\n", MYNAME, exception.reason,exception.userInfo?[NSString stringWithFormat:@" (userInfo=%@)",exception.userInfo]:@"");
        return EXIT_FATAL;
    }
    if (!groups) return EXIT_CLEAN; // did not match
    *secsRef = [[groups objectForKey:@1] doubleValue]*86400.0
             + [[groups objectForKey:@2] doubleValue]*3600.0
             + [[groups objectForKey:@3] doubleValue]*60.0
             + [[groups objectForKey:@4] doubleValue]; // NOTE: nil's -> 0.0
    if (DEBUG>1) NSLog(@"secs=%@",@(*secsRef));
    return EXIT_NORMAL;
}
int parseTimeSeparatedByColons(NSString *substr, double *secsRef) {
    NSDictionary<NSNumber*,NSString*> *groups;
    @try { groups = [substr substringsFirstMatchingRegexStringI:@"^\\s*(?:(?:(?:(\\d+)\\s*:)?\\s*(\\d+)\\s*:)?\\s*(\\d+)\\s*:)?\\s*(\\d+(?:\\.\\d*)?)$"]; } @catch (NSException *exception) {
       _print(stderr, @"%@: illegal D:H:M:S regular expression (this should not happen): %@%@\n", MYNAME, exception.reason,exception.userInfo?[NSString stringWithFormat:@" (userInfo=%@)",exception.userInfo]:@"");
       return EXIT_FATAL;
   }
    if (!groups) return EXIT_CLEAN; // did not match
    *secsRef = [[groups objectForKey:@1] doubleValue]*86400.0
             + [[groups objectForKey:@2] doubleValue]*3600.0
             + [[groups objectForKey:@3] doubleValue]*60.0
             + [[groups objectForKey:@4] doubleValue]; // NOTE: nil's -> 0.0
    if (DEBUG>1) NSLog(@"secs=%@",@(*secsRef));
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
                return EXIT_INVARG_BADDURATION;
            } else if (res != EXIT_NORMAL)
                return res;
        // }
        if (hasNegative)
            secs = - secs;
        // NSLog(@"stringToAbsoluteDateOrRelativeOffset: secs = %@",@(secs));
        *relativeOffsetRef = (NSTimeInterval)secs;
        *absoluteDateRef = nil; // shouldn't be necessary but just in case
    } else {
        NSError *error = nil;
        NSDataDetector *detector = [NSDataDetector dataDetectorWithTypes:(NSTextCheckingTypes)NSTextCheckingTypeDate error:&error];
        if (detector == nil) {
            _print(stderr, @"%@: unable to (allocate a DataDetector to) parse a %@date from \"%@\": #%@ %@\n", MYNAME, label?[label stringByAppendingString:@" "]:@"", str, @(error.code), localizedUnderlyingError(error));
            return EXIT_INVARG_BADDATADETECTOR;
        }
        NSUInteger nMatches = [detector numberOfMatchesInString:str options:0 range:NSMakeRange(0, [str length])];
        NSTextCheckingResult *firstMatch =  [detector firstMatchInString:str options:0 range:NSMakeRange(0, [str length])];
        // NSLog(@"firstmatch: %@",firstMatch);
        // NSLog(@"range of match: [%@,%@)",@(firstMatch.range.location),@(firstMatch.range.length));

        if (nMatches == 0 || !firstMatch || [firstMatch resultType]!=NSTextCheckingTypeDate) {
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


int radiusFromLocationString(double *radiusRef, NSString **locationStringRef) {
    NSDictionary<NSNumber*,NSString*> *groups;
    NSString *remainder;
    @try { groups = [*locationStringRef substringsFirstMatchingRegexStringI:@"\\s*(\\d+(?:\\.\\d*)?|\\.\\d+)\\s*(m|meter|meters|ft|feet|'|mi|miles|)\\s*(?:of|from|within|away\\s*from)?\\s*" leavingString:&remainder]; } @catch (NSException *exception) {
        _print(stderr, @"%@: illegal radius regular expression (this should not happen): %@%@\n", MYNAME, exception.reason,exception.userInfo?[NSString stringWithFormat:@" (userInfo=%@)",exception.userInfo]:@"");
        return EXIT_INVARG_BADLOCATION;
    }
    if (!groups) return EXIT_CLEAN; // did not match
    *radiusRef = [[groups objectForKey:@1] doubleValue]; // meters
    // find units
    NSString *units = [groups objectForKey:@2];
    if ([units isEqualToString:@"ft"] || [units isEqualToString:@"feet"] || [units isEqualToString:@"'"]) {
        *radiusRef *= 12.0*0.0254;
    } else if ([units isEqualToString:@"miles"] || [units isEqualToString:@"mi"]) {
        *radiusRef *= 5280.0 * 12.0*0.0254;
    } else if (![units isEqualToString:@"m"] && ![units isEqualToString:@"meters"]) {
        _print(stderr, @"%@: unknown radius units (%@)\n", MYNAME, units);
        return EXIT_INVARG_BADLOCATION;
    }
    *locationStringRef = remainder;
    if (DEBUG>1) NSLog(@"radius=%@",@(*radiusRef));
    return EXIT_NORMAL;
}
int latLongFromLocationString(double *latitudeRef, double *longitudeRef, NSString *locationString, NSString **locationTitleStringRef) {
    NSDictionary<NSNumber*,NSString*> *groups;
    NSString *remainder;
    @try { groups = [locationString substringsFirstMatchingRegexStringI:@"\\s*([+-]?\\d+(?:\\.\\d*)?|[+-]?\\.\\d+)\\s*(?:º|deg|degrees)?\\s*,\\s*([+-]?\\d+(?:\\.\\d*)?|[+-]?\\.\\d+)\\s*(?:º|deg|degrees)?\\s*" leavingString:&remainder]; } @catch (NSException *exception) {
        _print(stderr, @"%@: illegal latitude/longitude regular expression (this should not happen): %@%@\n", MYNAME, exception.reason,exception.userInfo?[NSString stringWithFormat:@" (userInfo=%@)",exception.userInfo]:@"");
        return EXIT_INVARG_BADLOCATION;
    }
    // do I want to try deg/mins/secs.xxxxx ???
    if (!groups) return EXIT_CLEAN; // did not match
    if (*latitudeRef)  *latitudeRef  = [[groups objectForKey:@1] doubleValue];
    if (*longitudeRef) *longitudeRef = [[groups objectForKey:@2] doubleValue];
    *locationTitleStringRef = [NSString stringWithString:locationString];
    remainder = [remainder stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (remainder.length)
        *locationTitleStringRef = remainder;
    return EXIT_NORMAL;
}

NSString *addressStringFromString(NSString *str) {
    NSError *error;
    NSDataDetector *detector = [NSDataDetector dataDetectorWithTypes:(NSTextCheckingTypes)NSTextCheckingTypeAddress error:&error];
    if (detector == nil) {
        _print(stderr, @"%@: unable to (allocate a DataDetector to) parse an address from \"%@\": #%@ %@\n", MYNAME, str, error ? @(error.code) : @"?", error ? localizedUnderlyingError(error) : @"unknown reason");
        return nil;
    }
    NSUInteger nMatches = [detector numberOfMatchesInString:str options:0 range:NSMakeRange(0, [str length])];
    NSTextCheckingResult *firstMatch =  [detector firstMatchInString:str options:0 range:NSMakeRange(0, [str length])];
    if (nMatches == 0 || !firstMatch || [firstMatch resultType]!=NSTextCheckingTypeAddress) {
        _print(stderr, @"%@: unable to parse a an address from \"%@\"\n", MYNAME, str);
        return nil;
    }
    return [str substringWithRange:firstMatch.range];
}

CLLocation *getCoordinate( NSString *addressString,
        NSError ** _Nonnull errorRef ) {
    CLGeocoder *geocoder = [[CLGeocoder alloc] init];
    __block BOOL completed = NO;
    __block NSError * _Nullable theError = nil;
    __block CLLocation * _Nullable ans = nil;
    [geocoder geocodeAddressString:addressString inRegion:nil completionHandler:^(NSArray<CLPlacemark*> *placemarks, NSError *error) {
            if (error)
                theError = error;
            else if (placemarks && placemarks.count==1)
                ans = placemarks[0].location;
            else if (placemarks && placemarks.count>1) {
                NSString *listOfPlaces = @"<unimplemented>"; // TO DO
                _print(stderr, @"%@: found multiple matching addresses in \"%@\":%@\n", MYNAME, addressString, listOfPlaces);
            } else {
                _print(stderr, @"%@: found no matching addresses in \"%@\"\n", MYNAME, addressString);
            }
        completed = YES;
        }];
    NSTimeInterval timeout = 30.0;
    for (int i=0; !completed; i++) {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
        if (timeout/0.1 <= i) {
            [geocoder cancelGeocode];
            break;
        }
    }
    *errorRef = completed ? theError : [NSError errorWithDomain:MY_ERROR_DOMAIN code:EXIT_GEOCODE_TIMEDOUT userInfo:@{
        NSLocalizedDescriptionKey: NSLocalizedString(@"Timed out waiting for geocode translating an address string to latitude/longitude.", nil),
        NSLocalizedFailureReasonErrorKey: NSLocalizedString(@"Timed out", nil),
        NSLocalizedRecoverySuggestionErrorKey: NSLocalizedString(@"unknown how to solve this", nil)
    }];
    return ans;
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
    NSString *noteString, *locationString;
    EKAlarmProximity locationProximity;
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
            NSDate *absoluteDate;
            NSTimeInterval relativeOffset;
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
        } else if ([swtch isEqualToString:@"arriving"]) {
            locationProximity = EKAlarmProximityEnter;
            locationString = [itemArgs shift];
        } else if ([swtch isEqualToString:@"leaving"] || [swtch isEqualToString:@"departing"]) {
            locationProximity = EKAlarmProximityLeave;
            locationString = [itemArgs shift];
        } else if ([swtch isEqualToString:@"note"]) {
            noteString = [itemArgs shift];
            // NSLog(@"set note to: %@", noteString);
        } else if ([swtch isEqualToString:@"priority"]) {
            NSString *priorityString = [itemArgs shift];
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
        } else {
            _print(stderr, @"%@: unknown \"%@\" switch \"--%@\".\n", MYNAME, COMMANDS[CMD_ADD], swtch);
            return EXIT_INVARG_BADSWITCH;
        }
    }
    
    // assume rest of arguments are the title of the new reminder
    NSString *reminderTitle = [[itemArgs subarrayWithRange:NSMakeRange(0, [itemArgs count])] componentsJoinedByString:@" "];
    [itemArgs removeAllObjects];
    if (!reminderTitle || !reminderTitle.length) {
        _print(stderr, @"%@: cannot \"%@\" with an empty title\n", MYNAME, COMMANDS[CMD_ADD]);
        return EXIT_INVARG_BADTITLE;
    }
    
    // create the reminder
    reminder = [EKReminder reminderWithEventStore:store];
    reminder.calendar = [store defaultCalendarForNewReminders];
    if (reminder.calendar == nil) {
        NSArray<EKCalendar *> *allCalendars = [store calendarsForEntityType:EKEntityTypeReminder];
        if (allCalendars && allCalendars.count) {
            reminder.calendar = allCalendars[0];
            _print(stderr, @"%@: warning: \"%@\" is using the first calendar (%@) since there is no default calendar\n", MYNAME, COMMANDS[CMD_ADD], reminder.calendar.title);
        } else {
            _print(stderr, @"%@: cannot \"%@\" when there is no default calendar\n", MYNAME, COMMANDS[CMD_ADD]);
            return EXIT_INVARG_NODEFAULTCALENDAR;
        }
    }
    reminder.title = reminderTitle;
    reminder.priority = priority;
    if (noteString) reminder.notes=noteString;
    
    // alarms
    EKAlarm *alarm = nil;
    if (alarmDate==nil && useAlarmOffset && normal_due) {
        alarmDate = [NSDate dateWithTimeIntervalSinceNow:alarmOffset];
        useAlarmOffset = NO;
    }
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
                snoozingAlarm = (EKAlarm*)[EKMutableAlarm alarmWithAbsoluteDate:[NSDate dateWithTimeIntervalSinceNow:delayFromNow]];
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
        alarm = [EKAlarm alarmWithAbsoluteDate:alarmDate];
        // NSLog(@"loc 13, reminder = %@", reminder);
        // NSLog(@"loc 13, reminder.alarms.count = %@", @(reminder.alarms.count));
        // NSLog(@"loc 13, reminder.alarms[0] = %@", reminder.alarms[0]);
        // NSLog(@"loc 13, reminder.alarms[0].absoluteDate = %@", reminder.alarms[0].absoluteDate);
    } else if (useAlarmOffset) {
        // if (normal_due) {not needed because handled above} else {
        alarm = [EKAlarm alarmWithRelativeOffset:alarmOffset];
        if (dueDate == nil) {
            // offset is relative to dueDate so set the dueDate to now if not set
            dueDate = [NSDate date];
        }
        // } // if (normal_due)
    }
    if (locationString) {
        int res;
        double radius = 200.0; // default
        res = radiusFromLocationString(&radius,&locationString);
        if (res) return res;
        // NSLog(@"location string after extracting radius = \"%@\"",locationString);
        EKStructuredLocation *loc;
        double latitude, longitude;
        NSString *locationTitleString;
        res = latLongFromLocationString(&latitude,&longitude,locationString,&locationTitleString);
        if (res == EXIT_NORMAL) { // found lat/long
            CLLocation *latLong = [[CLLocation alloc] initWithLatitude:latitude longitude:longitude];
            loc = [EKStructuredLocation locationWithTitle:locationTitleString?locationTitleString:locationString];
            loc.geoLocation = latLong;
            loc.radius = radius;
        } else if (res == EXIT_CLEAN) { // did not find lat/long so look for address
            NSString *addressString = addressStringFromString(locationString);
            if (addressString) {
                NSError *error;
                CLLocation *latLong = getCoordinate( addressString, &error);
                if (latLong && !error) {
                    loc = [EKStructuredLocation locationWithTitle:addressString];
                    loc.geoLocation = latLong;
                    loc.radius = radius;
                } else {
                    _print(stderr, @"%@: unable to convert address \"%@\" to latitude/longitude: #%@ %@\n", MYNAME, addressString, error ? @(error.code) : @"?", error ? localizedUnderlyingError(error) : @"unknown reason");
                    return EXIT_INVARG_BADLOCATION;
                }
            } else {
                // already printed error in addressStringFromString()
            }
        } else // some error code
            return res;
        if (loc) {
            if (alarm == nil) {
                alarm = [[EKAlarm alloc] init];
                alarm.proximity = locationProximity;
                alarm.soundName = @"Basso"; alarm.soundName = nil; // do not know why this is necessary but adding the reminder without it gives "action is required" error
            }
            alarm.structuredLocation = loc;
        }
        // NSLog(@"alarm = %@",alarm);
    }
    if (alarm)
        [reminder addAlarm:alarm];
    
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
        _print(stderr, @"%@: Error adding Reminder \"%@\": \t%@\n", MYNAME, reminderTitle, localizedUnderlyingError(error));
        NSLog(@"error = %@",error);
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
        _print(stderr, @"%@: Error removing Reminder #%@ \"%@\" from list %@\n\t%@", MYNAME, @(reminder_id), reminder.title, reminder.calendar.title, localizedUnderlyingError(error));
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
        _print(stderr, @"%@: Error marking as completed the Reminder #%@ \"%@\" from list %@\n\t%@", MYNAME, @(reminder_id), reminder.title, reminder.calendar.title, localizedUnderlyingError(error));
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
    if (!reminder.hasAlarms || reminder.alarms==nil || reminder.alarms.count==0) {
        _print(stderr, @"%@: Reminder #%@ \"%@\" from list % has no alarms\n", MYNAME, @(reminder_id), reminder.title, reminder.calendar.title);
        return EXIT_SNOOZE_NOALARMS;
    }
    
    // get the number of seconds
    double secsDouble = 0;
    int res = parseTimeSeparatedByDHMS(snoozeSecondsString,&secsDouble);
    if (res == EXIT_CLEAN)
        res = parseTimeSeparatedByColons(snoozeSecondsString,&secsDouble);
    if (res == EXIT_CLEAN) { // couldn't match either pattern
        _print(stderr, @"%@: bad %@ duration \"%@\".\n", MYNAME, COMMANDS[CMD_SNOOZE], snoozeSecondsString);
        return EXIT_INVARG_BADSNOOZE;
    } else if (res != EXIT_NORMAL)
        return res; // error message will already have been printed
    NSTimeInterval secs = secsDouble; // [snoozeSecondsString integerValue];

    NSArray<EKAlarm*> *extraneousAlarmsButWillNotDelete;
    EKAlarm *alarmToSnooze;
    if ((extraneousAlarmsButWillNotDelete=[reminder snoozedPastAlarms]) && extraneousAlarmsButWillNotDelete.count) {
        // snooze the most recent of these alarms (do not delete the others)
        alarmToSnooze = [EKAlarm mostRecentAlarmFromArray:extraneousAlarmsButWillNotDelete forReminder:reminder];
    }
    if (!alarmToSnooze && (extraneousAlarmsButWillNotDelete=[reminder unsnoozedPastAlarms]) && extraneousAlarmsButWillNotDelete.count) {
        // snooze the most recent of these
        // NOTE: we get here if a reminder has never been snoozed in Notification Center: the only alarm has isSnoozed=0 but has fired
        // NOTE: I tried creating a new alarm with isSnoozed=1 and a later date and adding it to the alarm -- which is what Notification Center does -- but it always ended up _replacing_ the original isSnoozed=0 alarm
        alarmToSnooze = [EKAlarm mostRecentAlarmFromArray:extraneousAlarmsButWillNotDelete forReminder:reminder];
    }
    if (!alarmToSnooze) {
        _print(stderr, @"%@: Reminder #%@ \"%@\" from list %@ is not snoozing\n", MYNAME, @(reminder_id), reminder.title, reminder.calendar.title);
        return EXIT_SNOOZE_NOTSNOOZING;
    }
    extraneousAlarmsButWillNotDelete = [alarmToSnooze arrayByRemovingFromArray:extraneousAlarmsButWillNotDelete];
    EKAlarm *newAlarm = [alarmToSnooze duplicateAlarmChangingTimeToNowPlusSecs:secs];
    [reminder removeAlarm:alarmToSnooze];
    [reminder addAlarm:newAlarm];
    /* could delete extraneous alarms with:
        for (EKAlarm *alarm in extraneousAlarmsButWillNotDelete) [reminder removeAlarm:alarm];
       but (a) it doesn't seem that we normally end up with any such alarms
       and (b) such past alarms may also have a location attached, trigger other things (email, URL, etc.) so shouldn't delete them
     */
    
    // save it
    NSError *error;
    BOOL success = [store saveReminder:reminder commit:YES error:&error];
    if (!success) {
        _print(stderr, @"%@: Error snoozing Reminder #%@ \"%@\" from list %@\n\t%@", MYNAME, @(reminder_id), reminder.title, reminder.calendar.title, localizedUnderlyingError(error));
        return EXIT_FAIL_SNOOZE;
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
        case CMD_IGNORED:
            listReminders(calendarTitle, command==CMD_EVERY, command==CMD_IGNORED);
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
        // NSString *prevCalendarTitle = calendarTitle; // used previously because calendarTitle previously had to match reminder.calendar.title for some of the functions in this loop
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
        // calendarTitle = prevCalendarTitle; // used previously because calendarTitle previously had to match reminder.calendar.title for some of the functions in this loop
    }
    return EXIT_NORMAL;
}

int main(int argc, const char * argv[]) {
    int exitStatus = 0;

    @autoreleasepool {
        [NSString setErrorDomainNSStringRegex:MY_ERROR_DOMAIN];

        useAdvanced = [@"johnsone" isEqualToString:NSUserName()];
        
        NSMutableArray *itemArgs;
        exitStatus = parseArguments(&itemArgs);
        if (exitStatus)
            return exitStatus==EXIT_CLEAN ? 0 : exitStatus;
        
        // allocate the event store
        exitStatus = initializeStoreIfNotAlreadyInitialized();
        if (! exitStatus) {
            if (command != CMD_ADD) {
                allReminders = fetchReminders();
                calendars = sortReminders(allReminders);
            }
            exitStatus = validateArguments();
        }
        if (! exitStatus)
            exitStatus = handleCommand(itemArgs);
    }
    return exitStatus==EXIT_CLEAN ? 0 : exitStatus;
}

