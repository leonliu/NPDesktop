//
//  Profiler.m
//  NPDesktop
//
//  Created by leon@github on 4/2/13.
//  Copyright (c) 2013 leon@github. All rights reserved.
//

#import "Profiler.h"
#import <QuartzCore/QuartzCore.h>

@implementation TimeProfileRecord

@synthesize last;
@synthesize current;
@synthesize total;
@synthesize average;
@synthesize count;
@synthesize name;

- (id)init
{
    if ((self = [super init])) {
        last = CACurrentMediaTime();
        current = CACurrentMediaTime();
        total = 0.f;
        average = 0.f;
        count = 0;
        name = @"TimeRecord";
        
        _firstUpdate = YES;
    }
    
    return self;
}

- (void)reset
{
    _firstUpdate = YES;
    
    last = CACurrentMediaTime();
    current = CACurrentMediaTime();
    total = 0.f;
    average = 0.f;
    count = 0;
}

- (void)update
{
    count++;
    
    last = current;
    current = CACurrentMediaTime();
    
    if (!_firstUpdate) {
        double dt = fabs(current - last);
        total += dt;
        average = total/count;
    } else {
        _firstUpdate = NO;
    }
}

@end

static Profiler *_instance = nil;

@implementation Profiler

+ (Profiler *)sharedInstance
{
    @synchronized(self) {
        if (!_instance) {
            _instance = [[self alloc] init];
        }
    }
    
    return _instance;
}

- (id)init
{
    if ((self = [super init])) {
        _timeRecords = [[NSMutableDictionary alloc] init];
    }
    
    return self;
}

- (BOOL)addEntry:(NSString *)name
{
    if (!name || [_timeRecords objectForKey:name]) {
        return NO;
    }
    
    TimeProfileRecord *entry = [[TimeProfileRecord alloc] init];
    [_timeRecords setObject:entry forKey:name];
    
    return YES;
}

- (BOOL)notch:(NSString *)name
{
    // to save time do not check the name and if entry exists for name
    TimeProfileRecord *entry = [_timeRecords objectForKey:name];
    [entry update];
    
    return YES;
}

- (BOOL)reset:(NSString *)name
{
    TimeProfileRecord *entry = [_timeRecords objectForKey:name];
    [entry reset];
    
    return YES;
}

- (BOOL)removeEntry:(NSString *)name
{
    if (!name) {
        return NO;
    }
    
    [_timeRecords removeObjectForKey:name];
    return YES;
}

@end
