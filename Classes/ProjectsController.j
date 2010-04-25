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

    CPJSONPConnection pushableReposConnection;
    CPJSONPConnection userReposConnection;
    CPJSONPConnection watchedReposConnection;

    CPArray         repositories;
    CPArray         manualRepos;
}

- (id)init
{
    self = [super init];

    if (self)
    {
        repositories = [];
        manualRepos = [];
    }

    return self;
}

- (void)reloadData
{
    repositories = [];

    if (![appController autopopulateRepos])
        return;

    var urlPrefix = "https://" + GITHUBUSERNAME + ":" + GITHUBPASSWORD + "@github.com/api/v2/json/"
        userReposURL = urlPrefix + "repos/show/" + GITHUBUSERNAME,
        pushableReposURL = urlPrefix + "repos/pushable",
        watchedReposURL = urlPrefix + "repos/watched/" + GITHUBUSERNAME;
        
    var theRequest = [[CPURLRequest alloc] initWithURL:userReposURL];
    userReposConnection = [CPJSONPConnection connectionWithRequest:theRequest callback:"callback" delegate:self];
    
    var theRequest = [[CPURLRequest alloc] initWithURL:pushableReposURL];
    pushableReposConnection = [CPJSONPConnection connectionWithRequest:theRequest callback:"callback" delegate:self];

    var theRequest = [[CPURLRequest alloc] initWithURL:watchedReposURL];
    //watchedReposConnection = [CPJSONPConnection connectionWithRequest:theRequest callback:"callback" delegate:self];
}

- (void)loadManualRepo:(CPString)repoID
{
    var parts = [repoID componentsSeparatedByString:"/"],
        fakeRepo = [CPDictionary dictionaryWithJSObject:
        {
            name:parts[1],
            owner:parts[0],
            url:"http://github.com/"+repoID,
            repo_type:"manual"
        }];

    var manualRepoURLs = [manualRepos valueForKey:"url"],
        repoURLs = [repositories valueForKey:"url"];

    if ([manualRepoURLs indexOfObject:[fakeRepo objectForKey:"url"]] === CPNotFound)
        manualRepos.push(fakeRepo);

    if ([repoURLs indexOfObject:[fakeRepo objectForKey:"url"]] === CPNotFound)
        repositories.unshift(fakeRepo);
    else
    {
        var index = [repoURLs indexOfObject:[fakeRepo objectForKey:"url"]],
            repo = [repositories objectAtIndex:index];

        [repo setObject:"manual" forKey:"repo_type"];
        repositories.splice(index, 1);
        repositories.unshift(repo);
    }

    [[appController sourceList] reloadData];
    [[appController sourceList] selectRowIndexes:[CPIndexSet indexSetWithIndex:0] byExtendingSelection:NO];
}

- (void)removeRepoAtIndex:(unsigned)anIndex
{
    var repo = repositories[anIndex],
        url = [repo objectForKey:"url"],
        manualURLs = [manualRepos valueForKey:"url"],
        manualIndex = [manualURLs indexOfObject:url];

    if (manualIndex !== -1)
        manualRepos.splice(manualIndex, 1);

    repositories.splice(anIndex, 1);

    [[appController sourceList] reloadData];
}

/*Source list Delegates*/
- (void)tableViewSelectionDidChange:(id)notification
{
    var item = [repositories objectAtIndex:[[[appController sourceList] selectedRowIndexes] firstIndex]];

    [issuesController setActiveRepo:item];
    [issuesController allIssuesForRepo:[item valueForKey:@"name"] user:[item valueForKey:@"owner"]];
    [issuesController allTagsForRepo:[item valueForKey:@"name"] user:[item valueForKey:@"owner"]];
}

- (id)tableView:(CPTableView)aTableView objectValueForTableColumn:(id)aColumn row:(int)aRow
{
    return repositories[aRow]
}

- (int)numberOfRowsInTableView:(CPTableView)aTableView
{
    return [repositories count];
}

-(void)connection:(CPURLConnection)connection didFailWithError:(id)error
{
    alert("Connection error: "+error);
}

-(void)connection:(CPURLConnection)connection didReceiveData:(CPString)data
{
    if(data.error)
    {
        console.log(data.error);
        alert("An error has occured, check the console dude.");
        return;
    }

    var repoTypeHash = {}
    repoTypeHash[[userReposConnection UID]] = "owned";
    repoTypeHash[[pushableReposConnection UID]] = "pushable";
    //repoTypeHash[[watchedReposConnection UID]] = "watched";

    for (var i = 0; i < data.repositories.length; i++)
    {
        var repo = [CPDictionary dictionaryWithJSObject:data.repositories[i] recursively:NO],
            repoIndex = [[repositories valueForKey:"url"] indexOfObject:[repo objectForKey:"url"]];

        if (repoIndex !== CPNotFound)
        {
            if (connection === userReposConnection)
                [repositories[repoIndex] setObject:"owned" forKey:"repo_type"];
            else if (connection === pushableReposConnection)
                [repositories[repoIndex] setObject:"pushable" forKey:"repo_type"];

            continue;
        }
   
        [repo setObject:repoTypeHash[[connection UID]] forKey:"repo_type"];
        [repositories addObject:repo];
    }

    [[appController sourceList] reloadData];
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
