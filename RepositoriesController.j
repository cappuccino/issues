
@import <Foundation/CPObject.j>
@import "IssuesController.j"

var ToolbarColor = nil;

@implementation RepositoriesController : CPObject
{
    @outlet CPView      repositoryView;
    @outlet CPView      noReposView;
    @outlet CPTableView sourcesListView @accessors;
    @outlet CPButtonBar sourcesListButtonBar @accessors;

            CPArray     sortedRepos @accessors;
	@outlet IssuesController issuesController;
}

+ (void)initialize
{
    // FIXME this needs to be themeable
    ToolbarColor = [CPColor colorWithPatternImage:[[CPImage alloc] initWithContentsOfFile:[[CPBundle mainBundle] pathForResource:"toolbarBackgroundColor.png"] size:CGSizeMake(1, 59)]];
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
        minusButton = [CPButtonBar minusButton],
        bezelColor = [CPColor colorWithPatternImage:[[CPImage alloc] initWithContentsOfFile:[[CPBundle mainBundle] pathForResource:"buttonBarBackground.png"] size:CGSizeMake(1, 27)]],
        leftBezel = [[CPImage alloc] initWithContentsOfFile:[[CPBundle mainBundle] pathForResource:"buttonBarLeftBezel.png"] size:CGSizeMake(2, 26)],
        centerBezel = [[CPImage alloc] initWithContentsOfFile:[[CPBundle mainBundle] pathForResource:"buttonBarCenterBezel.png"] size:CGSizeMake(1, 26)],
        rightBezel = [[CPImage alloc] initWithContentsOfFile:[[CPBundle mainBundle] pathForResource:"buttonBarRightBezel.png"] size:CGSizeMake(2, 26)],
        buttonBezel = [CPColor colorWithPatternImage:[[CPThreePartImage alloc] initWithImageSlices:[leftBezel, centerBezel, rightBezel] isVertical:NO]],
        leftBezelHighlighted = [[CPImage alloc] initWithContentsOfFile:[[CPBundle mainBundle] pathForResource:"buttonBarLeftBezelHighlighted.png"] size:CGSizeMake(2, 26)],
        centerBezelHighlighted = [[CPImage alloc] initWithContentsOfFile:[[CPBundle mainBundle] pathForResource:"buttonBarCenterBezelHighlighted.png"] size:CGSizeMake(1, 26)],
        rightBezelHighlighted = [[CPImage alloc] initWithContentsOfFile:[[CPBundle mainBundle] pathForResource:"buttonBarRightBezelHighlighted.png"] size:CGSizeMake(2, 26)],
        buttonBezelHighlighted = [CPColor colorWithPatternImage:[[CPThreePartImage alloc] initWithImageSlices:[leftBezelHighlighted, centerBezelHighlighted, rightBezelHighlighted] isVertical:NO]];

    [plusButton setTarget:self];
    [plusButton setAction:@selector(promptForNewRepository:)];
    [minusButton setTarget:self];
    [minusButton setAction:@selector(removeRepository:)];

    [sourcesListButtonBar setButtons:[plusButton, minusButton]];
    [sourcesListButtonBar setValue:bezelColor forThemeAttribute:"bezel-color"];
    [sourcesListButtonBar setValue:buttonBezel forThemeAttribute:"button-bezel-color"];
    [sourcesListButtonBar setValue:buttonBezelHighlighted forThemeAttribute:"button-bezel-color" inState:CPThemeStateHighlighted];

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
    [sourcesListView setRowHeight:26.0];
    [sourcesListView setSelectionHighlightStyle:CPTableViewSelectionHighlightStyleNone];

    [sourcesListView setBackgroundColor:[CPColor colorWithHexString:@"eef2f8"]];

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
    [[toolbar _toolbarView] setBackgroundColor:ToolbarColor];

	[noReposView removeFromSuperview];
}

- (void)windowWillClose:(id)sender
{
    //do something
}

- (void)addRepository:(id)aRepo
{
    [self addRepository:aRepo select:YES];
}

- (void)addRepository:(id)aRepo select:(BOOL)shouldSelect
{
    if (!aRepo)
        return;

    var count = sortedRepos.length,
        repoIdentifier = aRepo.identifier;

    for (var index = 0; index < count; index++)
    {
        if (sortedRepos[index].identifier === repoIdentifier)
        {
            [sourcesListView selectRowIndexes:[CPIndexSet indexSetWithIndex:index] byExtendingSelection:NO];
            [self tableViewSelectionDidChange:nil];
            return;
        }
    }

    if (shouldSelect)
    {
        sortedRepos.unshift(aRepo);
        [sourcesListView reloadData];
        [sourcesListView selectRowIndexes:[CPIndexSet indexSetWithIndex:0] byExtendingSelection:NO];
        [self tableViewSelectionDidChange:nil];
    }
    else
    {
        sortedRepos.push(aRepo);
        [sourcesListView reloadData];
    }

	[self hideNoReposView];
}

- (void)setSortedRepos:(CPArray)repos
{
    if (!repos || !repos.length)
        return;

    sortedRepos = repos;
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
