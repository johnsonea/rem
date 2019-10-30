//
//  EKAlarm+stringWith.h
//  rem
//
//  Created by Erik A Johnson on 10/29/19.
//  Copyright © 2019 kykim, inc. All rights reserved.
//

#import <EventKit/EventKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface EKAlarm (stringWith)

NSString *structuredLocationString(EKStructuredLocation *loc);
- (NSString *)proximityStr;
- (NSString *)typeString;
- (NSString *)stringWithDateFormatter:(NSFormatter*)formatter;

@end

NS_ASSUME_NONNULL_END
