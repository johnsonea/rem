//
//  NSString+regex.m
//  rem
//
//  Created by Erik A Johnson on 12/4/19 - 12/09/2019.
//  Copyright © 2019 Erik A Johnson. All rights reserved.
//

#import "NSString+regex.h"

#ifndef ERRORCODE_REGEXP_BADMATCH
#define ERRORCODE_REGEXP_BADMATCH 123
#endif
#ifndef ERRORCODE_REGEXP_BADREGEX
#define ERRORCODE_REGEXP_BADREGEX 121
#endif

static BOOL throwException = YES;
static int  exitStatus = 250;
static NSString *errorDomainNSStringRegex = @"default.NSString.regex";

@implementation NSString (regex)
+(int)exitStatus {return exitStatus;}
+(BOOL)throwException {return throwException;}
+(void)setExitStatus:(int)newExitStatus { exitStatus=newExitStatus; }
+(void)setThrowException:(BOOL)shouldThrowException { throwException=shouldThrowException; }
+(void)doThrowException { throwException=YES; }
+(void)dontThrowException { throwException=NO; }
+(NSString*)errorDomainNSStringRegex { return errorDomainNSStringRegex; }
+(void)setErrorDomainNSStringRegex:(NSString*_Nonnull)str { errorDomainNSStringRegex=str; }

#define NSLog(format, ...) NSLog([@"%s (%@:%d) " stringByAppendingString:format],__FUNCTION__,[[NSString stringWithUTF8String:__FILE__] lastPathComponent],__LINE__, ## __VA_ARGS__)

-(NSString*_Nullable)substringFirstMatchingRegexString:(NSString*_Nonnull)regexString options:(NSRegularExpressionOptions)options returningCaptureGroups:(NSDictionary<NSNumber*,NSString*>*_Nullable*_Nullable)captureGroupsDictRef leavingString:(NSString*_Nullable*_Nullable)remainderRef error:(NSError*_Nullable*_Nullable)errorRef {
    if (captureGroupsDictRef) *captureGroupsDictRef = nil;
    if (remainderRef) *remainderRef = nil;
    if (errorRef) *errorRef = nil;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:regexString options:NSRegularExpressionCaseInsensitive error:errorRef];
    if (errorRef && *errorRef) return nil;
    if (!regex) {
        // I don't know if this can happen without *errorRef being set but just in case ...
        if (errorRef) *errorRef = [NSError errorWithDomain:errorDomainNSStringRegex code:ERRORCODE_REGEXP_BADREGEX userInfo:@{
            NSLocalizedDescriptionKey:[NSString stringWithFormat:NSLocalizedString(@"Unable to create the regular expression \"%@\"",nil), regexString],
            NSLocalizedFailureReasonErrorKey:NSLocalizedString(@"Unknown why this happened.",nil),
            NSLocalizedRecoverySuggestionErrorKey:NSLocalizedString(@"Talk to the developer of this application.",nil),
        }];
        return nil;
    }
    NSTextCheckingResult *firstMatch = [regex firstMatchInString:self options:0 range:NSMakeRange(0, [self length])];
    if (!firstMatch) return nil;
    if (firstMatch.numberOfRanges != regex.numberOfCaptureGroups+1) {
        // I don't know if this can happen, but just in case
        if (errorRef) *errorRef = [NSError errorWithDomain:errorDomainNSStringRegex code:ERRORCODE_REGEXP_BADMATCH userInfo:@{
            NSLocalizedDescriptionKey:[NSString stringWithFormat:NSLocalizedString(@"Matching string \"%@\" with the regular expression \"%@\" returned the wrong number of ranges (%d but should be %d). This should not normally happen.",nil), self, regexString, firstMatch.numberOfRanges, regex.numberOfCaptureGroups+1],
            NSLocalizedFailureReasonErrorKey:NSLocalizedString(@"Unknown why this happened.",nil),
            NSLocalizedRecoverySuggestionErrorKey:NSLocalizedString(@"Talk to the developer of this application.",nil),
        }];
        return nil;
    }
    if (remainderRef) *remainderRef = [self stringByReplacingCharactersInRange:firstMatch.range withString:@""];
    if (captureGroupsDictRef) {
        NSMutableDictionary//<NSObject,NSString*>
        *captureGroups = [NSMutableDictionary dictionaryWithCapacity:firstMatch.numberOfRanges-1];
        // NSLog(@"firstMatch = %@",firstMatch);
        // NSLog(@"firstMatch.numberOfRanges = %@",@(firstMatch.numberOfRanges));
        for (NSUInteger i = 1; i < firstMatch.numberOfRanges; i++) {
            NSRange captureGroupRange = [firstMatch rangeAtIndex:i];
            // NSLog(@"loc 1, i=%@ range=(%@,%@)",@(i),@(captureGroupRange.location),@(captureGroupRange.length));
            if (captureGroupRange.location != NSNotFound)
                [captureGroups setObject:[self substringWithRange:captureGroupRange] forKey:@(i)];
        }
        *captureGroupsDictRef = [captureGroups copy];
    }
    return firstMatch.range.location==NSNotFound ? nil : [self substringWithRange:firstMatch.range];
}
// options:NSRegularExpressionCaseInsensitive

