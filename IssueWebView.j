@import <AppKit/CPWebView.j>
@import "markdown.js"
@import "mustache.js"

var IssuesHTMLTemplate = nil;

@implementation IssueWebView : CPWebView
{
    id issue @accessors;
    id repo @accessors;

    CGRect scrollRect;
}

+ (void)initialize
{
        //load template
    var request = new CFHTTPRequest();
    request.open("GET", "Resources/Issue.html", true);

    request.oncomplete = function()
    {
        if (request.success())
            IssuesHTMLTemplate = request.responseText();
    }

    request.send("");
}

- (void)awakeFromCib
{
    [self _init];
}

- (void)_init
{
    [[CPNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(issueChanged:)
                                                 name:GitHubAPIIssueDidChangeNotification
                                               object:nil];

    [self setFrameLoadDelegate:self];
    [self setDrawsBackground:YES];
}

- (id)initWithFrame:(CGRect)aFrame
{
    if (self = [super initWithFrame:aFrame])
    {
        [self _init];
    }

    return self;
}

- (void)windowWillClose:(id)sender
{
    [[CPNotificationCenter defaultCenter] removeObserver:self];
}

- (void)loadIssue
{
    scrollRect = nil;

    if (![issue objectForKey:"body_html"])
    {
        [issue setObject:Markdown.makeHtml([issue objectForKey:"body"] || "") forKey:"body_html"];
        [issue setObject:[CPDate simpleDate:[issue objectForKey:"created_at"]] forKey:"human_readable_created_date"];
        [issue setObject:[CPDate simpleDate:[issue objectForKey:"updated_at"]] forKey:"human_readable_updated_date"];
        [issue setObject:([issue objectForKey:"labels"] || []).join(", ") forKey:"comma_separated_tags"];
        [issue setObject:repo.identifier forKey:@"repo_identifier"];

        [[GithubAPIController sharedController] loadCommentsForIssue:issue repository:repo callback:function()
        {
            var comments = [issue objectForKey:"all_comments"];
            for (var i = 0, count = [comments count]; i < count; i++)
            {
                var comment = comments[i];
                comment.body_html = Markdown.makeHtml(comment.body || "");
                comment.human_readable_date = [CPDate simpleDate:comment.created_at];
            }

            var jsItem = [issue toJSObject],
                html = Mustache.to_html(IssuesHTMLTemplate, jsItem);

                [self loadHTMLString:html];
        }];
    }
    else
    {
        var jsItem = [issue toJSObject],
            html = Mustache.to_html(IssuesHTMLTemplate, jsItem);

            [self loadHTMLString:html];
    }
}

- (void)issueChanged:(CPNotification)aNote
{
    if ([aNote object] === issue)
    {
        var rect = [_frameView visibleRect];
        [self loadIssue];
        scrollRect = rect;
    }    
}

- (void)setDrawsBackground:(BOOL)drawsBackground
{
    if (drawsBackground)
    {
        _iframe.style.backgroundColor = "rgb(237, 241, 244)";
        _iframe.style.backgroundImage = "-webkit-gradient(linear, left top, left bottom, from(rgb(222, 226, 229)), to(rgb(237, 241, 244)))";
    }
    else
    {
        _iframe.style.backgroundColor = "";
        _iframe.style.backgroundImage = "";
    }
}

- (void)webView:(CPWebView)aWebView didFinishLoadForFrame:(id)aFrame
{
    // add in references so that commenting will work.
    var domWindow = [self DOMWindow];

    domWindow.REPO = repo;
    domWindow.ISSUE = issue;
    domWindow.STATE = [issue objectForKey:"state"];
    domWindow.GitHubAPI = window.GitHubAPI;

    if (scrollRect)
        [_frameView scrollRectToVisible:scrollRect];
}

@end
