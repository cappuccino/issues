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
@import <AppKit/CPTextField.j>
@import "Classes/LPMultiLineTextField.j"
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
    CPWindow    theWindow @accessors;
    CPSplitView outsideSplitView;
    CPView      searchFilterBar;
    CPSearchField searchField; // FIX ME: get rid of this and do it right please. :) 
    CPScrollView issuesScrollView;
    CPTableView sourceList @accessors;
    CPTableView issuesTable @accessors;
    IssueView  issueView @accessors;

    CPRadioGroup searchFilterRadioGroup;

    // controllers
    id          projectsController;
    id          issuesController;

    CPCookie    followedUsersCookie @accessors;

    CPWindow    newIssueWindow @accessors;
    CPTextField newIssueTitle @accessors;
    CPTextField newIssueBody @accessors;

    CPWindow    commentSheet @accessors;
    CPTextField commentBody @accessors;
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

    searchField = [[CPSearchField alloc] initWithFrame:CGRectMake(0,0, 140, 30)];
    [searchField setTarget:issuesController];
    [searchField setAction:@selector(searchFieldDidChange:)];
    [searchField setSendsSearchStringImmediately:YES];

    var toolbar = [[CPToolbar alloc] initWithIdentifier:@"MainToolbar"];
    [toolbar setDelegate:self];
    [theWindow setToolbar:toolbar];

    // make the "new issue" window
    newIssueWindow = [[CPWindow alloc] initWithContentRect:CGRectMake(0, 0, 400, 300) styleMask:CPTitledWindowMask | CPClosableWindowMask | CPResizableWindowMask];
    [newIssueWindow setMinSize:CGSizeMake(400,300)];
    [newIssueWindow setTitle:@"New Issue"];
    newIssueTitle = [[CPTextField alloc] initWithFrame:CGRectMake(15, 10, 370, 29)];
    [newIssueTitle setAutoresizingMask:CPViewWidthSizable];
    [newIssueTitle setPlaceholderString:@"Issue Title"];
    [newIssueTitle setEditable:YES];
    [newIssueTitle setBezeled:YES];
    [[newIssueWindow contentView] addSubview:newIssueTitle];

    newIssueBody = [[LPMultiLineTextField alloc] initWithFrame:CGRectMake(15, 49, 370, 205)];
    [newIssueBody setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable];
    [newIssueBody setPlaceholderString:@"Hello World"];
    [newIssueBody setEditable:YES];
    [newIssueBody setBezeled:YES];
    [[newIssueWindow contentView] addSubview:newIssueBody];

    var addButton = [[CPButton alloc] initWithFrame:CGRectMake(280, 260, 100, 24)];
    [addButton setAutoresizingMask:CPViewMinXMargin | CPViewMinYMargin];
    [addButton setTitle:@"Add Issue"];
    [addButton setTarget:issuesController];
    [addButton setAction:@selector(createNewIssue:)];
    [[newIssueWindow contentView] addSubview:addButton];

    var cancelButton = [[CPButton alloc] initWithFrame:CGRectMake(160, 260, 100, 24)];
    [cancelButton setAutoresizingMask:CPViewMinXMargin | CPViewMinYMargin];
    [cancelButton setTitle:@"Cancel"];
    [cancelButton setTarget:issuesController];
    [cancelButton setAction:@selector(cancel:)];
    [[newIssueWindow contentView] addSubview:cancelButton];

    [newIssueWindow setDefaultButton:addButton];
    [newIssueWindow center];
    //[newIssueWindow orderFront:self];

    //sheets
    commentSheet = [[CPWindow alloc] initWithContentRect:CGRectMake(0,0,400,300) styleMask:CPDocModalWindowMask|CPResizableWindowMask];
    [commentSheet setMinSize:CGSizeMake(400, 300)];
    [commentSheet setMaxSize:CGSizeMake(400, 700)];
    commentBody  = [[LPMultiLineTextField alloc] initWithFrame:CGRectMake(15, 10, 370, 246)];
    [commentBody setEditable:YES];
    [commentBody setBezeled:YES];
    [commentBody setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable];

    var addButton = [[CPButton alloc] initWithFrame:CGRectMake(280, 260, 100, 24)];
    [addButton setAutoresizingMask:CPViewMinXMargin | CPViewMinYMargin];
    [addButton setTitle:@"Add Comment"];
    [addButton setTarget:issuesController];
    [addButton setAction:@selector(commentOnActiveIssue:)];

    var cancelButton = [[CPButton alloc] initWithFrame:CGRectMake(165, 260, 100, 24)];
    [cancelButton setAutoresizingMask:CPViewMinXMargin | CPViewMinYMargin];
    [cancelButton setTitle:@"Cancel"];
    [cancelButton setTarget:issuesController];
    [cancelButton setAction:@selector(cancel:)];

    [commentSheet setDefaultButton:addButton];
    [[commentSheet contentView] addSubview:commentBody];
    [[commentSheet contentView] addSubview:addButton];
    [[commentSheet contentView] addSubview:cancelButton];
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

    var issueView = [[IssueView alloc] initWithFrame:[outsideSplitView bounds] controller:issuesController];
    [issuesController setIssueView:issueView];
    [issuesSplitView addSubview:issuesTable];
    [issuesSplitView addSubview:issueView];

    [issuesSplitView setPosition:200 ofDividerAtIndex:0];

    [self setupSourceList:sourceListContentView];
    [self setupIssuesTable:issuesTable];
}

