window.auth = function(key, theWindow){
    var value = key.substring(key.indexOf("=")+1, key.length);

     var accessKeyCookie = [[CPCookie alloc] initWithName:@"github.access_token"];
            [accessKeyCookie setValue:encodeURIComponent(value)
                              expires:[CPDate dateWithTimeIntervalSinceNow:31536000]
                               domain:nil];

    [[[controller loginController] chromeBugTimer] invalidate];
    theWindow.close();

    var controller = [GithubAPIController sharedController];
    [controller setOauthAccessToken:value];
    [controller authenticateWithCallback:nil];
}

@implementation OAuthController : CPObject
{
    CPTimer chromeBugTimer @accessors;
    Function chromeBugCallback;
    DOMWindow chromeBugWindowRef;
}
- (void)init
{
    self = [super init];

    if (self)
    {
        var clientID = "c775a44a08cffa50eba3",
            redirectURL = "http://githubissues.heroku.com/getAccessToken/",
            url = "https://github.com/login/oauth/authorize?scope=repo&client_id="+clientID+"&redirect_uri="+redirectURL;


        // callback uses a blank url to regain reference... 
        //chromeBugCallback = function() {
        //    chromeBugWindowRef = window.open("", "IssuesOAuth");

        //    if(chromeBugWindowRef && chromeBugWindowRef.sendAuth)
        //        chromeBugWindowRef.sendAuth();
        //}

        //chromeBugTimer = [CPTimer scheduledTimerWithTimeInterval:1 callback:chromeBugCallback repeats:YES];

        // first
        chromeBugWindowRef = window.open(url, "IssuesOAuth", "menubar=no,location=no,resizable=yes,scrollbars=no,status=no,left= 10,top=10,width=980,height=600");

        //[chromeBugTimer invalidate];
    }

    return self;
}

@end