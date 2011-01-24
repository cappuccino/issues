
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
    REPOS = sortedRepos;

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
    [changeOrientationButton setImage:[[CPImage alloc] initWithContentsOfFile:[[CPBundle mainBundle] pathForResource:"swapOrientationIcon2.png"] size:CGSizeMake(15,11)]];

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
    [sourcesListView setSelectionHighlightStyle:CPTableViewSelectionHighlightStyleSourceList];
    [sourcesListView setVerticalMotionCanBeginDrag:YES];
    [sourcesListView setDraggingDestinationFeedbackStyle:CPTableViewDropAbove];
    [sourcesListView registerForDraggedTypes:[@"GitHubIssuesRepoSourceListDragType"]];

    [[[sourcesListView enclosingScrollView] superview] setBackgroundColor:[CPColor colorWithHexString:@"eef2f8"]];

    [self showNoReposView];

    [[CPNotificationCenter defaultCenter] addObserver:sourcesListView
                                             selector:@selector(reloadData)
                                                 name:GitHubAPIRepoDidChangeNotification
                                               object:nil];
}

- (void)showNoReposView
{
    if ([noReposView superview])
        return;

    var theWindow = [[CPApp delegate] mainWindow],
        contentView = [theWindow contentView],
        subviews = [contentView subviews];

    // hiding the views caused an infinate loop... still investigating
    //[subviews makeObjectsPerformSelector:@selector(setHidden:) withObject:YES];

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
    // go ahead and load the tags for each repo since we bypass that on a normal load
    var c = repos.length;

    while(c--)
        [[GithubAPIController sharedController] loadLabelsForRepository:repos[c]];

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
    else
    {
        [sourcesListView selectRowIndexes:[CPIndexSet indexSetWithIndex:MAX(selectedRow, 1)] byExtendingSelection:NO];
        [self tableViewSelectionDidChange:nil];
    }

    [sourcesListView reloadData];
}

- (void)viewOnGithub:(id)sender
{
    var selectedRow = [sourcesListView selectedRow] - 1,
        repo = [sortedRepos objectAtIndex:selectedRow];

    OPEN_LINK(BASE_URL + repo.identifier);
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
        return {identifier:"REPOSITORIES", "private":NO, open_issues:0};

    return sortedRepos[aRow - 1];
}

