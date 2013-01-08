//
//  GrantooAPI.m
//
//  Copyright (c) 2013 Grantoo, LLC. All rights reserved.
//

#import "GrantooAPI.h"

NSString * const kChallengeURL = @"http://challenge-staging.grantoo.com/v1";
NSString * const kTournamentURL = @"https://staging.grantoo.com/api/v1";
NSString * const kGrantooURL = @"https://staging.grantoo.com/api/v1";

@interface GrantooAPI ()
{
    NSMutableData       *responseData_;
    NSURLConnection     *connection_;
    NSInvocation        *invoker_;
    
    BOOL                success_;
    
    BOOL                tokenRetryActive;
    NSDictionary        *lastSendData;
    
}

-(void)sendData:(NSString*)rtype url:(NSString*)url sdata:(NSString*)sdata;
-(void)sendData:(NSString*)rtype url:(NSString*)url sdata:(NSString*)sdata authenticate:(BOOL)authenticate;

-(void)prepareInvoker:(id)caller selector:(SEL)selector;
-(NSString *)addAuthentication:(NSString *)cdata;
-(BOOL)testForTokenFailure:(NSDictionary*)netResult;

-(void)tokenRetry;
-(void)tokenRetryComplete:(NSDictionary*)netResult;

@property (nonatomic, retain) NSString *grantooURL;
@property (nonatomic, retain) NSString *tournamentURL;
@property (nonatomic, retain) NSString *challengeURL;

@property (nonatomic, retain) NSString *gameID;
@property (nonatomic, retain) NSString *gameSecret;

@property (nonatomic, retain) NSString *userID;
@property (nonatomic, retain) NSString *userToken;

@end

@implementation GrantooAPI

static GrantooAPI *s_instance = nil;

#pragma mark -
#pragma mark Public static methods

+ (id)initWithGameID:(NSString*)gameID gameSecret:(NSString*)gameSecret
{
    return [self initWithGrantooURL:kGrantooURL tournamentURL:kTournamentURL challengeURL:kChallengeURL gameID:gameID gameSecret:gameSecret];
}

+ (id)initWithGrantooURL:(NSString*)grantooURL tournamentURL:(NSString*)tournamentURL challengeURL:(NSString *)challengeURL gameID:(NSString*)gameID gameSecret:(NSString*)gameSecret
{
    @synchronized(self) {
        if (s_instance == nil) {
            s_instance = [[self alloc] init];
        }
        
        [s_instance setGrantooURL:grantooURL];
        [s_instance setTournamentURL:tournamentURL];
        [s_instance setChallengeURL:challengeURL];
        [s_instance setGameID:gameID];
        [s_instance setGameSecret:gameSecret];
    }
    return s_instance;
}

// Factory method to get singleton instance.
+ (GrantooAPI *)instance {
    NSAssert(s_instance != nil, @"you must initialize the NetworkUtils first");
    return s_instance;
}

- (id)init {
    self = [super init];
    if(nil == self){
        return nil;
    }

    self.userToken = nil;
    self.userID = nil;
    self.gameSecret = nil;
    self.gameID = nil;
    self.grantooURL = nil;
    self.tournamentURL = nil;
    self.challengeURL = nil;
    
    invoker_ = nil;
    lastSendData = nil;
    connection_ = nil;
    responseData_ = nil;

    tokenRetryActive = NO;
    
    return self;
}

-(void)dealloc
{
    self.userToken = nil;
    self.userID = nil;
    self.gameSecret = nil;
    self.gameID = nil;
    self.grantooURL = nil;
    self.tournamentURL = nil;
    self.challengeURL = nil;
    
    [lastSendData release]; lastSendData = nil;
    [connection_ release]; connection_ = nil;
    [responseData_ release]; responseData_ = nil;
    [invoker_ release]; invoker_ = nil;
    [super dealloc];
}

-(void)setUser:(NSString *)userID userToken:(NSString *)userToken
{
    self.userID = userID;
    self.userToken = userToken;
}

