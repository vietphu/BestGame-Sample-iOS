//
//  ChallengeCountNotifier.h
//
//  Copyright (c) 2013 Grantoo, LLC. All rights reserved.
//
//  Instructions for use:
//
//  1. Call initWithNotificationInterval:... method to initialize the notifier singleton.
//  2. Access the notifier through the instance method.
//  3. Call start to get the notifier to poll the Challenge api.
//  4. Subscribe to the notification: ChallengeCountNotification.
//  5. To stop the notifier from polling the webservice, call stop. This will also stop notifications. The notifier
//     can be started up again by calling start.
//

#import <Foundation/Foundation.h>

#define CHALLENGE_COUNT_NOTIFICATION @"ChallengeCountNotification"

@interface ChallengeCountNotifier : NSObject

+ (ChallengeCountNotifier *)instance;

+ (id)init;
+ (id)initWithNotificationInterval:(int)notificationInterval;

- (void)start:playerId token:playerToken;
- (void)stop;

@property (nonatomic, readonly) int count;

@end
