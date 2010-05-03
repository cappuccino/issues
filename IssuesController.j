
@import <Foundation/CPObject.j>
@import "CPDate+Additions.j"
@import "FilterBar.j"
@import "Markdown.js"
@import "Mustache.js"

var IssuesHTMLTemplate = nil;

@implementation IssuesController : CPObject
{
    Repository  repo @accessors;

	@outlet CPView      detailParentView;
    @outlet CPView      noIssuesView;
	@outlet CPView      noRepoView;
	@outlet CPView		loadingIssuesView;
			CPView		displayedView;
			FilterBar   filterBar;

    @outlet CPTableView issuesTableView @accessors;
    @outlet CPWebView   issueWebView @accessors;

    CPString    displayedIssuesKey @accessors;

    CPArray     filteredIssues;
    CPString    searchString;
    unsigned    searchFilter;
}

+ (void)initialize
{
	//load template
	var request = new CFHTTPRequest();
	request.open("GET", "Issue.html", true);

	request.oncomplete = function()
	{
		if (request.success())
			IssuesHTMLTemplate = request.responseText();
	}

	request.send("");
}

- (void)awakeFromCib
{
    displayedIssuesKey = "openIssues";

	[self showView:noRepoView];

    var desc = [CPSortDescriptor sortDescriptorWithKey:@"number" ascending:YES],
        ID = [[CPTableColumn alloc] initWithIdentifier:"number"];

    [[ID headerView] setStringValue:"ID"];
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
    [title setResizingMask:CPTableColumnAutoresizingMask|CPTableColumnUserResizingMask];

    [issuesTableView addTableColumn:title];

    var desc = [CPSortDescriptor sortDescriptorWithKey:@"votes" ascending:YES],
        votes = [[CPTableColumn alloc] initWithIdentifier:"votes"];

    [[votes headerView] setStringValue:"Votes"];
    [votes setWidth:60.0];
    [votes setMinWidth:50.0];
    [votes setEditable:YES];
    [votes setSortDescriptorPrototype:desc];
    [votes setResizingMask:CPTableColumnUserResizingMask];

    [issuesTableView addTableColumn:votes];

    var desc = [CPSortDescriptor sortDescriptorWithKey:@"created_at" ascending:YES],
        date = [[CPTableColumn alloc] initWithIdentifier:"created_at"];

    [[date headerView] setStringValue:"Created"];
    [date setWidth:120.0];
    [date setMinWidth:50.0];
    [date setEditable:YES];
    [date setSortDescriptorPrototype:desc];
    [date setResizingMask:CPTableColumnUserResizingMask];

    [issuesTableView addTableColumn:date];

    var desc = [CPSortDescriptor sortDescriptorWithKey:@"updated_at" ascending:YES],
        updated = [[CPTableColumn alloc] initWithIdentifier:"updated_at"];

    [[updated headerView] setStringValue:"Updated"];
    [updated setWidth:120.0];
    [updated setMinWidth:50.0];
    [updated setEditable:YES];
    [updated setSortDescriptorPrototype:desc];
    [updated setResizingMask:CPTableColumnUserResizingMask];

    [issuesTableView addTableColumn:updated];

    [issuesTableView setUsesAlternatingRowBackgroundColors:YES];
    [issuesTableView setColumnAutoresizingStyle:CPTableViewUniformColumnAutoresizingStyle];

    filterBar = [[FilterBar alloc] initWithFrame:CGRectMake(0, 0, 400, 32)];
    [filterBar setAutoresizingMask:CPViewWidthSizable];
    [filterBar setDelegate:self];
    searchFilter = 0;
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

    [issuesTableView reloadData];
    [self searchFieldDidChange:nil];
    [self tableView:issuesTableView sortDescriptorsDidChange:nil];
    [self tableViewSelectionDidChange:nil];
}

