//
//  MainMenuScene.m
//
//  Copyright (c) 2013 Grantoo, LLC. All rights reserved.
//

#import "CCBReader.h"
#import "MainMenuScene.h"
#import "GamePayload.h"
#import "AppDelegate.h"
#import "GameHistory.h"
#import "SimpleAudioEngine.h"
//#import "Flurry.h"

@interface MainMenuScene () {
    CCLabelTTF          *challengeLabel;
    CCMenuItemImage    *soundOnButton;
    CCMenuItemImage    *soundOffButton;
}
- (BOOL)sendResult;
- (void)setSoundButtons;
@end

@implementation MainMenuScene

- (id)init {
	if (self = [super init]) {
        CCLOG(@"MainMenuScene::alloc");
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(receiveChallengeCount:)
                                                     name:@"PropellerSDKChallengeCountChanged"
                                                   object:nil];
	}
	return self;
}

-(void)dealloc {
    CCLOG(@"MainMenuScene::dealloc");
   [super dealloc];
}

- (void)onExit {
    CCLOG(@"MainMenuScene::onExit");
    [[NSNotificationCenter defaultCenter] removeObserver:self];//important!!!
    [super onExit];
}


- (void)onEnter {
    CCLOG(@"MainMenuScene::onEnter");
    [super onEnter];
    [self setSoundButtons];
    // check to see if we need to send the result.
    if (![self sendResult]) {
        // This will be called when going from game->mainmenu screen, so startup timer here.
        // When going from SDK webview->mainmenu we can't rely on this so we use the sdk delegate methods
        // to restart the timer.
        
        // Uncomment for Flurry
        //[Flurry logEvent:@"MainMenuSceneEntry"];
        
        [[SimpleAudioEngine sharedEngine] stopBackgroundMusic];
        [[SimpleAudioEngine sharedEngine] playBackgroundMusic:@"menuBGM.mp3" loop:NO];
        
        [self updateChallengeCount:0];
    }

    int currCount = [[PropellerSDK instance] getChallengeCounts];
    [self displayChallengeCount:currCount];
    [self schedule:@selector(updateChallengeCount:) interval:15];
}

- (void) goPlay:(id)sender
{
    CCLOG(@"goPlay calling stopNotification");
    // Load the game scene
    CCScene* gameScene = [CCBReader sceneWithNodeGraphFromFile:@"GameScene.ccbi"];
        
    // Go to the game scene
    [[CCDirector sharedDirector] replaceScene:gameScene];
}

- (void) goLaunch:(id)sender
{
    CCLOG(@"goLaunch calling stopNotification");
    // Uncomment for Flurry
    //[Flurry logEvent:@"SDKLaunch"];
    [self stopCocos];
    PropellerSDK *gSDK = [PropellerSDK instance];
    [gSDK launch:self];
}

- (void) goStats:(id)sender
{
    CCScene* scene = [CCBReader sceneWithNodeGraphFromFile:@"StatsScene.ccbi"];
    [[CCDirector sharedDirector] replaceScene:scene];
}

- (void) goRules:(id)sender
{
    CCScene* scene = [CCBReader sceneWithNodeGraphFromFile:@"HowToPlayScene.ccbi"];
    [[CCDirector sharedDirector] replaceScene:scene];
}

- (void) goFeedback:(id)sender
{
// Uncomment for Flurry
//    [Flurry logEvent:@"UserVoiceSelected"];
// Uncomment for UserVoice
//    AppController *app = (AppController*) [[UIApplication sharedApplication] delegate];
//    [UserVoice presentUserVoiceInterfaceForParentViewController:[app navController] andConfig:[app uvConfig]];
}

#pragma mark -
#pragma mark Private methods

- (void)receiveChallengeCount:(NSNotification *) notification
{
    if ([[notification name] isEqualToString:@"PropellerSDKChallengeCountChanged"]) {
        NSDictionary *userInfo = notification.userInfo;
        int count = [[userInfo objectForKey:@"count"] integerValue];
        [self displayChallengeCount:count];
    }
}

- (void)updateChallengeCount:(float) dt {
    [[PropellerSDK instance] syncChallengeCounts];
}

- (void)displayChallengeCount:(int) challengeCount {
    if (challengeCount > 0) {
        [challengeLabel.parent setVisible:YES];
        [challengeLabel setString:[NSString stringWithFormat:@"%d", challengeCount]];
    } else {
        [challengeLabel.parent setVisible:NO];
    }
}

