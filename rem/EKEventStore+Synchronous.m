//
//  EKEventStore+Synchronous.m
//  rem
//
//  Created by Erik A Johnson on 10/29/19.
//  Copyright © 2019 Erik A Johnson. All rights reserved.
//

#import "EKEventStore+Synchronous.h"
#import "errors.h"

#define REMINDERS_AUTHORIZATION_MAX_WAIT 30.0 // seconds
#define REMINDERS_AUTHORIZATION_INTERVAL 0.01 // seconds

@implementation EKEventStore (Synchronous)

NSDictionary *errorUserInfo = nil;
NSDictionary *errorUserInfoForStatus(ExitStatus status) {
    if (errorUserInfo == nil)
        errorUserInfo =  @{
            @(EXIT_ACCESS_DENIED): @{
                NSLocalizedDescriptionKey: NSLocalizedString(@"Access to reminders is denied", nil),
                NSLocalizedFailureReasonErrorKey: NSLocalizedString(@"Access to reminders is denied", nil),
                NSLocalizedRecoverySuggestionErrorKey: NSLocalizedString(@"Try adding this executable to the System Preferences -> Security & Privacy -> Privacy -> Reminders list", nil)
            },
            @(EXIT_ACCESS_RESTRICTED): @{
                NSLocalizedDescriptionKey: NSLocalizedString(@"Access to reminders is restricted", nil),
                NSLocalizedFailureReasonErrorKey: NSLocalizedString(@"Access to reminders is restricted", nil),
                NSLocalizedRecoverySuggestionErrorKey: NSLocalizedString(@"Try adding this executable to the System Preferences -> Security & Privacy -> Privacy -> Reminders list", nil)
            },
            @(EXIT_AUTH_UNKNOWNRESPONSE): @{
                NSLocalizedDescriptionKey: NSLocalizedString(@"Unexpected return value from EKEventStore's authorizationStatusForEntityType:EKEntityTypeReminder", nil),
                NSLocalizedFailureReasonErrorKey: NSLocalizedString(@"Unexpected return value from EKEventStore's authorizationStatusForEntityType:EKEntityTypeReminder", nil),
                NSLocalizedRecoverySuggestionErrorKey: NSLocalizedString(@"Try adding this executable to the System Preferences -> Security & Privacy -> Privacy -> Reminders list", nil)
            },
            @(EXIT_FAIL_NOINIT): @{
                NSLocalizedDescriptionKey: NSLocalizedString(@"Unable to initialize the Reminders storage", nil),
                NSLocalizedFailureReasonErrorKey: NSLocalizedString(@"Unable to initialize the Reminders storage", nil),
                NSLocalizedRecoverySuggestionErrorKey: NSLocalizedString(@"Try adding this executable to the System Preferences -> Security & Privacy -> Privacy -> Reminders list", nil)
            },
            @(EXIT_ACCESS_NOTGRANTED): @{
                NSLocalizedDescriptionKey: NSLocalizedString(@"Reminder access was not granted", nil),
                NSLocalizedFailureReasonErrorKey: NSLocalizedString(@"Reminder access was not granted", nil),
                NSLocalizedRecoverySuggestionErrorKey: NSLocalizedString(@"Try adding this executable to the System Preferences -> Security & Privacy -> Privacy -> Reminders list.", nil)
                },
            @(EXIT_ACCESS_TIMEDOUT): @{
                NSLocalizedDescriptionKey: NSLocalizedString(@"Timed out waiting for access to Reminders", nil),
                NSLocalizedFailureReasonErrorKey: NSLocalizedString(@"Timed out waiting for access to Reminders", nil),
                NSLocalizedRecoverySuggestionErrorKey: NSLocalizedString(@"Try adding this executable to the System Preferences -> Security & Privacy -> Privacy -> Reminders list.", nil)
                },
        };
    return errorUserInfo[@(status)];
}
NSDictionary *errorUserInfoForStatusAppendingStringToDescriptionAndReason(ExitStatus status, NSString *appendingString) {
    NSDictionary *baseUserInfo = errorUserInfoForStatus(status);
    NSMutableDictionary *userInfo = [[NSMutableDictionary alloc] init];
    [userInfo addEntriesFromDictionary:baseUserInfo];
    userInfo[NSLocalizedFailureReasonErrorKey] = [NSString stringWithFormat:@"%@ (%@)", userInfo[NSLocalizedFailureReasonErrorKey],appendingString];
    userInfo[NSLocalizedDescriptionKey] = [NSString stringWithFormat:@"%@ (%@)", userInfo[NSLocalizedDescriptionKey],appendingString];
    return [NSDictionary dictionaryWithDictionary:userInfo];
}

