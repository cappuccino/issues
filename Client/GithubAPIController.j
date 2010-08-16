
@import <Foundation/Foundation.j>
@import <AppKit/CPImage.j>
@import "md5-min.js"

BASE_URL = "/github/";
if(window.location && window.location.protocol === "file:")
    BASE_URL = "https://github.com/api/v2/json/";

var SharedController = nil,
    GravatarBaseURL = "http://www.gravatar.com/avatar/";

// Sent whenever an issue changes
GitHubAPIIssueDidChangeNotification = @"GitHubAPIIssueDidChangeNotification";


CFHTTPRequest.AuthenticationDelegate = function(aRequest)
{
    var sharedController = [GithubAPIController sharedController];

    if (![sharedController isAuthenticated])
        [sharedController promptForAuthentication:nil];
}

@implementation GithubAPIController : CPObject
{
    CPString        username @accessors;
    CPString        authenticationToken @accessors;

    CPString        website @accessors;
    CPString        emailAddress @accessors;
    CPString        emailAddressHashed;
    CPImage         userImage @accessors;
    CPImage         userThumbnailImage @accessors;
    
    CPDictionary    repositoriesByIdentifier @accessors(readonly);
}

+ (id)sharedController
{
    if (!SharedController)
    {
        SharedController = [[super alloc] init];
        [CPURLConnection setClassDelegate:SharedController];
    }

    return SharedController;
}

- (id)init
{
    if (self = [super init])
    {
        repositoriesByIdentifier = [CPDictionary dictionary];
    }

    return self;
}

- (BOOL)isAuthenticated
{
    return [[CPUserSessionManager defaultManager] status] === CPUserSessionLoggedInStatus;
}

- (void)toggleAuthentication:(id)sender
{
    if ([self isAuthenticated])
        [self logout:sender];
    else
        [self promptForAuthentication:sender];
}

- (void)logout:(id)sender
{
    username = nil;
    authenticationToken = nil;
    userImage = nil;
    userThumbnailImage = nil;
    [[CPUserSessionManager defaultManager] setStatus:CPUserSessionLoggedOutStatus];
}

- (CPString)_credentialsString
{
    var authString = "?app_id=280issues";
    if ([self isAuthenticated])
        authString += "&login="+encodeURIComponent(username)+"&token="+encodeURIComponent(authenticationToken);

    return authString;
}

- (void)authenticateWithCallback:(Function)aCallback
{
    var request = new CFHTTPRequest();
    request.open("GET", BASE_URL+"user/show?login="+encodeURIComponent(username)+"&token="+encodeURIComponent(authenticationToken), true);

    request.oncomplete = function()
    {
        if (request.success())
        {
            var response = JSON.parse(request.responseText()).user;

            emailAddress = response.email;
            emailAddressHashed = response.gravatar_id || (response.email ? hex_md5(emailAddress) : "");
            website = response.blog;

            if (emailAddressHashed)
            {
                var gravatarURL = GravatarBaseURL+emailAddressHashed;
                userImage = [[CPImage alloc] initWithContentsOfFile:gravatarURL+"?s=68&d=identicon"
                                                               size:CGSizeMake(68, 68)];
                userThumbnailImage = [[CPImage alloc] initWithContentsOfFile:gravatarURL+"?s=22&d=identicon"
                                                                        size:CGSizeMake(24, 24)];
            }

            [[CPUserSessionManager defaultManager] setStatus:CPUserSessionLoggedInStatus];
        }
        else
        {
            emailAddress = nil;
            emailAddressHashed = nil;
            website = nil;
            userImage = nil;

            [[CPUserSessionManager defaultManager] setStatus:CPUserSessionLoggedOutStatus];
        }
        
        if (aCallback)
            aCallback(request.success());

        [[CPRunLoop currentRunLoop] performSelectors];
    }

    request.send("");
}

- (void)promptForAuthentication:(id)sender
{
    var loginWindow = [LoginWindow sharedLoginWindow];
    [loginWindow makeKeyAndOrderFront:self];
}

- (CPDictionary)repositoryForIdentifier:(CPString)anIdentifier
{
    return [repositoriesByIdentifier objectForKey:anIdentifier];
}

