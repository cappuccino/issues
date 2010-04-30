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
@import "LoginView.j"
@import "DetailScreen.j"
@import "RepositoryView.j"
@import "UserView.j"
@import "GithubAPIController.j"

@implementation AppController : CPObject
{
    @outlet CPWindow    mainWindow @accessors;
    @outlet CPSplitView topLevelSplitView;
    @outlet CPSplitView detailLevelSplitView;
    @outlet RepositoriesController reposController @accessors;
    @outlet IssuesController issuesController @accessors;
}

- (void)applicationDidFinishLaunching:(CPNotification)aNotification
{
    // This is called when the application is done loading.
}

- (void)awakeFromCib
{
    [topLevelSplitView setIsPaneSplitter:YES];
}

@end

@implementation AppController (ToolbarDelegate)

-(CPArray)toolbarAllowedItemIdentifiers:(CPToolbar)toolbar
{
    return [CPToolbarFlexibleSpaceItemIdentifier, CPToolbarSpaceItemIdentifier, @"searchfield", @"newissue", @"switchViewStatus", "commentissue", "openissue", "closeissue", "loginStatus"];
}

-(CPArray)toolbarDefaultItemIdentifiers:(CPToolbar)toolbar
{
    return ["loginStatus", CPToolbarSpaceItemIdentifier, "switchViewStatus", CPToolbarFlexibleSpaceItemIdentifier, "newissue", CPToolbarSpaceItemIdentifier, @"commentissue", CPToolbarSpaceItemIdentifier, "openissue", "closeissue", CPToolbarFlexibleSpaceItemIdentifier, @"searchfield"];
}

- (CPToolbarItem)toolbar:(CPToolbar)toolbar itemForItemIdentifier:(CPString)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag
{
    var mainBundle = [CPBundle mainBundle],
        toolbarItem = [[CPToolbarItem alloc] initWithItemIdentifier:itemIdentifier];

    [toolbarItem setVisibilityPriority:CPToolbarItemVisibilityPriorityHigh];
    [toolbarItem setEnabled:NO];
/*
    switch(itemIdentifier)
    {
        case @"newissue":
            var image = [[CPImage alloc] initWithContentsOfFile:[mainBundle pathForResource:@"newissue.png"] size:CPSizeMake(32, 32)],
                highlighted = [[CPImage alloc] initWithContentsOfFile:[mainBundle pathForResource:@"newissue.png"] size:CPSizeMake(32, 32)];
                
            [toolbarItem setImage:image];
            [toolbarItem setAlternateImage:highlighted];

            [toolbarItem setTarget:issuesController];
            [toolbarItem setAction:@selector(showNewIssueWindow:)];
            [toolbarItem setLabel:"New Issue"];
            [toolbarItem setTag:@"NewIssue"];
            
            [toolbarItem setMinSize:CGSizeMake(32, 32)];
            [toolbarItem setMaxSize:CGSizeMake(32, 32)];
        break;

        case @"openissue":
            var image = [[CPImage alloc] initWithContentsOfFile:[mainBundle pathForResource:@"reopen.png"] size:CPSizeMake(32, 32)],
                highlighted = [[CPImage alloc] initWithContentsOfFile:[mainBundle pathForResource:@"reopen.png"] size:CPSizeMake(32, 32)];
                
            [toolbarItem setImage:image];
            [toolbarItem setAlternateImage:highlighted];
            
            [toolbarItem setTarget:issuesController];
            [toolbarItem setAction:@selector(reopenActiveIssue:)];
            [toolbarItem setLabel:"Re-open Issue"];
            [toolbarItem setTag:@"Open"];
            
            [toolbarItem setMinSize:CGSizeMake(32, 32)];
            [toolbarItem setMaxSize:CGSizeMake(32, 32)];
        break;

        case @"closeissue":
            var image = [[CPImage alloc] initWithContentsOfFile:[mainBundle pathForResource:@"close.png"] size:CPSizeMake(32, 32)],
                highlighted = [[CPImage alloc] initWithContentsOfFile:[mainBundle pathForResource:@"close.png"] size:CPSizeMake(32, 32)];
                
            [toolbarItem setImage:image];
            [toolbarItem setAlternateImage:highlighted];
            
            [toolbarItem setTarget:issuesController];
            [toolbarItem setAction:@selector(promptUserToCloseIssue:)];
            [toolbarItem setLabel:"Close Issue"];
            [toolbarItem setTag:@"Close"];
            [toolbarItem setEnabled:NO];
            
            [toolbarItem setMinSize:CGSizeMake(32, 32)];
            [toolbarItem setMaxSize:CGSizeMake(32, 32)];
        break;

        case @"commentissue":
            var image = [[CPImage alloc] initWithContentsOfFile:[mainBundle pathForResource:@"comment.png"] size:CPSizeMake(32, 32)],
                highlighted = [[CPImage alloc] initWithContentsOfFile:[mainBundle pathForResource:@"comment.png"] size:CPSizeMake(32, 32)];
                
            [toolbarItem setImage:image];
            [toolbarItem setAlternateImage:highlighted];
            
            [toolbarItem setTarget:issuesController];
            [toolbarItem setAction:@selector(commentOnSelectedIssue:)];
            [toolbarItem setLabel:"Add Comment"];
            [toolbarItem setTag:@"Comment"];
            
            [toolbarItem setMinSize:CGSizeMake(32, 32)];
            [toolbarItem setMaxSize:CGSizeMake(32, 32)];
        break;

        case @"searchfield":
            [toolbarItem setView:searchField];
            [toolbarItem setLabel:"Search Issues"];
            [toolbarItem setTag:@"SearchIssues"];
            
            [toolbarItem setMinSize:CGSizeMake(200, 30)];
            [toolbarItem setMaxSize:CGSizeMake(200, 30)];
        break;

        case @"switchViewStatus":
            var aSwitch = [[CPSegmentedControl alloc] initWithFrame:CGRectMake(0,0,0,0)];
            [aSwitch setTrackingMode:CPSegmentSwitchTrackingSelectOne];
            [aSwitch setTarget:issuesController];
            [aSwitch setAction:@selector(changeVisibleIssuesStatus:)];
            [aSwitch setSegmentCount:2];
            [aSwitch setWidth:75 forSegment:0];
            [aSwitch setWidth:75 forSegment:1];
            [aSwitch setTag:@"Open" forSegment:0];
            [aSwitch setTag:@"Closed" forSegment:1];
            [aSwitch setLabel:@"Open" forSegment:0];
            [aSwitch setLabel:@"Closed" forSegment:1];
            [aSwitch setSelectedSegment:0];

            [toolbarItem setView:aSwitch];
            [toolbarItem setLabel:"Change View Status"];
            [toolbarItem setTag:@"changeViewStatus"];
            
            [toolbarItem setMinSize:CGSizeMake(150, 24)];
            [toolbarItem setMaxSize:CGSizeMake(150, 24)];
        break;
    }
*/
    return toolbarItem;
}

@end

// Create a console object if none exists
if (typeof window.console === "undefined")
    window.console = {log:function(){}, info:function(){}, error:function(){}, warn:function(){}}
