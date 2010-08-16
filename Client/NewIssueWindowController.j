
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
    [errorField setAlignment:CPRightTextAlignment]
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

    if ([CPPlatform isBrowser] && [CPPlatformWindow supportsMultipleInstances])
    {
        var platformWindow = [[CPPlatformWindow alloc] initWithContentRect:CGRectMake(100, 100, 500, 450)];
        [[self window] setFullBridge:YES];
        [[self window] setPlatformWindow:platformWindow];
    }

    [bodyField setBackgroundColor:[CPColor whiteColor]];

    if (selectedIssue)
    {
        [bodyField setStringValue:[selectedIssue objectForKey:"body"]];
        [titleField setStringValue:[selectedIssue objectForKey:"title"]];
    }
}

- (void)setSelectedIssue:(id)anIssue
{
    selectedIssue = anIssue;

    [bodyField setStringValue:[selectedIssue objectForKey:"body"]];
    [titleField setStringValue:[selectedIssue objectForKey:"title"]];
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
        [errorField setStringValue:@"Enter a title before submitting this issue."];
    else if (![bodyField stringValue])
        [errorField setStringValue:@"Enter a description before submitting this issue."];
    else 
    {
        [errorField setStringValue:""];
        [progressView setHidden:NO];
        [okButton setEnabled:NO];
        [cancelButton setEnabled:NO];

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

- (@action)cancel:(id)sender
{
    [errorField setStringValue:""];
    [progressView setHidden:YES];
    [okButton setEnabled:YES];
    [cancelButton setEnabled:YES];

    [[self window] close];
    [[[self window] platformWindow] orderOut:nil];
}

@end

// FIXME: needed because of a missing feature in Atlas
@implementation NewIssueWindow : CPWindow
{
}

- (id)initWithContentRect:(CGRect)aRect styleMask:(unsigned)aMask
{
    return [super initWithContentRect:aRect styleMask:aMask|CPResizableWindowMask|CPMiniaturizableWindowMask];
}

@end