- (void)loadRepositoryWithIdentifier:(CPString)anIdentifier callback:(Function)aCallback
{
    var parts = anIdentifier.split("/");
    if (parts.length > 2)
        anIdentifier = parts.slice(0, 2).join("/");

    var request = new CFHTTPRequest();
    request.open("GET", BASE_URL+"repos/show/"+anIdentifier+[self _credentialsString], true);

    request.oncomplete = function()
    {
        var repo = nil;
        if (request.success())
        {
            try {
                repo = JSON.parse(request.responseText()).repository;
                repo.identifier = anIdentifier;

                [repositoriesByIdentifier setObject:repo forKey:anIdentifier];
            }
            catch (e) {
                CPLog.error("Unable to load repositority with identifier: "+anIdentifier+" -- "+e);
            }
        }

        if (aCallback)
            aCallback(repo, request);

        [[CPRunLoop currentRunLoop] performSelectors];
    }

    request.send("");
}

- (void)loadIssuesForRepository:(Repository)aRepo callback:(Function)aCallback
{
    var openIssuesLoaded = NO,
        closedIssuesLoaded = NO,
        waitForBoth = function()
        {
            if (!openIssuesLoaded || !closedIssuesLoaded)
                return;

            if (aCallback)
                aCallback(openRequest.success() && closedRequest.success(), aRepo, openRequest, closedRequest);

            [[CPRunLoop currentRunLoop] performSelectors];
        };

    var openRequest = new CFHTTPRequest();
    openRequest.open("GET", BASE_URL+"issues/list/"+aRepo.identifier+"/open"+[self _credentialsString], true);

    openRequest.oncomplete = function()
    {
        if (openRequest.success())
        {
            try {
                var issues = [[CPDictionary dictionaryWithJSObject:JSON.parse(openRequest.responseText()) recursively:YES] objectForKey:"issues"];
                aRepo.openIssues = issues;

                var maxPosition = 0,
                    minPosition = Infinity;
                for (var i = 0, count = issues.length; i < count; i++)
                {
                    maxPosition = MAX([issues[i] objectForKey:"position"], maxPosition);
                    minPosition = MIN([issues[i] objectForKey:"position"], minPosition);
                }

                aRepo.openIssuesMax = maxPosition;
                aRepo.openIssuesMin = minPosition;
            }
            catch (e) {
                CPLog.error("Unable to load issues for repo: "+aRepo+" -- "+e);
            }
        }

        openIssuesLoaded = YES;
        waitForBoth();
    }

    var closedRequest = new CFHTTPRequest();
    closedRequest.open("GET", BASE_URL+"issues/list/"+aRepo.identifier+"/closed"+[self _credentialsString], true);

    closedRequest.oncomplete = function()
    {
        if (closedRequest.success())
        {
            try {
                var issues = [[CPDictionary dictionaryWithJSObject:JSON.parse(closedRequest.responseText()) recursively:YES] objectForKey:"issues"];
                aRepo.closedIssues = issues;

                var maxPosition = 0,
                    minPosition = Infinity;
                for (var i = 0, count = issues.length; i < count; i++)
                {
                    maxPosition = MAX([issues[i] objectForKey:"position"], maxPosition);
                    minPosition = MIN([issues[i] objectForKey:"position"], minPosition);
                }

                aRepo.closedIssuesMax = maxPosition;
                aRepo.closedIssuesMin = minPosition;
            }
            catch (e) {
                CPLog.error("Unable to load repositority with identifier: "+anIdentifier+" -- "+e);
            }
        }

        closedIssuesLoaded = YES;
        waitForBoth();
    }
    
    openRequest.send("");
    closedRequest.send("");
}

- (void)loadCommentsForIssue:(Issue)anIssue repository:(Repository)aRepo callback:(Function)aCallback
{
    var request = new CFHTTPRequest();
    request.open("GET", BASE_URL+"issues/comments/"+aRepo.identifier+"/"+[anIssue objectForKey:"number"]+[self _credentialsString], true);

    request.oncomplete = function()
    {
        var comments = [];
        if (request.success())
        {
            try {
                comments = JSON.parse(request.responseText()).comments || [];
            }
            catch (e) {
                CPLog.error("Unable to load comments for issue: "+anIssue+" -- "+e);
            }
        }

        [anIssue setObject:comments forKey:"all_comments"];

        if (aCallback)
            aCallback(comments, anIssue, aRepo, request)

        [[CPRunLoop currentRunLoop] performSelectors];
    }

    request.send("");
}

