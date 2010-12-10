window.auth = function(key, theWindow){
    var value = key.substring(key.indexOf("=")+1, key.length);

     var accessKeyCookie = [[CPCookie alloc] initWithName:@"github.access_token"];
            [accessKeyCookie setValue:encodeURIComponent(value)
                              expires:[CPDate dateWithTimeIntervalSinceNow:31536000]
                               domain:nil];

    theWindow.close();

    [[GithubAPIController sharedController] setOauthAccessToken:value];
    [[GithubAPIController sharedController] authenticateWithCallback:nil];
}

@implementation OAuthController : CPObject
- (void)init
{
    self = [super init];

    if (self)
    {
        var clientID = "c775a44a08cffa50eba3",
            redirectURL = "http://githubissues.heroku.com/getAccessToken/";

        var url = "https://github.com/login/oauth/authorize?scope=repo&client_id="+clientID+"&redirect_uri="+redirectURL;

        window.open(url, "_blank", "menubar=no,location=no,resizable=yes,scrollbars=no,status=no,left= 10,top=10,width=980,height=600");
    }

    return self;
}

@end