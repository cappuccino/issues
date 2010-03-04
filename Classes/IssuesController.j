/*
 * IssuesController.j
 * GitIssues
 *
 * Created by Randall Luecke on February 20, 2010.
 * Copyright 2010, Randall Luecke All rights reserved.
 *
*/

@implementation IssuesController : CPObject
{
    CPJSONPConnection   downloadIssuesConnection;
    CPJSONPConnection   downloadCommentsConnection;
    CPJSONPConnection   downloadTagsConnection;
    CPURLConnection     addCommentConnection;
    CPURLConnection     closeIssueConnection;
    CPURLConnection     reopenIssueConnection;
    CPURLConnection     createNewIssueConnection;
    id                  appController @accessors;
    IssueView           issueView @accessors;
    CPArray             theIssues;
    CPArray             visibleIssues;
    CPDictionary        activeIssue @accessors;
    CPDictionary        activeRepo @accessors;
    AjaxSeries          requests;

    /*
        search filter values:
        0: all
        1: title
        2: body
        3: tags
    */
    unsigned            searchFilter;
    CPString            searchValue;
    BOOL                viewingOpenIssues;

    //CPString            activeRepo;
    CPString            activeUser;
}
- (id)init
{
    self = [super init];

    if(self)
    {
        requests = [[AjaxSeries alloc] initWithDelegate:self];
        visibleIssues = [CPArray array];
        viewingOpenIssues = YES;
    }

    return self;
}

- (void)allIssuesForRepo:(CPString)theRepo user:(id)theUser
{
    //activeRepo = theRepo;
    //activeuser = theUser;

    var theReadURL = "https://" + GITHUBUSERNAME + ":" + GITHUBPASSWORD + "@github.com/api/v2/json/issues/list/" + theUser + "/" + theRepo + "/" + ((viewingOpenIssues) ? "open" : "closed"),
        theRequest = [[CPURLRequest alloc] initWithURL:theReadURL];

    //[requests addReqeust theRequest];
    downloadIssuesConnection = [[CPJSONPConnection alloc] initWithRequest:theRequest callback:@"callback" delegate:self startImmediately:YES];
}

- (void)allTagsForRepo:(CPString)theRepo user:(id)theUser
{
    var theReadURL = "https://" + GITHUBUSERNAME + ":" + GITHUBPASSWORD + "@github.com/api/v2/json/issues/labels/" + theUser + "/" + theRepo,
        theRequest = [[CPURLRequest alloc] initWithURL:theReadURL];
    downloadTagsConnection = [[CPJSONPConnection alloc] initWithRequest:theRequest callback:@"callback" delegate:self startImmediately:YES];
}

- (void)commentsForActiveIssue 
{
    //this is the issue number not the index btw
     var theUser = [activeRepo valueForKey:@"owner"],
         anIssueNumber = [activeIssue valueForKey:@"number"],
         repo = [activeRepo valueForKey:@"name"],
         getCommentsURL = "https://" + GITHUBUSERNAME + ":" + GITHUBPASSWORD + "@github.com/api/v2/json/issues/comments/" + theUser + "/" + repo + "/" + anIssueNumber,
         getCommentsRequest = [[CPURLRequest alloc] initWithURL:getCommentsURL];
    //console.log(getCommentsURL);
    downloadCommentsConnection = [[CPJSONPConnection alloc] initWithRequest:getCommentsRequest callback:@"callback" delegate:self startImmediately:YES];
}

- (void)promptUserForComment:(id)sender
{
    //var comment = prompt("enter comment");
    //[self commentOnActiveIssue:comment];
    [CPApp beginSheet:[appController commentSheet] modalForWindow:[appController theWindow] modalDelegate:self didEndSelector:nil contextInfo:nil];
}