- (void)loadLabelsForRepository:(Repository)aRepo
{
    var request = new CFHTTPRequest();
    request.open(@"GET", [CPString stringWithFormat:@"%@issues/labels/%@/%@", BASE_URL, aRepo.identifier, [self _credentialsString]], YES);

    request.oncomplete = function()
    {
        var labels;
        if (request.success())
        {
            try
            {
                labels = JSON.parse(request.responseText()).labels || [];
            }
            catch (e)
            {
                CPLog.error(@"Unable to load labels for issue: " + anIssue + @" -- " + e);
            }
        }

        aRepo.labels = labels;
        [[CPRunLoop currentRunLoop] performSelectors];
    };

    request.send(@"");
}

- (void)label:(CPString)aLabel forIssue:(Issue)anIssue repository:(Repository)aRepo shouldRemove:(BOOL)shouldRemove
{
    var request = new CFHTTPRequest(),
        addOrRemove = shouldRemove ? @"remove" : @"add";

    request.open(@"GET", [CPString stringWithFormat:@"%@issues/label/%@/%@/%@/%@%@", BASE_URL, addOrRemove, aRepo.identifier, aLabel, [anIssue objectForKey:@"number"], [self _credentialsString]], YES);

    request.oncomplete = function()
    {
        var labels;
        if (request.success())
        {
            try
            {
                // returns all the labels for the issue it was assigned to
                labels = JSON.parse(request.responseText()).labels || [];
                [anIssue setObject:labels forKey:@"labels"];
                [self _noteIssueChanged:anIssue];

                // now that we know it worked add the label to the repo if it's new
                if (![aRepo.labels containsObject:aLabel])
                    aRepo.labels.push(aLabel);
            }
            catch (e)
            {
                CPLog.error(@"Unable to set labels for issue: " + anIssue + @" -- " + e);
            }
        }

        [[CPRunLoop currentRunLoop] performSelectors];
    };

    request.send(@"");
}

- (void)closeIssue:(id)anIssue repository:(id)aRepo callback:(Function)aCallback
{
    var request = new CFHTTPRequest();
    request.open("POST", BASE_URL+"issues/close/"+aRepo.identifier+"/"+[anIssue objectForKey:"number"]+[self _credentialsString], true);

    request.oncomplete = function()
    {
        if (request.success())
        {
            [anIssue setObject:"closed" forKey:"state"];
            [aRepo.openIssues removeObject:anIssue];
            aRepo.closedIssues.unshift(anIssue);

            [self _noteIssueChanged:anIssue];
        }

        if (aCallback)
            aCallback(request.success(), anIssue, aRepo, request);

        [[CPRunLoop currentRunLoop] performSelectors];
    }
    
    request.send("");
}

- (void)reopenIssue:(id)anIssue repository:(id)aRepo callback:(Function)aCallback
{
    var request = new CFHTTPRequest();
    request.open("POST", BASE_URL+"issues/reopen/"+aRepo.identifier+"/"+[anIssue objectForKey:"number"]+[self _credentialsString], true);

    request.oncomplete = function()
    {
        if (request.success())
        {
            [anIssue setObject:"open" forKey:"state"];
            [aRepo.closedIssues removeObject:anIssue];
            aRepo.openIssues.unshift(anIssue);

            [self _noteIssueChanged:anIssue];
        }

        if (aCallback)
            aCallback(request.success(), anIssue, aRepo, request);

        [[CPRunLoop currentRunLoop] performSelectors];
    }

    request.send("");
}

- (void)openNewIssueWithTitle:(CPString)aTitle body:(CPString)aBody repository:(id)aRepo callback:(Function)aCallback
{
    var request = new CFHTTPRequest();
    request.open("POST", BASE_URL+"issues/open/"+aRepo.identifier+[self _credentialsString]+
                                                 "&title="+encodeURIComponent(aTitle)+
                                                 "&body="+encodeURIComponent(aBody), true);

    request.oncomplete = function()
    {
        if (request.success())
        {
            var issue = nil;
            try {
                issue = [CPDictionary dictionaryWithJSObject:JSON.parse(request.responseText()).issue];
                aRepo.openIssues.push(issue);
                
                if (![issue containsKey:"position"])
                    [issue setObject:aRepo.minPosition forKey:"position"];
                
                aRepo.openIssuesMax = MAX([issue objectForKey:"position"], aRepo.openIssuesMax);
                aRepo.openIssuesMin = MIN([issue objectForKey:"position"], aRepo.openIssuesMin);
            }
            catch (e) {
                CPLog.error("Unable to open new issue: "+aTitle+" -- "+e);
            }
        }

        if (aCallback)
            aCallback(issue, aRepo, request);

        [[CPRunLoop currentRunLoop] performSelectors];
    }

    request.send("");
}

