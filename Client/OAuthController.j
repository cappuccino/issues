window.auth = function(key, theWindow){
    var value = key.substring(key.indexOf("=")+1, key.length);

     var accessKeyCookie = [[CPCookie alloc] initWithName:@"github.access_token"];
            [accessKeyCookie setValue:encodeURIComponent(value)
                              expires:[CPDate dateWithTimeIntervalSinceNow:31536000]
                               domain:nil];

    [[[controller loginController] chromeBugTimer] invalidate];

    if (theWindow)
        theWindow.close();

    var controller = [GithubAPIController sharedController];
    [controller setOauthAccessToken:value];
    [controller authenticateWithCallback:nil];
    [CPApp abortModal];
    [[controller chromePINWindow]._window close];
}

@implementation OAuthController : CPObject
{
    CPTimer chromeBugTimer @accessors;
    Function chromeBugCallback;
    DOMWindow chromeBugWindowRef;

    CPWindow chromePINWindow @accessors;
    CPTextField chromePINField;
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

        chromePINWindow = [CPAlert alertWithMessageText:"If you are using Chrome you will be asked to paste a PIN in the text field below:" defaultButton:"Authenticate" alternateButton:"Cancel" otherButton:nil informativeTextWithFormat:nil];
        [chromePINWindow setDelegate:self];

        chromePINField = [[CPTextField alloc] initWithFrame:CGRectMake(0,0, 235, 28)];
        [chromePINField setEditable:YES];
        [chromePINField setBezeled:YES];

        [chromePINWindow setAccessoryView:chromePINField];

        [chromePINWindow runModal];

//        [[chromePINField window] makeFirstResponder:chromePINField];
        //[chromeBugTimer invalidate];
    }

    return self;
}

- (void)alertDidEnd:(id)sender returnCode:(int)returnCode
{
    // if the "Authenticate" button was clicked
    if (returnCode === 0)
    {
        var value = [chromePINField stringValue];
        if (!value)
            alert("You must enter a PIN to login.");
        else
            window.auth(value, nil);
    }
}

@end