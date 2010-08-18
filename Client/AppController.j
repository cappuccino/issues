/*
 * AppController.j
 * GitHubIssues
 *
 * Created by Ross Boucher on April 28, 2010.
 * Copyright 2010, 280 North All rights reserved.
 */

@import <Foundation/CPObject.j>
@import <AppKit/CPScrollView.j>
@import <AppKit/CPTableColumn.j>
@import <AppKit/CPCookie.j>
@import "RepositoriesController.j"
@import "IssuesController.j"
@import "OctoWindows.j"
@import "DetailScreen.j"
@import "RepositoryView.j"
@import "UserView.j"
@import "GithubAPIController.j"
@import "LPMultiLineTextField.j"
@import "AboutPanelController.j"
@import "RLTableHeaderView.j"
@import "OAuthController.j"

@implementation AppController : CPObject
{
    @outlet CPWindow    mainWindow @accessors;
    @outlet CPSplitView topLevelSplitView;
    @outlet CPSplitView detailLevelSplitView;
    @outlet CPView      userView;
    @outlet CPView      initialLoadingView;
    @outlet CPView      logoView;
    @outlet RepositoriesController reposController @accessors;
    @outlet IssuesController issuesController @accessors;
            CPPanel     cachedAboutPanel;
}

- (void)applicationDidFinishLaunching:(CPNotification)aNotification
{
    // parse the url arguments here. i.e. load a repo/issue on startup.
    var args = [CPApp arguments],
        argCount = [args count];

    [[[[[CPApp mainMenu] itemAtIndex:0] submenu] itemAtIndex:0] setTarget:self];

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
        apiTokenCookie = [[CPCookie alloc] initWithName:@"github.apiToken"],
        oauthAccessCookie = [[CPCookie alloc] initWithName:@"github.access_token"];

    if ([oauthAccessCookie value])
    {
        var controller = [GithubAPIController sharedController];
        [controller setOauthAccessToken:[oauthAccessCookie value]];
        [controller authenticateWithCallback:initializationFunction];
    }
    else if ([usernameCookie value] && [apiTokenCookie value])
    {
        var controller = [GithubAPIController sharedController];
        [controller setUsername:[usernameCookie value]];
        [controller setAuthenticationToken:[apiTokenCookie value]];
        [controller authenticateWithCallback:initializationFunction];
    }
    else
        initializationFunction();

    // special DOM hook if you have unsubmitted issues or comments.
    window.onbeforeunload = function() {
        if(issuesController._openIssueWindows > 0)
            return "You have unsubmitted issues. Reloading or quitting the application will prevent you from submitting these issues. You have Are you sure you want to quit?";
        try {
            if([[issuesController issueWebView] DOMWindow].hasUnsubmittedComment())
                return "You have an unsubmitted comment. This comment will be lost if you reload or quit the application. Are you sure you want to quit?";
        }catch (e){}
    }
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

    [[[CPCookie alloc] initWithName:@"github.access_token"] setValue:[githubController authenticationToken] || ""
                                                         expires:[CPDate dateWithTimeIntervalSinceNow:31536000]
                                                          domain:nil];
}

- (void)awakeFromCib
{
    [CPMenu setMenuBarVisible:NO];

    var toolbar = [[CPToolbar alloc] initWithIdentifier:"mainToolbar"];
    [toolbar setDelegate:self];
    [[self mainWindow] setToolbar:toolbar];

    var toolbarColor = [CPColor colorWithPatternImage:
                            [[CPImage alloc] initWithContentsOfFile:
                                [[CPBundle mainBundle] pathForResource:"toolbarBackgroundColor.png"] 
                                                               size:CGSizeMake(1, 59)]];
    
    if ([CPPlatform isBrowser])
        [[toolbar _toolbarView] setBackgroundColor:toolbarColor];

    [toolbar validateVisibleItems];

    var reloadItem = [[CPMenuItem alloc] initWithTitle:"Reload Issues" action:@selector(reload:) keyEquivalent:"r"];
    [reloadItem setTarget:issuesController];
    [[CPApp mainMenu] addItem:reloadItem];
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
    return [CPToolbarFlexibleSpaceItemIdentifier, CPToolbarSpaceItemIdentifier, "searchfield", "newissue", "switchViewStatus", "commentissue", "tagissue", "openissue", "reload", "closeissue", "logo"];
}

