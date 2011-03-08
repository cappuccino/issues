
@import <AppKit/CPWindowController.j>

@implementation NewIssueWindowController : CPWindowController
{
    @outlet CPPopUpButton        selectedRepo;
    @outlet CPTextField          titleField;
    @outlet LPMultiLineTextField bodyField;
    @outlet CPTextField          bodyLabel;
    @outlet CPTextField          repoLabel;
    @outlet CPTextField          errorField;
    @outlet CPImageView          progressView;
    @outlet CPButton             okButton;
    @outlet CPButton             cancelButton;
    @outlet CPButton             previewButton;

    id delegate @accessors;
    BOOL shouldEdit @accessors;
    id selectedIssue @accessors;
}

- (void)awakeFromCib
{
    [bodyField setEditable:YES];
    [bodyField setEnabled:YES];

    [bodyLabel setAlignment:CPRightTextAlignment];
    [repoLabel setAlignment:CPRightTextAlignment];

    [bodyLabel setVerticalAlignment:CPCenterVerticalTextAlignment];
    [repoLabel setVerticalAlignment:CPCenterVerticalTextAlignment];
    [errorField setVerticalAlignment:CPCenterVerticalTextAlignment];
    [errorField setTextColor:[CPColor redColor]];
    [errorField setStringValue:""];
    [titleField sizeToFit];

    var box = [CPBox boxEnclosingView:bodyField];
    [box setBorderType:CPBezelBorder];
    [box setAutoresizingMask:CPViewWidthSizable|CPViewHeightSizable];

    [[self window] setShowsResizeIndicator:YES];
    [[[self window] contentView] setBackgroundColor:[CPColor colorWithWhite:244/255 alpha:1.0]];
    [[self window] setDelegate:self];

    if ([CPPlatform isBrowser] && [CPPlatformWindow supportsMultipleInstances])
    {
        var platformWindow = [[CPPlatformWindow alloc] initWithContentRect:CGRectMake(100, 100, 500, 450)];
        [[self window] setFullBridge:YES];
        [[self window] setPlatformWindow:platformWindow];

        // timeout here because we can't talk to the DOM window until we open it... 
        window.setTimeout(function(){
            platformWindow._DOMWindow.onbeforeunload = function() {
                if (delegate)
                    delegate._openIssueWindows--;
            }
        },0);
    }

    [bodyField setBackgroundColor:[CPColor whiteColor]];

    if (selectedIssue)
    {
        [bodyField setStringValue:[selectedIssue objectForKey:"body"]];
        [titleField setStringValue:[selectedIssue objectForKey:"title"]];
        [selectedRepo setEnabled:NO];
    }
}

- (void)setSelectedIssue:(id)anIssue
{
    selectedIssue = anIssue;

    [bodyField setStringValue:[selectedIssue objectForKey:"body"]];
    [titleField setStringValue:[selectedIssue objectForKey:"title"]];
    [selectedRepo setEnabled:NO];
}

- (void)setRepos:(CPArray)anArray
{
    [selectedRepo removeAllItems];

    for (var i = 0, count = anArray.length; i < count; i++)
    {
        var identifier = anArray[i].identifier;
        [selectedRepo addItemWithTitle:identifier];

        var item = [selectedRepo lastItem];
        [item setTag:anArray[i]];
    }
}

- (void)selectRepo:(id)aRepo
{
    var items = [selectedRepo itemArray],
        count = items.length,
        identifier = aRepo.identifier;

    for (var i = 0; i < count; i++)
    {
        if ([items[i] tag].identifier === identifier)
            return [selectedRepo selectItemAtIndex:i];
    }
}

