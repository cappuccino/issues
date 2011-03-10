var SubmitHelpHTMLString;

@implementation SubmitHelpWindowController : CPWindowController
{
    @outlet CPWebView helpWebView;
}

+ (void)initialize
{
        //load template
    var request = new CFHTTPRequest();
    request.open("GET", "Resources/SubmitHelp.html", true);

    request.oncomplete = function()
    {
        if (request.success())
            SubmitHelpHTMLString = request.responseText();
        [[CPNotificationCenter defaultCenter] postNotificationName:"SubmitHelpHTMLStringDidLoad"
                                                            object:SubmitHelpHTMLString
                                                          userInfo:nil];
    }

    request.send("");
}

- (void)loadWindow
{
    [super loadWindow];

    if ([CPPlatform isBrowser] && [CPPlatformWindow supportsMultipleInstances])
    {
        var platformWindow = [[CPPlatformWindow alloc] initWithContentRect:[[self window] frame]];
        [[self window] setFullBridge:YES];
        [[self window] setPlatformWindow:platformWindow];
    }

    if (!SubmitHelpHTMLString)
            [[CPNotificationCenter defaultCenter] addObserver:self selector:@selector(_loadString:) name:"SubmitHelpHTMLStringDidLoad" object:nil];
    else
        [self _loadString:nil];
}

- (void)_loadString:(CPNotification)aNote
{
    // give the iframe a chance to set up... :(
    window.setTimeout(function(){
        [helpWebView loadHTMLString:SubmitHelpHTMLString];
        [[CPNotificationCenter defaultCenter] removeObserver:self];
    },0);
}

@end