- (void)selectIssueAtIndex:(unsigned)index
{
    [issuesTableView scrollRowToVisible:index];
    [issuesTableView selectRowIndexes:[CPIndexSet indexSetWithIndex:index] byExtendingSelection:NO];
    [self tableViewSelectionDidChange:nil];
}

- (@action)closeIssue:(id)sender
{

}

- (@action)reopenIssue:(id)sender
{

}

- (@action)comment:(id)sender
{

}

- (@action)newIssue:(id)sender
{

}

- (@action)reload:(id)sender
{
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

		if (success && repo[displayedIssuesKey].length)
			[self showView:nil];
		else
			[self showView:noIssuesView];
	}];
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
			if (repo[displayedIssuesKey].length)
			{
			    [issuesTableView selectRowIndexes:[CPIndexSet indexSet] byExtendingSelection:NO];
				[self showView:nil];
			    [self tableViewSelectionDidChange:nil];
			}
			else
				[self showView:noIssuesView];
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
}

- (void)tableViewSelectionDidChange:(CPNotification)aNotification
{
	var row = [issuesTableView selectedRow],
		item = nil;

	if (row >= 0)
        item = [(filteredIssues || repo[displayedIssuesKey]) objectAtIndex:row];

    [issueWebView loadHTMLString:""];

	if (item)
	{
		if (![item objectForKey:"body_html"])
		{
		    [item setObject:Markdown.makeHtml([item objectForKey:"body"]) forKey:"body_html"];
		    [item setObject:[CPDate simpleDate:[item objectForKey:"created_at"]] forKey:"human_readable_created_date"];
		    [item setObject:[CPDate simpleDate:[item objectForKey:"updated_at"]] forKey:"human_readable_updated_date"];
		    [item setObject:([item objectForKey:"labels"] || []).join(", ") forKey:"comma_separated_tags"];
		    //[item setObject:Markdown.makeHtml([item objectForKey:body]) forKey:"user_email_hash"];
		    //[item setObject:Markdown.makeHtml([item objectForKey:body]) forKey:"user_email"];
		    [item setObject:YES forKey:"has_user_image"];
		    
		    [[GithubAPIController sharedController] loadCommentsForIssue:item repository:repo callback:function()
		    {
		        var comments = [item objectForKey:"all_comments"];
		        for (var i = 0, count = comments.length; i < count; i++)
		        {
		            var comment = comments[i];
		            comment.body_html = Markdown.makeHtml(comment.body);
		            comment.human_readable_date = [CPDate simpleDate:comment.created_at];
		            //comment.user_email_hash
		        }

    		    var jsItem = [item toJSObject],
        			html = Mustache.to_html(IssuesHTMLTemplate, jsItem);

        		[issueWebView loadHTMLString:html];
		    }]		    
		}
        else
        {
		    var jsItem = [item toJSObject],
    			html = Mustache.to_html(IssuesHTMLTemplate, jsItem);

    		[issueWebView loadHTMLString:html];
		}

		//update the location hash
		[CPApp setArguments:[repo.owner, repo.name, [item objectForKey:"number"]]];
	}
}

- (id)tableView:(CPTableView)aTableView objectValueForTableColumn:(int)aColumn row:(int)aRow
{
    var columnIdentifier = [aColumn identifier],
        issue = [(filteredIssues || repo[displayedIssuesKey]) objectAtIndex:aRow],
        value = [issue objectForKey:columnIdentifier];

    //special cases
    if(columnIdentifier === @"created_at" || columnIdentifier === @"updated_at")
        value = [CPDate simpleDate:value];

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

- (void)searchFieldDidChange:(id)sender
{
    if (sender)
        searchString = [sender stringValue];

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
        [self hideFilterBar];
        filteredIssues = nil;

        [issuesTableView reloadData];
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

@end

@implementation CPDictionary (JSObjects)

- (Object)toJSObject
{
	var object = {},
		keyEnumerator = [self keyEnumerator],
		key = nil;

	while((key = [keyEnumerator nextObject]) !== nil)
		object[key] = [self objectForKey:key];

	return object;
}

@end