// don't use this method, use ...returningCaptureGroups:... above returning a dictionary
-(NSString*_Nullable)substringFirstMatchingRegexString:(NSString*_Nonnull)regexString options:(NSRegularExpressionOptions)options returningCaptureGroupsArray:(NSArray<NSString*>**_Nullable)captureGroupsRef leavingString:(NSString*_Nullable*_Nullable)remainderRef error:(NSError*_Nullable*_Nullable)errorRef {
    if (captureGroupsRef) *captureGroupsRef = nil;
    if (remainderRef) *remainderRef = nil;
    if (errorRef) *errorRef = nil;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:regexString options:NSRegularExpressionCaseInsensitive error:errorRef];
    if (errorRef && *errorRef) return nil;
    if (!regex) {
        // I don't know if this can happen without *errorRef being set but just in case ...
        if (errorRef) *errorRef = [NSError errorWithDomain:errorDomainNSStringRegex code:ERRORCODE_REGEXP_BADREGEX userInfo:@{
            NSLocalizedDescriptionKey:[NSString stringWithFormat:NSLocalizedString(@"Unable to create the regular expression \"%@\"",nil), regexString],
            NSLocalizedFailureReasonErrorKey:NSLocalizedString(@"Unknown why this happened.",nil),
            NSLocalizedRecoverySuggestionErrorKey:NSLocalizedString(@"Talk to the developer of this application.",nil),
        }];
        return nil;
    }
    NSTextCheckingResult *firstMatch = [regex firstMatchInString:self options:0 range:NSMakeRange(0, [self length])];
    if (!firstMatch) return nil;
    if (firstMatch.numberOfRanges != regex.numberOfCaptureGroups+1) {
        // I don't know if this can happen, but just in case
        if (errorRef) *errorRef = [NSError errorWithDomain:errorDomainNSStringRegex code:ERRORCODE_REGEXP_BADMATCH userInfo:@{
            NSLocalizedDescriptionKey:[NSString stringWithFormat:NSLocalizedString(@"Matching string \"%@\" with the regular expression \"%@\" returned the wrong number of ranges (%d but should be %d). This should not normally happen.",nil), self, regexString, firstMatch.numberOfRanges, regex.numberOfCaptureGroups+1],
            NSLocalizedFailureReasonErrorKey:NSLocalizedString(@"Unknown why this happened.",nil),
            NSLocalizedRecoverySuggestionErrorKey:NSLocalizedString(@"Talk to the developer of this application.",nil),
        }];
        return nil;
    }
    if (remainderRef) *remainderRef = [self stringByReplacingCharactersInRange:firstMatch.range withString:@""];
    if (captureGroupsRef) {
        NSMutableArray<NSString*> *strings = [NSMutableArray arrayWithCapacity:firstMatch.numberOfRanges-1];
        NSLog(@"firstMatch = %@",firstMatch);
        NSLog(@"firstMatch.numberOfRanges = %@",@(firstMatch.numberOfRanges));
        for (NSUInteger i = 1; i < firstMatch.numberOfRanges; i++) {
            NSRange captureGroupRange = [firstMatch rangeAtIndex:i];
            NSLog(@"loc 1, i=%@ range=(%@,%@)",@(i),@(captureGroupRange.location),@(captureGroupRange.length));
            [strings addObject:captureGroupRange.location==NSNotFound?(NSString*)@(NSNotFound):[self substringWithRange:captureGroupRange]];
        }
        *captureGroupsRef = [strings copy];
    }
    return firstMatch.range.location==NSNotFound ? nil : [self substringWithRange:firstMatch.range];
}






