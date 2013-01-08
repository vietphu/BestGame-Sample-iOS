//
//  GrantooAPI.h
//
//  Copyright (c) 2013 Grantoo, LLC. All rights reserved.
//

#import "cocos2d.h"

NSString * const kChallengeURL;
NSString * const kTournamentURL;
NSString * const kGrantooURL;

@interface GrantooAPI : NSObject<NSURLConnectionDelegate> {
}

+ (GrantooAPI *)instance;

+ (id)initWithGameID:(NSString*)gameID gameSecret:(NSString*)gameSecret;
+ (id)initWithGrantooURL:(NSString*)grantooURL tournamentURL:(NSString*)tournamentURL challengeURL:(NSString *)challengeURL gameID:(NSString*)gameID gameSecret:(NSString*)gameSecret;

-(void)requestToken:(id)caller selector:(SEL)selector;
-(void)requestTournamentList:(NSString*)type page:(int)page caller:(id)caller selector:(SEL)selector;
-(void)requestChallengeCounts:(NSArray *)tournamentIDs filter:(NSDictionary *)filter caller:(id)caller selector:(SEL)selector;
-(void)setUser:(NSString *)userID userToken:(NSString *)userToken;
-(BOOL)isAvailable;


@end