- (@action)submitNewIssue:(id)sender
{
    if (![titleField stringValue])
        [errorField setStringValue:@"You must enter a title."];
    else if (![bodyField stringValue])
        [errorField setStringValue:@"You must enter a description."];
    else if ([[titleField stringValue] length] + [[bodyField stringValue] length] < 30 &&
             [[selectedRepo selectedItem] tag].identifier === @"280north/cappuccino")
    {
        var alert = [CPAlert alertWithMessageText:@"This bug report doesn't pass muster."
                                    defaultButton:@"My bad."
                                  alternateButton:nil
                                      otherButton:nil
                        informativeTextWithFormat:@"Please add more information about how and where you encountered the bug. Also, please don't file bug reports on the Cappuccino project just to test out the GitHub Issues app. Cappuccino is a real, live project, and having to devote effort to closing bogus issues makes the maintainers die just a tiny bit inside every time."];
        [alert beginSheetModalForWindow:[self window] modalDelegate:nil didEndSelector:nil contextInfo:nil];
    }
    else 
    {
        [errorField setStringValue:""];
        [progressView setHidden:NO];
        [okButton setEnabled:NO];
        [cancelButton setEnabled:NO];
        [previewButton setEnabled:NO];

        if (shouldEdit)
        {
            [[GithubAPIController sharedController] editIsssue:selectedIssue
                                                        title:[titleField stringValue]
                                                         body:[bodyField stringValue]
                                                   repository:[[selectedRepo selectedItem] tag]
                                                     callback:function(issue, repo)
            {
            [progressView setHidden:YES];
            [okButton setEnabled:YES];
            [cancelButton setEnabled:YES];
            [previewButton setEnabled:YES];

            if (!issue)
                [errorField setStringValue:@"Problem editing issue. Try again."];

            if (issue)
                [self cancel:nil];
            }];
        }
        else
        {
            [[GithubAPIController sharedController] openNewIssueWithTitle:[titleField stringValue]
                                                                 body:[bodyField stringValue]
                                                           repository:[[selectedRepo selectedItem] tag]
                                                             callback:function(issue, repo)
            {
            [progressView setHidden:YES];
            [okButton setEnabled:YES];
            [cancelButton setEnabled:YES];
            [previewButton setEnabled:YES];

            if (issue && [delegate respondsToSelector:@selector(newIssueWindowController:didAddIssue:toRepo:)])
                [delegate newIssueWindowController:self didAddIssue:issue toRepo:repo];
            else if (!issue)
                [errorField setStringValue:@"Problem submitting issue. Try again."];

            if (issue)
                [self cancel:nil];
            }];
        }
    }
}

- (@action)previewIssue:(id)sender
{
    // create a mock issue
    var issue = [CPDictionary dictionaryWithObjects:[[titleField stringValue], [bodyField stringValue], "You", "open", "#", 0] 
                                             forKeys:[@"title", @"body", "user", "state", "repo_identifier", "votes"]];

    try {
        [issue setObject:Markdown.makeHtml([issue objectForKey:"body"] || "") forKey:"body_html"];
    } catch (e) {
        [issue setObject:"" forKey:"body_html"];
    }

    var newWindow = [[CPWindow alloc] initWithContentRect:CGRectMake(100, 100, 800, 600) styleMask:CPTitledWindowMask|CPClosableWindowMask|CPMiniaturizableWindowMask|CPResizableWindowMask];
    [newWindow setMinSize:CGSizeMake(300, 300)];

    if ([CPPlatform isBrowser] && [CPPlatformWindow supportsMultipleInstances])
    {
        var platformWindow = [[CPPlatformWindow alloc] initWithContentRect:CGRectMake(100, 100, 800, 600)];
        [newWindow setPlatformWindow:platformWindow];
        [newWindow setFullBridge:YES];

    }

    var contentView = [newWindow contentView],
        webView = [[IssueWebView alloc] initWithFrame:[contentView bounds]];
    [webView setAutoresizingMask:CPViewWidthSizable|CPViewHeightSizable];

    [contentView addSubview:webView];
    [newWindow setTitle:[issue objectForKey:"title"]];
    [newWindow orderFront:self];

    [newWindow setDelegate:nil];
    [webView setIssue:issue];
    [webView setRepo:nil];
    [webView loadIssue];
}

- (@action)cancel:(id)sender
{
    [errorField setStringValue:""];
    [progressView setHidden:YES];
    [okButton setEnabled:YES];
    [cancelButton setEnabled:YES];
    [previewButton setEnabled:YES];

    [[self window] close];

    if ([CPPlatform isBrowser] && [CPPlatformWindow supportsMultipleInstances])
        [[[self window] platformWindow] orderOut:nil];
}

- (BOOL)windowShouldClose:(CPWindow)aWin
{
    if ((![CPPlatform isBrowser] || ![CPPlatformWindow supportsMultipleInstances]) && delegate)
        delegate._openIssueWindows--;
}

@end

// FIXME: needed because of a missing feature in Atlas
@implementation NewIssueWindow : CPWindow
{
}

- (id)initWithContentRect:(CGRect)aRect styleMask:(unsigned)aMask
{
    return [super initWithContentRect:aRect styleMask:aMask|CPClosableWindowMask|CPResizableWindowMask|CPMiniaturizableWindowMask];
}

@end
