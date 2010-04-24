/*
 * ProjectsController.j
 * GitIssues
 *
 * Created by Randall Luecke on February 20, 2010.
 * Copyright 2010, Randall Luecke All rights reserved.
 *
*/


//http://github.com/api/v2/yaml/repos/show/schacon

@implementation ProjectsController : CPObject
{
    id              issuesController @accessors;
    id              appController @accessors;

    CPURLConnection downloadAllRepos;
    CPJSONPConnection pushableRepos;
    CPArray         sourceListData;
    CPArray         followedUsers @accessors;
    //CPArray       userRepos;
    AjaxSeries      requests;
}
- (id)init
{
    self = [super init];

    if (self)
    {
        followedUsers = [CPArray array];
        sourceListData = [followedUsers];
        requests = [[AjaxSeries alloc] initWithDelegate:self];
    }

    return self;
}

- (void)allReposForUser:(CPString)aUser
{
    var theReadURL = "https://" + GITHUBUSERNAME + ":" + GITHUBPASSWORD + "@github.com/api/v2/json/repos/show/" + aUser,
        theRequest = [[CPURLRequest alloc] initWithURL:theReadURL];
    //console.log(theReadURL);
    [requests addRequest: theRequest];
    //downloadAllRepos = [[CPJSONPConnection alloc] initWithRequest:theRequest callback:@"callback" delegate:self startImmediately:YES];
}

- (void)downloadPushableRepos
{
    var theReadURL = "https://" + GITHUBUSERNAME + ":" + GITHUBPASSWORD + "@github.com/api/v2/json/repos/pushable",
        theRequest = [[CPURLRequest alloc] initWithURL:theReadURL];
    //console.log(theReadURL);
    //[requests addRequest: theRequest];
    // FIX ME: WTF BBQ?!?! I get a 403 back... could be an API bug.
    pushableRepos = [[CPJSONPConnection alloc] initWithRequest:theRequest callback:@"callback" delegate:self startImmediately:YES];
}

/*Source list Delegates*/
/*- (void)tableViewSelectionDidChange:(id)notification
{
    console.log("blah123");
    var repo = [userRepos objectAtIndex:[[[appController sourceList] selectedRowIndexes] firstIndex]];
    [issuesController allIssuesForRepo:[repo valueForKey:@"name"] user:[repo valueForKey:@"owner"]];
    console.log("get the tags!!");
    [issuesController allTagsForRepo:[repo valueForKey:@"name"] user:[repo valueForKey:@"owner"]];
    console.log("get the tags!! 2");
}

- (id)tableView:(CPTableView)aTableView objectValueForTableColumn:(id)aColumn row:(int)aRow
{
    return [[userRepos objectAtIndex:aRow] valueForKey:@"name"];
}

- (int)numberOfRowsInTableView:(CPTableView)aTableView
{
    return [userRepos count];
}*/



/*
    connection delegates
*/

-(void)connection:(CPURLConnection)connection didFailWithError:(id)error
{
    alert("There was a fail!");
}

-(void)connectionDidFinishLoading:(CPURLConnection)connection
{
    if (connection === pushableRepos)
    {
        console.log("asdasdasdasdasd");
        return;
    }
}

-(void)connection:(CPURLConnection)connection didReceiveData:(CPString)data
{
    if(data.error)
    {
        console.log(data.error);
        alert("An error has occured, check the console dude.");
        return;
    }


    if (connection === [appController downloadFollowedUsers])
    {
        //console.log(data);
        for (var i = 0; i < data.users.length; i++)
        //@each(var user in data.users)
        {
            var user = data.users[i];
            [self allReposForUser:user];
        }

        return;
    }

    if (connection === pushableRepos)
    {
        console.log(data);
        return;
    }


    // from here we've got a json object of all the issues need to be displayed
    // once parsed display update the table
    var userRepos = [CPArray array];
    for (var i = 0; i < data.repositories.length; i++)
    //@each (var repo in data.repositories)
    {
        var repo = data.repositories[i];
            if (!repo.fork)
        {
            var aRepo = [CPDictionary dictionaryWithJSObject:repo recursively:NO];
            [userRepos addObject:aRepo];
        }
    }
    [followedUsers addObject:userRepos];
    [[appController sourceList] reloadData];

    var values = [];
    for (var i=0; i < followedUsers.length; i++)
    {
        var value = [followedUsers[i][0] valueForKey:@"owner"];
        [values addObject:value];
    }
    var values = JSON.stringify(values);
    
    //set the cookie

    [[appController followedUsersCookie] setValue:values expires:[CPDate distantFuture] domain:nil];
}


/*SplitView delegates*/
- (CPRect)splitView:(CPSplitView)aSplitView additionalEffectiveRectOfDividerAtIndex:(int)aDividerIndex
{
    // making it a little easier to grab the thin resize indicator thing
    var rect = [[aSplitView subviews][0] frame],
        x = rect.size.width - 3,
        y = 0;
        
        rect = CGRectMake(x,y,3,CGRectGetMaxY(rect));
    return rect;
}

- (CGFloat)splitView:(CPSplitView)splitView constrainMaxCoordinate:(float)proposedMax ofSubviewAt:(int)dividerIndex
{
    
    return 300;
}

- (CGFloat)splitView:(CPSplitView)splitView constrainMinCoordinate:(float)proposedMax ofSubviewAt:(int)dividerIndex
{
    return 100;
}

@end

@implementation ProjectsController (OutlineViewDelegates)
- (void)outlineViewSelectionDidChange:(CPNotification)aNote
{
    var sourceList = [appController sourceList],
        selectedIndex = [[sourceList selectedRowIndexes] firstIndex],
        item = [sourceList itemAtRow:selectedIndex]

    //var repo = [userRepos objectAtIndex:[[[appController sourceList] selectedRowIndexes] firstIndex]];
    if([item isKindOfClass:[CPDictionary class]])
    {
        [issuesController setActiveRepo:item];
        [issuesController allIssuesForRepo:[item valueForKey:@"name"] user:[item valueForKey:@"owner"]];
        [issuesController allTagsForRepo:[item valueForKey:@"name"] user:[item valueForKey:@"owner"]];
    }
}
- (id)outlineView:(CPOutlineView)theOutlineView child:(int)theIndex ofItem:(id)theItem
{
    if (!theItem)
        return [followedUsers objectAtIndex:theIndex];
    else
        return [theItem objectAtIndex:theIndex];
}

- (BOOL)outlineView:(CPOutlineView)theOutlineView isItemExpandable:(id)theItem
{
    if([theItem isKindOfClass:[CPArray class]])
        return ([theItem count] > 0)
    else
        return NO;
}

- (int)outlineView:(CPOutlineView)theOutlineView numberOfChildrenOfItem:(id)theItem
{
    if (theItem === nil)
        return [followedUsers count];
    else if ([theItem isKindOfClass:[CPArray class]])
        return [theItem count];
    else
        return 0;
}

- (id)outlineView:(CPOutlineView)anOutlineView objectValueForTableColumn:(CPTableColumn)theColumn byItem:(id)theItem
{
    if ([theItem isKindOfClass:[CPArray class]])
        return [theItem[0] valueForKey:@"owner"];
    else
        return [theItem valueForKey:@"name"];
}

@end