- (id)tableView:(CPTableView)aTableView badgeValueForRow:(int)aRow
{
    if (aRow === 0)
        return 0;
    var anObject = sortedRepos[aRow -1],
        value = anObject.openIssues ? anObject.openIssues.length : anObject.open_issues;

    return value;
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
    if (aTableView === sourcesListView && ![rowIndexes containsIndex:0])
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
    if (aTableView === sourcesListView)
    {
        if ([info draggingSource] !== sourcesListView && row >= [sortedRepos count] || row < 1)
            row = [sortedRepos count];

        if ([info draggingSource] === sourcesListView)
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
    if (aTableView === sourcesListView)
    {
        if ([info draggingSource] === sourcesListView)
        {
            var pboard = [info draggingPasteboard],
                rowData = [pboard dataForType:@"GitHubIssuesRepoSourceListDragType"];

            rowData = [CPKeyedUnarchiver unarchiveObjectWithData:rowData];

            // if we drop below the drag point we must subtract one
            if ([rowData firstIndex] < row)
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

- (CPMenu)tableView:(CPTableView)aTableView menuForTableColumn:(CPTableColumn)aColumn row:(int)aRow
{
    // select it first
    if (aRow >= 0)
    {
        [sourcesListView selectRowIndexes:[CPIndexSet indexSetWithIndex:aRow] byExtendingSelection:NO];
        [self tableViewSelectionDidChange:nil];
    }

    var menu = [[CPMenu alloc] initWithTitle:""],
        newRepo = [[CPMenuItem alloc] initWithTitle:"Add Repository" action:@selector(promptForNewRepository:) keyEquivalent:nil],
        removeRepo = [[CPMenuItem alloc] initWithTitle:"Remove Repository" action:@selector(removeRepository:) keyEquivalent:nil],
        showOnGithub = [[CPMenuItem alloc] initWithTitle:"View On GitHub" action:@selector(viewOnGithub:) keyEquivalent:nil];

    [newRepo setTarget:self];
    [removeRepo setTarget:self];
    [showOnGithub setTarget:self];

    if (aRow === CPNotFound)
    {
        [removeRepo setEnabled:NO];
        [showOnGithub setEnabled:NO];
    }

    [menu addItem:newRepo];
    [menu addItem:removeRepo];
    [menu addItem:[CPMenuItem separatorItem]];
    [menu addItem:showOnGithub];

    return menu;
}
@end


@implementation RepositorySourceListView : CPTableView
- (void)drawRow:(CPInteger)rowIndex clipRect:(CGRect)clipRect
{
    // IE can't draw text so just return early.
    if (!CPFeatureIsCompatible(CPHTMLCanvasFeature))
        return;


    var count = [[self delegate] tableView:self badgeValueForRow:rowIndex];

    if (!count)
        return;

    var columnIndex = [self columnWithIdentifier:@"sourcelist"],
        viewRect = [self frameOfDataViewAtColumn:columnIndex row:rowIndex],
        value = count + "",
        badgeSize = [value sizeWithFont:[CPFont boldSystemFontOfSize:11]];

        badgeSize.height = 16;
        badgeSize.width = MAX(badgeSize.width + 10, 22);

        badgeFrame = CGRectMake(CGRectGetMaxX(viewRect) - badgeSize.width - 8,
                                   CGRectGetMidY(viewRect) - (badgeSize.height/2.0),
                                   badgeSize.width,
                                   badgeSize.height);

    [self drawBadgeForRow:rowIndex inRect:badgeFrame];
}

- (void)drawBadgeForRow:(CPInteger)rowIndex inRect:(CGRect)badgeFrame
{
    // IE can't draw text so just return early.
    if (!CPFeatureIsCompatible(CPHTMLCanvasFeature))
        return;

    var badgePath = [CPBezierPath bezierPath];
    
    [badgePath appendBezierPathWithRoundedRect:badgeFrame xRadius:8 yRadius:8];

    //Get window and control state to determine colours used
    var isFocused = [[[self window] firstResponder] isEqual:self],
        rowBeingEdited = -1 // uninplemented [self editedRow];

    //Set the attributes based on the row state
    var backgroundColor,
        textColor;

    if ([[self selectedRowIndexes] containsIndex:rowIndex])
    {
        //Set the text color based on window and control state
        backgroundColor = [CPColor whiteColor];
        textColor = [CPColor colorWithCalibratedRed:(75/255.0) green:(137/255.0) blue:(208/255.0) alpha:1];
    }
    else
    {
        //Set the text colour based on window and control state
        textColor = [CPColor whiteColor];
        backgroundColor = [CPColor colorWithCalibratedRed:(152/255.0) green:(168/255.0) blue:(202/255.0) alpha:1];
    }

    [backgroundColor set];
    [badgePath fill];

    //Draw the badge text
    var badgeString = [CPString stringWithFormat:@"%d", [[self delegate] tableView:self badgeValueForRow:rowIndex]],
        stringSize = [badgeString sizeWithFont:[CPFont systemFontOfSize:11]],
        badgeTextPoint = CGPointMake(CGRectGetMidX(badgeFrame) - (stringSize.width/2.0),        //Center in the badge frame
                                         CGRectGetMidY(badgeFrame) + (stringSize.height/4.0) + 1);  //Center in the badge frame
    [textColor setFill];
    [badgeString drawAtPoint:badgeTextPoint withFont:[CPFont boldSystemFontOfSize:11]];
}
@end

@implementation CPString (DrawingAdditions)

- (CGSize)drawAtPoint:(CGPoint)point withFont:(CPFont)font
{
    var ctx = [[CPGraphicsContext currentContext] graphicsPort];
    CGContextSaveGState(ctx);
    CGContextSetFont(ctx, font);
    CGContextShowTextAtPoint(ctx, point.x, point.y, self, 0);
    CGContextRestoreGState(ctx);
    return [self sizeWithFont:font];
}

@end

function CGContextShowTextAtPoint(aContext, x, y, aString,/* unused */ aStringLength)
{
    aContext.fillText(aString, x, y);
}

function CGContextSetFont(aContext, aFont)
{
    aContext.font = [aFont cssString];
}