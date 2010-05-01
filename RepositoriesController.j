
@import <Foundation/CPObject.j>
@import "IssuesController.j"

@implementation RepositoriesController : CPObject
{
    @outlet CPView      repositoryView;
    @outlet CPView      noReposView;
    @outlet CPTableView sourcesListView @accessors;
    @outlet CPButtonBar sourcesListButtonBar @accessors;

            CPArray     sortedRepos @accessors;
	@outlet IssuesController issuesController;
}

- (id)init
{
    self = [super init];
    sortedRepos = [];
    return self;
}

- (void)awakeFromCib
{
    var plusButton = [CPButtonBar plusButton],
        minusButton = [CPButtonBar minusButton];

    [plusButton setTarget:self];
    [plusButton setAction:@selector(promptForNewRepository:)];
    [minusButton setTarget:self];
    [minusButton setAction:@selector(removeRepository:)];

    [sourcesListButtonBar setButtons:[plusButton, minusButton]];
    [sourcesListView setHeaderView:nil];
    [sourcesListView setCornerView:nil];

    var column = [[CPTableColumn alloc] initWithIdentifier:"sourcelist"];
    [[column headerView] setStringValue:"Projects"];

    [column setWidth:220.0];
    [column setMinWidth:50.0];
    [column setEditable:YES];
    [column setDataView:repositoryView];
    
    [sourcesListView addTableColumn:column];
    [sourcesListView setColumnAutoresizingStyle:CPTableViewUniformColumnAutoresizingStyle];
    [sourcesListView setRowHeight:28.0];
    [sourcesListView setSelectionHighlightStyle:CPTableViewSelectionHighlightStyleSourceList];
    sourcesListView._sourceListActiveGradient = CGGradientCreateWithColorComponents(CGColorSpaceCreateDeviceRGB(), [161.0/255.0, 192.0/255.0, 210.0/255.0,1.0, 99.0/255.0, 150.0/255.0, 180.180/255.0, 1.0], [0,1], 2);
    sourcesListView._sourceListActiveTopLineColor = [CPColor colorWithCalibratedRed:(106.0/255.0) green:(154.0/255.0) blue:(182.0/255.0) alpha:1.0];
    sourcesListView._sourceListActiveBottomLineColor = [CPColor colorWithCalibratedRed:(87.0/255.0) green:(127.0/255.0) blue:(151.0/255.0) alpha:1.0];

    [repositoryView setBackgroundColor:[CPColor colorWithHexString:@"eef2f8"]];

	[self showNoReposView];
}

- (void)showNoReposView
{
	var theWindow = [[CPApp delegate] mainWindow],
		contentView = [theWindow contentView];

	[theWindow setToolbar:nil];
	[noReposView setFrame:[contentView bounds]];
	[contentView addSubview:noReposView];
}

- (void)hideNoReposView
{
    var toolbar = [[CPToolbar alloc] initWithIdentifier:"mainToolbar"],
        delegate = [CPApp delegate];

    [toolbar setDelegate:delegate];
	[[delegate mainWindow] setToolbar:toolbar];

	[noReposView removeFromSuperview];
}

- (void)windowWillClose:(id)sender
{
    //do something
}

- (void)addRepository:(id)aRepo
{
    if (!aRepo)
        return;

    sortedRepos.unshift(aRepo);
    [sourcesListView reloadData];
    [sourcesListView selectRowIndexes:[CPIndexSet indexSetWithIndex:0] byExtendingSelection:NO];
    [self tableViewSelectionDidChange:nil];

	[self hideNoReposView];
}

- (@action)promptForNewRepository:(id)sender
{
    var newRepoWindow = [NewRepoWindow sharedNewRepoWindow];
    [newRepoWindow setDelegate:self];
    [newRepoWindow makeKeyAndOrderFront:self];
}

- (@action)removeRepository:(id)sender
{
    var selectedRow = [sourcesListView selectedRow];
    if (selectedRow < 0)
        return;

    sortedRepos.splice(selectedRow, 1);
    [sourcesListView reloadData];

	if (sortedRepos.length === 0)
		[self showNoReposView];
	else
	{
        [sourcesListView selectRowIndexes:[CPIndexSet indexSetWithIndex:MAX(MIN(selectedRow, sortedRepos.length - 1), 0)] byExtendingSelection:NO];
        [self tableViewSelectionDidChange:nil];
	}
}

- (void)tableViewSelectionDidChange:(CPNotification)aNotification
{
	var selectedRow = [sourcesListView selectedRow];
	if (selectedRow === -1)
		[issuesController setRepo:nil];
	else
		[issuesController setRepo:sortedRepos[selectedRow]];
}

- (id)tableView:(CPTableView)aTableView objectValueForTableColumn:(int)aColumn row:(int)aRow
{
    return sortedRepos[aRow];
}

- (int)numberOfRowsInTableView:(CPTableView)aTableView
{
    return sortedRepos.length;
}

@end