- (void)addComment:(CPString)commentBody onIssue:(id)anIssue inRepository:(id)aRepo callback:(Function)aCallback
{
    var request = new CFHTTPRequest();
    request.open("POST", BASE_URL+"issues/comment/"+aRepo.identifier+"/"+
                [anIssue objectForKey:"number"]+[self _credentialsString]+
                "&comment="+encodeURIComponent(commentBody), true);

    request.oncomplete = function()
    {
        var comment = nil;
        if (request.success())
        {
            try {
                comment = JSON.parse(request.responseText()).comment;

                var comments = [anIssue objectForKey:"all_comments"];

                comment.body_html = Markdown.makeHtml(comment.body || "");
                comment.human_readable_date = [CPDate simpleDate:comment.created_at];

                comments.push(comment);

                [self _noteIssueChanged:anIssue];
            }
            catch (e) {
                CPLog.error("Unable to load comments for issue: "+anIssue+" -- "+e);
            }
        }

        if (aCallback)
            aCallback(comment, request);

            [[CPRunLoop currentRunLoop] performSelectors];
    }

    request.send("");
}

- (void)editIsssue:(Issue)anIssue title:(CPString)aTitle body:(CPString)aBody repository:(id)aRepo callback:(Function)aCallback
{
    // we've got to make two calls one for the title and one for the body
    var request = new CFHTTPRequest();
    request.open("POST", BASE_URL+"issues/edit/"+aRepo.identifier+"/"+[anIssue objectForKey:"number"]+[self _credentialsString]+
                                                 "&title="+encodeURIComponent(aTitle)+
                                                 "&body="+encodeURIComponent(aBody), true);
    
    request.oncomplete = function()
    {
        if (request.success())
        {
            var issue = nil;
            try {
                issue = [CPDictionary dictionaryWithJSObject:JSON.parse(request.responseText()).issue];

                [anIssue setObject:[issue objectForKey:"title"] forKey:"title"];
                [anIssue setObject:[issue objectForKey:"body"] forKey:"body"];
                [anIssue setObject:[issue objectForKey:"updated_at"] forKey:"updated_at"];

                [self _noteIssueChanged:anIssue];
            }
            catch (e) {
                CPLog.error("Unable to open new issue: "+aTitle+" -- "+e);
            }
        }
    
        if (aCallback)
            aCallback(issue, aRepo, request);
    
        [[CPRunLoop currentRunLoop] performSelectors];
    }
    
    request.send("");

}

- (void)setPositionForIssue:(id)anIssue inRepository:(id)aRepo to:(int)aPosition callback:(Function)aCallback
{
    var request = new CFHTTPRequest();
    request.open("POST", BASE_URL+"issues/edit/"+aRepo.identifier+"/"+[anIssue objectForKey:"number"]+[self _credentialsString]+"&position="+encodeURIComponent(aPosition), true);

    request.oncomplete = function()
    {
        if (request.success())
        {
            // not really sure what we need to do here
            // I'm getting false back...
        }

        if (aCallback)
            aCallback(request.success(), anIssue, aRepo, request);

        [[CPRunLoop currentRunLoop] performSelectors];
    }

    request.send("");
}

- (void)_noteIssueChanged:(id)anIssue
{
    [[CPNotificationCenter defaultCenter] postNotificationName:GitHubAPIIssueDidChangeNotification
                                                        object:anIssue
                                                      userInfo:nil];
}
@end

// expose root level interface, for accessing from the iframes
GitHubAPI = {
    addComment: function(commentBody, anIssue, aRepo, callback)
    {
        [SharedController addComment:commentBody 
                             onIssue:anIssue 
                        inRepository:aRepo
                            callback:callback];
    },
    
    closeIssue: function(anIssue, aRepo, callback)
    {
        [SharedController closeIssue:anIssue 
                          repository:aRepo
                            callback:callback];
    },
    
    reopenIssue: function(anIssue, aRepo, callback)
    {
        [SharedController reopenIssue:anIssue 
                           repository:aRepo
                            callback:callback];
    },

    openEditWindow: function(anIssue, aRepo)
    {
        [[[CPApp delegate] issuesController] editIssue:anIssue repo:aRepo];
    }
}
