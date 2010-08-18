@implementation OAuthController : CPObject
{
    DOMElement _DOMWindow;
    CPTimer    timer;
    int        counter;
}

- (void)go
{
    var clientID = "c775a44a08cffa50eba3",
        redirectURL = "http://10.0.1.9:8001/getAccessToken/";

    var url = "https://github.com/login/oauth/authorize?scope=repo&client_id="+clientID+"&redirect_uri="+redirectURL;

    _DOMWindow = window.open(url, "_blank", "menubar=no,location=no,resizable=yes,scrollbars=no,status=no,left= 10,top=10,width=980,height=600");

    [self runAuthCheckLoop];
}

- (void)runAuthCheckLoop
{
    counter = 0;
    timer = [CPTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(checkIsAuthenticated) userInfo:nil repeats:YES];
}

- (void)checkIsAuthenticated
{
    var value = [self popupContainsCookie:"github.access_token"];

    if (value)
    {
        // now set it with a CPCookie so we dont lose it...
        [timer invalidate];
        var accessKeyCookie = [[CPCookie alloc] initWithName:@"github.access_token"];
        [accessKeyCookie setValue:encodeURIComponent(value)
                          expires:[CPDate dateWithTimeIntervalSinceNow:31536000]
                           domain:nil];

        _DOMWindow.close();

        [[GithubAPIController sharedController] setOauthAccessToken:value];
        [[GithubAPIController sharedController] authenticateWithCallback:nil];
    }

    if (counter > 240)
    {
        [timer invalidate];

        if (_DOMWindow)
            _DOMWindow.close();
    }
}

- (CPString)popupContainsCookie:(CPString)aKey
{
    // first check to see if the authorization failed
    if (_DOMWindow && _DOMWindow.authFailed === true)
    {
        [timer invalidate];
        _DOMWindow.close();
    }

    if (_DOMWindow && _DOMWindow.document && _DOMWindow.document.cookie && _DOMWindow.document.cookie.length > 0)
    {
        var head = _DOMWindow.document.cookie.indexOf(aKey + "=");
        if (head !== CPNotFound)
        {
            head += aKey.length + 1;
            var tail = _DOMWindow.document.cookie.indexOf(";", head);

            if (tail === CPNotFound) tail = _DOMWindow.document.cookie.length;
                return unescape(_DOMWindow.document.cookie.substring(head, tail));
        }
    }

    return "";
}

@end