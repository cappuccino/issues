
@import <Foundation/CPObject.j>
@import "CPDate+Additions.j"
@import "FilterBar.j"
@import "IssueWebView.j"
@import "PriorityTableDataView.j"
@import "NewIssueWindowController.j"
@import "NewTagController.j"

@implementation IssuesController : CPObject
{
    Repository  repo @accessors;

    @outlet CPView      detailParentView;
    @outlet CPView      noIssuesView;
    @outlet CPView      noRepoView;
    @outlet CPView      loadingIssuesView;
            CPView      displayedView;
            FilterBar   filterBar;

    @outlet CPTableView issuesTableView @accessors;
    @outlet CPWebView   issueWebView @accessors;

    CPString    displayedIssuesKey @accessors;

    CPArray     filteredIssues;
    CPString    searchString;
    unsigned    searchFilter;

    CPAlert     unsavedWarn;
    CPAlert     closeWarn;
    CPAlert     reopenWarn;

    id          _ephemeralSelectedIssue;
    int         _openIssueWindows;
    Function    _callbackIfReturnYes;

    CPImage     _cachedHasPullRequestsImage;
}

- (void)awakeFromCib
{
    displayedIssuesKey = "openIssues";
    _openIssueWindows = 0;

    [self showView:noRepoView];

    // custom headerview so we can show/hide columns
    var newHeader = [[RLTableHeaderView alloc] initWithFrame:[[issuesTableView headerView] frame]];
    [issuesTableView setHeaderView:newHeader];

    // FIX ME: when atlas has a table we wont need this... 
    [issuesTableView setCornerView:[[_CPCornerView alloc] initWithFrame:CGRectMake(0, 0, [CPScroller scrollerWidth], CGRectGetHeight([newHeader frame]))]];

    [issuesTableView setBackgroundColor:[CPColor whiteColor]];

    var desc = [CPSortDescriptor sortDescriptorWithKey:@"has_pull_request" ascending:YES],
        pull = [[CPTableColumn alloc] initWithIdentifier:"pull"];

    var headerview = [pull headerView],
        imageview = [[CPImageView alloc] initWithFrame:CGRectMake(0,5,CGRectGetWidth([headerview bounds]),13)];
        [imageview setImage:[[CPImage alloc] initWithContentsOfFile:[[CPBundle mainBundle] pathForResource:"pull_request_icon.png"] size:CGSizeMake(13, 13)]];
        [imageview setAutoresizingMask:CPViewWidthSizable];
        [imageview setImageScaling:CPScaleNone];
        [headerview addSubview:imageview];

    [pull setWidth:40.0];
    [pull setMinWidth:40.0];
    [pull setSortDescriptorPrototype:desc];

    _cachedHasPullRequestsImage = [[CPImage alloc] initWithContentsOfFile:[[CPBundle mainBundle] pathForResource:"has-pull-request-marker.png"] size:CGSizeMake(11, 12)]
    [pull setDataView:imageview];

    [issuesTableView addTableColumn:pull];

    var desc = [CPSortDescriptor sortDescriptorWithKey:@"number" ascending:YES],
        ID = [[CPTableColumn alloc] initWithIdentifier:"number"],
        dataView = [CPTextField new];

    [dataView setAlignment:CPRightTextAlignment];
    [dataView setLineBreakMode:CPLineBreakByTruncatingTail];
    [dataView setValue:[CPColor colorWithHexString:@"929496"] forThemeAttribute:@"text-color"];
    [dataView setValue:[CPColor whiteColor] forThemeAttribute:@"text-color" inState:CPThemeStateSelectedDataView];
    [dataView setValue:[CPFont boldSystemFontOfSize:12] forThemeAttribute:@"font" inState:CPThemeStateSelectedDataView];
    [dataView setValue:CGInsetMake(0,10,0,0) forThemeAttribute:@"content-inset"];
    [dataView setValue:CPCenterVerticalTextAlignment forThemeAttribute:@"vertical-alignment"];

    [[ID headerView] setStringValue:"ID"];
    [ID setDataView:dataView];
    [ID setWidth:50.0];
    [ID setMinWidth:50.0];
    [ID setEditable:YES];
    [ID setSortDescriptorPrototype:desc];
    [ID setResizingMask:CPTableColumnUserResizingMask];

    [issuesTableView addTableColumn:ID];

    var desc = [CPSortDescriptor sortDescriptorWithKey:@"title" ascending:YES],
        title = [[CPTableColumn alloc] initWithIdentifier:"title"];

    [[title headerView] setStringValue:"Title"];
    [title setWidth:420.0];
    [title setMinWidth:50.0];
    [title setEditable:YES];
    [title setSortDescriptorPrototype:desc];
    [title setResizingMask:CPTableColumnAutoresizingMask | CPTableColumnUserResizingMask];

    var dv = [[CPTextField alloc] initWithFrame:CGRectMakeZero()];
    [dv setLineBreakMode:CPLineBreakByTruncatingTail];
    [title setDataView:dv];

    [issuesTableView addTableColumn:title];

    var desc = [CPSortDescriptor sortDescriptorWithKey:@"votes" ascending:YES],
        votes = [[CPTableColumn alloc] initWithIdentifier:"votes"];

    [[votes headerView] setStringValue:"Votes"];
    [votes setWidth:60.0];
    [votes setMinWidth:50.0];
    [votes setSortDescriptorPrototype:desc];
    [votes setResizingMask:CPTableColumnUserResizingMask];

    [issuesTableView addTableColumn:votes];

    var desc = [CPSortDescriptor sortDescriptorWithKey:@"created_at" ascending:YES],
        date = [[CPTableColumn alloc] initWithIdentifier:"created_at"];

    [[date headerView] setStringValue:"Created"];
    [date setWidth:120.0];
    [date setMinWidth:50.0];
    [date setSortDescriptorPrototype:desc];
    [date setResizingMask:CPTableColumnUserResizingMask];

    [issuesTableView addTableColumn:date];

    var desc = [CPSortDescriptor sortDescriptorWithKey:@"updated_at" ascending:YES],
        updated = [[CPTableColumn alloc] initWithIdentifier:"updated_at"];

    [[updated headerView] setStringValue:"Updated"];
    [updated setWidth:120.0];
    [updated setMinWidth:50.0];
    [updated setSortDescriptorPrototype:desc];
    [updated setResizingMask:CPTableColumnUserResizingMask];

    [issuesTableView addTableColumn:updated];

    var desc = [CPSortDescriptor sortDescriptorWithKey:@"position" ascending:YES],
        priority = [[CPTableColumn alloc] initWithIdentifier:"position"],
        priorityDataView = [PriorityTableDataView new];

    [[priority headerView] setStringValue:"Priority"];
    [priority setDataView:priorityDataView];
    [priority setWidth:60.0];
    [priority setMinWidth:50.0];
    [priority setSortDescriptorPrototype:desc];
    [priority setResizingMask:CPTableColumnUserResizingMask];

    [issuesTableView addTableColumn:priority];

    var desc = [CPSortDescriptor sortDescriptorWithKey:@"user" ascending:YES],
        creator = [[CPTableColumn alloc] initWithIdentifier:"user"];

    [[creator headerView] setStringValue:"Creator"];
    [creator setWidth:120.0];
    [creator setHidden:YES];
    [creator setMinWidth:50.0];
    [creator setSortDescriptorPrototype:desc];
    [creator setResizingMask:CPTableColumnUserResizingMask];

    [issuesTableView addTableColumn:creator];

    var desc = [CPSortDescriptor sortDescriptorWithKey:@"comments" ascending:YES],
        comments = [[CPTableColumn alloc] initWithIdentifier:"comments"];

    [[comments headerView] setStringValue:"Comments"];
    [comments setWidth:120.0];
    [comments setHidden:YES];
    [comments setMinWidth:50.0];
    [comments setSortDescriptorPrototype:desc];
    [comments setResizingMask:CPTableColumnUserResizingMask];

    [issuesTableView addTableColumn:comments];

    var desc = [CPSortDescriptor sortDescriptorWithKey:@"closed_at" ascending:YES],
        closedAt = [[CPTableColumn alloc] initWithIdentifier:"closed_at"];

    [[closedAt headerView] setStringValue:"Closed On"];
    [closedAt setWidth:120.0];
    [closedAt setHidden:YES];
    [closedAt setMinWidth:50.0];
    [closedAt setSortDescriptorPrototype:desc];
    [closedAt setResizingMask:CPTableColumnUserResizingMask];

    [issuesTableView addTableColumn:closedAt];

    [issuesTableView setTarget:self];
    [issuesTableView setDoubleAction:@selector(openIssueInNewWindow:)];
    [issuesTableView setUsesAlternatingRowBackgroundColors:YES];
    [issuesTableView setColumnAutoresizingStyle:CPTableViewUniformColumnAutoresizingStyle];
    [issuesTableView registerForDraggedTypes:[@"RepositionIssueDragType"]];
    [issuesTableView setAllowsMultipleSelection:YES];


    filterBar = [[FilterBar alloc] initWithFrame:CGRectMake(0, 0, 400, 32)];
    [filterBar setAutoresizingMask:CPViewWidthSizable];
    [filterBar setDelegate:self];
    searchFilter = 0;

    [[CPNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(issueChanged:)
                                                 name:GitHubAPIIssueDidChangeNotification
                                               object:nil];
}

- (id)init
{
    if (self = [super init])
    {
        displayedIssuesKey = "openIssues";
    }

    return self;
}

- (@action)takeIssueTypeFrom:(id)sender
{
    [self setDisplayedIssuesKey:[sender selectedTag]];
}

- (void)setDisplayedIssuesKey:(CPString)aKey
{
    displayedIssuesKey = aKey;

    if (!repo)
        return;

    [self selectIssueAtIndex:-1];
    [issuesTableView reloadData];

    [self searchFieldDidChange:nil];
}

- (void)selectIssueAtIndex:(unsigned)index
{
    var indexSet = index < 0 ? [CPIndexSet indexSet] : [CPIndexSet indexSetWithIndex:index];

    if (index >= 0)
        [issuesTableView scrollRowToVisible:index];

    [issuesTableView selectRowIndexes:indexSet byExtendingSelection:NO];
    [self tableViewSelectionDidChange:nil];
}

- (id)selectedIssue
{
    if ([[issuesTableView selectedRowIndexes] count] > 1)
        return nil;

    [[issuesTableView selectedRowIndexes] count];

    var row = [issuesTableView selectedRow],
        item = nil;

    if (row >= 0 && repo)
    {
        if ([filteredIssues count] && [filteredIssues count] > row)
            item = [filteredIssues objectAtIndex:row];
        else if ([repo[displayedIssuesKey] count] && [repo[displayedIssuesKey] count] > row)
            item = [repo[displayedIssuesKey] objectAtIndex:row];
    }

    return item;
}

- (CPArray)selectedIssues
{
    var rows = [issuesTableView selectedRowIndexes],
        count = [rows count],
        items = [ ];

    if (count > 0 && repo)
    {
        if ([filteredIssues count])
            items = [filteredIssues objectsAtIndexes:rows];
        else if ([repo[displayedIssuesKey] count])
            items = [repo[displayedIssuesKey] objectsAtIndexes:rows];
    }

    return items;
}

- (void)issueChanged:(CPNotification)aNote
{
    var issue = [aNote object];
    if (issue === [issueWebView issue])
    {
        [issuesTableView reloadData];
        [self searchFieldDidChange:nil];
        [self tableView:issuesTableView sortDescriptorsDidChange:nil];

        var newIndex = [(filteredIssues || repo[displayedIssuesKey]) indexOfObject:issue];
        [self selectIssueAtIndex:newIndex];
    }
}

- (BOOL)validateToolbarItem:(CPToolbarItem)anItem
{
    var hasSelection = [self selectedIssue] !== nil,
        hasMultipleSelection = [[issuesTableView selectedRowIndexes] count] > 1,
        identifier = [anItem itemIdentifier];

    if (identifier === "openissue")
        return displayedIssuesKey === "closedIssues" && (hasSelection || hasMultipleSelection);
    else if (identifier === "closeissue")
        return displayedIssuesKey === "openIssues" && (hasSelection || hasMultipleSelection);
    else if (identifier === "commentissue")
        return hasSelection;
    else if (identifier === "tagissue")
        return hasSelection;
    else
        return !!repo;
}

- (@action)openIssueInNewWindow:(id)sender
{
    if ([CPPlatform isBrowser] && ![CPPlatformWindow supportsMultipleInstances])
        return;

    var issue = [self selectedIssue];
    if (issue === nil)
        return;

    var newWindow = [[CPWindow alloc] initWithContentRect:CGRectMake(100, 100, 800, 600) styleMask:CPTitledWindowMask | CPClosableWindowMask | CPMiniaturizableWindowMask | CPResizableWindowMask];
    [newWindow setMinSize:CGSizeMake(300, 300)];

    if ([CPPlatform isBrowser])
    {
        var platformWindow = [[CPPlatformWindow alloc] initWithContentRect:CGRectMake(100, 100, 800, 600)];
        [newWindow setPlatformWindow:platformWindow];
        [newWindow setFullBridge:YES];
    }

    var contentView = [newWindow contentView],
        webView = [[IssueWebView alloc] initWithFrame:[contentView bounds]];

    [webView setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable];
    [contentView addSubview:webView];
    [newWindow setTitle:[issue objectForKey:"title"]];

    [newWindow orderFront:self];
    [newWindow setDelegate:webView];

    [webView setIssue:issue];
    [webView setRepo:repo];
    [webView loadIssue];
}

/*
    If the user has a bunch of issues selected we want to make sure 
    they're sure they want to close the issues before we actually do it
    hence an intermediate method...
*/
- (@action)closeIssue:(id)sender
{
    var issues = [self selectedIssues],
        count = [issues count];

        closeWarn = [[CPAlert alloc] init];
        [closeWarn setTitle:"Are You Sure?"];
        [closeWarn setMessageText:"Are you sure you want to close " + count + " issues?"];
        [closeWarn setInformativeText:"Remeber, closed issues can always be reopened by browsing the 'closed issues' tab."];
        [closeWarn setAlertStyle:CPWarningAlertStyle];
        [closeWarn addButtonWithTitle:"Cancel"];
        [closeWarn setDelegate:self];
        [closeWarn addButtonWithTitle:"Close Issues"];
        [closeWarn runModal];
}

/*
    This method actually closes the issues
*/
- (void)_closeIssue
{
    var issues = [self selectedIssues],
        count = [issues count];
    while (count--)
    {
        var issue = issues[count];

        if (issue && [issue objectForKey:"state"] === "open")
            [[GithubAPIController sharedController] closeIssue:issue repository:repo callback:function(){[issuesTableView reloadData];}];
    }

    [issuesTableView selectRowIndexes:[CPIndexSet indexSet] byExtendingSelection:NO];
}

/*
    If the user has a bunch of issues selected we want to make sure 
    they're sure they want to reopen the issues before we actually do it
    hence an intermediate method...
*/
- (@action)reopenIssue:(id)sender
{
    var issues = [self selectedIssues],
        count = [issues count];

    if (count > 1)
    {
        reopenWarn = [[CPAlert alloc] init];
        [reopenWarn setTitle:"Are You Sure?"];
        [reopenWarn setMessageText:"Are you sure you want to reopen " + count + " issues?"];
        [reopenWarn setAlertStyle:CPWarningAlertStyle];
        [reopenWarn addButtonWithTitle:"Cancel"];
        [reopenWarn setDelegate:self];
        [reopenWarn addButtonWithTitle:"Reopen Issues"];
        [reopenWarn runModal];
    }
    else
       [self _reopenIssue];
}

/*
    This method actually reopens the issues
*/
- (void)_reopenIssue
{
    var issues = [self selectedIssues],
        count = [issues count];

    [issuesTableView selectRowIndexes:[CPIndexSet indexSet] byExtendingSelection:NO];

    while (count--)
    {
        var issue = issues[count];

        if (issue && [issue objectForKey:"state"] === "closed")
            [[GithubAPIController sharedController] reopenIssue:issue repository:repo callback:function(){[issuesTableView reloadData];}];
    }
}

- (@action)comment:(id)sender
{
    var issue = [self selectedIssue];
    if (!issue)
        return;

    // FIXME
    var webFrame = [issueWebView._frameView frame];
    [issueWebView._frameView scrollPoint:CGPointMake(0, CGRectGetMaxY(webFrame))];

    var scriptObject = [issueWebView windowScriptObject];
    [scriptObject callWebScriptMethod:"showCommentForm" withArguments:nil];
}

- (CPMenu)_tagsMenu
{
    var menu = [[CPMenu alloc] init],
        newItem = [[CPMenuItem alloc] initWithTitle:@"New Tag" action:@selector(newTag:) keyEquivalent:nil];

    [newItem setTarget:self];

    [menu addItem:newItem];

    var tags = [self tagsForSelectedIssue],
        count = [tags count];

    if (count)
        [menu addItem:[CPMenuItem separatorItem]];

    for (var i = 0; i < count; i++)
    {
        var tag = tags[i],
            item = [[CPMenuItem alloc] initWithTitle:tag.label action:@selector(_toggleTag:) keyEquivalent:nil];

        if (tag.isUsed)
            [item setState:CPOnState];

        [item setTarget:self];
        [item setTag:tag];
        [menu addItem:item];
    }

    return menu;
}

- (@action)tag:(id)aSender
{
    var toolbarView = [[aSender toolbar] _toolbarView],
        view = [toolbarView viewForItem:aSender];

    [CPMenu popUpContextMenu:[self _tagsMenu] withEvent:[CPApp currentEvent] forView:view];
}

- (@action)newTag:(id)aSender
{
    [[[NewTagController alloc] init] showWindow:self];
}

- (@action)_toggleTag:(id)aSender
{
    var tag = [aSender tag],
        selector = tag.isUsed ? @selector(unsetTagForSelectedIssue:) : @selector(setTagForSelectedIssue:);

    [self performSelector:selector withObject:tag.label];
}

- (int)_indexOfEphemeralSelectedIssue
{
    var visiableIssues = filteredIssues || repo[displayedIssuesKey],
        count = [visiableIssues count],
        index = CPNotFound;

    while (count--)
    {
        var sig = repo.identifier + "---" + [visiableIssues[count] objectForKey:"number"];

        if (sig === _ephemeralSelectedIssue)
        {
            index = count;
            break;
        }
    }

    return index;
}

- (@action)newIssue:(id)sender
{
    var controller = [[NewIssueWindowController alloc] initWithWindowCibName:"NewIssueWindow"];
    [controller showWindow:self];
    [controller setRepos:[[[CPApp delegate] reposController] sortedRepos]];
    [controller selectRepo:repo];
    [controller setDelegate:self];

    _openIssueWindows++;

    // YUCKKKKKKK!!!
    [[[[CPApp delegate] mainWindow] platformWindow] _propagateCurrentDOMEvent:NO];
}

- (void)newIssueWindowController:(CPWindowController)aController didAddIssue:(id)anIssue toRepo:(id)aRepo
{
    if (aRepo === repo)
        [issuesTableView reloadData];
}

- (@action)reload:(id)sender
{
    var issue = [self selectedIssue];

    _ephemeralSelectedIssue = [issue objectForKey:"repo_identifier"] + "---" + [issue objectForKey:"number"];

    delete repo.openIssues;
    delete repo.closedIssues;
    [self loadIssues];
}

- (void)loadIssues
{
    if (repo.openIssues && repo.closedIssues)
        return;

    [[GithubAPIController sharedController] loadIssuesForRepository:repo callback:function(success)
    {
        [issuesTableView reloadData];
        [self showView:nil];

        // reselect the issue if it's still there:
        if (_ephemeralSelectedIssue)
        {
            [self selectIssueAtIndex:[self _indexOfEphemeralSelectedIssue]];
            _ephemeralSelectedIssue = nil;
        }
    }];
}

- (void)viewOnGithub:(id)sender
{
    var issue = [self selectedIssue],
        link = BASE_URL + [issue objectForKey:"repo_identifier"] +"/issues/"+[issue objectForKey:"number"];

    OPEN_LINK(link);
}

- (void)showView:(CPView)aView
{
    [displayedView removeFromSuperview];

    if (aView)
    {
        [aView setFrame:[detailParentView bounds]];
        [detailParentView addSubview:aView];
    }

    displayedView = aView;
}

- (void)setRepo:(id)aRepo
{
    if (repo === aRepo)
        return;

    repo = aRepo;

    if (repo)
    {
        if (repo.openIssues && repo.closedIssues)
        {
            [issuesTableView selectRowIndexes:[CPIndexSet indexSet] byExtendingSelection:NO];
            [self showView:nil];
            [self tableViewSelectionDidChange:nil];
        }
        else
        {
            [self showView:loadingIssuesView];
            [self loadIssues];
        }
    }
    else
        [self showView:noRepoView];

    [issuesTableView reloadData];
    [[[[CPApp delegate] mainWindow] toolbar] validateVisibleItems];
}

/*
// it would be nice if the GitHub API would support this
- (void)moveIssueWithNumber:(int)issueNumber toPosition:(int)newPosition
{
    // we can assume the we're not filtering issues

    // find the issue
    var item = nil;

    for (var i = 0; i < [repo[displayedIssuesKey] count]; i++)
    {
        item = repo[displayedIssuesKey][i];

        if ([item valueForKey:@"number"] === issueNumber)
            break;
    }

    if (!item)
        return;

    [[GithubAPIController sharedController] setPositionForIssue:item inRepository:repo to:newPosition callback:function(success)
    {
        //[issuesTableView reloadData];
        // FIX ME: this is returning false... XD
    }];

   
}*/

- (void)alertDidEnd:(CPAlert)anAlert returnCode:(int)tag
{
    if (anAlert === unsavedWarn)
    {
        if (tag === 0 && _callbackIfReturnYes)
            _callbackIfReturnYes();

        _callbackIfReturnYes = nil;
    }
    else if (anAlert === closeWarn && tag === 1)
        [self _closeIssue];
    else if (anAlert === reopenWarn && tag === 1)
        [self _reopenIssue];
}

/*
    The API here is a little weird so bear with me.
    The initial return is BOOL. If it returns NO the 
    callback supplied will get called if the user clicks "okay"
    otherwise nothing happens.
*/
- (BOOL)_shouldUnloadIssueWithCallBack:(Function)aCallback
{
    if (_callbackIfReturnYes !== nil)
        return NO;

     try {
        if ([issueWebView DOMWindow].hasUnsubmittedComment())
        {
            unsavedWarn = [[CPAlert alloc] init];
            [unsavedWarn setTitle:"Unsubmitted Comment"];
            [unsavedWarn setDelegate:self];
            [unsavedWarn setAlertStyle:CPWarningAlertStyle];
            [unsavedWarn setMessageText:"You have an unsubmitted comment. This comment will be lost if you switch issues."]
            [unsavedWarn addButtonWithTitle:"Switch Issue"];
            [unsavedWarn addButtonWithTitle:"Stay Here"];
            [unsavedWarn._buttons[1] setKeyEquivalent:CPEscapeFunctionKey];
            [unsavedWarn runModal];
            _callbackIfReturnYes = aCallback;

            return NO;
        }

    } catch(e) { }

    return YES;
}

- (BOOL)tableView:(CPTableView)aTableView shouldSelectRow:(int)aRow
{
    var callback = function()
    {
        [issuesTableView selectRowIndexes:[CPIndexSet indexSetWithIndex:aRow] byExtendingSelection:NO];
        [self tableViewSelectionDidChange:nil];
    }
    return [self _shouldUnloadIssueWithCallBack:callback];
}

- (void)tableViewSelectionDidChange:(CPNotification)aNotification
{
    [issueWebView loadHTMLString:""];

    if ([[issuesTableView selectedRowIndexes] count] === 1)
    {
        var item = [self selectedIssue];

        if (item)
        {
            [issueWebView setIssue:item];
            [issueWebView setRepo:repo];
            [issueWebView loadIssue];

            [CPApp setArguments:[repo.owner.login, repo.name, [item objectForKey:"number"]]];
        }
    }
    else
    {
        [issueWebView setIssue:item];
        [issueWebView setRepo:repo];
    }

    [[[[CPApp delegate] mainWindow] toolbar] validateVisibleItems];
}

- (id)tableView:(CPTableView)aTableView objectValueForTableColumn:(int)aColumn row:(int)aRow
{
    var columnIdentifier = [aColumn identifier],
        issue = [(filteredIssues || repo[displayedIssuesKey]) objectAtIndex:aRow],
        value = [issue objectForKey:columnIdentifier];

    if (value === [CPNull null])
        value = "";

    //special cases
    if (columnIdentifier === @"created_at" || columnIdentifier === @"updated_at")
        value = [CPDate simpleDate:value];
    else if ((columnIdentifier === @"votes" && value === 0) || columnIdentifier === @"comments" && value === 0)
        value = @"-";
    else if (columnIdentifier === @"position")
    {
        var min = repo[displayedIssuesKey + "Min"],
            max = repo[displayedIssuesKey + "Max"];
        value = (max - value) / (max - min);
    }
    else if (columnIdentifier === @"closed_at")
    {
        if (value === [CPNull null])
            return "Open";
        else
            value = [CPDate simpleDate:value];
    }
    else if (columnIdentifier === "pull")
        value = [issue objectForKey:"has_pull_request"] ? _cachedHasPullRequestsImage : nil;


    return value;
}

- (int)numberOfRowsInTableView:(CPTableView)aTableView
{
    if (filteredIssues)
        return filteredIssues.length;
    else if (repo && repo[displayedIssuesKey])
        return repo[displayedIssuesKey].length;
    else
        return 0;
}

- (void)tableView:(CPTableView)aTableView sortDescriptorsDidChange:(CPArray)oldDescriptors
{
    var newDescriptors = [aTableView sortDescriptors],
        issues = filteredIssues || repo[displayedIssuesKey],
        currentIssue = issues[[aTableView selectedRow]];

    [issues sortUsingDescriptors:newDescriptors];
    [aTableView reloadData];

    var newIndex = [issues indexOfObject:currentIssue];
    if (newIndex >= 0)
        [aTableView selectRowIndexes:[CPIndexSet indexSetWithIndex:newIndex] byExtendingSelection:NO];
}

- (BOOL)tableView:(CPTableView)aTableView writeRowsWithIndexes:(CPIndexSet)rowIndexes toPasteboard:(CPPasteboard)pboard
{
    // early return because it doesn't look like the GitHub API supports repositioning yet.
    return NO;

    // we can only reposition issue if they're sorted by position and we're not filtering them
    if (![[aTableView sortDescriptors] count] || [[aTableView sortDescriptors][0] key] !== @"position" || [filteredIssues count])
        return NO;

    [pboard declareTypes:[CPArray arrayWithObject:@"RepositionIssueDragType"] owner:self];

    // give the issue number to the pasteboard.
    var item = [[repo[displayedIssuesKey] objectAtIndex:[rowIndexes firstIndex]] valueForKey:@"number"],
        encodedData = [CPKeyedArchiver archivedDataWithRootObject:item];
    [pboard setData:encodedData forType:@"RepositionIssueDragType"];

    return YES;
}

- (CPDragOperation)tableView:(CPTableView)aTableView
                   validateDrop:(id)info
                   proposedRow:(CPInteger)row
                   proposedDropOperation:(CPTableViewDropOperation)operation
{
    if ([[[info draggingPasteboard] types] containsObject:@"RepositionIssueDragType"])
    {
        [aTableView setDropRow:row dropOperation:CPTableViewDropAbove];
        return CPDragOperationMove;
    }

    return CPDragOperationNone;
}

- (BOOL)tableView:(CPTableView)aTableView acceptDrop:(id)info row:(int)row dropOperation:(CPTableViewDropOperation)operation
{
    if ([[[info draggingPasteboard] types] containsObject:@"RepositionIssueDragType"])
    {

        var pboard = [info draggingPasteboard],
            dragData = [CPKeyedUnarchiver unarchiveObjectWithData:[pboard dataForType:@"RepositionIssueDragType"]];

        [self moveIssueWithNumber:dragData toPosition:row];

        return YES;
    }

    return NO;
}

- (CPMenu)tableView:(CPTableView)aTableView menuForTableColumn:(CPTableColumn)aColumn row:(int)aRow
{
    // menu should open/close
    // comment
    // tag
    var menu = [[CPMenu alloc] initWithTitle:""],
        menuItems = ["Re-open Issue", "Close Issue", "Tag", "Comment", "View On GitHub"],
        menuActions = [@selector(reopenIssue:), @selector(closeIssue:), nil, @selector(comment:), @selector(viewOnGithub:)],
        isOpen = displayedIssuesKey === "openIssues",
        numberOfSelectedIssues = [[self selectedIssues] count],
        count = menuItems.length,
        i = 0;

    // if we have more than one issue selected and the user right clicks
    // on a different issue we should just select the issue he right clicked
    if (![[issuesTableView selectedRowIndexes] containsIndex:aRow])
        [self selectIssueAtIndex:aRow];

    // this might have just changed... recalculate
    numberOfSelectedIssues = [[self selectedIssues] count];

        for (; i < count; i++)
        {
            var title = menuItems[i],
                newMenuItem = [[CPMenuItem alloc] initWithTitle:title action:menuActions[i] keyEquivalent:nil];

            [newMenuItem setTarget:self];

            switch (title)
            {
                case "Re-open Issue":
                    if (numberOfSelectedIssues > 1)
                        [newMenuItem setTitle:"Re-open (" + numberOfSelectedIssues + ") Issues" ];

                    [newMenuItem setEnabled:!isOpen];
                    break;

                case "Close Issue":
                    if (numberOfSelectedIssues > 1)
                        [newMenuItem setTitle:"Close (" + numberOfSelectedIssues + ") Issues"];


                    [newMenuItem setEnabled:isOpen];
                    break;

                case "Tag":
                    var shouldTag = numberOfSelectedIssues === 1;

                    [newMenuItem setEnabled:shouldTag];

                    if (shouldTag)
                        [newMenuItem setSubmenu:[self _tagsMenu]];
                    break;
                case "Comment":
                    [newMenuItem setEnabled:(numberOfSelectedIssues === 1)];
                    break;
                // we want a seperator so just skip it for now
                case "View On GitHub":
                    [newMenuItem setEnabled:(numberOfSelectedIssues === 1 || aRow !== CPNotFound)];
                    continue;
                    break;
            }

            if (aRow === CPNotFound)
                [newMenuItem setEnabled:NO];

            [menu addItem:newMenuItem];
        }

        // add the seperator and the last item
        [menu addItem:[CPMenuItem separatorItem]];
        [menu addItem:newMenuItem];

    return menu;
}

- (BOOL)tableView:(CPTableView)aTableView shouldEditTableColumn:(CPTableColumn)tableColumn row:(int)row
{
    if (![[GithubAPIController sharedController] isAuthenticated])
        return NO;

    return ([tableColumn identifier] === "title");
}

- (void)tableView:(CPTableView)aTableView setObjectValue:(id)aValue forTableColumn:(CPTableColumn)tableColumn row:(int)row
{
    // go ahead and set the value
    var issue = [(filteredIssues || repo[displayedIssuesKey]) objectAtIndex:row],
        curr = [issue objectValueForKey:"title"];

    // Dont update if there's nothing to change...
    if (curr === aValue)
        return;

    [issue setObject:aValue forKey:"title"];
    // query github inside callback reload data with github's new title.
    [[GithubAPIController sharedController] editIsssue:issue title:aValue body:[issue objectForKey:"body"] repository:repo callback:function(){
        // FIX ME: only a couple columns and rows instead of everything...
        [aTableView reloadData];
    }];
}

- (void)tableViewDeleteKeyPressed:(CPTableView)aTableView
{
    [self closeIssue:self];
}

- (void)searchFieldDidChange:(id)sender
{
    if (sender)
        searchString = [[sender stringValue]  lowercaseString];

    if (searchString)
    {
        [self showFilterBar];
        filteredIssues = [];

        var theIssues = repo[displayedIssuesKey];
        for (var i = 0, count = [theIssues count]; i < count; i++)
        {
            var item = [theIssues objectAtIndex:i];

            if ((searchFilter === IssuesFilterAll || searchFilter === IssuesFilterTitle) &&
                [[item valueForKey:@"title"] lowercaseString].match(searchString))
            {
                [filteredIssues addObject:[theIssues objectAtIndex:i]];
                continue;
            }

            if ((searchFilter === IssuesFilterAll || searchFilter === IssuesFilterCreator) && [item valueForKey:@"user"] !== [CPNull null] &&
                [[item valueForKey:@"user"] lowercaseString].match(searchString))
            {
                [filteredIssues addObject:[theIssues objectAtIndex:i]];
                continue;
            }

            if ((searchFilter === IssuesFilterAll || searchFilter === IssuesFilterBody) &&
                [[item valueForKey:@"body"] lowercaseString].match(searchString))
            {
                [filteredIssues addObject:[theIssues objectAtIndex:i]];
                continue;
            }

            var tags = [[item objectForKey:@"labels"] componentsJoinedByString:@" "];
            if ((searchFilter === IssuesFilterAll || searchFilter === IssuesFilterLabels) &&
                [tags lowercaseString].match(searchString))
            {
                [filteredIssues addObject:[theIssues objectAtIndex:i]];
            }
        }

        [issuesTableView reloadData];
    }
    else
    {
        // get selected item
        var item = [self selectedIssue];

        [self hideFilterBar];
        filteredIssues = nil;

        // reload the table
        [issuesTableView reloadData];
        //select the index of found data to keep the correct selection
        if (item && [issuesTableView numberOfRows] > 0)
        {
            var index = [repo[displayedIssuesKey] indexOfObject:item];
            [self selectIssueAtIndex:index];
        }
    }
}

- (void)filterBarSelectionDidChange:(id)aFilterBar
{
    searchFilter = [aFilterBar selectedFilter];
    [self searchFieldDidChange:nil];
}

- (void)showFilterBar
{
    if ([filterBar superview])
        return;

    [filterBar setFrame:CGRectMake(0, 0, CGRectGetWidth([detailParentView frame]), 32)];
    [detailParentView addSubview:filterBar];

    var scrollView = [issuesTableView enclosingScrollView],
        frame = [scrollView frame];

    frame.origin.y = 32;
    frame.size.height -= 32;
    [scrollView setFrame:frame];
}

- (void)hideFilterBar
{
    if (![filterBar superview])
        return;

    [filterBar removeFromSuperview];

    var scrollView = [issuesTableView enclosingScrollView],
        frame = [scrollView frame];

    frame.origin.y = 0;
    frame.size.height += 32;
    [scrollView setFrame:frame];
}

- (CPArray)tagsForSelectedIssue
{
    var items = [],
        issuesLabels = [[self selectedIssue] objectForKey:@"labels"],
        repoLabelCount = [repo.labels count];

    for (var i = 0; i < repoLabelCount; i++)
    {
        var currentLabel = repo.labels[i],
            newItem = {label: currentLabel, isUsed: [issuesLabels containsObject:currentLabel]};

        items.push(newItem);
    }

    return items;
}

- (void)setTagForSelectedIssue:(CPString)aTag
{
    [[GithubAPIController sharedController] label:aTag forIssue:[self selectedIssue] repository:repo shouldRemove:NO];
}

- (void)unsetTagForSelectedIssue:(CPString)aTag
{
    [[GithubAPIController sharedController] label:aTag forIssue:[self selectedIssue] repository:repo shouldRemove:YES];
}

- (void)editIssue:(Issue)anIssue repo:(Repository)aRepo
{
    var controller = [[NewIssueWindowController alloc] initWithWindowCibName:"NewIssueWindow"];

    [controller showWindow:self];
    [controller setRepos:[[[CPApp delegate] reposController] sortedRepos]];
    [controller selectRepo:repo];
    [controller setDelegate:self];
    [controller setShouldEdit:YES];
    [controller setSelectedIssue:anIssue];

    _openIssueWindows++;
}

@end

@implementation CPDictionary (JSObjects)

- (Object)toJSObject
{
    var object = {},
        keyEnumerator = [self keyEnumerator],
        key = nil;

    while ((key = [keyEnumerator nextObject]) !== nil)
        object[key] = [self objectForKey:key];

    return object;
}

@end

@implementation CPArray (pluck)
- (CPArray)pluckForKey:(CPString)aString
{
    var i = 0,
        count = [self count],
        pluckedValues = [];

    for (; i < count; i++)
    {
        var obj = self[i];

        if (obj.isa)
            var value = [obj objectForKey:aString];
        else
            var value = obj[aString];

        if (value)
            pluckedValues.push(value)
    }

    return pluckedValues;
}
@end