- (void)setupSourceList:(id)view
{
    var scrollView = [[CPScrollView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth([view bounds]), CGRectGetHeight([view bounds]) - 26)];
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


    var buttonBarTop = [view frame].size.height - 26;
    sourceViewButtonBar = [[CPButtonBar alloc] initWithFrame:CGRectMake(0, buttonBarTop, [view frame].size.width, 26)];
    [sourceViewButtonBar setAutoresizingMask:CPViewWidthSizable|CPViewMinYMargin];
    [view addSubview:sourceViewButtonBar];
    sourceViewAddButton = [[CPButton alloc] initWithFrame:CGRectMake(0,0,35,26)];
    sourceViewRemoveButton = [[CPButton alloc] initWithFrame:CGRectMake(34,0,35,26)];
    [sourceViewAddButton setBordered:NO];
    [sourceViewRemoveButton setBordered:NO];
    
    [sourceViewAddButton setImage:[[CPImage alloc] initWithContentsOfFile:@"Resources/PlusButton.png" size:CGSizeMake(35, 26)]];
    [sourceViewRemoveButton setImage:[[CPImage alloc] initWithContentsOfFile:@"Resources/MinusButton.png" size:CGSizeMake(35, 26)]];
    [sourceViewAddButton setAlternateImage:[[CPImage alloc] initWithContentsOfFile:@"Resources/PlusButtonHighlight.png" size:CGSizeMake(35, 26)]];
    [sourceViewRemoveButton setAlternateImage:[[CPImage alloc] initWithContentsOfFile:@"Resources/MinusButtonHighlight.png" size:CGSizeMake(35, 26)]];
    
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
    searchFilterBar = [[CPView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth([view bounds]), 32)];
    var headerImage = [[CPImage alloc] initWithContentsOfFile:@"Resources/HeaderBackground.png" size:CGSizeMake(14, 32)];
    [searchFilterBar setBackgroundColor:[CPColor colorWithPatternImage:headerImage]];
    [searchFilterBar setAutoresizingMask:CPViewWidthSizable];
    [view addSubview:searchFilterBar];
    [searchFilterBar setHidden:YES];

    var bundle = [CPBundle bundleForClass:[self class]],
        leftCapImage = [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"MediaFilterLeftCap.png"] size:CGSizeMake(9, 19)],
        rightCapImage = [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"MediaFilterRightCap.png"] size:CGSizeMake(9, 19)],
        centerImage = [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"MediaFilterCenter.png"] size:CGSizeMake(1, 19)],
        bezelImage = [[CPThreePartImage alloc] initWithImageSlices:[leftCapImage, centerImage, rightCapImage] isVertical:NO];

    var allRadio = [CPRadio radioWithTitle:@"All"],
        titleRadio = [CPRadio radioWithTitle:@"Title"],
        bodyRadio = [CPRadio radioWithTitle:@"Body"],
        labelsRadio = [CPRadio radioWithTitle:@"Labels"],
        radioButtons = [allRadio, titleRadio, bodyRadio, labelsRadio];
    for (var i=0, count = radioButtons.length; i < count; i++)
    {
        var thisRadio = radioButtons[i];
        
        [thisRadio setAlignment:CPCenterTextAlignment];
        [thisRadio setValue:[CPColor clearColor] forThemeAttribute:@"bezel-color"];
        [thisRadio setValue:[CPColor colorWithPatternImage:bezelImage] forThemeAttribute:@"bezel-color" inState:CPThemeStateSelected];
        [thisRadio setValue:CGInsetMake(0.0, 10.0, 0.0, 10.0) forThemeAttribute:@"content-inset"];
        [thisRadio setValue:CGSizeMake(0.0, 19.0) forThemeAttribute:@"min-size"];
    
        [thisRadio setValue:CGSizeMake(0.0, 1.0) forThemeAttribute:@"text-shadow-offset" inState:CPThemeStateBordered];
        [thisRadio setValue:[CPColor colorWithCalibratedWhite:79.0 / 255.0 alpha:1.0] forThemeAttribute:@"text-color"];
        [thisRadio setValue:[CPColor colorWithCalibratedWhite:240.0 / 255.0 alpha:1.0] forThemeAttribute:@"text-shadow-color"];
        [thisRadio setValue:[CPColor colorWithCalibratedWhite:1.0 alpha:1.0] forThemeAttribute:@"text-color" inState:CPThemeStateSelected];
        [thisRadio setValue:[CPColor colorWithCalibratedWhite:79 / 255.0 alpha:1.0] forThemeAttribute:@"text-shadow-color" inState:CPThemeStateSelected];
    
        [thisRadio sizeToFit];
 
        [thisRadio setTarget:issuesController];
        [thisRadio setAction:@selector(filterDidChange:)];
 
        [searchFilterBar addSubview:thisRadio];
    }

    searchFilterRadioGroup = [allRadio radioGroup];
    [titleRadio setRadioGroup:searchFilterRadioGroup];
    [bodyRadio setRadioGroup:searchFilterRadioGroup];
    [labelsRadio setRadioGroup:searchFilterRadioGroup];

    [allRadio setTag:0];
    [titleRadio setTag:1];
    [bodyRadio setTag:2];
    [labelsRadio setTag:3];

    [allRadio setFrameOrigin:CGPointMake(8, 6)];
    [titleRadio setFrameOrigin:CGPointMake(CGRectGetMaxX([allRadio frame]) + 8, CGRectGetMinY([allRadio frame]))];
    [bodyRadio setFrameOrigin:CGPointMake(CGRectGetMaxX([titleRadio frame]) + 8, CGRectGetMinY([titleRadio frame]))];
    [labelsRadio setFrameOrigin:CGPointMake(CGRectGetMaxX([bodyRadio frame]) + 8, CGRectGetMinY([bodyRadio frame]))];

    issuesScrollView = [[CPScrollView alloc] initWithFrame:[view bounds]];
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


    [issuesScrollView setDocumentView:issuesTable];
    [issuesScrollView setAutohidesScrollers:YES];
    [issuesScrollView setAutoresizingMask:CPViewWidthSizable|CPViewHeightSizable];
    [view addSubview:issuesScrollView];

    //[issuesTable sizeLastColumnToFit];

    [titleRadio performClick:nil];
}

