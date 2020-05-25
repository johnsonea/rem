//
//  main.h
//  rem
//
//  Created by Erik A Johnson on 11/24/19.
//  Copyright © 2019 Erik A Johnson. All rights reserved.
//

#ifndef main_h
#define main_h

#define SHOW_UNDOCUMENTED 1

#ifndef DEBUG
#define DEBUG 0
#endif

void _print(FILE *file, NSString *format, ...);

#define NSLog(format, ...) NSLog([@"%s (%@:%d) " stringByAppendingString:format],__FUNCTION__,[[NSString stringWithUTF8String:__FILE__] lastPathComponent],__LINE__, ## __VA_ARGS__)
#define N NSLog([@"%s (%@:%d) " stringByAppendingString:format],__FUNCTION__,[[NSString stringWithUTF8String:__FILE__] lastPathComponent],__LINE__, ## __VA_ARGS__);
// #define debug3(format, ...) fprintf (stderr, format, ## __VA_ARGS__)

int snoozeSecondsStringToTimeInterval(NSString *snoozeSecondsString);

#endif /* main_h */
