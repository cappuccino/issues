/*
 * AppController.j
 * GitHubIssues
 *
 * Created by Ross Boucher on April 28, 2010.
 * Copyright 2010, 280 North All rights reserved.
 */

@import <Foundation/CPObject.j>
@import "RepositoriesController.j"
@import "IssuesController.j"
@import "OctoWindows.j"
@import "DetailScreen.j"
@import "RepositoryView.j"
@import "UserView.j"
@import "GithubAPIController.j"
@import "LPMultiLineTextField.j"

@implementation AppController : CPObject
{
    @outlet CPWindow    mainWindow @accessors;
    @outlet CPSplitView topLevelSplitView;
    @outlet CPSplitView detailLevelSplitView;
    @outlet CPView      userView;
    @outlet CPView      initialLoadingView;
    @outlet RepositoriesController reposController @accessors;
    @outlet IssuesController issuesController @accessors;
}

- (void)applicationDidFinishLaunching:(CPNotification)aNotification
{
    // parse the url arguments here. i.e. load a repo/issue on startup.
    var args = [CPApp arguments],
        argCount = [args count];

    if (argCount >= 2)
    {
        var contentView = [mainWindow contentView],
            frame = [contentView bounds];

        [initialLoadingView setFrame:frame];
        [contentView addSubview:initialLoadingView];
    }

    var initializationFunction = function(){
        var reposCookie = [[CPCookie alloc] initWithName:@"github.repos"],
            cookieRepos = nil;

        try {
            cookieRepos = JSON.parse(decodeURIComponent([reposCookie value]));
        }
        catch (e) {
            CPLog.info("unable to load repos from cookie: "+e+" "+[reposCookie value]);
        }

        if (argCount >= 2)
        {
            var identifier = args[0] + "/" + args[1];
            [[GithubAPIController sharedController] loadRepositoryWithIdentifier:identifier callback:function(repo)
            {
                if (repo)
                {
                    if (argCount >= 3)
                    {
                        [[GithubAPIController sharedController] loadIssuesForRepository:repo callback:function(){

                            var issueNumber = parseInt(args[2], 10),
                                openIssues = repo.openIssues,
                                count = openIssues.length,
                                issueIndex = -1;

                            for (var i = 0; i < count && issueIndex < 0; i++)
                            {
                                if ([openIssues[i] objectForKey:"number"] === issueNumber)
                                    issueIndex = i;
                            }

                            var closedIssues = repo.closedIssues,
                                count = closedIssues.length;

                            for (var i = 0; i < count && issueIndex < 0; i++)
                            {
                                if ([closedIssues[i] objectForKey:"number"] === issueNumber)
                                {
                                    [issuesController setDisplayedIssuesKey:"closedIssues"];
                                    issueIndex = i;
                                }
                            }

                            [reposController addRepository:repo];
                            [initialLoadingView removeFromSuperview];

                            if (cookieRepos)
                            {
                                for (var i = 0, count = cookieRepos.length; i < count; i++)
                                    [reposController addRepository:cookieRepos[i] select:NO];
                            }

                            if (issueIndex >= 0)
                                [issuesController selectIssueAtIndex:issueIndex];
                        }];
                    }
                    else
                    {
                        [reposController addRepository:repo];
                        [initialLoadingView removeFromSuperview];

                        if (cookieRepos)
                        {
                            for (var i = 0, count = cookieRepos.length; i < count; i++)
                                [reposController addRepository:cookieRepos[i] select:NO];
                        }
                    }
                }
                else if (cookieRepos)
                {
                    for (var i = 0, count = cookieRepos.length; i < count; i++)
                        [reposController addRepository:cookieRepos[i] select:NO];
                }
            }];
        }
        else if (cookieRepos)
            [reposController setSortedRepos:cookieRepos];
    }

    var usernameCookie = [[CPCookie alloc] initWithName:@"github.username"],
        apiTokenCookie = [[CPCookie alloc] initWithName:@"github.apiToken"];

    if ([usernameCookie value] && [apiTokenCookie value])
    {
        var controller = [GithubAPIController sharedController];
        [controller setUsername:[usernameCookie value]];
        [controller setAuthenticationToken:[apiTokenCookie value]];
        [controller authenticateWithCallback:initializationFunction];
    }
    else
        initializationFunction();

}

