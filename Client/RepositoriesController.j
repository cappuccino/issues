
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
        minusButton = [CPButtonBar minusButton],
        changeOrientationButton = [CPButtonBar minusButton],
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
    [changeOrientationButton setTarget:[CPApp delegate]];
    [changeOrientationButton setAction:@selector(swapMainWindowOrientation:)];
    [changeOrientationButton setImage:[[CPImage alloc] initWithContentsOfFile:[[CPBundle mainBundle] pathForResource:"swapOrientationIcon.png"] size:CGSizeMake(12,12)]];

    [sourcesListButtonBar setButtons:[plusButton, minusButton, changeOrientationButton]];
    [sourcesListButtonBar setValue:bezelColor forThemeAttribute:"bezel-color"];
    [sourcesListButtonBar setValue:buttonBezel forThemeAttribute:"button-bezel-color"];
    [sourcesListButtonBar setValue:buttonBezelHighlighted forThemeAttribute:"button-bezel-color" inState:CPThemeStateHighlighted];

    [sourcesListView setIntercellSpacing:CGSizeMakeZero()];
    [sourcesListView setHeaderView:nil];
    [sourcesListView setCornerView:nil];

    var column = [[CPTableColumn alloc] initWithIdentifier:"sourcelist"];
    [[column headerView] setStringValue:"Projects"];

    [column setWidth:220.0];
    [column setMinWidth:50.0];
    [column setEditable:YES];
    [column setDataView:repositoryView];
    
    [sourcesListView addTableColumn:column];
    [sourcesListView setColumnAutoresizingStyle:CPTableViewLastColumnOnlyAutoresizingStyle];
    [sourcesListView setRowHeight:26.0];
    [sourcesListView setSelectionHighlightStyle:CPTableViewSelectionHighlightStyleNone];
    [sourcesListView setVerticalMotionCanBeginDrag:YES];
    [sourcesListView setDraggingDestinationFeedbackStyle:CPTableViewDropAbove];
    [sourcesListView registerForDraggedTypes:[@"GitHubIssuesRepoSourceListDragType"]];

    [[[sourcesListView enclosingScrollView] superview] setBackgroundColor:[CPColor colorWithHexString:@"eef2f8"]];

    [self showNoReposView];
}

- (void)showNoReposView
{
    if ([noReposView superview])
        return;

    var theWindow = [[CPApp delegate] mainWindow],
        contentView = [theWindow contentView],
        subviews = [contentView subviews];

    [subviews makeObjectsPerformSelector:@selector(setHidden:) withObject:YES];

    [noReposView setFrame:[contentView bounds]];
    [contentView addSubview:noReposView];
}

