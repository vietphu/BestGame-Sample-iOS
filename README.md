How to add the PropellerSDK to your iOS app:
============================================

Overview
--------

The Propeller SDK allows you to add rich online and social features to
your app without you having to write any networking code. Users can
connect with one another, create challenges and join tournaments.



![](https://raw.github.com/Grantoo/BestGame-Sample-iOS/master/readme_image_files/image002.png)
![](https://raw.github.com/Grantoo/BestGame-Sample-iOS/master/readme_image_files/image004.png)
  


 **Note** This document is for the preview of our SDK version 2.0. New
features, platforms and orientations are being added regularly.

Installation
------------

- Download the latest build of the SDK

  [http://propellersdksite.herokuapp.com/developers](http://propellersdksite.herokuapp.com/developers)

- Drag the **libPropellerSDK.a** & the **PropellerSDK.h** into your
project

- Make sure the library is added to your target (check the **Add to
Target** box).

- Add **–ObjC** to your **Other Linker Flags** in your build settings if
required (this may be needed for older versions of XCode)

- Add the **AdSupport** framework to your project.

Obtain Key and Secret
---------------------

- Talk to your Grantoo developer support contact to receive your
game key and game secret.

**Note** that the key you receive will be for our staging test
environment only. When you are ready for pushing your product onto
production you will receive another key and secret for our production
environment

Basic Integration
-----------------

Now you are ready to implement the propeller SDK within your code. The
PropellerSDK needs to be initialized (ideally in your **AppDelegate**) which
sets up the information required to connect to our servers. Then you
will implement some calls to launch the SDK and the delegate, which will
respond to the SDK.

### Configuration

Add our header file to whichever files access the PropellerSDK:
 
    #import “PropellerSDK.h”

Initialize the PropellerSDK with the following call (ideally at the
start of your app in the **AppDelegate**’s **application:didFinishLaunchingWithOptions:**
method):
 
    [PropellerSDK useTestServers];    [PropellerSDK setRootViewController:navController_];    [PropellerSDK initialize:gameId gameSecret:gameSecret];    [[PropellerSDK instance] setOrientation:kPropelSDKLandscape]]
 
The first call to **useTestServers** will point you to the staging/test
environment. This call will be removed when you go to production.  In
the second call we set the **rootviewcontroller** the SDK will use to place
its interface off of. In the third call **gameId** and **gameSecret** should be
the strings you were provided with in the section **Obtain Key and
Secret** above.  When you move to production you will need a new
Id/Secret combination. The final call sets the orientation you wish to
launch the SDK with. For now landscape will be shown no matter what
value you have in here. However, portrait mode is coming soon and if you
indicate portrait the SDK will automatically use that feature when it is
available (without you having to resubmit your application).

### Invocation

To execute the PropellerSDK you need to call one of the **Launch** functions
and supply a delegate that will respond to one of the SDK responses when
it exits.

Generally you would execute the basic launch call in response to a
button press (such as a “multiplayer” button). You would execute a
**launchWithMatchResult:delegate:** method after you have completed a game and wanted
to post a score with the given **tournamentID** and **matchID** tokens you were
given.

Here are some code fragments that illustrate how to launch and deal with
SDK responses:

Responding to a “multiplayer button press” to launch the SDK.

    - (void)goLaunch:(id)sender    {    	[[PropellerSDK instance] launch:self];    }    
The parameter to the launch method specifies the delegate class which
implements the callbacks for the responses from the SDK. The interface
for the SDK should be added to that class. 

    @interface MyMenuLayer : CCLayer<PropellerSDKDelegate>

Once the player has completed using the SDK you will get one of three
responses. If you receive an **sdkCompletedWithMatch** response (in other
words, the **sdkCompletedWithMatch:** callback is called) you will be
expected to launch the SDK with a result using that token (**tournID** and
**matchID**) at a later time.

    - (void)sdkCompletedWithExit 
    {        // sdk completed with no further action    }     - (void)sdkFailed:(NSDictionary *)result     {        // sdk failed        // (alert box will have been displayed )    }    - (void)sdkCompletedWithMatch:(NSDictionary *)match     {        // sdk completed with a match        // extract details from dictionary        NSString *tournID = [match objectForKey:PSDK_MATCH_RESULT_TOURNAMENT_KEY];        NSString *matchID = [match objectForKey:PSDK_MATCH_RESULT_MATCH_KEY];        NSDictionary *params = [match objectForKey:PSDK_MATCH_RESULT_PARAMS_KEY];        // now that you have the token (a tournamentID and matchID        //combination) … play the game and return result with token        [self goPlay:nil]; // this is your function    }
 
After completing the match the SDK should be re-launched with score and
a **launchWithMatchResult:delegate:** call:

    - (void)sendResult:(int)score    {        NSDictionary *matchResult =             [[NSDictionary alloc] initWithObjectsAndKeys:            tournID, SDK_MATCH_POST_TOURNAMENT_KEY,            matchID,PSDK_MATCH_POST_MATCH_KEY,            [NSNumber numberWithInt:score],PSDK_MATCH_POST_SCORE_KEY,            nil]; 
		PropellerSDK *gSDK = [PropellerSDK instance];		[gSDK launchWithMatchResult:matchResult delegate:self];	    [matchResult release];	}

### Moving Data

Your game will have its own implementation around how scores are moved
between various parts of your system. In some cases it may be that the
data is not moved around at all (i.e. the score never leaves the game
scene).

To reduce integration footprint you may want to implement the sdk
delegate in a single location (possibly your main scene). In this case
you may need to keep the latest score in memory and pass this around.

To facilitate this you can use a small singleton class that contains the
last token information as well as the score when it is completed. This
class has the additional ability to save the score immediately on
completion of the level to avoid possible cheating techniques. This
class is called **GamePayload** and can be included in your code to
facilitate the movement of score data if needed. Ideally the **GamePayload**
is accessed in three key places. You may implement this differently in
your code.

1. When entering the screen/class which handles the launching and
responding to the PropellerSDK

		GamePayload *payLoad = [GamePayload instance];		if (payLoad && payLoad.activeFlag && payLoad.completeFlag)		{		    PropellerSDK *gSDK = [PropellerSDK instance];		    NSDictionary *matchResult = [[NSDictionary alloc]		        initWithObjectsAndKeys:payLoad.tournID, PSDK_MATCH_POST_TOURNAMENT_KEY,
		        payLoad.matchID, PSDK_MATCH_POST_MATCH_KEY,		        [NSNumber numberWithInt:payLoad.score],PSDK_MATCH_POST_SCORE_KEY,		        nil];
		    [gSDK launchWithMatchResult:matchResult delegate:self];		    [payLoad clear];		}

1. When receiving an **sdkCompletedWithMatch** response

	    NSString *tournID = [match 
	        objectForKey:PSDK_MATCH_RESULT_TOURNAMENT_KEY];	    NSString *matchID = [match 	        objectForKey:PSDK_MATCH_RESULT_MATCH_KEY];	    NSDictionary *params = [match 	        objectForKey:PSDK_MATCH_RESULT_PARAMS_KEY];
	    GamePayload *payLoad = [GamePayload instance];	    payLoad.tournID = tournID;	    payLoad.matchID = matchID;	    payLoad.params = params;	    payLoad.activeFlag = true;	    payLoad.completeFlag= false;

1. When completing the gameplay and producing a score

	    GamePayload *payLoad = [GamePayload instance];	    if (payLoad && payLoad.activeFlag)	    {	        payLoad.score = <score_to_post>;	        payLoad.completeFlag = true;	        [payLoad store];	        // now return to main screen	    }

Integrating Challenge Counts
============================

The number of open challenges for a logged in player is available even
when the SDK is not running in the foreground. There are two methods
available to get the challenge count so that you can display it in your
app/game. The SDK will not gather an updated challenge count unless
requested by the game.

To get the cached value from the last gather you call:

    int count = [[PropellerSDK instance] getChallengeCounts];

To gather a new value with the updated information call:

    [[PropellerSDK instance] syncChallengeCounts];

This call will gather the information from our servers if a current
player is logged in. If the number of challenges has changed since the
last gather for this player a notification is posted on the
**defaultCenter** with the event:

    PropellerSDKChallengeCountChanged

Below is some example code of how the notification can be ingested in
your app/game. You do not need to ingest this, however, and can simply
ask for a new value some time after the asynchronous gather call:

    - (id)init
    {        if (self = [super init]) 
        {
            [[NSNotificationCenter defaultCenter] addObserver:self 
                selector:@selector(receiveChallengeCount:)
                name:@"PropellerSDKChallengeCountChanged"
                object:nil];        }        return self;    }    - (void)onEnter
    {        [super onEnter];        if (![self sendResult])        {
            [self updateChallengeCount:0];        }        [self schedule:@selector(updateChallengeCount:) interval:15];    }    - (void)dealloc    {        [[NSNotificationCenter defaultCenter] removeObserver:self];        [super dealloc];    }    - (void)receiveChallengeCount:(NSNotification *)notification    {       if ([[notification name] isEqualToString:@"PropellerSDKChallengeCountChanged"])        {           NSDictionary *userInfo = notification.userInfo;           int count = [[userInfo objectForKey:@"count"] integerValue];       }    }    - (void)updateChallengeCount:(float)dt    {       [[PropellerSDK instance] syncChallengeCounts];    }

Integrating Push Notifications
==============================

Push notifications allow the users of your app/game to be notified on their devices challenge or tournament related events occur. 

**Note:** This feature will be available in the released version of the Propeller SDK 2.0. For further information please contact Grantoo developer support.

### Push Certificates

You must submit to Grantoo a push SSL certificate that you obtain
from Apple plus the private key associated with that SSL certificate. 
Export the two from your Keychain as a p12 file that is not password
protected.

 There are two different types of push certificates: development and
production. While you are debugging/testing your app, use the
development certificate from Apple. This development certificate will be
associated with your Staging  game id and be used with the staging
servers at Grantoo. When the time comes to publish your app to the
AppStore, you will have to submit to Grantoo a production push
certificate (with private key) and we will associate it with your
Production game id.

Helpful References:

- [http://stackoverflow.com/questions/6576660/apple-push-notifications-how-do-i-properly-export-my-cert](http://stackoverflow.com/questions/6576660/apple-push-notifications-how-do-i-properly-export-my-cert)

- [http://www.pushwoosh.com/programming-push-notification/iphone-configuration-guide/](http://www.pushwoosh.com/programming-push-notification/iphone-configuration-guide/)

- [https://docs.urbanairship.com/display/DOCS/Exporting+Your+Push+Notification+Key](https://docs.urbanairship.com/display/DOCS/Exporting+Your+Push+Notification+Key)

### Provisioning Profiles

Generate a new provisioning profile containing the push entitlement.
	
At the Apple Developer website generate and download a new provisioning
profile for your iOS app. You must download a new development
provisioning profile containing the push notification entitlement. These
provisioning profiles are only generated anew on the Apple website
whenever a device is added or deleted so you may have to remove and then
add the same device to get this to work. Once it’s downloaded to your
machine, double-click it to add it to your keychain.

Helpful References:
 
- [http://developer.apple.com/library/mac/ -
documentation/NetworkingInternet/Conceptual/RemoteNotificationsPG/ProvisioningDevelopment/ProvisioningDevelopment.html](http://developer.apple.com/library/mac/#documentation/NetworkingInternet/Conceptual/RemoteNotificationsPG/ProvisioningDevelopment/ProvisioningDevelopment.html)
 
- [http://stackoverflow.com/questions/10987102/how-to-fix-no-valid-aps-environment-entitlement-string-found-for-application](http://stackoverflow.com/questions/10987102/how-to-fix-no-valid-aps-environment-entitlement-string-found-for-application)
 
- [http://stackoverflow.com/questions/5681172/bundle-identifier-and-push-certificate-aps-environment-entitlement-error](http://stackoverflow.com/questions/5681172/bundle-identifier-and-push-certificate-aps-environment-entitlement-error)

### Device Registration

Your app must request a device token from Apple before push
notifications can be sent to it.  This request is usually made in your
**AppDelegate** method **application:didFinishLaunchingWithOptions:**.
	
	    - (BOOL)application:(UIApplication *)application
	    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions	    {	        // Other initialization code…	 	        [[UIApplication sharedApplication] registerForRemoteNotificationTypes:	            (UIRemoteNotificationTypeAlert |	             UIRemoteNotificationTypeBadge |	             UIRemoteNotificationTypeSound)];		        // Other initialization code…	    }	
When your app receives a response from Apple, one of two callback
methods will be called in your **AppDelegate**:
	
	    - (void)application:didRegisterForRemoteNotificationsWithDeviceToken:(NSData*)devToken	    - (void)application:didFailToRegisterForRemoteNotificationsWithError:(NSError*)err	
If the first callback is called, you will receive a device token that
you must register with the Propeller SDK in order for the app to get
notifications from Grantoo. If the second callback is called, then an
error has occurred with your request. So add the following code to your
**AppDelegate** to handle these two cases:

	    - (void)application:(UIApplication *)app
	    didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)devToken	    {	        NSString *deviceToken = [[devToken description] stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"<>"]];	        deviceToken = [deviceToken stringByReplacingOccurrencesOfString:@" " withString:@""];	        [PropellerSDK setNotificationToken:deviceToken];	    }		    - (void)application:(UIApplication *)app
	    didFailToRegisterForRemoteNotificationsWithError:(NSError *)err	    {	        NSString *str = [NSString stringWithFormat:@"Error: %@", err];	        NSLog(@"%@",str);	        [PropellerSDK setNotificationToken:nil];	    }

In both callback methods be sure to call the setNotificationToken:
method on the PropellerSDK class to pass the device token to the sdk.
The token must be stripped of the characters “<>” and space before it
is passed to that method. This is shown in the example. In the case of a
registration failure just pass nil to the method.

###Handling Push Notifications (Inactive App)

When the app handles a push notification it should call the
**handleNotification:** method on the PropellerSDK class. If the
notification is a Grantoo notification the method will return YES to
signal that it’s processed the notification, otherwise it will return
NO. You should check this result and handle the notification yourself if
the result is NO. Pass in YES to the newLaunch parameter. This push
handling code goes in the **application:didFinishLaunchingWithOptions:**
method in your **AppDelegate** class.

	- (BOOL)application:(UIApplication *)application
	didFinishLaunchingWithOptions:(NSDictionary *)launchOptions	{		 // Other initalization code…				 // Check if the app has been launched due to an incoming push notification.		NSDictionary *remoteNotificationDict = [launchOptions 		    objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey];		if (remoteNotificationDict) 
        {			 if (![PropellerSDK handleRemoteNotification:remoteNotificationDict			        newLaunch:YES]) 
             {				 // This is not a Grantoo notification, I should				 // handle it.			 }		 }
		  		 //	Other initialization code…	}

###Handling Push Notifications (Active App)
	
When the app handles a push notification it should call the
**handleNotification:** method on the PropellerSDK class. If the
notification is a Grantoo notification the method will return YES to
signal that it’s processed the notification, otherwise it will return
NO. You should check this result and handle the notification yourself if
the result is NO. Pass in NO to the newLaunch parameter. This push
notification handling code goes in the
**application:didReceiveRemoteNotification:** method in your **AppDelegate**
class.
	
	// Handle push notification coming in while the app is active or running in the background.	- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo	{
		if (![PropellerSDK handleRemoteNotification:userInfo newLaunch:NO])
		{
			// This is not a Grantoo notification, I should 			// handle it.
		}	}