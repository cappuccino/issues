// The DataController class connects to GitHub
// Providing an abstraction from their API
// This could potentially provide a connection to lite

@import <Foundation/CPObject.j>

@implementation DataController : CPObject
{
    CPArray issues;
    id      selectedIssue @accessors;
    CPArray tags;
    id      appController;
    
    CPJSONPConnection issuesConnection;
    CPJSONPConnection tagsConnection;
    CPJSONPConnection writeConnection;
    CPJSONPConnection addCommentsConnection;
    
    CPString    theRepo;
    CPString    theUser;
}

- (id)initWithProject:(CPString)aRepo user:(CPString)aUser appController:(id)theAppController
{
    self = [super init];
    if (self)
    {
        appController = theAppController;
        theRepo = aRepo;
        theUser = aUser;
        issues = [CPArray array];
    }
    return self;
}

- (void)searchWithString:(CPString)aSearchString
{
    if(aSearchString)
        var theReadURL = "http://github.com/api/v2/json/issues/search/" + theUser + "/" + theRepo + "/open/" + aSearchString;
    else
        var theReadURL = "http://github.com/api/v2/json/issues/list/" + theUser + "/" + theRepo + "/open";
    
    
    var theRequest = [[CPURLRequest alloc] initWithURL:theReadURL];
    
    //readConnection = [[CPURLConnection alloc] initWithRequest:theRequest delegate:self startImmediately:YES];
    issuesConnection = [[CPJSONPConnection alloc] initWithRequest:theRequest callback:@"callback" delegate:self startImmediately:YES];
}

- (void)addComment:(CPString)aComment forIssue:(int)anIssueNumber 
{
    aComment = encodeURI(aComment);
    //this is the issue number not the index btw
     var addCommentURL = "https://github.com/api/v2/json/issues/comment/" + theUser + "/" + theRepo + "/" + anIssueNumber + "?login=" + GITHUBUSERNAME + "&token=" + GITHUBAPITOKEN + "&comment=" + aComment, 
         addCommentRequest = [[CPURLRequest alloc] initWithURL:addCommentURL];
    //console.log(encodeURI(addCommentURL));
    //return;
    addCommentsConnection = [[CPJSONPConnection alloc] initWithRequest:addCommentRequest callback:@"callback" delegate:self startImmediately:YES];
}

- (void)commentsForIssue:(int)anIssueNumber 
{
    //this is the issue number not the index btw
     var getCommentsURL = "http://github.com/api/v2/json/issues/comments/" + "Me1000" + "/" + "RLOfflineDataStore/" + anIssueNumber,
         getCommentsRequest = [[CPURLRequest alloc] initWithURL:getCommentsURL];

    getCommentsConnection = [[CPJSONPConnection alloc] initWithRequest:getCommentsRequest callback:@"callback" delegate:self startImmediately:YES];
}


- (void)getAllTags
{
    //var theReadURL = "https://github.com/api/v2/json/issues/labels/" + theUser + "/" + theRepo + "?login=" + GITHUBUSERNAME + "&token=" + GITHUBAPITOKEN,  
    var theReadURL = "https://Me1000:icu81234@github.com/api/v2/json/issues/labels/" + theUser + "/" + theRepo,  
        theRequest = [[CPURLRequest alloc] initWithURL:theReadURL];

    tagsConnection = [[CPJSONPConnection alloc] initWithRequest:theRequest callback:@"callback" delegate:self startImmediately:YES];
}

- (id)issueAtindex:(id)anIndex
{
    
    return issues[anIndex];
}

- (int)numberOfIssues
{
    return [issues count];
}

- (int)issueNumberForIssueAtIndex:(int)issueIndex
{
    return [issues objectAtIndex:issueIndex].number;
}

- (int)votesForIssueAtIndex:(int)issueIndex
{
    return [issues objectAtIndex:issueIndex].votes;
}

- (CPString)titleForIssueAtIndex:(int)issueIndex
{
    return [issues objectAtIndex:issueIndex].title;
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
    //alert("called");
    //we're looking for a json object back but we might get a stringified json object
    //console.log(typeof(data));
    if(typeof(data) === "string")
        data = JSON.parse(data);
    
    if(data.error)
    {
        console.log(data.error);
        alert("An error has occured, check the console dude.");
        return;
    }
    
    if(connection === issuesConnection)
    {
        // from here we've got a json object of all the issues need to be displayed
        // once parsed display update the table
        issues = data.issues;
        [appController reloadData];
    }
    else if(connection === tagsConnection)
    {
        // here we have a list of all the labels. 
        // we then update the menu to display only those specific tags
        tags = data.labels;
        console.log(tags);
        //[appController updateTagsButtonWithTags:tags];
    }
    else if(connection === addCommentsConnection)
    {
        alert("your comment was saved.");
    }
    else if(connection === getCommentsConnection)
    {
        alert("you have comments, check the console dude.");
        console.log(data);
    }
}

@end