- (void)applicationWillTerminate:(CPNotification)aNote
{
    [[[CPCookie alloc] initWithName:@"github.repos"] setValue:encodeURIComponent(JSON.stringify([reposController sortedRepos], ["name", "owner", "identifier", "open_issues", "description", "private"]))
                                                      expires:[CPDate dateWithTimeIntervalSinceNow:31536000]
                                                       domain:nil];

    var githubController = [GithubAPIController sharedController];

    [[[CPCookie alloc] initWithName:@"github.username"] setValue:[githubController username] || ""
                                                         expires:[CPDate dateWithTimeIntervalSinceNow:31536000]
                                                          domain:nil];

    [[[CPCookie alloc] initWithName:@"github.apiToken"] setValue:[githubController authenticationToken] || ""
                                                         expires:[CPDate dateWithTimeIntervalSinceNow:31536000]
                                                          domain:nil];
}

- (void)awakeFromCib
{
    [topLevelSplitView setIsPaneSplitter:YES];
    [CPMenu setMenuBarVisible:NO];
}

- (CGFloat)splitView:(CPSplitView)splitView constrainMinCoordinate:(float)proposedMin ofSubviewAt:(int)dividerIndex
{
    return 140;
}

- (CGFloat)splitView:(CPSplitView)splitView constrainMaxCoordinate:(float)proposedMax ofSubviewAt:(int)dividerIndex
{
    return 500;
}

@end

@implementation AppController (ToolbarDelegate)

-(CPArray)toolbarAllowedItemIdentifiers:(CPToolbar)toolbar
{
    return [CPToolbarFlexibleSpaceItemIdentifier, CPToolbarSpaceItemIdentifier, @"searchfield", @"newissue", @"switchViewStatus", "commentissue", "openissue", "closeissue", "loginStatus"];
}

-(CPArray)toolbarDefaultItemIdentifiers:(CPToolbar)toolbar
{
    return ["loginStatus", "switchViewStatus", CPToolbarFlexibleSpaceItemIdentifier, "newissue", @"commentissue", "openissue", "closeissue", CPToolbarFlexibleSpaceItemIdentifier, @"searchfield"];
}

