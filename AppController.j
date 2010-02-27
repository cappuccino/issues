/*
 * AppController.j
 * GitIssues
 *
 * Created by Randall Luecke on February 20, 2010.
 * Copyright 2010, Randall Luecke All rights reserved.
 */

@import <Foundation/CPObject.j>
@import <AppKit/CPSplitView.j>
@import <AppKit/CPTableView.j>
@import <AppKit/CPScrollView.j>
@import <AppKit/CPOutlineView.j>
@import "Classes/ProjectsController.j"
@import "Classes/IssuesController.j"
@import "Classes/CPDate+Additions.j"
@import "Classes/IssueView.j"
@import "Classes/AjaxSeries.j"

// GitHub credentials
GITHUBUSERNAME = "";
GITHUBPASSWORD = "";
//GITHUBAPITOKEN = "";

@implementation AppController : CPObject
{
    CPWindow    theWindow;
    CPSplitView outsideSplitView;
    CPTableView sourceList @accessors;
    CPTableView issuesTable @accessors;
    IssueView  issueView @accessors;

    // controllers
    id          projectsController;
    id          issuesController;

    CPCookie    followedUsersCookie @accessors;
}

- (void)applicationDidFinishLaunching:(CPNotification)aNotification
{
    // FIX ME: this is nasty...
    GITHUBUSERNAME = prompt("GitHub Username");    
    GITHUBPASSWORD = prompt("GitHub Password");

    theWindow = [[CPWindow alloc] initWithContentRect:CGRectMakeZero() styleMask:CPBorderlessBridgeWindowMask];
    [theWindow orderFront:self];

    // Uncomment the following line to turn on the standard menu bar.
    //[CPMenu setMenuBarVisible:YES];

    projectsController = [[ProjectsController alloc] init];
    issuesController   = [[IssuesController alloc] init];

    [projectsController setIssuesController:issuesController];
    [issuesController setAppController:self];
    [projectsController setAppController:self];

    [self setupViews];

    followedUsersCookie = [[CPCookie alloc] initWithName:@"GitIssuesFollowedUsers"];

    [self beginInitalRepoDownloads];

    var toolbar = [[CPToolbar alloc] initWithIdentifier:@"MainToolbar"];
    [toolbar setDelegate:self];
    [theWindow setToolbar:toolbar];
}

- (void)beginInitalRepoDownloads
{
    var values = [followedUsersCookie value];

    if(!values)
        return;

    values = JSON.parse(values);
    
    for (var i=0; i<values.length; i++)
    {
        var user = values[i];
        [projectsController allReposForUser:user];
    }
}

- (void)setupViews
{
    var contentView = [theWindow contentView];

    // setup the outside splitview.
    // the left has projects
    // the right side has issues splitview.
    outsideSplitView = [[CPSplitView alloc] initWithFrame:[contentView bounds]];
    [outsideSplitView setIsPaneSplitter:YES];
    [outsideSplitView setAutoresizingMask:CPViewWidthSizable|CPViewHeightSizable];
    [outsideSplitView setVertical:YES];
    [outsideSplitView setDelegate:projectsController];
    

    [contentView addSubview:outsideSplitView];
    var sourceListContentView = [[CPView alloc] initWithFrame:[outsideSplitView bounds]];

    var issuesSplitView = [[CPSplitView alloc] initWithFrame:[outsideSplitView bounds]];
    [issuesSplitView setAutoresizingMask:CPViewWidthSizable|CPViewHeightSizable];
    [issuesSplitView setVertical:NO];


    [outsideSplitView addSubview:sourceListContentView];
    [outsideSplitView addSubview:issuesSplitView];

    [outsideSplitView setPosition:180 ofDividerAtIndex:0];

    var issuesTable = [[CPView alloc] initWithFrame:[outsideSplitView bounds]];

    var issueView = [[IssueView alloc] initWithFrame:[outsideSplitView bounds]];
    [issuesController setIssueView:issueView];
    [issuesSplitView addSubview:issuesTable];
    [issuesSplitView addSubview:issueView];

    [issuesSplitView setPosition:200 ofDividerAtIndex:0];

    [self setupSourceList:sourceListContentView];
    [self setupIssuesTable:issuesTable];
}

