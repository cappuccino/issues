@implementation PullRequestWindowController : CPWindowController
{
    @outlet DiffView diffViewer;

    @outlet CPTextField authorField;
    @outlet CPTextField dateField;
    @outlet CPTextField descriptionField;
    @outlet CPImageView userAvatar;

    @outlet CPTextField authorLabel;
    @outlet CPTextField dateLabel;
    @outlet CPTextField descriptionLabel;

    CPString defferedDiffString;
}

- (void)awakeFromCib
{
    [diffViewer setFrameLoadDelegate:self];
    [descriptionField setLineBreakMode:CPLineBreakByWordWrapping];
}

- (void)webView:(CPWebView)aWebView didFinishLoadForFrame:(id)aFrame
{
    if (differedDiffString)
        [diffViewer DOMWindow].showDiff(differedDiffString);

    differedDiffString = nil;
}

- (void)setPullRequest:(JSObject)aRequest
{
    var request = new CFHTTPRequest();
    request.open("GET", aRequest.diff_url, true);

    request.oncomplete = function()
    {
        if (request.success())
        {
            [diffViewer loadHTMLString:DiffViewHTML];
            differedDiffString = request.responseText();
        }
        else
        {
            alert("failed to download diff");
        }
    }

    request.send("");
console.log(aRequest);
    [authorField setStringValue:aRequest.user.login];
//    [dateField setStringValue:[CPDate simpleDate:aRequest.created_at]]
    [descriptionField setStringValue:aRequest.body];

    [descriptionField sizeToFit];

//    var maxY = CGRectGetMaxY([descriptionField frame]);

    var url = "http://www.gravatar.com/avatar/" + aRequest.user.gravatar_id + "?s=100&d=identicon";

    [userAvatar setImage:[[CPImage alloc] initWithContentsOfFile:url]];
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
}

@end

var DiffViewHTML = "";

@implementation DiffView : CPWebView
{
    
}

+ (void)initialize
{
        //load template
    var request = new CFHTTPRequest();
    request.open("GET", "Resources/DiffView.html", true);

    request.oncomplete = function()
    {
        if (request.success())
            DiffViewHTML = request.responseText();
    }

    request.send("");
}

@end