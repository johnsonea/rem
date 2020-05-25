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


/*
 *  Utility methods
 */

-(NSRegularExpression*_Nullable)regexWithOptions:(NSRegularExpressionOptions)options error:(NSError*_Nullable*_Nullable)errorRef {
    if (errorRef) *errorRef = nil;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:self options:options error:errorRef];
    if (errorRef && *errorRef) return nil;
    if (!regex) {
        // I don't know if this can happen without *errorRef being set but just in case ...
        if (errorRef) *errorRef = [NSError errorWithDomain:errorDomainNSStringRegex code:ERRORCODE_REGEXP_BADREGEX userInfo:@{
            NSLocalizedDescriptionKey:[NSString stringWithFormat:NSLocalizedString(@"Unable to create the regular expression \"%@\"",nil), self],
            NSLocalizedFailureReasonErrorKey:NSLocalizedString(@"Unknown why this happened.",nil),
            NSLocalizedRecoverySuggestionErrorKey:NSLocalizedString(@"Talk to the developer of this application.",nil),
        }];
        return nil;
    }
    return regex;
}

/*
 *  Matching methods
 */


-(NSString*_Nullable)substringFirstMatchingRegexString:(NSString*_Nonnull)regexString options:(NSRegularExpressionOptions)options returningCaptureGroups:(NSDictionary<NSNumber*,NSString*>*_Nullable*_Nullable)captureGroupsDictRef leavingString:(NSString*_Nullable*_Nullable)remainderRef error:(NSError*_Nullable*_Nullable)errorRef {
    if (captureGroupsDictRef) *captureGroupsDictRef = nil;
    if (remainderRef) *remainderRef = nil;
    NSRegularExpression *regex = [regexString regexWithOptions:options error:errorRef];
    if (regex == nil) return nil;
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

// don't use this method, use ...returningCaptureGroups:... (below) returning a dictionary
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




/*
 *  Replace methods
 */

-(NSString*_Nullable)stringByReplacingMatchesOfRegex:(NSString*_Nonnull)regexString matchOptions:(NSRegularExpressionOptions)matchOptions range:(NSRange)range replacement:(NSString *)replacement replaceOptions:(NSMatchingOptions)replaceOptions error:(NSError*_Nullable*_Nullable)errorRef {
    NSRegularExpression *regex = [regexString regexWithOptions:matchOptions error:errorRef];
    if (regex == nil) return nil;
    return [regex stringByReplacingMatchesInString:self options:replaceOptions range:range withTemplate:replacement];
}
// matchOptions:NSRegularExpressionCaseInsensitive

-(NSString*_Nullable)stringByReplacingMatchesOfRegex:(NSString*_Nonnull)regexString matchOptions:(NSRegularExpressionOptions)matchOptions replacement:(NSString *)replacement error:(NSError*_Nullable*_Nullable)errorRef {
    return [self stringByReplacingMatchesOfRegex:regexString matchOptions:matchOptions range:NSMakeRange(0, [self length]) replacement:(NSString *)replacement replaceOptions:0 error:(NSError*_Nullable*_Nullable)errorRef];
}
-(NSString*_Nullable)stringByReplacingMatchesOfRegex:(NSString*_Nonnull)regexString with:(NSString *)replacement error:(NSError*_Nullable*_Nullable)errorRef {
    return [self stringByReplacingMatchesOfRegex:regexString matchOptions:0 replacement:replacement error:errorRef];
}
-(NSString*_Nullable)stringByReplacingMatchesOfRegexI:(NSString*_Nonnull)regexString with:(NSString *)replacement error:(NSError*_Nullable*_Nullable)errorRef {
    return [self stringByReplacingMatchesOfRegex:regexString matchOptions:NSRegularExpressionCaseInsensitive replacement:replacement error:errorRef];
}

-(NSString*_Nullable)stringByReplacingMatchesOfRegex:(NSString*_Nonnull)regexString matchOptions:(NSRegularExpressionOptions)matchOptions replacement:(NSString *_Nullable)replacement {
    NSError *error;
    NSString *ans = [self stringByReplacingMatchesOfRegex:regexString matchOptions:matchOptions replacement:replacement error:&error];
    if (error) {
        /*
        NSError *underlyingError = [[error userInfo] objectForKey:NSUnderlyingErrorKey];
        NSString *underlyingErrorString = !underlyingError ? @"" : underlyingError.localizedDescription ? [NSString stringWithFormat:@" (%@ #%@: %@)",underlyingError.domain,@(underlyingError.code),underlyingError.localizedDescription] : [NSString stringWithFormat:@" (%@ #%@)",underlyingError.domain,@(underlyingError.code)];
        if (throwException) {
            [NSException raise:@"NSString regex error" format:@"Regular expression \"%@\" gave an error: %@%@",regexString,error.localizedDescription,underlyingErrorString];
        } else {
            NSLog(@"Regular expression \"%@\" gave an error (%@%@). This should not happen; please contact the application author.",regexString,error.localizedDescription,underlyingErrorString);
            exit(exitStatus);
        }
        */
        if (throwException) {
            [NSException raise:@"NSString regex error" format:@"%@",error.localizedDescription];
        } else {
            NSLog(@"%@",error.localizedDescription);
            exit(exitStatus);
        }
        return nil; // won't actually get here
    }
    return ans;
}
-(NSString*_Nullable)stringByReplacingMatchesOfRegex:(NSString*_Nonnull)regexString with:(NSString *)replacement {
    return [self stringByReplacingMatchesOfRegex:regexString matchOptions:0 replacement:replacement];
}
-(NSString*_Nullable)stringByReplacingMatchesOfRegexI:(NSString*_Nonnull)regexString with:(NSString *)replacement{
    return [self stringByReplacingMatchesOfRegex:regexString matchOptions:NSRegularExpressionCaseInsensitive replacement:replacement];
}


/*
 *  testing
 */

void _print(FILE *file, NSString *format, ...);

-(void)testStringRegex:(NSString *)pattern replacement:(NSString *)replacement {
    _print(stderr,@"str=\"%@\" pattern=\"%@\" replace=\"%@\" ==> \"%@\"\n",self,pattern,replacement,[self stringByReplacingMatchesOfRegex:pattern with:replacement]);
}
-(void)testStringRegexCountMatches:(NSString *)pattern {
    NSRegularExpression *regex = [pattern regexWithOptions:0 error:nil];
    if (regex == nil) {
        NSLog(@"regex is nill for pattern \"%@\"",pattern);
        exit(0);
    }
    NSUInteger nMatches = [regex numberOfMatchesInString:self options:0 range:NSMakeRange(0, [self length])];
    _print(stderr,@"str=\"%@\" pattern=\"%@\" ==> %@ match%@\n",self,pattern,@(nMatches),nMatches==1?@"":@"es");
}
-(void)testStringMatchCountWithRegex:(NSString*)pattern replacement:(NSString*)replacement {
    NSRegularExpression *regex = [pattern regexWithOptions:0 error:nil];
    if (regex == nil) {
        NSLog(@"regex is nill for pattern \"%@\"",pattern);
        exit(0);
    }
    NSUInteger nMatches = [regex numberOfMatchesInString:self options:0 range:NSMakeRange(0, [self length])];
    _print(stderr,@"str=\"%@\" pattern=\"%@\" ==> %@ match%@ ==> replace with \"%@\" ==>\n    \"%@\"\n",self,pattern,@(nMatches),nMatches==1?@"":@"es",replacement,[self stringByReplacingMatchesOfRegex:pattern with:replacement]);
}
#include "popenv.h"
#define BUFSIZE 4096
-(void)testStringMatchCountAndCompareWithPerlWithRegex:(NSString*)pattern replacement:(NSString*)replacement {
    NSRegularExpression *regex = [pattern regexWithOptions:0 error:nil];
    if (regex == nil) {
        NSLog(@"regex is nill for pattern \"%@\"",pattern);
        exit(0);
    }
    NSUInteger nMatches = [regex numberOfMatchesInString:self options:0 range:NSMakeRange(0, [self length])];
    
    NSString *perl = @"";
    char *argv[] = {"perl","-e","my ($str,$pat,$rep)=@ARGV; $str=~s/$pat/$rep/g; print $str;",self.UTF8String,pattern.UTF8String,replacement.UTF8String,NULL};
    FILE *f = popenv("r",argv);
    char buf[BUFSIZE];
    while (fgets(buf,BUFSIZE,f) != NULL) {
        perl = [perl stringByAppendingString:[NSString stringWithUTF8String:buf]];
    }
    int res = pclosev(f);
    if (res)
        perl = [NSString stringWithFormat:@"calling perl gave exit %@",@(res)];
    
    NSString *replaced = [self stringByReplacingMatchesOfRegex:pattern with:replacement];
    _print(stderr,@"str=\"%@\" pattern=\"%@\" ==> %@ match%@ ==> replace with \"%@\" ==>\n    \"%@\"\n%@",self,pattern,@(nMatches),nMatches==1?@"":@"es",replacement,replaced,[perl isEqualToString:replaced] ? @"" : [NSString stringWithFormat:@"    \"%@\" (perl)\n", perl]);
}
+(void)testStringRegex {
    NSString *str = @"Hello, world!";
    [str testStringRegex:@"l" replacement:@"L"];
    [str testStringRegex:@"ll" replacement:@"LL"];
    [str testStringRegex:@"(ll)o" replacement:@"$1"];
    _print(stderr,@"\n");
    
    // all are the same as Perl except as noted
    [str testStringMatchCountAndCompareWithPerlWithRegex:@".+" replacement:@"_"];
    [str testStringMatchCountAndCompareWithPerlWithRegex:@".*" replacement:@"_"];
    [str testStringMatchCountAndCompareWithPerlWithRegex:@".*?" replacement:@"_"]; // this gives "_H_e_l_l_o_,_ _w_o_r_l_d_!_" but Perl gives "___________________________"
    [str testStringMatchCountAndCompareWithPerlWithRegex:@"^.*" replacement:@"_"];
    [str testStringMatchCountAndCompareWithPerlWithRegex:@".*$" replacement:@"_"];
    [str testStringMatchCountAndCompareWithPerlWithRegex:@"^.*$" replacement:@"_"];
    [str testStringMatchCountAndCompareWithPerlWithRegex:@"\\s*" replacement:@"_"];
    [str testStringMatchCountAndCompareWithPerlWithRegex:@"\\s+" replacement:@"_"];
    [str testStringMatchCountAndCompareWithPerlWithRegex:@"\\S*" replacement:@"_"];
    [str testStringMatchCountAndCompareWithPerlWithRegex:@"\\S+" replacement:@"_"];
    [str testStringMatchCountAndCompareWithPerlWithRegex:@"[\\s\\S]*" replacement:@"_"];
    [str testStringMatchCountAndCompareWithPerlWithRegex:@"[\\s\\S]+" replacement:@"_"];
    _print(stderr,@"\n");

    // [str testStringRegexCountMatches:@"[\\s\\S]*"];

}


@end
