//
//  PropellerSDK.h
//  libPropellerSDK
//
//  Copyright (c) 2012 Grantoo. All rights reserved.
//
// PropellerSDK is implemented as a singleton that is accessible
// via an static instance factory method. One may use this class
// to setup an easy Grantoo integration by simply following these
// ordered steps:
//
// 1.) Call the initialize: method with the appropriate start-up params
// 2.) Call the instance method to get a reference to the singleton instance
//     of this class.
// 3.) Call any of the instance methods for the function needed.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef enum {
    kPropelSDKPortrait,
    kPropelSDKLandscape
} PropelSDKGameOrientation;

@protocol PropellerSDKDelegate <NSObject>

@required

- (void)sdkCompletedWithExit;
- (void)sdkCompletedWithMatch:(NSDictionary *)match;
- (void)sdkFailed:(NSDictionary *)result;

@end


#define PSDK_MATCH_RESULT_TOURNAMENT_KEY @"tournamentID"
#define PSDK_MATCH_RESULT_MATCH_KEY @"matchID"
#define PSDK_MATCH_RESULT_PARAMS_KEY @"params"
#define PSDK_MATCH_POST_TOURNAMENT_KEY @"tournamentID"
#define PSDK_MATCH_POST_MATCH_KEY @"matchID"
#define PSDK_MATCH_POST_SCORE_KEY @"score"

@interface PropellerSDK : NSObject
// Used to initialize the singleton instance with some
// kind of parameters.
+ (void)setRootViewController:(UIViewController *)rootViewController;
+ (void)useTestServers __deprecated;
+ (void)useSandbox;
+ (void)initialize:(NSString *)gameID gameSecret:(NSString *)gameSecret;
+ (void)setNotificationToken:(NSString *)token;
// Handle incoming push notification.
// bNewLaunch = YES if the push notification caused the app to launch
// bNewLaunch = NO if the push notification came in while the app is already active
// Returns YES if the notification was handled, NO otherwise.
+ (BOOL)handleRemoteNotification:(NSDictionary *)userInfo newLaunch:(BOOL)bNewLaunch;

// Returns YES if a Grantoo push notification came in and was stored by the SDK for the next launch of the SDK
// Returns NO if no push notification came in since the last time the SDK was launched
+ (BOOL)hasPendingRemoteNotification;

// setup functions that can be called on the created instance
- (void)setOrientation:(PropelSDKGameOrientation)orientation;

// Returns an instance of this class as a Singleton
+ (PropellerSDK *)instance;

// Displays the grantoo view by using the root view controller
// and pushing onto the navigation stack, if we have a UINavigationController
// at the root on iPhone or by presenting modally on iPhone or else by presenting
// as a modal form sheet on iPad.
- (BOOL)launch:(id<PropellerSDKDelegate>)delegate;
- (BOOL)launchWithTournament:(NSString *)tournamentID delegate:(id<PropellerSDKDelegate>)delegate;
- (BOOL)launchWithMatchResult:(NSDictionary *)matchResult delegate:(id<PropellerSDKDelegate>)delegate;

// Retrieves and returns the challenge counts for the current user
- (void)syncChallengeCounts;
- (int)getChallengeCounts;

- (NSDictionary *)getUserDetails;
@end
