
@import <Foundation/CPObject.j>
@import "IssuesController.j"

@implementation RepositoriesController : CPObject
{
    @outlet CPView      repositoryView;
    @outlet CPView      noReposView;
    @outlet CPTableView sourcesListView @accessors;
    @outlet CPButtonBar sourcesListButtonBar @accessors;

            CPArray     sortedRepos;
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
    [plusButton setAction:@selector(addRepository:)];
    [minusButton setTarget:self];
    [minusButton setAction:@selector(removeRepository:)];

    [sourcesListButtonBar setButtons:[plusButton, minusButton]];
    //[sourcesListView setHeaderView:nil];
    //[sourcesListView setCornerView:nil];

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
	[[[CPApp delegate] mainWindow] setToolbar:[[CPToolbar alloc] initWithIdentifier:"mainToolbar"]];
	[noReposView removeFromSuperview];
}

- (@action)addRepository:(id)sender
{
    var repoIdentifier = prompt("Enter the user/repo to add (e.g. 280north/cappuccino)");

    if (!repoIdentifier)
        return;

    [[GithubAPIController sharedController] loadRepositoryWithIdentifier:repoIdentifier callback:function(repo)
    {
        if (!repo)
            return;

        sortedRepos.unshift(repo);
        [sourcesListView reloadData];
    }];

	[self hideNoReposView];
}

- (@action)removeRepository:(id)sender
{
	if (sortedRepos.length === 0)
		[self showNoReposView];
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
