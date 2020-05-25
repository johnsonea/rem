//
//  NSString+regex.h
//  rem
//
//  Created by Erik A Johnson on 12/4/19 - 12/09/2019.
//  Copyright © 2019 Erik A Johnson. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSString (regex)

+(int)exitStatus;
+(void)setExitStatus:(int)newExitStatus;

+(BOOL)throwException;
+(void)setThrowException:(BOOL)shouldThrowException;
+(void)doThrowException;
+(void)dontThrowException;

+(NSString*)errorDomainNSStringRegex;
+(void)setErrorDomainNSStringRegex:(NSString*_Nonnull)str;

// Utility methods

-(NSRegularExpression*_Nullable)regexWithOptions:(NSRegularExpressionOptions)options error:(NSError*_Nullable*_Nullable)errorRef;


// Matching methods

-(NSString*_Nullable)substringFirstMatchingRegexString:(NSString*_Nonnull)regexString options:(NSRegularExpressionOptions)options returningCaptureGroups:(NSDictionary<NSNumber*,NSString*>*_Nullable*_Nullable)captureGroupsDictRef leavingString:(NSString*_Nullable*_Nullable)remainderRef error:(NSError*_Nullable*_Nullable)errorRef;

-(NSString*_Nullable)substringFirstMatchingRegexString:(NSString*_Nonnull)regexString options:(NSRegularExpressionOptions)options returningCaptureGroups:(NSDictionary<NSNumber*,NSString*>*_Nullable*_Nullable)captureGroupsDictRef leavingString:(NSString*_Nullable*_Nullable)remainderRef;
-(NSString*_Nullable)substringFirstMatchingRegexString:(NSString*_Nonnull)regexString returningCaptureGroups:(NSDictionary<NSNumber*,NSString*>*_Nullable*_Nullable)captureGroupsDictRef leavingString:(NSString*_Nullable*_Nullable)remainderRef;
-(NSString*_Nullable)substringFirstMatchingRegexStringI:(NSString*_Nonnull)regexString returningCaptureGroups:(NSDictionary<NSNumber*,NSString*>*_Nullable*_Nullable)captureGroupsDictRef leavingString:(NSString*_Nullable*_Nullable)remainderRef;

-(NSDictionary<NSNumber*,NSString*>*_Nullable)substringsFirstMatchingRegexString:(NSString*_Nonnull)regexString options:(NSRegularExpressionOptions)options leavingString:(NSString*_Nullable*_Nullable)remainderRef;
-(NSDictionary<NSNumber*,NSString*>*_Nullable)substringsFirstMatchingRegexString:(NSString*_Nonnull)regexString leavingString:(NSString*_Nullable*_Nullable)remainderRef;
-(NSDictionary<NSNumber*,NSString*>*_Nullable)substringsFirstMatchingRegexStringI:(NSString*_Nonnull)regexString leavingString:(NSString*_Nullable*_Nullable)remainderRef;

-(NSDictionary<NSNumber*,NSString*>*_Nullable)substringsFirstMatchingRegexString:(NSString*_Nonnull)regexString options:(NSRegularExpressionOptions)options;
-(NSDictionary<NSNumber*,NSString*>*_Nullable)substringsFirstMatchingRegexString:(NSString*_Nonnull)regexString;
-(NSDictionary<NSNumber*,NSString*>*_Nullable)substringsFirstMatchingRegexStringI:(NSString*_Nonnull)regexString;

-(NSString*_Nullable)firstMatchingRegexString:(NSString*_Nonnull)regexString options:(NSRegularExpressionOptions)options;
-(NSString*_Nullable)firstMatchingRegexString:(NSString*_Nonnull)regexString;
-(NSString*_Nullable)firstMatchingRegexStringI:(NSString*_Nonnull)regexString;

-(BOOL)matchesRegexString:(NSString*_Nonnull)regexString options:(NSRegularExpressionOptions)options;
-(BOOL)matchesRegexString:(NSString*_Nonnull)regexString;
-(BOOL)matchesRegexStringI:(NSString*_Nonnull)regexString;



//Replace methods

-(NSString*_Nullable)stringByReplacingMatchesOfRegex:(NSString*_Nonnull)regexString matchOptions:(NSRegularExpressionOptions)matchOptions range:(NSRange)range replacement:(NSString *)replacement replaceOptions:(NSMatchingOptions)replaceOptions error:(NSError*_Nullable*_Nullable)errorRef;

-(NSString*_Nullable)stringByReplacingMatchesOfRegex:(NSString*_Nonnull)regexString matchOptions:(NSRegularExpressionOptions)matchOptions replacement:(NSString *)replacement error:(NSError*_Nullable*_Nullable)errorRef;
-(NSString*_Nullable)stringByReplacingMatchesOfRegex:(NSString*_Nonnull)regexString with:(NSString *)replacement error:(NSError*_Nullable*_Nullable)errorRef;
-(NSString*_Nullable)stringByReplacingMatchesOfRegexI:(NSString*_Nonnull)regexString with:(NSString *)replacement error:(NSError*_Nullable*_Nullable)errorRef;

-(NSString*_Nullable)stringByReplacingMatchesOfRegex:(NSString*_Nonnull)regexString matchOptions:(NSRegularExpressionOptions)matchOptions replacement:(NSString *_Nullable)replacement;
-(NSString*_Nullable)stringByReplacingMatchesOfRegex:(NSString*_Nonnull)regexString with:(NSString *)replacement;
-(NSString*_Nullable)stringByReplacingMatchesOfRegexI:(NSString*_Nonnull)regexString with:(NSString *)replacement;

+(void)testStringRegex;

@end

NS_ASSUME_NONNULL_END
