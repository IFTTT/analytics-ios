//
//  SOUtils.m
//  Analytics
//
//  Created by Tony Xiao on 8/17/13.
//  Copyright (c) 2013 Segment.io. All rights reserved.
//

#import "AnalyticsUtils.h"

static BOOL kAnalyticsLoggerShowLogs = NO;

NSURL *AnalyticsURLForFilename(NSString *filename) {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
    NSString *path = [[paths objectAtIndex:0] stringByAppendingPathComponent:filename];
    return [NSURL fileURLWithPath:path];
}


// Logging

void SetShowDebugLogs(BOOL showDebugLogs) {
    kAnalyticsLoggerShowLogs = showDebugLogs;
}

void SOLog(NSString *format, ...) {   
    if (kAnalyticsLoggerShowLogs) {
        va_list args;
        va_start(args, format);
        NSLogv(format, args);
        va_end(args);
    }
}

// JSON Utils

static id CoerceJSONObject(id obj) {
    // if the object is a NSString, NSNumber or NSNull
    // then we're good
    if ([obj isKindOfClass:[NSString class]] ||
        [obj isKindOfClass:[NSNumber class]] ||
        [obj isKindOfClass:[NSNull class]]) {
        return obj;
    }
    
    if ([obj isKindOfClass:[NSArray class]]) {
        NSMutableArray *array = [NSMutableArray array];
        for (id i in obj)
            [array addObject:CoerceJSONObject(i)];
        return array;
    }
    
    if ([obj isKindOfClass:[NSDictionary class]]) {
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        for (NSString *key in obj) {
            if (![key isKindOfClass:[NSString class]])
                NSLog(@"warning: dictionary keys should be strings. got: %@. coercing to: %@", [key class], [key description]);
            dict[key.description] = CoerceJSONObject(obj[key]);
        }
        return dict;
    }
    
    // NSDate description is already a valid ISO8061 string
    if ([obj isKindOfClass:[NSDate class]])
        return [obj description];

    if ([obj isKindOfClass:[NSURL class]])
        return [obj absoluteString];
    
    // default to sending the object's description
    NSLog(@"warning: dictionary values should be valid json types. got: %@. coercing to: %@", [obj class], [obj description]);
    return [obj description];
}

static void AssertDictionaryTypes(id dict) {
    assert([dict isKindOfClass:[NSDictionary class]]);
    for (id key in dict) {
        assert([key isKindOfClass: [NSString class]]);
        id value = dict[key];
        
        assert([value isKindOfClass:[NSString class]] ||
               [value isKindOfClass:[NSNumber class]] ||
               [value isKindOfClass:[NSNull class]] ||
               [value isKindOfClass:[NSArray class]] ||
               [value isKindOfClass:[NSDictionary class]] ||
               [value isKindOfClass:[NSDate class]] ||
               [value isKindOfClass:[NSURL class]]);
    }
}

NSDictionary *CoerceDictionary(NSDictionary *dict) {
    // make sure that a new dictionary exists even if the input is null
    dict = dict ?: @{};
    // assert that the proper types are in the dictionary
    AssertDictionaryTypes(dict);
    // coerce urls, and dates to the proper format
    return CoerceJSONObject(dict);
}