-(NSString*_Nullable)substringFirstMatchingRegexString:(NSString*_Nonnull)regexString options:(NSRegularExpressionOptions)options returningCaptureGroups:(NSDictionary<NSNumber*,NSString*>*_Nullable*_Nullable)captureGroupsDictRef leavingString:(NSString*_Nullable*_Nullable)remainderRef {
    NSError *error;
    NSString *match = [self substringFirstMatchingRegexString:regexString options:options returningCaptureGroups:captureGroupsDictRef leavingString:remainderRef error:&error];
    if (error) {
        NSError *underlyingError = [[error userInfo] objectForKey:NSUnderlyingErrorKey];
        NSString *underlyingErrorString = !underlyingError ? @"" : underlyingError.localizedDescription ? [NSString stringWithFormat:@" (%@ #%@: %@)",underlyingError.domain,@(underlyingError.code),underlyingError.localizedDescription] : [NSString stringWithFormat:@" (%@ #%@)",underlyingError.domain,@(underlyingError.code)];
        if (throwException) {
            [NSException raise:@"NSString regex error" format:@"Regular expression \"%@\" gave an error: %@%@",regexString,error.localizedDescription,underlyingErrorString];
        } else {
            NSLog(@"Regular expression \"%@\" gave an error (%@%@). This should not happen; please contact the application author.",regexString,error.localizedDescription,underlyingErrorString);
            exit(exitStatus);
        }
        return nil; // won't actually get here
    }
    return match;
}
-(NSString*_Nullable)substringFirstMatchingRegexString:(NSString*_Nonnull)regexString returningCaptureGroups:(NSDictionary<NSNumber*,NSString*>*_Nullable*_Nullable)captureGroupsDictRef leavingString:(NSString*_Nullable*_Nullable)remainderRef {
    return [self substringFirstMatchingRegexString:regexString options:0 returningCaptureGroups:captureGroupsDictRef leavingString:remainderRef];
}
-(NSString*_Nullable)substringFirstMatchingRegexStringI:(NSString*_Nonnull)regexString returningCaptureGroups:(NSDictionary<NSNumber*,NSString*>*_Nullable*_Nullable)captureGroupsDictRef leavingString:(NSString*_Nullable*_Nullable)remainderRef {
    return [self substringFirstMatchingRegexString:regexString options:NSRegularExpressionCaseInsensitive returningCaptureGroups:captureGroupsDictRef leavingString:remainderRef];
}


-(NSDictionary<NSNumber*,NSString*>*_Nullable)substringsFirstMatchingRegexString:(NSString*_Nonnull)regexString options:(NSRegularExpressionOptions)options leavingString:(NSString*_Nullable*_Nullable)remainderRef {
    NSDictionary<NSNumber*,NSString*> *captureGroups;
    NSString *firstMatch = [self substringFirstMatchingRegexString:regexString options:options returningCaptureGroups:&captureGroups leavingString:remainderRef];
    return firstMatch ? captureGroups : nil;
}
-(NSDictionary<NSNumber*,NSString*>*_Nullable)substringsFirstMatchingRegexString:(NSString*_Nonnull)regexString leavingString:(NSString*_Nullable*_Nullable)remainderRef {
    return [self substringsFirstMatchingRegexString:(NSString*_Nonnull)regexString options:0 leavingString:remainderRef];
}
-(NSDictionary<NSNumber*,NSString*>*_Nullable)substringsFirstMatchingRegexStringI:(NSString*_Nonnull)regexString leavingString:(NSString*_Nullable*_Nullable)remainderRef {
    return [self substringsFirstMatchingRegexString:(NSString*_Nonnull)regexString options:NSRegularExpressionCaseInsensitive leavingString:remainderRef];
}


-(NSDictionary<NSNumber*,NSString*>*_Nullable)substringsFirstMatchingRegexString:(NSString*_Nonnull)regexString options:(NSRegularExpressionOptions)options {
    return [self substringsFirstMatchingRegexString:(NSString*_Nonnull)regexString options:(NSRegularExpressionOptions)options leavingString:nil];
}
-(NSDictionary<NSNumber*,NSString*>*_Nullable)substringsFirstMatchingRegexString:(NSString*_Nonnull)regexString {
    return [self substringsFirstMatchingRegexString:regexString options:0];
}
-(NSDictionary<NSNumber*,NSString*>*_Nullable)substringsFirstMatchingRegexStringI:(NSString*_Nonnull)regexString {
    return [self substringsFirstMatchingRegexString:regexString options:NSRegularExpressionCaseInsensitive];
}


-(NSString*_Nullable)firstMatchingRegexString:(NSString*_Nonnull)regexString options:(NSRegularExpressionOptions)options {
    return [self substringFirstMatchingRegexString:regexString options:options returningCaptureGroups:nil leavingString:nil];
}
-(NSString*_Nullable)firstMatchingRegexString:(NSString*_Nonnull)regexString {
    return [self substringFirstMatchingRegexString:regexString options:0 returningCaptureGroups:nil leavingString:nil];
}
-(NSString*_Nullable)firstMatchingRegexStringI:(NSString*_Nonnull)regexString {
    return [self substringFirstMatchingRegexString:regexString options:NSRegularExpressionCaseInsensitive returningCaptureGroups:nil leavingString:nil];
}


