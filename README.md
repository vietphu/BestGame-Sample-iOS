How to add the PropellerSDK to your iOS app:
============================================

Overview
--------

The propeller SDK allows you to add rich online and social features to
your app without you having to write any networking code. Users can
connect with one another, create challenges and join tournaments.

 

![](https://raw.github.com/Grantoo/BestGame-Sample-iOS/master/readme_image_files/image002.png)
![](https://raw.github.com/Grantoo/BestGame-Sample-iOS/master/readme_image_files/image004.png)
  


 **Note** that the propeller SDK is currently only available for iOS
devices and is presented in a landscape format. New features, platforms
and orientations are being added regularly (and almost of them will not
require a new SDK or 1<sup>st</sup> party submission).

Installation
------------

- Download the latest build of the SDK

- Drag the libPropellerSDK.a & the PropellerSDK.h into your
project

- Make sure the library is added to your target (check the Add to
Target box).

- Add –ObjC to your Other Linker Flags in your build settings if
required (this may be needed for older versions of XCode)

Obtain Key and Secret
---------------------

- Talk to your Grantoo developer support contact to receive your
game key and game secret.

**Note** that the key you receive will be for our staging test environment only. When you are ready for pushing your product onto production you will receive another key and secret for our production environment.

SDK Integration
---------------

Now you are ready to implement the propeller SDK within your code. The
PropellerSDK needs to be initialized (ideally in your appDelegate) which
sets up the information required to connect to our servers. Then you
will implement some calls to launch the SDK and the delegate, which will
respond to the SDK.

### Configuration

Initialize the PropellerSDK with the following call (ideally at the
start of your app in the appDelegate’s didFinishLaunchingWithOptions
method):

    [PropellerSDK initializeWithGameID:gameId gameSecret:gameSecret gameOrientation:gameOrientation sdkURL:sdkURL];

 The gameId and gameSecret should be the strings you were provided with
in the section Obtain Key and Secret. The sdkUrl should be:

    @"https://staging.grantoo.com/sdk"
    
 Note that when you are ready for production you can drop the sdkURL
parameter as the SDK will automatically default to our production
servers. i.e.:

    [PropellerSDK initializeWithGameID:gameId gameSecret:gameSecret gameOrientation:gameOrientation];

### Invocation

To execute the PropellerSDK you need to call one of the Launch functions
and supply a delegate that will respond to one of the SDK responses when
it exits.

Generally you would execute the basic launch call in response to a
button press (such as a “multiplayer” button). You would execute a
launchWithMatchResult after you have completed a game and wanted to post
a score with the given tournamentID and matchID tokens you were given.

Here are some code fragments that illustrate how to launch and deal with
SDK responses:

Responding to a “multiplayer button press” to launch the SDK.

    (void)goLaunch:(id)sender    {        PropellerSDK *gSDK = [PropellerSDK instance];        [gSDK launch:self];    }

Once the player has completed using the SDK you will get one of three
responses. If you receive an sdkCompletedWithMatch response you will be
expected to launch the SDK with a result using that token
(tournamentID+matchID) at a later time.

    (void)sdkCompletedWithExit 
    {        // sdk completed with nofurther action    }     (void)sdkFailed:(NSDictionary *)result     {        // sdk failed (alert box will have been displayed)    }    (void)sdkCompletedWithMatch:(NSDictionary *)match 
    {        // ended with a match, extract details from dictionary        NSString *tournID = [match objectForKey:PSDK_MATCH_RESULT_TOURNAMENT_KEY];        NSString *matchID = [match objectForKey:PSDK_MATCH_RESULT_MATCH_KEY];        NSDictionary *params = [match objectForKey:PSDK_MATCH_RESULT_PARAMS_KEY];        // now that you have the token (a tournamentID and matchID         // combination) … play the game and return result with token        [self goPlay:nil]; // this is your function    }
 
 After completing the match the SDK should be re-launched with score and
a launchWithMatchResult call:

    (void)sendResult:(int)score    {        NSDictionary *matchResult =         [[NSDictionary alloc] initWithObjectsAndKeys:        tournID, PSDK_MATCH_POST_TOURNAMENT_KEY,         matchID, PSDK_MATCH_POST_MATCH_KEY,        [NSNumber numberWithInt:score], PSDK_MATCH_POST_SCORE_KEY,         nil];
        PropellerSDK *gSDK = [PropellerSDK instance];        [gSDK launchWithMatchResult:matchResult delegate:self];        [matchResult release];     }

Advanced API Integration
------------------------

It is also possible to communicate directly with the GrantooAPI which
lives behind the PropellerSDK. This allows a game developer to create
greater integration with information about the games, tournaments and players in our system.  The GrantooAPI is a webservice that allows communication if you have
appropriate access to the information. Access is unlimited on some API calls (i.e. open) but most calls require you to make calls on behalf of a user. To make these calls you require a userID and a userToken. You are able to query the propellerSDK for the current logged in users ID and Token. Note that the token, however, is time limited and you may need to request a new Token should a call fail with an INVALID_TOKEN message.

The following call can be made to the PropellerSDK to retrieve the
current users ID and Token. If there is no player currently logged in
the information returned will be NULL.

    NSDictionary *userDetails = [[PropellerSDK instance] getUserDetails];    NSString *playerId = [userDetails objectForKey:@"userID"];    NSString *playerToken = [userDetails objectForKey:@"userToken"];

Once you have the Id and Token you may make web service calls to the API
to get information such as the number of outstanding challenges or the
list of active tournaments. Additional code examples can be made
available to those wishing to implement these features.

 