- (void)setupSourceList:(id)view
{
    var scrollView = [[CPScrollView alloc] initWithFrame:[view bounds]];
    // leave room for the button bar below... if we actually have one
    sourceList = [[CPOutlineView alloc] initWithFrame:[view bounds]];//[[CPTableView alloc] initWithFrame:CGRectMake(0,0,CGRectGetWidth([view bounds]), CGRectGetHeight([view bounds]) - 32)];
    [sourceList setAutoresizingMask:CPViewWidthSizable|CPViewHeightSizable];
    [sourceList setDelegate:projectsController];
    [sourceList setDataSource:projectsController];
    [sourceList setSelectionHighlightStyle:CPTableViewSelectionHighlightStyleSourceList];

    var column = [[CPTableColumn alloc] initWithIdentifier:"sourcelist"];
    [[column headerView] setStringValue:"Projects"];

    [column setWidth:180.0];
    [column setMinWidth:50.0];
    [column setMaxWidth:250];
    [column setEditable:YES];
    
    [sourceList addTableColumn:column];
    [sourceList setOutlineTableColumn:column];
    [sourceList setColumnAutoresizingStyle:CPTableViewUniformColumnAutoresizingStyle];
    [sourceList setRowHeight:22.0];

    [sourceList setBackgroundColor:[CPColor colorWithHexString:@"dde8f7"]];

    [scrollView setDocumentView:sourceList];
    [scrollView setHasHorizontalScroller:NO];
    [scrollView setAutohidesScrollers:YES];
    [scrollView setAutoresizingMask:CPViewWidthSizable|CPViewHeightSizable];
    [scrollView setHorizontalLineScroll:0];
    [view addSubview:scrollView];

    [sourceList sizeLastColumnToFit];


    var buttonBarTop = [view frame].size.height - 27;
    sourceViewButtonBar = [[CPButtonBar alloc] initWithFrame:CGRectMake(0, buttonBarTop, [view frame].size.width, 26)];
    [sourceViewButtonBar setAutoresizingMask:CPViewWidthSizable|CPViewMinYMargin];
    [view addSubview:sourceViewButtonBar];
    sourceViewAddButton = [[CPButton alloc] initWithFrame:CGRectMake(0,0,35,27)];
    sourceViewRemoveButton = [[CPButton alloc] initWithFrame:CGRectMake(34,0,35,27)];
    [sourceViewAddButton setBordered:NO];
    [sourceViewRemoveButton setBordered:NO];
    
    [sourceViewAddButton setImage:[[CPImage alloc] initWithContentsOfFile:@"Resources/PlusButton.png" size:CGSizeMake(35, 27)]];
    [sourceViewRemoveButton setImage:[[CPImage alloc] initWithContentsOfFile:@"Resources/MinusButton.png" size:CGSizeMake(35, 27)]];
    [sourceViewAddButton setAlternateImage:[[CPImage alloc] initWithContentsOfFile:@"Resources/PlusButtonHighlight.png" size:CGSizeMake(35, 27)]];
    [sourceViewRemoveButton setAlternateImage:[[CPImage alloc] initWithContentsOfFile:@"Resources/MinusButtonHighlight.png" size:CGSizeMake(35, 27)]];
    
    [sourceViewAddButton setTarget:self];
    [sourceViewAddButton setAction:@selector(addUser:)];
    
    [sourceViewRemoveButton setTarget:self];
    [sourceViewRemoveButton setAction:@selector(removeUser:)];
    
    [sourceViewButtonBar addSubview:sourceViewAddButton];
    [sourceViewButtonBar addSubview:sourceViewRemoveButton];
    
    var resizeImage = [[CPView alloc] initWithFrame:CGRectMake(CGRectGetWidth([sourceViewButtonBar bounds]) - 13, 0, 13, 20)];
    // [resizeImage setBackgroundColor:[CPColor colorWithPatternImage:[[CPImage alloc] initWithContentsOfFile::"Frameworks/AppKit/Themes/Aristo/Resources/buttonbar-bezel-right.png" size:CGSizeMake(13.0, 26.0)]]];
    resizeImage._DOMElement.style.cursor = [[CPCursor resizeLeftRightCursor] _cssString];
    [sourceViewButtonBar addSubview:resizeImage];

    [sourceViewAddButton setAutoresizingMask:nil];
    [sourceViewRemoveButton setAutoresizingMask:nil];
    [sourceViewButtonBar setNeedsLayout];
    [view addSubview:sourceViewButtonBar];
}

