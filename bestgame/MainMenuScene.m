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
#import "ChallengeCountNotifier.h"
#import "SimpleAudioEngine.h"
//#import "Flurry.h"

@interface MainMenuScene () {
    CCLabelTTF          *challengeLabel;
    CCMenuItemImage    *soundOnButton;
    CCMenuItemImage    *soundOffButton;
}
- (BOOL)sendResult;
- (void)startNotification;
- (void)stopNotification;
- (void)receiveChallengeCountNotification:(NSNotification *)notification;
- (void)setSoundButtons;
@end

@implementation MainMenuScene

- (id)init {
	if (self = [super init]) {
        CCLOG(@"MainMenuScene::alloc");
	}
	return self;
}

-(void)dealloc {
    CCLOG(@"MainMenuScene::dealloc");
   [super dealloc];
}

- (void)onExit {
    CCLOG(@"MainMenuScene::onExit");
    [self stopNotification];
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
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(receiveChallengeCountNotification:)
                                                     name:CHALLENGE_COUNT_NOTIFICATION
                                                   object:nil];
        
        CCLOG(@"onEnter: calling startNotification.");
        [self startNotification];
    }
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
    [self stopNotification];
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
    CCLOG(@"sdkCompletedWithExit calling startNotification");
    [self startNotification];
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
    else {
        [self startNotification];
    }
}

- (void)sdkFailed:(NSDictionary *)result {
    // Uncomment for Flurry
    //[Flurry logEvent:@"SDKCompletedWithFail"];
    [self startCocos];
    CCLOG(@"sdkFailed calling startNotification");
    [self startNotification];
}

#pragma mark -
#pragma mark Notifier Methods

- (void)startNotification {
    // Update the userDetails status and the playerId used
    // by the notifier object.
    NSDictionary *userDetails = [[PropellerSDK instance] getUserDetails];
    NSString *playerId = [userDetails objectForKey:@"userID"];
    NSString *playerToken = [userDetails objectForKey:@"userToken"];
    [challengeLabel.parent setVisible:false];
    if (playerId) {
        [[ChallengeCountNotifier instance] start:playerId token:playerToken];
    }
}

- (void)stopNotification {
    [[ChallengeCountNotifier instance] stop];
}

- (void)receiveChallengeCountNotification:(NSNotification *)notification {
    
    if ([[notification name] isEqualToString:CHALLENGE_COUNT_NOTIFICATION]) {
        CCLOG (@"Successfully received the %@ notification!", CHALLENGE_COUNT_NOTIFICATION);
        
        int challengeCount = [(ChallengeCountNotifier *)[notification object] count];
        
        if (challengeCount > 0) {
            [challengeLabel.parent setVisible:true];
            [challengeLabel setString:[NSString stringWithFormat:@"%i", challengeCount]];
        } else {
            [challengeLabel.parent setVisible:false];
        }
    }
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