- (CPToolbarItem)toolbar:(CPToolbar)toolbar itemForItemIdentifier:(CPString)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag
{
    var mainBundle = [CPBundle mainBundle],
        toolbarItem = [[CPToolbarItem alloc] initWithItemIdentifier:itemIdentifier];

    [toolbarItem setVisibilityPriority:CPToolbarItemVisibilityPriorityHigh];
    [toolbarItem setEnabled:NO];

    switch(itemIdentifier)
    {
        case @"loginStatus":
            [toolbarItem setView:userView];
            [toolbarItem setMinSize:CGSizeMake(200, 32)];
            [toolbarItem setMaxSize:CGSizeMake(200, 32)];
            [toolbarItem setTarget:[GithubAPIController sharedController]];
            [toolbarItem setAction:@selector(toggleAuthentication:)];
        break;
        
        case @"newissue":
            var image = [[CPImage alloc] initWithContentsOfFile:[mainBundle pathForResource:@"newIssueIcon.png"] size:CPSizeMake(26, 27)],
                highlighted = [[CPImage alloc] initWithContentsOfFile:[mainBundle pathForResource:@"newIssueIconHighlighted.png"] size:CPSizeMake(26, 27)];
                
            [toolbarItem setImage:image];
            [toolbarItem setAlternateImage:highlighted];

            [toolbarItem setTarget:issuesController];
            [toolbarItem setAction:@selector(newIssue:)];
            [toolbarItem setLabel:"New Issue"];
            [toolbarItem setTag:@"NewIssue"];
            
            [toolbarItem setMinSize:CGSizeMake(32, 32)];
            [toolbarItem setMaxSize:CGSizeMake(32, 32)];
            [toolbarItem setVisibilityPriority:CPToolbarItemVisibilityPriorityLow];
        break;

        case @"openissue":
            var image = [[CPImage alloc] initWithContentsOfFile:[mainBundle pathForResource:@"reopenIcon.png"] size:CPSizeMake(27, 27)],
                highlighted = [[CPImage alloc] initWithContentsOfFile:[mainBundle pathForResource:@"reopenIconHighlighted.png"] size:CPSizeMake(27, 27)];
                
            [toolbarItem setImage:image];
            [toolbarItem setAlternateImage:highlighted];
            
            [toolbarItem setTarget:issuesController];
            [toolbarItem setAction:@selector(reopenIssue:)];
            [toolbarItem setLabel:"Re-open Issue"];
            [toolbarItem setTag:@"Open"];
            
            [toolbarItem setMinSize:CGSizeMake(32, 32)];
            [toolbarItem setMaxSize:CGSizeMake(32, 32)];
            [toolbarItem setVisibilityPriority:CPToolbarItemVisibilityPriorityLow];
        break;

        case @"closeissue":
            var image = [[CPImage alloc] initWithContentsOfFile:[mainBundle pathForResource:@"closeIcon.png"] size:CPSizeMake(28, 27)],
                highlighted = [[CPImage alloc] initWithContentsOfFile:[mainBundle pathForResource:@"closeIconHighlighted.png"] size:CPSizeMake(28, 27)];
                
            [toolbarItem setImage:image];
            [toolbarItem setAlternateImage:highlighted];
            
            [toolbarItem setTarget:issuesController];
            [toolbarItem setAction:@selector(closeIssue:)];
            [toolbarItem setLabel:"Close Issue"];
            [toolbarItem setTag:@"Close"];
            [toolbarItem setEnabled:NO];
            
            [toolbarItem setMinSize:CGSizeMake(32, 32)];
            [toolbarItem setMaxSize:CGSizeMake(32, 32)];
            [toolbarItem setVisibilityPriority:CPToolbarItemVisibilityPriorityLow];
        break;

        case @"commentissue":
            var image = [[CPImage alloc] initWithContentsOfFile:[mainBundle pathForResource:@"commentIcon.png"] size:CPSizeMake(27, 26)],
                highlighted = [[CPImage alloc] initWithContentsOfFile:[mainBundle pathForResource:@"commentIconHighlighted.png"] size:CPSizeMake(27, 26)];
                
            [toolbarItem setImage:image];
            [toolbarItem setAlternateImage:highlighted];
            
            [toolbarItem setTarget:issuesController];
            [toolbarItem setAction:@selector(comment:)];
            [toolbarItem setLabel:"Add Comment"];
            [toolbarItem setTag:@"Comment"];
            
            [toolbarItem setMinSize:CGSizeMake(32, 32)];
            [toolbarItem setMaxSize:CGSizeMake(32, 32)];
            [toolbarItem setVisibilityPriority:CPToolbarItemVisibilityPriorityLow];
        break;

        case @"searchfield":
            var searchField = [[CPSearchField alloc] initWithFrame:CGRectMake(0,0, 140, 30)];
            [searchField setTarget:issuesController];
            [searchField setAction:@selector(searchFieldDidChange:)];
            [searchField setSendsSearchStringImmediately:YES];
            [searchField setPlaceholderString:"Search Issues"];

            [toolbarItem setView:searchField];
            [toolbarItem setTag:@"SearchIssues"];
            [toolbarItem setVisibilityPriority:CPToolbarItemVisibilityPriorityHigh];
            
            [toolbarItem setMinSize:CGSizeMake(200, 30)];
            [toolbarItem setMaxSize:CGSizeMake(200, 30)];
        break;

        case @"switchViewStatus":
            var aSwitch = [[CPSegmentedControl alloc] initWithFrame:CGRectMake(0,0,0,0)];
            
            [self addCustomStyleAttributes:aSwitch];

            [aSwitch setTrackingMode:CPSegmentSwitchTrackingSelectOne];
            [aSwitch setTarget:issuesController];
            [aSwitch setAction:@selector(takeIssueTypeFrom:)];
            [aSwitch setSegmentCount:2];
            [aSwitch setWidth:75 forSegment:0];
            [aSwitch setWidth:75 forSegment:1];
            [aSwitch setTag:@"openIssues" forSegment:0];
            [aSwitch setTag:@"closedIssues" forSegment:1];
            [aSwitch setLabel:@"Open" forSegment:0];
            [aSwitch setLabel:@"Closed" forSegment:1];
            [aSwitch selectSegmentWithTag:[issuesController displayedIssuesKey]];

            [toolbarItem setView:aSwitch];
            [toolbarItem setTag:@"changeViewStatus"];
            
            [toolbarItem setMinSize:CGSizeMake(150, 24)];
            [toolbarItem setMaxSize:CGSizeMake(150, 24)];
        break;
    }

    return toolbarItem;
}