-(CPArray)toolbarDefaultItemIdentifiers:(CPToolbar)toolbar
{
    var items = ["switchViewStatus", CPToolbarFlexibleSpaceItemIdentifier, "newissue", "commentissue", "tagissue", "closeissue", "openissue", "reload", CPToolbarFlexibleSpaceItemIdentifier, @"searchfield"];

    if ([CPPlatform isBrowser])
        items.unshift("logo");

    return items;
}

- (CPToolbarItem)toolbar:(CPToolbar)toolbar itemForItemIdentifier:(CPString)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag
{
    var mainBundle = [CPBundle mainBundle],
        toolbarItem = [[CPToolbarItem alloc] initWithItemIdentifier:itemIdentifier];

    [toolbarItem setVisibilityPriority:CPToolbarItemVisibilityPriorityUser];

    switch(itemIdentifier)
    {
        case @"logo":
            [toolbarItem setView:logoView];
            [toolbarItem setMinSize:CGSizeMake(200, 32)];
            [toolbarItem setMaxSize:CGSizeMake(200, 32)];

            //FIXME this should be possible without this
            window.setTimeout(function(){
                var toolbarView = [toolbar _toolbarView],
                    superview = [[toolbar items][0] view]; //FIXME
                
                while (superview && superview !== toolbarView)
                {
                    [superview setClipsToBounds:NO];
                    superview = [superview superview];
                }
            }, 0);
        break;
        
        case @"newissue":
            var image = [[CPImage alloc] initWithContentsOfFile:[mainBundle pathForResource:@"newIssueIcon.png"] size:CPSizeMake(26, 27)],
                highlighted = [[CPImage alloc] initWithContentsOfFile:[mainBundle pathForResource:@"newIssueIconHighlighted.png"] size:CPSizeMake(26, 27)];
                
            [toolbarItem setImage:image];
            [toolbarItem setAlternateImage:highlighted];

            [toolbarItem setTarget:issuesController];
            [toolbarItem setAction:@selector(newIssue:)];
            [toolbarItem setLabel:"New"];
            [toolbarItem setTag:@"NewIssue"];
            
            [toolbarItem setMinSize:CGSizeMake(32, 32)];
            [toolbarItem setMaxSize:CGSizeMake(32, 32)];
            [toolbarItem setVisibilityPriority:CPToolbarItemVisibilityPriorityHigh];
        break;

        case @"openissue":
            var image = [[CPImage alloc] initWithContentsOfFile:[mainBundle pathForResource:@"reopenIcon.png"] size:CPSizeMake(28, 27)],
                highlighted = [[CPImage alloc] initWithContentsOfFile:[mainBundle pathForResource:@"reopenIconHighlighted.png"] size:CPSizeMake(28, 27)];
                
            [toolbarItem setImage:image];
            [toolbarItem setAlternateImage:highlighted];
            
            [toolbarItem setTarget:issuesController];
            [toolbarItem setAction:@selector(reopenIssue:)];
            [toolbarItem setLabel:"Re-open"];
            [toolbarItem setTag:@"Open"];
            
            [toolbarItem setMinSize:CGSizeMake(32, 32)];
            [toolbarItem setMaxSize:CGSizeMake(32, 32)];
            [toolbarItem setVisibilityPriority:CPToolbarItemVisibilityPriorityHigh];
        break;

        case @"closeissue":
            var image = [[CPImage alloc] initWithContentsOfFile:[mainBundle pathForResource:@"closeIcon.png"] size:CPSizeMake(28, 27)],
                highlighted = [[CPImage alloc] initWithContentsOfFile:[mainBundle pathForResource:@"closeIconHighlighted.png"] size:CPSizeMake(28, 27)];
                
            [toolbarItem setImage:image];
            [toolbarItem setAlternateImage:highlighted];
            
            [toolbarItem setTarget:issuesController];
            [toolbarItem setAction:@selector(closeIssue:)];
            [toolbarItem setLabel:"Close"];
            [toolbarItem setTag:@"Close"];
            [toolbarItem setEnabled:NO];
            
            [toolbarItem setMinSize:CGSizeMake(38, 32)];
            [toolbarItem setMaxSize:CGSizeMake(38, 32)];
            [toolbarItem setVisibilityPriority:CPToolbarItemVisibilityPriorityHigh];
        break;

        case @"reload":
            var image = [[CPImage alloc] initWithContentsOfFile:[mainBundle pathForResource:@"refreshIcon.png"] size:CPSizeMake(24, 24)],
                highlighted = [[CPImage alloc] initWithContentsOfFile:[mainBundle pathForResource:@"refreshIconHighlighted.png"] size:CPSizeMake(24, 24)];

            [toolbarItem setImage:image];
            [toolbarItem setAlternateImage:highlighted];

            [toolbarItem setTarget:issuesController];
            [toolbarItem setAction:@selector(reload:)];
            [toolbarItem setLabel:"Reload"];
            [toolbarItem setTag:@"Reload"];
            [toolbarItem setEnabled:NO];

            [toolbarItem setMinSize:CGSizeMake(32, 32)];
            [toolbarItem setMaxSize:CGSizeMake(32, 32)];
            [toolbarItem setVisibilityPriority:CPToolbarItemVisibilityPriorityHigh];
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
            [toolbarItem setVisibilityPriority:CPToolbarItemVisibilityPriorityHigh];
        break;

        case @"tagissue":
            var image = [[CPImage alloc] initWithContentsOfFile:[mainBundle pathForResource:@"tagIcon.png"] size:CPSizeMake(26, 27)],
                highlighted = [[CPImage alloc] initWithContentsOfFile:[mainBundle pathForResource:@"tagIconHighlighted.png"] size:CPSizeMake(26, 27)];

            [toolbarItem setImage:image];
            [toolbarItem setAlternateImage:highlighted];

            [toolbarItem setTarget:issuesController];
            [toolbarItem setAction:@selector(tag:)];
            [toolbarItem setLabel:@"Tag"];
            [toolbarItem setTag:@"Tag"];

            [toolbarItem setMinSize:CGSizeMake(42.0, 32.0)];
            [toolbarItem setMaxSize:CGSizeMake(42.0, 32.0)];
            [toolbarItem setVisibilityPriority:CPToolbarItemVisibilityPriorityHigh];
        break;

        case @"searchfield":
            var searchField = [[ToolbarSearchField alloc] initWithFrame:CGRectMake(0,0, 140, 30)];

            [searchField setTarget:issuesController];
            [searchField setAction:@selector(searchFieldDidChange:)];
            [searchField setSendsSearchStringImmediately:YES];
            [searchField setPlaceholderString:"title / body / labels"];

            [toolbarItem setLabel:"Search Issues"];
            [toolbarItem setView:searchField];
            [toolbarItem setTag:@"SearchIssues"];
            
            [toolbarItem setMinSize:CGSizeMake([CPPlatform isBrowser] ? 180 : 220, 30)];
            [toolbarItem setMaxSize:CGSizeMake([CPPlatform isBrowser] ? 180 : 220, 30)];

            [self addCustomSearchFieldAttributes:searchField];
        break;

        case @"switchViewStatus":
            var aSwitch = [[CPSegmentedControl alloc] initWithFrame:CGRectMake(0,0,0,0)];

            [aSwitch setTrackingMode:CPSegmentSwitchTrackingSelectOne];
            [aSwitch setTarget:issuesController];
            [aSwitch setAction:@selector(takeIssueTypeFrom:)];
            [aSwitch setSegmentCount:2];
            [aSwitch setWidth:[CPPlatform isBrowser] ? 65 : 80 forSegment:0];
            [aSwitch setWidth:[CPPlatform isBrowser] ? 65 : 80 forSegment:1];
            [aSwitch setTag:@"openIssues" forSegment:0];
            [aSwitch setTag:@"closedIssues" forSegment:1];
            [aSwitch setLabel:@"Open" forSegment:0];
            [aSwitch setLabel:@"Closed" forSegment:1];
            [aSwitch selectSegmentWithTag:[issuesController displayedIssuesKey]];

            [toolbarItem setView:aSwitch];
            [toolbarItem setTag:@"changeViewStatus"];
            [toolbarItem setLabel:"View Issues in State"];
            
            [toolbarItem setMinSize:CGSizeMake([CPPlatform isBrowser] ? 130 : 160, 24)];
            [toolbarItem setMaxSize:CGSizeMake([CPPlatform isBrowser] ? 130 : 160, 24)];
            
            [self addCustomSegmentedAttributes:aSwitch];
        break;
    }

    return toolbarItem;
}

