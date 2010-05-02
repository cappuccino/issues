/*
 * AppController.j
 * AtlasIssues
 *
 * Created by Ross Boucher on April 28, 2010.
 * Copyright 2010, Your Company All rights reserved.
 */

@import <Foundation/CPObject.j>
@import "RepositoriesController.j"
@import "IssuesController.j"
@import "OctoWindows.j"
@import "DetailScreen.j"
@import "RepositoryView.j"
@import "UserView.j"
@import "GithubAPIController.j"

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
    var usernameCookie = [[CPCookie alloc] initWithName:@"github.username"],
        apiTokenCookie = [[CPCookie alloc] initWithName:@"github.apiToken"];

    if ([usernameCookie value] && [apiTokenCookie value])
    {
        var controller = [GithubAPIController sharedController];
        [controller setUsername:[usernameCookie value]];
        [controller setAuthenticationToken:[apiTokenCookie value]];
        [controller authenticateWithCallback:nil];
    }

    var reposCookie = [[CPCookie alloc] initWithName:@"github.repos"],
        cookieRepos = nil;

    try {
        cookieRepos = JSON.parse([reposCookie value]);
    }
    catch (e) {
        CPLog.info("unable to load repos from cookie: "+e);
    }

    // parse the url arguments here. i.e. load a repo/issue on startup.
    var args = [CPApp namedArguments];
    if ([args containsKey:@"repo"])
    {
        var contentView = [mainWindow contentView],
            frame = [contentView bounds];

        [initialLoadingView setFrame:frame];
        [contentView addSubview:initialLoadingView];

        var repo = [args valueForKey:@"repo"];
        [[GithubAPIController sharedController] loadRepositoryWithIdentifier:repo callback:function(repo)
        {
            if (repo)
            {
                if ([args containsKey:"issue"])
                {
                    [[GithubAPIController sharedController] loadIssuesForRepository:repo callback:function(){

                        [reposController addRepository:repo];
                        [initialLoadingView removeFromSuperview];

                        if (cookieRepos)
                        {
                            for (var i = 0, count = cookieRepos.length; i < count; i++)
                                [reposController addRepository:cookieRepos[i] select:NO];
                        }

                        var issueNumber = parseInt([args valueForKey:@"issue"], 10),
                            openIssues = repo.openIssues,
                            count = openIssues.length;

                        for (var i = 0; i < count; i++)
                        {
                            if ([openIssues[i] objectForKey:"number"] === issueNumber)
                            {
                                [issuesController selectIssueAtIndex:i];
                                return;
                            }
                        }

                        var closedIssues = repo.closedIssues,
                            count = closedIssues.length;

                        for (var i = 0; i < count; i++)
                        {
                            if ([closedIssues[i] objectForKey:"number"] === issueNumber)
                            {
                                [issuesController setDisplayedIssuesKey:"closedIssues"];
                                [issuesController selectIssueAtIndex:i];
                                return;
                            }
                        }
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

- (void)applicationWillTerminate:(CPNotification)aNote
{
    var repos = [reposController sortedRepos],
        count = repos.length;

    for (var i = 0; i < count; i++)
    {
        delete repos[i].openIssues;
        delete repos[i].closedIssues;
    }

    [[[CPCookie alloc] initWithName:@"github.repos"] setValue:JSON.stringify(repos) 
                                                      expires:[CPDate distantFuture] 
                                                       domain:nil];

    var githubController = [GithubAPIController sharedController];

    [[[CPCookie alloc] initWithName:@"github.username"] setValue:[githubController username] || ""
                                                         expires:[CPDate distantFuture] 
                                                          domain:nil];

    [[[CPCookie alloc] initWithName:@"github.apiToken"] setValue:[githubController authenticationToken] || ""
                                                         expires:[CPDate distantFuture] 
                                                          domain:nil];
}

- (void)awakeFromCib
{
    [topLevelSplitView setIsPaneSplitter:YES];
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
    return ["loginStatus", CPToolbarSpaceItemIdentifier, "switchViewStatus", CPToolbarFlexibleSpaceItemIdentifier, "newissue", @"commentissue", "openissue", "closeissue", CPToolbarFlexibleSpaceItemIdentifier, @"searchfield"];
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
            [toolbarItem setMinSize:CGSizeMake(180, 32)];
            [toolbarItem setMaxSize:CGSizeMake(180, 32)];
            [toolbarItem setTarget:[GithubAPIController sharedController]];
            [toolbarItem setAction:@selector(toggleAuthentication:)];
        break;
        
        case @"newissue":
            var image = [[CPImage alloc] initWithContentsOfFile:[mainBundle pathForResource:@"newissue.png"] size:CPSizeMake(32, 32)],
                highlighted = [[CPImage alloc] initWithContentsOfFile:[mainBundle pathForResource:@"newissue.png"] size:CPSizeMake(32, 32)];
                
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
            var image = [[CPImage alloc] initWithContentsOfFile:[mainBundle pathForResource:@"reopen.png"] size:CPSizeMake(32, 32)],
                highlighted = [[CPImage alloc] initWithContentsOfFile:[mainBundle pathForResource:@"reopen.png"] size:CPSizeMake(32, 32)];
                
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
            var image = [[CPImage alloc] initWithContentsOfFile:[mainBundle pathForResource:@"close.png"] size:CPSizeMake(32, 32)],
                highlighted = [[CPImage alloc] initWithContentsOfFile:[mainBundle pathForResource:@"close.png"] size:CPSizeMake(32, 32)];
                
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
            var image = [[CPImage alloc] initWithContentsOfFile:[mainBundle pathForResource:@"comment.png"] size:CPSizeMake(32, 32)],
                highlighted = [[CPImage alloc] initWithContentsOfFile:[mainBundle pathForResource:@"comment.png"] size:CPSizeMake(32, 32)];
                
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
            [aSwitch setSelectedSegment:0];

            [toolbarItem setView:aSwitch];
            [toolbarItem setTag:@"changeViewStatus"];
            
            [toolbarItem setMinSize:CGSizeMake(150, 24)];
            [toolbarItem setMaxSize:CGSizeMake(150, 24)];
        break;
    }

    return toolbarItem;
}

@end