- (void)addCustomStyleAttributes:(CPSegmentedControl)aControl
{
    var dividerColor = [CPColor colorWithPatternImage:[[CPImage alloc] initWithContentsOfFile:[[CPBundle mainBundle] pathForResource:"display-mode-divider.png"] size:CGSizeMake(1, 24)]],
        leftBezel = PatternColor(MainBundleImage("display-mode-left-bezel.png", CGSizeMake(4, 24))),
        centerBezel = PatternColor(MainBundleImage("display-mode-center-bezel.png", CGSizeMake(1, 24))),
        rightBezel = PatternColor(MainBundleImage("display-mode-right-bezel.png", CGSizeMake(4, 24))),
        leftBezelHighlighted = PatternColor(MainBundleImage("display-mode-left-bezel-highlighted.png", CGSizeMake(4, 24))),
        centerBezelHighlighted = PatternColor(MainBundleImage("display-mode-center-bezel-highlighted.png", CGSizeMake(1, 24))),
        rightBezelHighlighted = PatternColor(MainBundleImage("display-mode-right-bezel-highlighted.png", CGSizeMake(4, 24))),
        leftBezelSelected = PatternColor(MainBundleImage("display-mode-left-bezel-selected.png", CGSizeMake(4, 24))),
        centerBezelSelected = PatternColor(MainBundleImage("display-mode-center-bezel-selected.png", CGSizeMake(1, 24))),
        rightBezelSelected = PatternColor(MainBundleImage("display-mode-right-bezel-selected.png", CGSizeMake(4, 24))),
        leftBezelDisabled = PatternColor(MainBundleImage("display-mode-left-bezel-disabled.png", CGSizeMake(4, 24))),
        centerBezelDisabled = PatternColor(MainBundleImage("display-mode-center-bezel-disabled.png", CGSizeMake(1, 24))),
        rightBezelDisabled = PatternColor(MainBundleImage("display-mode-right-bezel-disabled.png", CGSizeMake(4, 24))),
        leftBezelSelectedDisabled = PatternColor(MainBundleImage("display-mode-left-bezel-selected-disabled.png", CGSizeMake(4, 24))),
        centerBezelSelectedDisabled = PatternColor(MainBundleImage("display-mode-center-bezel-selected-disabled.png", CGSizeMake(1, 24))),
        rightBezelSelectedDisabled = PatternColor(MainBundleImage("display-mode-right-bezel-selected-disabled.png", CGSizeMake(4, 24)));

    [aControl setValue:centerBezel forThemeAttribute:"center-segment-bezel-color"];
    [aControl setValue:centerBezelHighlighted forThemeAttribute:"center-segment-bezel-color" inState:CPThemeStateHighlighted];
    [aControl setValue:centerBezelSelected forThemeAttribute:"center-segment-bezel-color" inState:CPThemeStateSelected];
    [aControl setValue:centerBezelDisabled forThemeAttribute:"center-segment-bezel-color" inState:CPThemeStateDisabled];
    [aControl setValue:centerBezelSelectedDisabled forThemeAttribute:"center-segment-bezel-color" inState:CPThemeStateSelected|CPThemeStateDisabled];

    [aControl setValue:leftBezel forThemeAttribute:"left-segment-bezel-color"];
    [aControl setValue:leftBezelHighlighted forThemeAttribute:"left-segment-bezel-color" inState:CPThemeStateHighlighted];
    [aControl setValue:leftBezelSelected forThemeAttribute:"left-segment-bezel-color" inState:CPThemeStateSelected];
    [aControl setValue:leftBezelDisabled forThemeAttribute:"left-segment-bezel-color" inState:CPThemeStateDisabled];
    [aControl setValue:leftBezelSelectedDisabled forThemeAttribute:"left-segment-bezel-color" inState:CPThemeStateSelected|CPThemeStateDisabled];

    [aControl setValue:rightBezel forThemeAttribute:"right-segment-bezel-color"];
    [aControl setValue:rightBezelHighlighted forThemeAttribute:"right-segment-bezel-color" inState:CPThemeStateHighlighted];
    [aControl setValue:rightBezelSelected forThemeAttribute:"right-segment-bezel-color" inState:CPThemeStateSelected];
    [aControl setValue:rightBezelDisabled forThemeAttribute:"right-segment-bezel-color" inState:CPThemeStateDisabled];
    [aControl setValue:rightBezelSelectedDisabled forThemeAttribute:"right-segment-bezel-color" inState:CPThemeStateSelected|CPThemeStateDisabled];

    [aControl setValue:dividerColor forThemeAttribute:@"divider-bezel-color"];

    [aControl setValue:[CPColor colorWithCalibratedWhite:73.0/255.0 alpha:1.0] forThemeAttribute:@"text-color"];
    [aControl setValue:[CPColor colorWithCalibratedWhite:96.0/255.0 alpha:1.0] forThemeAttribute:@"text-color" inState:CPThemeStateDisabled];
    [aControl setValue:[CPColor colorWithCalibratedWhite:222.0/255.0 alpha:1.0] forThemeAttribute:@"text-shadow-color"];
    [aControl setValue:CGSizeMake(0.0, 1.0) forThemeAttribute:@"text-shadow-offset"];

    [aControl setValue:[CPColor colorWithCalibratedWhite:1.0 alpha:1.0] forThemeAttribute:@"text-color" inState:CPThemeStateSelected];
    [aControl setValue:[CPColor colorWithCalibratedWhite:0.8 alpha:1.0] forThemeAttribute:@"text-color" inState:CPThemeStateSelected|CPThemeStateDisabled];
    [aControl setValue:[CPColor colorWithCalibratedWhite:0.0/255.0 alpha:1.0] forThemeAttribute:@"text-shadow-color" inState:CPThemeStateSelected];
}

@end

function PatternColor(anImage)
{
    return [CPColor colorWithPatternImage:anImage];
}

function MainBundleImage(path, size)
{
    return [[CPImage alloc] initWithContentsOfFile:[[CPBundle mainBundle] pathForResource:path] size:size];
}

window.GitHubIssuesToggleVertical = function()
{
    var splitView = [CPApp delegate].detailLevelSplitView;
    [splitView setVertical:![splitView isVertical]];
    [splitView setNeedsDisplay:YES];
}
