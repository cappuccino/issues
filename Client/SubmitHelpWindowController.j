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

- (void)windowDidLoad
{
    if ([CPPlatform isBrowser] && [CPPlatformWindow supportsMultipleInstances])
    {
        var platformWindow = [[CPPlatformWindow alloc] initWithContentRect:CGRectMake(200, 50, 630, 550)];
        [[self window] setFullBridge:YES];
        [[self window] setPlatformWindow:platformWindow];
    }

    if (!SubmitHelpHTMLString)
            [[CPNotificationCenter defaultCenter] addObserver:self selector:@selector(_loadString:) name:"SubmitHelpHTMLStringDidLoad" object:nil];
    else
        [helpWebView loadHTMLString:SubmitHelpHTMLString];
}

- (void)_loadString:(CPNotification)aNote
{
    [helpWebView loadHTMLString:[aNote object]];
    [[CPNotificationCenter defaultCenter] removeObserver:self];
}

@end