- (EKEventStore *)initWithAccessToRemindersReturningError:(NSError**)errorRef {
    EKAuthorizationStatus authorizationStatus;
    EKEventStore *store = nil;
    *errorRef = nil;
    
    if ([self respondsToSelector:@selector(initWithAccessToEntityTypes:)]) { // deprecated in MacOS 10.9 so make sure it still works
        store = [self initWithAccessToEntityTypes:EKEntityMaskReminder];
    } else if (! [[EKEventStore class] respondsToSelector:@selector(authorizationStatusForEntityType:)]) {
        // assume we don't need authorization if neither initWithAccess nor authorizationStatus work
        // NSLog(@"did not check for authorization");
        store = [self init];
    } else if ((authorizationStatus=[EKEventStore authorizationStatusForEntityType:EKEntityTypeReminder]) == EKAuthorizationStatusDenied) {
        *errorRef = [NSError errorWithDomain:MY_ERROR_DOMAIN code:EXIT_ACCESS_DENIED userInfo:errorUserInfoForStatus(EXIT_ACCESS_DENIED)];
        return nil;
    } else if (authorizationStatus == EKAuthorizationStatusRestricted) {
        *errorRef = [NSError errorWithDomain:MY_ERROR_DOMAIN code:EXIT_ACCESS_RESTRICTED userInfo:errorUserInfoForStatus(EXIT_ACCESS_RESTRICTED)];
        return nil;
    } else if (authorizationStatus == EKAuthorizationStatusAuthorized) {
        // NSLog(@"authorized");
        store = [self init];
    } else if (authorizationStatus == EKAuthorizationStatusNotDetermined) {
        store = [self init];
        NSLog(@"NEED TO authorize");
        if ((*errorRef = [self requestAccessToEntityTypeSynchronous:EKEntityTypeReminder]) != nil)
            return nil;
    } else {
        *errorRef = [NSError errorWithDomain:MY_ERROR_DOMAIN code:EXIT_AUTH_UNKNOWNRESPONSE userInfo:errorUserInfoForStatusAppendingStringToDescriptionAndReason(EXIT_AUTH_UNKNOWNRESPONSE,[NSString stringWithFormat:@"%@",@(authorizationStatus)])];
        return nil;
    }
    
    if (store == nil) {
        *errorRef = [NSError errorWithDomain:MY_ERROR_DOMAIN code:EXIT_FAIL_NOINIT userInfo:errorUserInfoForStatus(EXIT_FAIL_NOINIT)];
        return nil;
    }
    return store;
}




- (NSError*)requestAccessToEntityTypeSynchronous:(EKEntityType)entityType withTimeout:(NSTimeInterval)timeout {
    // entityType should be either EKEntityTypeReminder or EKEntityTypeEvent
    __block BOOL requesting = YES;
    __block NSError * _Nullable myError = nil;
    
    NSLog(@"before request");
    [self requestAccessToEntityType:entityType completion:^void(BOOL granted, NSError * _Nullable error) {
        if (error) {
            NSLog(@"in request: error");
            // dispatch_async(dispatch_get_main_queue(), ^{
                // NSLog(@"requestAccessToEntityType completion error: %@",error);
                myError = error;
            // });
        } else if (granted) {
            NSLog(@"in request: granted");
            // NSLog(@"requestAccessToEntityType completion granted");
            // no need to do anything, nil error and "requsting=NO" (below) handle it
        } else {
            NSLog(@"in request: denied");
            // dispatch_async(dispatch_get_main_queue(), ^{
                // NSLog(@"requestAccessToEntityType completion denied (but no error)");
                myError = [NSError errorWithDomain:MY_ERROR_DOMAIN code:EXIT_ACCESS_NOTGRANTED userInfo:errorUserInfoForStatus(EXIT_ACCESS_NOTGRANTED)];
            // });
        }
        requesting = NO;
        NSLog(@"in request: returning");
        return;
    }];

    NSLog(@"wait request");
    // should we idle until we have authorization?
    for (int i=0; requesting; i++) {
        NSLog(@"sleep waiting for authorization to be granted");
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:REMINDERS_AUTHORIZATION_INTERVAL]]; //[NSThread sleepForTimeInterval:REMINDERS_AUTHORIZATION_INTERVAL]; // idle
        if (timeout/REMINDERS_AUTHORIZATION_INTERVAL <= i) {
            myError = [NSError errorWithDomain:MY_ERROR_DOMAIN code:EXIT_ACCESS_TIMEDOUT userInfo:errorUserInfoForStatus(EXIT_ACCESS_TIMEDOUT)];
            
            break;
        }
    }
    NSLog(@"after request");

    return myError;
}

- (NSError*)requestAccessToEntityTypeSynchronous:(EKEntityType)entityType {
    return [self requestAccessToEntityTypeSynchronous:entityType withTimeout:REMINDERS_AUTHORIZATION_MAX_WAIT];
}




@end
