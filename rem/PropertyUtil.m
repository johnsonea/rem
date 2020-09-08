//
//  PropertyUtil.m
//  adapted from https://stackoverflow.com/questions/754824/get-an-object-properties-list-in-objective-c

#import "PropertyUtil.h"
#import <objc/runtime.h>

@implementation PropertyUtil

static const char *getPropertyType(objc_property_t property) {
    const char *attributes = property_getAttributes(property);
    //printf("attributes=%s\n", attributes);
    char buffer[1 + strlen(attributes)];
    strcpy(buffer, attributes);
    char *state = buffer, *attribute;
    while ((attribute = strsep(&state, ",")) != NULL) {
        if (attribute[0] == 'T' && attribute[1] != '@') {
            // it's a C primitive type:
            /*
             if you want a list of what will be returned for these primitives, search online for
             "objective-c" "Property Attribute Description Examples"
             apple docs list plenty of examples of what you get for int "i", long "l", unsigned "I", struct, etc.
             */
            NSString *name = [[NSString alloc] initWithBytes:attribute + 1 length:strlen(attribute) - 1 encoding:NSASCIIStringEncoding];
            return (const char *)[name cStringUsingEncoding:NSASCIIStringEncoding];
        }
        else if (attribute[0] == 'T' && attribute[1] == '@' && strlen(attribute) == 2) {
            // it's an ObjC id type:
            return "id";
        }
        else if (attribute[0] == 'T' && attribute[1] == '@') {
            // it's another ObjC object type:
            NSString *name = [[NSString alloc] initWithBytes:attribute + 3 length:strlen(attribute) - 4 encoding:NSASCIIStringEncoding];
            return (const char *)[name cStringUsingEncoding:NSASCIIStringEncoding];
        }
    }
    return "";
}

NSString *translatedType(NSString *propertyType) {
    // see https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/ObjCRuntimeGuide/Introduction/Introduction.html?language=objc#//apple_ref/doc/uid/TP40008048
    // and https://developer.apple.com/documentation/objectivec/objective-c_runtime?language=objc
    if ([propertyType hasPrefix:@"^"]) {
        return [NSString stringWithFormat:@" *%@",translatedType([propertyType substringFromIndex:1])];
    }
    else if ([propertyType isEqualToString:@"c"]) return @"char";
    else if ([propertyType isEqualToString:@"d"]) return @"double";
    else if ([propertyType isEqualToString:@"i"]) return @"int";
    else if ([propertyType isEqualToString:@"f"]) return @"float";
    else if ([propertyType isEqualToString:@"l"]) return @"long";
    else if ([propertyType isEqualToString:@"s"]) return @"short";
    else if ([propertyType isEqualToString:@"I"]) return @"unsigned int";
    else if ([propertyType isEqualToString:@"C"]) return @"unsigned char";
    else if ([propertyType isEqualToString:@"S"]) return @"unsigned short";
    else if ([propertyType isEqualToString:@"q"]) return @"long long";
    else if ([propertyType isEqualToString:@"L"]) return @"unsigned long";
    else if ([propertyType isEqualToString:@"Q"]) return @"unsigned long long";
    else if ([propertyType isEqualToString:@"B"]) return @"C++bool";
    else return [NSString stringWithFormat:@"%@ *",propertyType];
}

+ (NSDictionary *)classPropsFor:(Class)klass
{
    if (klass == NULL) {
        return nil;
    }

    NSMutableDictionary *results = [[NSMutableDictionary alloc] init];

    unsigned int outCount, i;
    objc_property_t *properties = class_copyPropertyList(klass, &outCount);
    for (i = 0; i < outCount; i++) {
        objc_property_t property = properties[i];
        const char *propName = property_getName(property);
        if(propName) {
            const char *propType = getPropertyType(property);
            NSString *propertyName = [NSString stringWithUTF8String:propName];
            NSString *propertyType = [NSString stringWithUTF8String:propType];
            [results setObject:translatedType(propertyType) forKey:propertyName];
        }
    }
    free(properties);

    // returning a copy here to make sure the dictionary is immutable
    return [NSDictionary dictionaryWithDictionary:results];
}

@end