-(BOOL)matchesRegexString:(NSString*_Nonnull)regexString options:(NSRegularExpressionOptions)options {
    return [self substringFirstMatchingRegexString:regexString options:options returningCaptureGroups:nil leavingString:nil] != nil;
}
-(BOOL)matchesRegexString:(NSString*_Nonnull)regexString {
    return [self matchesRegexString:regexString options:0];
}
-(BOOL)matchesRegexStringI:(NSString*_Nonnull)regexString {
    return [self matchesRegexString:regexString options:NSRegularExpressionCaseInsensitive];
}



//// BOOL NSLocationInRange(NSUInteger loc, NSRange range);
//
//// NSLog(@"loc 1");
//if (regex==nil || error) {
//    _print(stderr, @"%@: illegal radius regular expression (this should not happen): #%@ %@\n", MYNAME, error ? @(error.code) : @"?", error ? localizedUnderlyingError(error) : @"unknown reason");
//    NSLog(@"error = %@",error);
//    return EXIT_INVARG_BADLOCATION;
//}
//// NSLog(@"loc 2, regex = %@",regex);
//NSTextCheckingResult *match = [regex firstMatchInString:*locationStringRef options:0 range:NSMakeRange(0, [*locationStringRef length])];
//// NSLog(@"loc 3, match = %@",match);
//if (match && match.numberOfRanges==3) {

#define quoted(x) (x)?[NSString stringWithFormat:@"\"%@\"",(x)]:@"(null)"
+(void)testNSStringRegex {
    NSString *s = @"Hello, world!";
    NSString *remainder;
    NSError *error;
    NSString *firstMatch;
    NSLog(@"test testNSStringRegex substringFirstMatchingRegexString:options:returningCaptureGroupsArray:leavingString:error:");
    NSArray *groupsArray;
    firstMatch = [s substringFirstMatchingRegexString:@"(z)?(.)l" options:NSRegularExpressionCaseInsensitive returningCaptureGroupsArray:&groupsArray leavingString:&remainder error:&error];
    NSLog(@"error = %@",quoted(error));
    NSLog(@"firstMatch = %@",quoted(firstMatch));
    for (NSInteger i=0; groupsArray && i<groupsArray.count; i++) {
        NSLog(@"capture group %d = %@",i+1,quoted(groupsArray[i]));
    }
    NSLog(@"leaving = %@",quoted(remainder));
    NSLog(@"\n\n\n\n");
    
    NSLog(@"test testNSStringRegex substringFirstMatchingRegexString:options:returningCaptureGroups:leavingString:error:");
    NSDictionary *groupsDict;
    firstMatch = [s substringFirstMatchingRegexString:@"(z)?(.)l(.)(.)" options:NSRegularExpressionCaseInsensitive returningCaptureGroups:&groupsDict leavingString:&remainder error:&error];
    NSLog(@"error = %@",quoted(error));
    NSLog(@"firstMatch = %@",quoted(firstMatch));
    id key;
    key=@0; NSLog(@"capture group[%@] = %@",key,quoted(groupsDict[key]));
    key=@1; NSLog(@"capture group[%@] = %@",key,quoted(groupsDict[key]));
    key=@2; NSLog(@"capture group[%@] = %@",key,quoted(groupsDict[key]));
    key=@3; NSLog(@"capture group[%@] = %@",key,quoted(groupsDict[key]));
    key=@4; NSLog(@"capture group[%@] = %@",key,quoted(groupsDict[key]));
    NSString *ss;
    for (id key in groupsDict) {
        NSString *skey = [NSString stringWithFormat:@"%@=>%@",key,quoted(groupsDict[key])];
        NSLog(@"");
        if (ss)
            ss = [NSString stringWithFormat:@"%@, %@",ss,skey];
        else
            ss = skey;
    }
    NSLog(@"capture group = @{%@}",ss);
    NSLog(@"leaving = %@",quoted(remainder));
    NSLog(@"\n\n\n\n");
    
    BOOL bob = [s matchesRegexStringI:@"(z)?(.)l(.)(.)("];
    @try {
        BOOL bob = [s matchesRegexStringI:@"(z)?(.)l(.)(.)("];
        NSLog(bob ? @"matched" : @"no match");
    } @catch (NSException *exception) {
        NSLog(@"%@",[NSString stringWithFormat:@"error={name=%@, reason=%@, userInfo=%@}",exception.name,exception.reason,exception.userInfo]);
        exit(1);
    }

    exit(1);
}


@end
