//
//  ChallengeCountNotifier.m
//
//  Copyright (c) 2013 Grantoo, LLC. All rights reserved.
//

#import "ChallengeCountNotifier.h"
#import "GrantooAPI.h"

#define DEFAULT_TIMER_INTERVAL 25

@interface ChallengeCountNotifier () {
    NSString *m_playerId;
    NSTimer *m_myTimer;
    int m_timerInterval;
    
    BOOL m_active;
    
    NSMutableArray *m_activeTournaments;
}

- (void)timerTicked:(NSTimer*)timer;
- (void)retrieveTournamentList:(id)params;
- (void)retrieveChallengeCounts;

@property (nonatomic) int notificationInterval;
@property (nonatomic, retain) NSString *playerId;

@end

@implementation ChallengeCountNotifier

@synthesize notificationInterval=m_timerInterval, playerId=m_playerId;

// This is a GrantooLib singleton class, see getInstance below
static ChallengeCountNotifier *s_instance = nil;

#pragma mark -
#pragma mark Public static methods

+ (id)init
{
    return [self initWithNotificationInterval:0];
}

+ (id)initWithNotificationInterval:(int)notificationInterval
{
    @synchronized(self) {
        if (s_instance == nil) {
            s_instance = [[self alloc] init];
        }

        if (notificationInterval > 0) {
            [s_instance setNotificationInterval:notificationInterval];
        }
        else {
            [s_instance setNotificationInterval:DEFAULT_TIMER_INTERVAL];
        }
    }
    return s_instance;
}

// Factory method to get singleton instance.
+ (ChallengeCountNotifier *)instance {
    NSAssert(s_instance != nil, @"you must initialize the notifier first");
    return s_instance;
}

- (id)init {
    if (self = [super init]) {
        m_playerId = nil;
        m_activeTournaments = nil;
        m_active = NO;
    }
    return self;
}

- (void)dealloc {
    CCLOG(@"ChallengeCountNotifier:dealloc");
    
    m_active = NO;
    [m_activeTournaments release];
    m_activeTournaments = nil;
    [m_myTimer invalidate];
     m_myTimer = nil;
    [super dealloc];
}

- (void)start:playerId token:playerToken {
    CCLOG(@"ChallengeCountNotifier: startTimer");
    
    if (!m_active) {
        m_active = YES;

        m_playerId = playerId;
        [[GrantooAPI instance] setUser:playerId userToken:playerToken];
        
        // create timer on run loop
        m_myTimer = [NSTimer scheduledTimerWithTimeInterval:m_timerInterval target:self selector:@selector(timerTicked:) userInfo:nil repeats:YES];
        // call once quickly to get the information
        [self timerTicked:0];
    }
}

- (void)timerTicked:(NSTimer*)timer {
    if (m_active && [[GrantooAPI instance] isAvailable]) {
        // clear any existing active tournament list
        [m_activeTournaments release];
        m_activeTournaments = nil;
        m_activeTournaments = [[NSMutableArray alloc] init];
        [m_activeTournaments addObject:@"0"];   // add in the local tournament for full count
        [self retrieveTournamentList:[NSNumber numberWithInt:1]];
    }
}

- (void)stop {
    CCLOG(@"ChallengeCountNotifier: stopTimer");
    
    [m_myTimer invalidate];
    m_myTimer = nil;
    m_active = NO;
}

- (void)retrieveTournamentList:(id)params {
    if (m_active) {
        int page = [(NSNumber*)params integerValue];
        GrantooAPI *networkUtil = [GrantooAPI instance];
        [networkUtil requestTournamentList:@"current" page:page caller:self selector:@selector(requestTournamentListCallback:netResult:)];
    }
}

- (void)retrieveChallengeCounts {
    if (m_active) {
        GrantooAPI *networkUtil = [GrantooAPI instance];
        NSDictionary *filter = [NSDictionary dictionaryWithObjectsAndKeys:
                                [NSNumber numberWithBool:true], @"isTurn",
                                [NSNumber numberWithBool:true], @"open",
                                nil];
        [networkUtil requestChallengeCounts:m_activeTournaments filter:filter caller:self selector:@selector(requestChallengeCountsCallback:netResult:)];
    }
}


- (void)requestTournamentListCallback:(BOOL)netSuccess netResult:(NSDictionary*)netResult
{
    CCLOG(@"requestTournamentListCallback");
    if (netSuccess == NO)
    {
        CCLOG(@"syncTournamentCountCallback: Error.");
    }
    else if (netResult == nil || [[netResult objectForKey:@"success"] boolValue] == NO)
    {
        CCLOG(@"syncTournamentCountCallback: Error.");
    }
    else {
        NSArray *tournaments = [netResult objectForKey:@"result"];
        
        for (NSDictionary *tournament in tournaments) {
            [m_activeTournaments addObject:[tournament objectForKey:@"id"]];
        }
        
        int page = [[netResult objectForKey:@"page"] integerValue];
        int totalPages = [[netResult objectForKey:@"pages"] integerValue];
        if (page == totalPages) {
            [self performSelector:@selector(retrieveChallengeCounts) withObject:nil afterDelay:0];
        } else {
            [self performSelector:@selector(retrieveTournamentList) withObject:[NSNumber numberWithInt:page+1] afterDelay:0];
        }
    }
}

- (void)requestChallengeCountsCallback:(BOOL)netSuccess netResult:(NSDictionary*)netResult
{
     CCLOG(@"requestChallengeCountsCallback");
     if (netSuccess == NO)
     {
         CCLOG(@"syncChallengeCountCallback: Error.");
     }
     else if (netResult == nil || [[netResult objectForKey:@"success"] boolValue] == NO)
     {
         CCLOG(@"syncChallengeCountCallback: Error.");
     }
     else {
         NSArray *countsArray = [netResult objectForKey:@"result"];

         _count = 0;
         
         for (NSDictionary *tournamentCount in countsArray) {
             int count = [[tournamentCount objectForKey:@"count"] integerValue];
             CCLOG(@"Count = %d for %@", count, [tournamentCount objectForKey:@"gid"]);
             _count += count;
         }         
         // Post notification.
         [[NSNotificationCenter defaultCenter]
          postNotificationName:CHALLENGE_COUNT_NOTIFICATION
          object:self];
     }
}

@end