- (void)setupIssuesTable:(id)view
{
    var scrollView = [[CPScrollView alloc] initWithFrame:[view bounds]];
    // leave room for the button bar below... if we actually have one
    issuesTable = [[CPTableView alloc] initWithFrame:CGRectMake(0,0,CGRectGetWidth([view bounds]), CGRectGetHeight([view bounds]) - 32)];
    [issuesTable setAutoresizingMask:CPViewWidthSizable|CPViewHeightSizable];
    [issuesTable setDelegate:issuesController];
    [issuesTable setDataSource:issuesController];
    [issuesTable setUsesAlternatingRowBackgroundColors:YES];
    //[issuesTable setGridStyleMask:CPTableViewSolidHorizontalGridLineMask | CPTableViewSolidVerticalGridLineMask];

    var desc = [CPSortDescriptor sortDescriptorWithKey:@"number" ascending:YES],
        ID = [[CPTableColumn alloc] initWithIdentifier:"number"];
    [[ID headerView] setStringValue:"ID"];
    [ID setWidth:50.0];
    [ID setMinWidth:50.0];
//    [ID setMaxWidth:250];
    [ID setEditable:YES];
    [ID setSortDescriptorPrototype:desc];
    [issuesTable addTableColumn:ID];

    var desc = [CPSortDescriptor sortDescriptorWithKey:@"title" ascending:YES],
        title = [[CPTableColumn alloc] initWithIdentifier:"title"];
    [[title headerView] setStringValue:"Title"];
    [title setWidth:420.0];
    [title setMinWidth:50.0];

    [title setEditable:YES];
    [title setSortDescriptorPrototype:desc];
    [issuesTable addTableColumn:title];

    var desc = [CPSortDescriptor sortDescriptorWithKey:@"created_at" ascending:YES],
        date = [[CPTableColumn alloc] initWithIdentifier:"created_at"];
    [[date headerView] setStringValue:"Date"];
    [date setWidth:120.0];
    [date setMinWidth:50.0];

    [date setEditable:YES];
    [date setSortDescriptorPrototype:desc];
    [issuesTable addTableColumn:date];

    var desc = [CPSortDescriptor sortDescriptorWithKey:@"votes" ascending:YES],
        votes = [[CPTableColumn alloc] initWithIdentifier:"votes"];
    [[votes headerView] setStringValue:"Votes"];
    [votes setWidth:100.0];
    [votes setMinWidth:50.0];

    [votes setEditable:YES];
    [votes setSortDescriptorPrototype:desc];
    [issuesTable addTableColumn:votes];

    var desc = [CPSortDescriptor sortDescriptorWithKey:@"updated_at" ascending:YES],
        updated = [[CPTableColumn alloc] initWithIdentifier:"updated_at"];
    [[updated headerView] setStringValue:"Updated"];
    [updated setWidth:120.0];
    [updated setMinWidth:50.0];

    [updated setEditable:YES];
    [updated setSortDescriptorPrototype:desc];
    [issuesTable addTableColumn:updated];


    [issuesTable setColumnAutoresizingStyle:CPTableViewUniformColumnAutoresizingStyle];


    [scrollView setDocumentView:issuesTable];
    [scrollView setAutohidesScrollers:YES];
    [scrollView setAutoresizingMask:CPViewWidthSizable|CPViewHeightSizable];
    [view addSubview:scrollView];

    //[issuesTable sizeLastColumnToFit];
}

- (void)addUser:(id)sender
{
    var newUser = prompt("Enter the new GitHub user");
    [projectsController allReposForUser:newUser];
}

- (void)removeUser:(id)sender
{
    alert("coming soon");
}


/*TOOLBAR DELEGATES*/
-(CPArray)toolbarAllowedItemIdentifiers:(CPToolbar)toolbar
{
    return [CPToolbarFlexibleSpaceItemIdentifier, @"searchfield", @"newissue"];
}

-(CPArray)toolbarDefaultItemIdentifiers:(CPToolbar)toolbar
{
    return [CPToolbarFlexibleSpaceItemIdentifier, @"newissue", @"searchfield"];
}

- (CPToolbarItem)toolbar:(CPToolbar)toolbar itemForItemIdentifier:(CPString)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag
{
    //return [CPToolbarFlexibleSpaceItemIdentifier, @"searchfield", @"newissue"];
    var mainBundle = [CPBundle mainBundle],
        toolbarItem = [[CPToolbarItem alloc] initWithItemIdentifier:itemIdentifier];
    switch(itemIdentifier)
    {
        case @"newissue":
            var image = [[CPImage alloc] initWithContentsOfFile:[mainBundle pathForResource:@"toolbar_main_subscribe.png"] size:CPSizeMake(32, 32)],
                highlighted = [[CPImage alloc] initWithContentsOfFile:[mainBundle pathForResource:@"toolbar_main_subscribe.png"] size:CPSizeMake(32, 32)];
                
            [toolbarItem setImage:image];
            [toolbarItem setAlternateImage:highlighted];
            
            [toolbarItem setTarget:self];
            //[toolbarItem setAction:@selector(loadProjectsView:)];
            [toolbarItem setLabel:"New Issue"];
            [toolbarItem setTag:@"NewIssue"];
            
            [toolbarItem setMinSize:CGSizeMake(32, 32)];
            [toolbarItem setMaxSize:CGSizeMake(32, 32)];
        break;

        case @"searchfield":
            var search = [[CPSearchField alloc] initWithFrame:CGRectMake(0,0, 140, 30)]
            [toolbarItem setView:search];
            [toolbarItem setLabel:"Search Issues"];
            [toolbarItem setTag:@"Search Issues"];
            
            [toolbarItem setMinSize:CGSizeMake(140, 30)];
            [toolbarItem setMaxSize:CGSizeMake(140, 30)];
        break;
    }
    return toolbarItem;
}

@end