- (void)addUser:(id)sender
{
    var newUser = prompt("Enter the new GitHub user");
    if(newUser)
        [projectsController allReposForUser:newUser];
}

- (void)removeUser:(id)sender
{
    alert("coming soon");
}


/*TOOLBAR DELEGATES*/
-(CPArray)toolbarAllowedItemIdentifiers:(CPToolbar)toolbar
{
    return [CPToolbarFlexibleSpaceItemIdentifier, CPToolbarSpaceItemIdentifier, @"searchfield", @"newissue", @"switchViewStatus"];
}

-(CPArray)toolbarDefaultItemIdentifiers:(CPToolbar)toolbar
{
    // Is there a better way to make that segmented control stay centered? 
    return [@"newissue", CPToolbarFlexibleSpaceItemIdentifier, CPToolbarSpaceItemIdentifier, CPToolbarSpaceItemIdentifier, CPToolbarSpaceItemIdentifier, CPToolbarSpaceItemIdentifier, @"switchViewStatus", CPToolbarFlexibleSpaceItemIdentifier, @"searchfield"];
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
            
            [toolbarItem setTarget:issuesController];
            [toolbarItem setAction:@selector(showNewIssueWindow:)];
            [toolbarItem setLabel:"New Issue"];
            [toolbarItem setTag:@"NewIssue"];
            
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
    return toolbarItem;
}

- (void)toolbar:(id)aToolbar itemForItemIdentifier:(id)anID willbeInsertedIntoToolbar:(BOOL)aFlag
{
    //console.log(anID);
}

@end

@implementation AppController (search)
- (void)showSearchFilter
{
    if(![searchFilterBar isHidden])    
        return;

    var bounds = [issuesScrollView bounds];
    [issuesScrollView setFrame:CGRectMake(0, 32, CGRectGetWidth(bounds), CGRectGetHeight(bounds) - 32)];
    [searchFilterBar setHidden:NO];
}

- (void)hideSearchFilter
{
    if([searchFilterBar isHidden])    
        return;

    var bounds = [issuesScrollView bounds];
    [issuesScrollView setFrame:CGRectMake(0, 0, CGRectGetWidth(bounds), CGRectGetHeight(bounds) + 32)];
    [searchFilterBar setHidden:YES];
}
@end