- (void)hideNoReposView
{
    [noReposView removeFromSuperview];

    var theWindow = [[CPApp delegate] mainWindow],
        subviews = [[theWindow contentView] subviews];

    [subviews makeObjectsPerformSelector:@selector(setHidden:) withObject:NO];
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

    [[GithubAPIController sharedController] loadLabelsForRepository:aRepo];

    for (var index = 0; index < count; index++)
    {
        if (sortedRepos[index].identifier === repoIdentifier)
        {
            [sourcesListView selectRowIndexes:[CPIndexSet indexSetWithIndex:index + 1] byExtendingSelection:NO];
            [self tableViewSelectionDidChange:nil];
            return;
        }
    }

    if (shouldSelect)
    {
        sortedRepos.unshift(aRepo);
        [sourcesListView reloadData];
        [sourcesListView selectRowIndexes:[CPIndexSet indexSetWithIndex:1] byExtendingSelection:NO];
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
    [sourcesListView selectRowIndexes:[CPIndexSet indexSetWithIndex:1] byExtendingSelection:NO];
    [self tableViewSelectionDidChange:nil];

    [self hideNoReposView];
}

- (@action)promptForNewRepository:(id)sender
{
    var newRepoWindow = [NewRepoWindow sharedNewRepoWindow];
    [newRepoWindow makeKeyAndOrderFront:self];
}

- (@action)removeRepository:(id)sender
{
    var selectedRow = [sourcesListView selectedRow] - 1;

    if (selectedRow < 0)
        return;

    [sortedRepos removeObjectAtIndex:selectedRow];

    if (sortedRepos.length === 0)
    {
        [self showNoReposView];        
        [sourcesListView selectRowIndexes:[CPIndexSet indexSet] byExtendingSelection:NO];
        [self tableViewSelectionDidChange:nil];
    }

    [sourcesListView reloadData];
}

- (BOOL)tableView:(CPTableView)aTableView shouldSelectRow:(int)aRow
{
    if (aRow === 0)
        return NO;

    var callback = function()
    {
        [aTableView selectRowIndexes:[CPIndexSet indexSetWithIndex:aRow] byExtendingSelection:NO];
        [self tableViewSelectionDidChange:nil];
    }
    return [issuesController _shouldUnloadIssueWithCallBack:callback];
}

- (void)tableViewSelectionDidChange:(CPNotification)aNotification
{
    var selectedRow = MAX([sourcesListView selectedRow] - 1, CPNotFound);

    if (selectedRow === CPNotFound)
    {
        [CPApp setArguments:[]];
        [issuesController setRepo:nil];
    }
    else
    {
        var repo = sortedRepos[selectedRow];
        [CPApp setArguments:[repo.owner, repo.name]];
        [issuesController setRepo:repo];
    }

    [[[[CPApp delegate] mainWindow] toolbar] validateVisibleItems];
}

- (id)tableView:(CPTableView)aTableView objectValueForTableColumn:(int)aColumn row:(int)aRow
{
    if (aRow === 0)
        return {identifier:"REPOSITORIES", "private":NO};

    return sortedRepos[aRow - 1];
}

- (int)numberOfRowsInTableView:(CPTableView)aTableView
{
    return sortedRepos.length + 1;
}

- (BOOL)tableView:(CPTableView)aTableView isGroupRow:(int)aRow
{
    return aRow === 0;
}

- (BOOL)tableView:(CPTableView)aTableView writeRowsWithIndexes:(CPIndexSet)rowIndexes toPasteboard:(CPPasteboard)pboard
{
    if(aTableView === sourcesListView && ![rowIndexes containsIndex:0])
    {
        // encode the index(es)being dragged
        var encodedData = [CPKeyedArchiver archivedDataWithRootObject:rowIndexes];
        [pboard declareTypes:[CPArray arrayWithObject:@"GitHubIssuesRepoSourceListDragType"] owner:self];
        [pboard setData:encodedData forType:@"GitHubIssuesRepoSourceListDragType"];
    
        return YES;
    }

    return NO;
}

- (CPDragOperation)tableView:(CPTableView)aTableView 
                   validateDrop:(id)info 
                   proposedRow:(CPInteger)row 
                   proposedDropOperation:(CPTableViewDropOperation)operation
{
    if(aTableView === sourcesListView)
    {
        if([info draggingSource] !== sourcesListView && row >= [sortedRepos count] || row < 1)
            row = [sortedRepos count];

        if([info draggingSource] === sourcesListView)
        {
            [aTableView setDropRow:row dropOperation:CPTableViewDropAbove];
            return CPDragOperationMove;
        }
    }
    return CPDragOperationNone;
}

- (BOOL)tableView:(CPTableView)aTableView acceptDrop:(id)info row:(int)row dropOperation:(CPTableViewDropOperation)operation
{
    //remember to check the operation/info
    if(aTableView === sourcesListView)
    {
        if([info draggingSource] === sourcesListView)
        {
            var pboard = [info draggingPasteboard],
                rowData = [pboard dataForType:@"GitHubIssuesRepoSourceListDragType"];    

            rowData = [CPKeyedUnarchiver unarchiveObjectWithData:rowData];

            // if we drop below the drag point we must subtract one
            if([rowData firstIndex] < row)
                var dropRow = row -1;
            // otherwise we're on the correct index
            else
                var dropRow = row;

            // remember that we must take into account that the first row is always the group row
            dropRow--;

            var movedObject = [sortedRepos objectAtIndex:[rowData firstIndex] - 1];
            [sortedRepos removeObjectAtIndex:[rowData firstIndex] - 1];
            [sortedRepos insertObject:movedObject atIndex:dropRow];

            // select the new row before we reload the data
            [sourcesListView reloadData];
            [sourcesListView selectRowIndexes:[CPIndexSet indexSetWithIndex:dropRow + 1] byExtendingSelection:NO];
            // select the row (index + 1 to account for the first group row)


            [aTableView _noteSelectionDidChange];
            return YES;
         }
    }

    return NO;
}
@end