- (void)commentOnActiveIssue:(id)sender
{
  [CPApp endSheet:[sender window] returnCode:nil];

   var theUser = [activeRepo valueForKey:@"owner"],
       anIssueNumber = [activeIssue valueForKey:@"number"],
       repo = [activeRepo valueForKey:@"name"],
       aComment = escape([[appController commentBody] stringValue]),
       requestSuffix = "comment/" + theUser + "/" + repo + "/" + anIssueNumber + "?comment=" + aComment;

    var theReadURL = "GitHubAPI.php",
        requestBody = "user=" + GITHUBUSERNAME + "&pass=" + GITHUBPASSWORD + "&suffix=" + escape(requestSuffix);
        theRequest = [[CPURLRequest alloc] initWithURL:theReadURL];
    [theRequest setHTTPMethod:@"POST"];
    [theRequest setValue:"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    [theRequest setHTTPBody:requestBody];

    addCommentConnection = [[CPURLConnection alloc] initWithRequest:theRequest delegate:self startImmediately:YES];
}

- (void)promptUserToCloseIssue:(id)sender
{
    // this will make a beautiful sheet... :) 
    var flag = confirm("Are you sure you want to close this issue?");

    if (flag)
        [self closeActiveIssue]
}

- (void)closeActiveIssue
{
    var theUser = [activeRepo valueForKey:@"owner"],
       anIssueNumber = [activeIssue valueForKey:@"number"],
       repo = [activeRepo valueForKey:@"name"],
       requestSuffix = "close/" + theUser + "/" + repo + "/" + anIssueNumber;

    var theReadURL = "GitHubAPI.php",
        requestBody = "user=" + GITHUBUSERNAME + "&pass=" + GITHUBPASSWORD + "&suffix=" + escape(requestSuffix);
        theRequest = [[CPURLRequest alloc] initWithURL:theReadURL];
    [theRequest setHTTPMethod:@"POST"];
    [theRequest setValue:"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    [theRequest setHTTPBody:requestBody];

    // to make it look syncronous remove it from the array
    [theIssues removeObject:activeIssue];
    [visibleIssues removeObject:activeIssue];
    [[appController issuesTable] reloadData];

    closeIssueConnection = [[CPURLConnection alloc] initWithRequest:theRequest delegate:self startImmediately:YES];
}

- (void)reopenActiveIssue:(id)sender
{
    var theUser = [activeRepo valueForKey:@"owner"],
       anIssueNumber = [activeIssue valueForKey:@"number"],
       repo = [activeRepo valueForKey:@"name"],
       requestSuffix = "reopen/" + theUser + "/" + repo + "/" + anIssueNumber;

    var theReadURL = "GitHubAPI.php",
        requestBody = "user=" + GITHUBUSERNAME + "&pass=" + GITHUBPASSWORD + "&suffix=" + escape(requestSuffix);
        theRequest = [[CPURLRequest alloc] initWithURL:theReadURL];
    [theRequest setHTTPMethod:@"POST"];
    [theRequest setValue:"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    [theRequest setHTTPBody:requestBody];

    // to make it look syncronous remove it from the array
    [theIssues removeObject:activeIssue];
    [visibleIssues removeObject:activeIssue];
    [[appController issuesTable] reloadData];

    reopenIssueConnection = [[CPURLConnection alloc] initWithRequest:theRequest delegate:self startImmediately:YES];
}

// either view open or closed issues
- (void)changeVisibleIssuesStatus:(id)sender
{
    
    if ([sender selectedTag] === "Open")
        viewingOpenIssues = YES;
    else
        viewingOpenIssues = NO;

    [self allIssuesForRepo:[activeRepo valueForKey:@"name"] user:[activeRepo valueForKey:@"owner"]];
    [[appController issuesTable] selectRowIndexes:[CPIndexSet indexSet] byExtendingSelection:NO];
}

- (void)createNewIssue:(id)sender
{
    var theUser = [activeRepo valueForKey:@"owner"],
       anIssueNumber = [activeIssue valueForKey:@"number"],
       repo = [activeRepo valueForKey:@"name"],
       requestSuffix = "open/" + theUser + "/" + repo + "/?title=" + escape([[appController newIssueTitle] stringValue]) + "&body=" + escape([[appController newIssueBody] stringValue]);
    var theReadURL = "GitHubAPI.php",
        requestBody = "user=" + GITHUBUSERNAME + "&pass=" + GITHUBPASSWORD + "&suffix=" + escape(requestSuffix);
        theRequest = [[CPURLRequest alloc] initWithURL:theReadURL];
    [theRequest setHTTPMethod:@"POST"];
    [theRequest setValue:"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    [theRequest setHTTPBody:requestBody];

    // to make it look syncronous remove it from the array
    //[theIssues removeObject:activeIssue];
    //[visibleIssues removeObject:activeIssue];
    //[[appController issuesTable] reloadData];
    //console.log(theRequest);
   createNewIssueConnection = [[CPURLConnection alloc] initWithRequest:theRequest delegate:self startImmediately:YES];

    // reset the fields
    [self cancel:nil];
}

//cancel posting new issue
- (void)cancel:(id)sender
{
    if ([sender window] === [appController commentSheet])
        [CPApp endSheet:[sender window] returnCode:nil];
    
    [[appController newIssueTitle] setStringValue:@""];
    [[appController newIssueBody] setStringValue:@""];
    [[appController newIssueWindow] close];
}

- (void)showNewIssueWindow:(id)sender
{
    // make sure a repo is selected first...
    [[appController newIssueWindow] orderFront:self];
}

/*Source list Delegates*/
- (void)tableViewSelectionDidChange:(id)notification
{
    var index = [[[notification object] selectedRowIndexes] firstIndex];

    if(index < 0)
        activeIssue = nil;
    else
        activeIssue = [visibleIssues objectAtIndex:index];

    [self commentsForActiveIssue];
    [issueView setIssue:activeIssue];
}

- (id)tableView:(CPTableView)aTableView objectValueForTableColumn:(int)aColumn row:(int)aRow
{
    var column = [aColumn identifier],
        issue  = [visibleIssues objectAtIndex:aRow],
        value = [issue valueForKey:column];
    
    //special cases
    if(column === @"created_at" || column === @"updated_at")
        value = [CPDate simpleDate:value];

    return value;
}

- (int)numberOfRowsInTableView:(CPTableView)aTableView
{
    return [visibleIssues count];
}

- (void)tableView:(CPTableView)aTableView sortDescriptorsDidChange:(CPArray)oldDescriptors
{   
    var newDescriptors = [aTableView sortDescriptors];

    [theIssues sortUsingDescriptors:newDescriptors];
    [self searchFieldDidChange:nil];

	[aTableView reloadData];

    [aTableView selectRowIndexes:[CPIndexSet indexSetWithIndex:[theIssues indexOfObject:activeIssue]] byExtendingSelection:NO];
}

/*
    connection delegates
*/

-(void)connection:(CPURLConnection)connection didFailWithError:(id)error
{
    alert("There was a fail!");
}

-(void)connection:(CPURLConnection)connection didReceiveData:(CPString)data
{
    if(data.error)
    {
        alert("An error has occured, check the console dude.");
        console.log(data.error);
        return;
    }
    
    if(connection === downloadIssuesConnection)
    {
        // from here we've got a json object of all the issues need to be displayed
        // once parsed display update the table
        theIssues = [CPArray array];

        for (var i = 0; i < data.issues.length; i++)
        //@each(var issue in data.issues)
        {
            var issue = data.issues[i];
            var anIssue = [CPDictionary dictionaryWithJSObject:issue recursively:NO];
            [theIssues addObject:anIssue];
        }
        visibleIssues = [CPArray arrayWithArray:theIssues];
        [self searchFieldDidChange:nil];
        [[appController issuesTable] reloadData];
    }
    else if(connection === downloadCommentsConnection)
    {
        //alert("you have comments, check the console dude.");
        //console.log(data);
        var theComments = [CPArray array];
        for (var i = 0; i < data.comments.length; i++)
        //@each(var comment in data.comments)
        {
            var comment = data.comments[i];
            var aComment = [CPDictionary dictionaryWithJSObject:comment recursively:NO];
            [theComments addObject:aComment];
        }
        [issueView setComments:theComments];
    }
    else if(connection === downloadTagsConnection)
    {
        //console.log(data);
        // here we have a list of all the labels. 
        // we then update the menu to display only those specific tags
        //tags = data.labels;
        //console.log(tags);
        //[appController updateTagsButtonWithTags:tags];
    }
    else if (connection === addCommentConnection)
    {
        alert(data);
    }
    else if (connection === reopenIssueConnection || connection === closeIssueConnection)
    {
        // not really much to do here... 
    }
    else if (connection === createNewIssueConnection)
    {
        data = JSON.parse(data);
        console.log(data.issue);
        if (viewingOpenIssues)
        {
            //{"issue":{"number":6,"votes":0,"created_at":"2010/03/03 23:51:30 -0800","body":"This is the final test","title":"Final","updated_at":"2010/03/03 23:51:30 -0800","closed_at":null,"user":"Me1000","labels":[],"state":"open"}}
            var anIssue = [CPDictionary dictionaryWithJSObject:data.issue recursively:NO];
            [theIssues addObject: anIssue];
            [visibleIssues addObject: anIssue];
            [[appController issuesTable] reloadData];
        }
    }
}
@end

@implementation IssuesController (search)
- (void)searchFieldDidChange:(id)sender
{
    if(sender)
        searchValue = [sender stringValue];
    
    //console.log(sender);
    if (searchValue)
    {
        searchValue = [searchValue lowercaseString];
        [appController showSearchFilter];
        [visibleIssues removeAllObjects];
    }
    else
    {
        [appController hideSearchFilter];
        visibleIssues = [CPArray arrayWithArray:theIssues];
        [[appController issuesTable] reloadData];
        return;
    }

    for (var i = 0; i < [theIssues count]; i++)
    {
        var item = [theIssues objectAtIndex:i];

        // FIX ME: This is really bad... 
        if ((searchFilter === 0 || searchFilter === 1) && [[item valueForKey:@"title"] lowercaseString].match(searchValue))
        {
            [visibleIssues addObject:[theIssues objectAtIndex:i]];
            // we continue to avoid duplicates if "all" is selected.
            continue;
        }

        if ((searchFilter === 0 || searchFilter === 2) && [[item valueForKey:@"body"] lowercaseString].match(searchValue))
        {
            [visibleIssues addObject:[theIssues objectAtIndex:i]];
            continue;
        }
        
        var tags = [[item valueForKey:@"labels"] componentsJoinedByString:@" "];
        if ((searchFilter === 0 || searchFilter === 3) && [tags lowercaseString].match(searchValue))
        {
            [visibleIssues addObject:[theIssues objectAtIndex:i]];
        }
    }

    [[appController issuesTable] reloadData];
}

- (void)filterDidChange:(id)sender
{
    searchFilter = [sender tag];
    [self searchFieldDidChange:nil];
}
@end