- (void)addCustomSegmentedAttributes:(CPSegmentedControl)aControl
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

- (void)addCustomSearchFieldAttributes:(CPSearchField)textfield
{
    var bezelColor = PatternColor([[CPThreePartImage alloc] initWithImageSlices:
            [
                MainBundleImage("searchfield-left-bezel.png", CGSizeMake(23.0, 24.0)),
                MainBundleImage("searchfield-center-bezel.png", CGSizeMake(1.0, 24.0)),
                MainBundleImage("searchfield-right-bezel.png", CGSizeMake(14.0, 24.0))
            ] isVertical:NO]),

        bezelFocusedColor = PatternColor([[CPThreePartImage alloc] initWithImageSlices:
            [
                MainBundleImage("searchfield-left-bezel-selected.png", CGSizeMake(27.0, 30.0)),
                MainBundleImage("searchfield-center-bezel-selected.png", CGSizeMake(1.0, 30.0)),
                MainBundleImage("searchfield-right-bezel-selected.png", CGSizeMake(17.0, 30.0))
            ] isVertical:NO]);

    [textfield setValue:bezelColor forThemeAttribute:@"bezel-color" inState:CPThemeStateBezeled | CPTextFieldStateRounded];
    [textfield setValue:bezelFocusedColor forThemeAttribute:@"bezel-color" inState:CPThemeStateBezeled | CPTextFieldStateRounded | CPThemeStateEditing];

    [textfield setValue:[CPFont systemFontOfSize:12.0] forThemeAttribute:@"font"];
    [textfield setValue:CGInsetMake(9.0, 14.0, 6.0, 14.0) forThemeAttribute:@"content-inset" inState:CPThemeStateBezeled | CPTextFieldStateRounded];

    [textfield setValue:CGInsetMake(3.0, 3.0, 3.0, 3.0) forThemeAttribute:@"bezel-inset" inState:CPThemeStateBezeled|CPTextFieldStateRounded];
    [textfield setValue:CGInsetMake(0.0, 0.0, 0.0, 0.0) forThemeAttribute:@"bezel-inset" inState:CPThemeStateBezeled|CPTextFieldStateRounded|CPThemeStateEditing];
}

- (void)swapMainWindowOrientation:(id)sender
{
    GitHubIssuesToggleVertical();
}

- (@action)orderFrontStandardAboutPanel:(id)sender
{
    if (cachedAboutPanel)
    {
        [cachedAboutPanel orderFront:nil];
        return;
    }
    
    var aboutPanelController = [[AboutPanelController alloc] initWithWindowCibName:@"AboutPanel"],
        aboutPanel = [aboutPanelController window];

    [aboutPanel center];
    [aboutPanel orderFront:self];
    cachedAboutPanel = aboutPanel;
}

@end

@implementation ToolbarSearchField : CPSearchField
{
}

- (void)resetSearchButton
{
    [super resetSearchButton];
    [[self searchButton] setImage:nil];
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
    [[CPRunLoop mainRunLoop] performSelectors];
}
