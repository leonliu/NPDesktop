//
//  Profiler.h
//  NPDesktop
//
//  Created by leon@github on 4/2/13.
//  Copyright (c) 2013 leon@github. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TimeProfileRecord : NSObject
{
    BOOL _firstUpdate;
}

@property double last;
@property double current;
@property double average;
@property double total;
@property double count;
@property NSString *name;

- (void)reset;
- (void)update;

@end

@interface Profiler : NSObject
{
    NSMutableDictionary *_timeRecords;
}

+ (Profiler *)sharedInstance;

- (BOOL)addEntry:(NSString *)name;
- (BOOL)notch:(NSString *)name;
- (BOOL)reset:(NSString *)name;
- (BOOL)removeEntry:(NSString *)name;

@end
