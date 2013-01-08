//
//  GamePayload.m
//
//  Copyright (c) 2013 Grantoo, LLC. All rights reserved.
//

#import "GamePayload.h"

@interface GamePayload (Private)
- (id)init;
- (void)reset;
- (void)storeGamePayload;
- (void)loadGamePayload;
@end

@implementation GamePayload

@synthesize tournID, matchID, params, score, completeFlag, activeFlag;

// This is a GrantooLib singleton class, see getInstance below
static GamePayload *instance = nil;
// Factory method to get singleton instance.
+ (GamePayload *) instance {
    @synchronized(self) {
        if (instance == nil) {
            instance = [[self alloc] init];
        }
        return instance;
    }
}

- (void)clear {
    [self reset];
    [self storeGamePayload];
}

- (void)store {
    [self storeGamePayload];
}


#pragma mark -
#pragma mark Private methods

// Made private to prevent accidental usage.
- (id)init {
	if (self = [super init]) {
        [self reset];
        [self loadGamePayload];
	}
	return self;
}

-(void) reset {
    tournID = nil;
    matchID = nil;
    params = nil;
    score = 0;
    completeFlag = false;
    activeFlag = false;
}

- (void)storeGamePayload {
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    [prefs setInteger:1 forKey:@"gamePayloadVersion"];
    [prefs setBool:completeFlag forKey:@"complete"];
    [prefs setInteger:activeFlag forKey:@"active"];
    [prefs setInteger:score forKey:@"sPayload"];
    [prefs setObject:params forKey:@"pPayload"];
    [prefs setObject:matchID forKey:@"mPayload"];
    [prefs setObject:tournID forKey:@"tPayload"];
    [prefs synchronize];
}

- (void)loadGamePayload {
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    int gameVersion = [prefs integerForKey:@"gamePayloadVersion"];
    if (gameVersion == 1) {
        completeFlag = [prefs boolForKey:@"complete"];
        activeFlag = [prefs boolForKey:@"active"];
        score = [prefs integerForKey:@"sPayload"];
        params = [prefs objectForKey:@"pPayload"];
        matchID = [prefs objectForKey:@"mPayload"];
        tournID = [prefs objectForKey:@"tPayload"];
    }
}

@end