- (void)stopCocos
{
    CCLOG(@"MainMenuScene::stopCocos");
    [[CCDirector sharedDirector] pause];
    [[CCDirector sharedDirector] stopAnimation];
}

- (void)startCocos
{
    CCLOG(@"MainMenuScene::startCocos");
    if ([[UIApplication sharedApplication] applicationState] == UIApplicationStateActive) {
        [[CCDirector sharedDirector] startAnimation];
        [[CCDirector sharedDirector] resume];
    }
}

- (BOOL)sendResult
{
    BOOL sentResult = NO;
    GamePayload *payLoad = [GamePayload instance];
    if (payLoad && payLoad.activeFlag && payLoad.completeFlag) {
        
        // Uncomment for Flurry
        //[Flurry logEvent:@"SDKLaunchWithMatch"];
        PropellerSDK *gSDK = [PropellerSDK instance];
        NSDictionary *matchResult = [[NSDictionary alloc] initWithObjectsAndKeys:
                                     payLoad.tournID, PSDK_MATCH_POST_TOURNAMENT_KEY,
                                     payLoad.matchID,PSDK_MATCH_POST_MATCH_KEY,
                                     [NSNumber numberWithInt:payLoad.score],PSDK_MATCH_POST_SCORE_KEY,
                                     nil];
        CCLOG(@"sendResult calling stopNotification");
        [self stopCocos];
        [[SimpleAudioEngine sharedEngine] stopBackgroundMusic];
        [[SimpleAudioEngine sharedEngine] playBackgroundMusic:@"outgameBGM.mp3" loop:NO];
        [gSDK launchWithMatchResult:matchResult delegate:self];
        [payLoad clear];
        [matchResult release];
        sentResult = YES;
    }
    return sentResult;
}

#pragma mark -
#pragma mark GrantooLibDelegate protocol methods

- (void)sdkCompletedWithExit {
    // Uncomment for Flurry
    //[Flurry logEvent:@"SDKCompletedWithExit"];
    [self startCocos];
    // just a regular exit ... go along with your business
    [[SimpleAudioEngine sharedEngine] stopBackgroundMusic];
    [[SimpleAudioEngine sharedEngine] playBackgroundMusic:@"menuBGM.mp3" loop:NO];
}

- (void)sdkCompletedWithMatch:(NSDictionary *)match {
    // Uncomment for Flurry
    //[Flurry logEvent:@"SDKCompletedWithMatch"];
    [self startCocos];
    // ended with a match ... should play the game
    // we are sending out a tournament token and a match token
    NSString *tournID = [match objectForKey:PSDK_MATCH_RESULT_TOURNAMENT_KEY];
    NSString *matchID = [match objectForKey:PSDK_MATCH_RESULT_MATCH_KEY];
    NSDictionary *params = [match objectForKey:PSDK_MATCH_RESULT_PARAMS_KEY];
    // create a game payload
    GamePayload *payLoad = [GamePayload instance];
    if (payLoad) {
        payLoad.tournID = tournID;
        payLoad.matchID = matchID;
        payLoad.params = params;
        payLoad.activeFlag = true;
        payLoad.completeFlag= false;
        
        [self goPlay:nil];
    }
}

- (void)sdkFailed:(NSDictionary *)result {
    // Uncomment for Flurry
    //[Flurry logEvent:@"SDKCompletedWithFail"];
    [self startCocos];
}

#pragma mark -
#pragma mark sound button functions

- (void) setSoundButtons
{
    float musicLevel = [[SimpleAudioEngine sharedEngine] backgroundMusicVolume];
    float sfxLevel = [[SimpleAudioEngine sharedEngine] effectsVolume];
    
    BOOL currentlyOn = true;
    
    if (musicLevel == 0.0f && sfxLevel == 0.0f) {
        currentlyOn = false;
    }
    
    if (currentlyOn) {
        [soundOnButton setVisible:true];
        [soundOffButton setVisible:false];
    } else {
        [soundOnButton setVisible:false];
        [soundOffButton setVisible:true];
    }
    
}

- (void) goSoundOff:(id)sender
{
    [[SimpleAudioEngine sharedEngine] setBackgroundMusicVolume:1.0f];
    [[SimpleAudioEngine sharedEngine] setEffectsVolume:1.0f];
    
    [self setSoundButtons];
}

- (void) goSoundOn:(id)sender
{
    [[SimpleAudioEngine sharedEngine] setBackgroundMusicVolume:0.0f];
    [[SimpleAudioEngine sharedEngine] setEffectsVolume:0.0f];
    
    [self setSoundButtons];
}


@end