-(void)prepareInvoker:(id)caller selector:(SEL)selector
{
    CCLOG(@"prepareInvoker");
    [invoker_ release]; invoker_ = nil;
    success_ = NO;
    
    if (caller != nil && selector != nil)
    {
        // invoker signature intended to be
        // -(void) method:(bool)suceeded (nsdictionary)result
        
        NSMethodSignature *sig = [[caller class] instanceMethodSignatureForSelector:selector];
        invoker_ = [[NSInvocation invocationWithMethodSignature:sig] retain];
        [invoker_ setTarget:caller];
        [invoker_ setSelector:selector];
    }
}

-(BOOL)isAvailable
{
    return (connection_ == nil && responseData_ == nil);
}

-(void)sendData:(NSString*)rtype url:(NSString*)url sdata:(NSString*)sdata
{
    [self sendData:rtype url:url sdata:sdata authenticate:true];
}

-(void)sendData:(NSString*)rtype url:(NSString*)url sdata:(NSString*)sdata authenticate:(BOOL)authenticate
{
    BOOL didSend = NO;
    if (connection_ == nil && responseData_ == nil)
    {
        if (!tokenRetryActive) {
            [lastSendData release]; lastSendData = nil;
            lastSendData = [[NSDictionary dictionaryWithObjectsAndKeys:
                             rtype, @"type",
                             url, @"url",
                             sdata, @"data",
                             invoker_, @"invoker",
                             [NSNumber numberWithBool:authenticate ], @"authenticate",
                             nil] retain];
        }
        
        if (authenticate) {
            sdata = [self addAuthentication:sdata];
        }
        
        if ([rtype isEqualToString:@"GET"] && sdata != nil) {
            url = [NSString stringWithFormat:@"%@?%@", url, sdata];
            sdata = nil;
        }
        
        NSURL *remoteURL = [NSURL URLWithString: url];
                
        //initialize a request from url
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[remoteURL standardizedURL]];
        //set http method
        [request setHTTPMethod:rtype];
        //set request content type we MUST set this value.
        [request setValue:@"application/x-www-form-urlencoded; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
        //set data of request
        if (sdata)
        {
            [request setHTTPBody:[sdata dataUsingEncoding:NSUTF8StringEncoding]];
        }
        
        //initialize a connection from request
        CCLOG(@"curl %@", url);
        CCLOG(@"cdata %@", sdata);

        CCLOG(@"creating connection");
        connection_ = [[NSURLConnection alloc] initWithRequest:request delegate:self];
        if(connection_)
        {
            responseData_ = [[NSMutableData data] retain];
            didSend = YES;
        }
    }
    else
    {
        NSAssert(false, @"connection and response not yet released");
    }
    if (!didSend)
    {
        CCLOG(@"send failed");
        // immediately call the invoker with a fail message
        if (invoker_)
        {
            NSMutableDictionary *result = nil;
            [invoker_ setArgument:&success_ atIndex:2];
            [invoker_ setArgument:&result atIndex:3];
            [invoker_ invoke];
        }

        [responseData_ release];
        responseData_ = nil;
        [connection_ release];
        connection_ = nil;    
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    CCLOG(@"didReceiveResponse");
    [responseData_ setLength:0];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    CCLOG(@"didReceiveData");
    [responseData_ appendData:data];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    // immediately call the invoker with a fail message
    CCLOG(@"didFailWithError");
    CCLOG(@"%@", error);
    if (invoker_)
    {
        NSMutableDictionary *result = nil;
        [invoker_ setArgument:&success_ atIndex:2];
        [invoker_ setArgument:&result atIndex:3];
        [invoker_ invoke];
    }
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    CCLOG(@"connectionDidFinishLoading");
    NSMutableDictionary *json = nil;
    if (responseData_ != nil)
    {
        NSError* error = nil;
        json = [NSJSONSerialization JSONObjectWithData:responseData_ options:kNilOptions error:&error];
        if (error)
        {
            CCLOG(@" error = %@", error);
            json = nil;
        }
        else
        {
            CCLOG(@"result = %@", json);
            success_ = YES;
        }
    }

    if ([self testForTokenFailure:json] == NO && invoker_)
    {
        [invoker_ setArgument:&success_ atIndex:2];
        [invoker_ setArgument:&json atIndex:3];
        [invoker_ invoke];
    }

    [responseData_ release];
    responseData_ = nil;
    [connection_ release];
    connection_ = nil;
}

-(BOOL) testForTokenFailure:(NSDictionary*)netResult
{
    BOOL failure = NO;
    
    BOOL success = [[netResult objectForKey:@"success"] boolValue];
    NSString *errorcode = [netResult objectForKey:@"errorcode"];
    if ( success == NO && [errorcode isEqualToString:@"INVALID_TOKEN"]){
        // we need to retry the token
        [self tokenRetry];
        failure = YES;
    } else if (tokenRetryActive) {
        [self tokenRetryComplete:netResult];
        failure = YES;
    }
    
    return failure;
}

-(void)tokenRetry
{
    tokenRetryActive = YES;
    [self requestToken:nil selector:nil];
}

-(void)tokenRetryComplete:(NSDictionary*)netResult
{
    // set our userToken
    NSDictionary *result = [netResult objectForKey:@"result"];
    self.userToken = [result objectForKey:@"token"];
    tokenRetryActive = NO;
    if (invoker_) {
        [invoker_ release]; invoker_ = nil;
    }
    invoker_ = [[lastSendData objectForKey:@"invoker"] retain];
    [self sendData:[lastSendData objectForKey:@"type"] url:[lastSendData objectForKey:@"url"] sdata:[lastSendData objectForKey:@"sdata"] authenticate:[[lastSendData objectForKey:@"sdata"] boolValue]];
}

-(void)requestToken:(id)caller selector:(SEL)selector
{
    // get a token for the current game with the current secret
    CCLOG(@"request token started");
    [self prepareInvoker:caller selector:selector];
    
    NSString *curl = [NSString stringWithFormat:@"%@/games/", self.grantooURL];
    NSString *cdata = [NSString stringWithFormat:@"pid=%@&gid=%@&secret=%@&oldToken=%@",
                       self.userID, self.gameID, self.gameSecret, self.userToken];
    [self sendData:@"POST" url:curl sdata:cdata];
}

-(void)requestTournamentList:(NSString*)type page:(int)page caller:(id)caller selector:(SEL)selector
{
    CCLOG(@"sync tournament list started");
    [self prepareInvoker:caller selector:selector];
    
    NSString *curl = [NSString stringWithFormat:@"%@/games/%@/tournaments/", self.tournamentURL, self.gameID];
    NSString *cdata = [NSString stringWithFormat:@"pid=%@&show=%@&page=%d", self.userID, type, page];
    [self sendData:@"GET" url:curl sdata:cdata];
}

-(void)requestChallengeCounts:(NSArray *)tournamentIDs filter:(NSDictionary *)filter caller:(id)caller selector:(SEL)selector;
{
    CCLOG(@"requestChallengeCount started");
    
    [self prepareInvoker:caller selector:selector];
    
    NSString *curl = [NSString stringWithFormat:@"%@/games/%@/groups/count/", self.challengeURL, self.gameID];
    NSError* error = nil;
    
    NSData* jsonData = [NSJSONSerialization dataWithJSONObject:tournamentIDs options:kNilOptions error:&error];
    NSString *tournamentString = [[[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding] autorelease];

    NSData* jsonData2 = [NSJSONSerialization dataWithJSONObject:filter options:kNilOptions error:&error];
    NSString *filterString = [[[NSString alloc] initWithData:jsonData2 encoding:NSUTF8StringEncoding] autorelease];
    
    NSString *cdata = [NSString stringWithFormat:@"pid=%@&filter=%@&glist=%@", self.userID, filterString, tournamentString];
    [self sendData:@"POST" url:curl sdata:cdata];
}

-(NSString *)addAuthentication:(NSString *)cdata {
    NSString *newString = @"";
    if (cdata != nil && [cdata length] > 0) {
        newString = [NSString stringWithFormat:@"%@&", cdata];
    }
    newString = [NSString stringWithFormat:@"%@authuser=%@&authgame=%@&authtoken=%@", newString, self.userID, self.gameID, self.userToken];
    return newString;
}



@end