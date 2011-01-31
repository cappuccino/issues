
@import <Foundation/Foundation.j>
@import <AppKit/CPImage.j>
@import "md5-min.js"

BASE_API = "/github/";
BASE_URL = "https://github.com/";

if (window.location && window.location.protocol === "file:")
    BASE_API = BASE_URL + "api/v2/json/";

var SharedController = nil,
    GravatarBaseURL = "http://www.gravatar.com/avatar/";

// Sent whenever an issue changes
GitHubAPIIssueDidChangeNotification = @"GitHubAPIIssueDidChangeNotification";
GitHubAPIRepoDidChangeNotification  = "GitHubAPIRepoDidChangeNotification";


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
    CPString        oauthAccessToken @accessors;

    CPString        website @accessors;
    CPString        emailAddress @accessors;
    CPString        emailAddressHashed;
    CPImage         userImage @accessors;
    CPImage         userThumbnailImage @accessors;

    CPDictionary    repositoriesByIdentifier @accessors(readonly);

    OAuthController loginController @accessors;

    CPAlert         warnAlert;
    CPAlert         logoutWarn;

    Function        nextAuthCallback @accessors;
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

- (void)logoutPrompt:(id)sender
{
    // if we're not using OAuth it's a pain to find the
    // API token... so just ask them to make sure

    if (oauthAccessToken)
        return [self logout:nil];

    logoutWarn= [[CPAlert alloc] init];
    [logoutWarn setTitle:"Are You Sure?"];
    [logoutWarn setMessageText:"Are you sure you want to logout?"];
    [logoutWarn setInformativeText:text];
    [logoutWarn setAlertStyle:CPInformationalAlertStyle];
    [logoutWarn addButtonWithTitle:"Cancel"];
    [logoutWarn setDelegate:self];
    [logoutWarn addButtonWithTitle:"Logout"];

    [logoutWarn runModal];
}

- (void)logout:(id)sender
{
    username = nil;
    authenticationToken = nil;
    userImage = nil;
    userThumbnailImage = nil;
    oauthAccessToken = nil;
    [[CPUserSessionManager defaultManager] setStatus:CPUserSessionLoggedOutStatus];
}

- (CPString)_credentialsString
{
    var authString = "?app_id=280issues";
    if ([self isAuthenticated])
    {
        if (oauthAccessToken)
            authString += "&access_token="+encodeURIComponent(oauthAccessToken);
        else
            authString += "&login="+encodeURIComponent(username)+"&token="+encodeURIComponent(authenticationToken);
    }

    return authString;
}

- (void)authenticateWithCallback:(Function)aCallback
{
    var request = new CFHTTPRequest();

    if (oauthAccessToken)
        request.open("GET", BASE_API + "user/show?access_token=" + encodeURIComponent(oauthAccessToken), true);
    else
        request.open("GET", BASE_API + "user/show?login=" + encodeURIComponent(username) + "&token=" + encodeURIComponent(authenticationToken), true);

    request.oncomplete = function()
    {
        if (request.success())
        {
            var response = JSON.parse(request.responseText()).user;

            username = response.login;
            emailAddress = response.email;
            emailAddressHashed = response.gravatar_id || (response.email ? hex_md5(emailAddress) : "");
            website = response.blog;

            if (emailAddressHashed)
            {
                var gravatarURL = GravatarBaseURL + emailAddressHashed;
                userImage = [[CPImage alloc] initWithContentsOfFile:gravatarURL + "?s=68&d=identicon"
                                                               size:CGSizeMake(68, 68)];
                userThumbnailImage = [[CPImage alloc] initWithContentsOfFile:gravatarURL + "?s=22&d=identicon"
                                                                        size:CGSizeMake(24, 24)];
            }

            [[CPUserSessionManager defaultManager] setStatus:CPUserSessionLoggedInStatus];

            if (nextAuthCallback)
                nextAuthCallback();
        }
        else
        {
            username = nil;
            emailAddress = nil;
            emailAddressHashed = nil;
            website = nil;
            userImage = nil;
            oauthAccessToken = nil;

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
    // because oauth relies on the server and multiple windows
    if ([CPPlatform isBrowser] && [CPPlatformWindow supportsMultipleInstances] && BASE_API === "/github/")
        loginController = [[OAuthController alloc] init];
    else
    {
        var loginWindow = [LoginWindow sharedLoginWindow];
        [loginWindow makeKeyAndOrderFront:self];
    }
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
    request.open("GET", BASE_API+"repos/show/"+anIdentifier+[self _credentialsString], true);

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

        if (repo)
            [self loadLabelsForRepository:repo];

        [[CPRunLoop currentRunLoop] performSelectors];
    }

    request.send("");
}

- (void)loadIssuesForRepository:(Repository)aRepo callback:(id)aCallback
{
    var openIssuesLoaded = NO,
        closedIssuesLoaded = NO,
        waitForBoth = function () {
            if (!openIssuesLoaded || !closedIssuesLoaded)
                return;

            if (aCallback)
                aCallback(openRequest.success() && closedRequest.success(), aRepo, openRequest, closedRequest);

            [[CPRunLoop currentRunLoop] performSelectors];
        };

    var openRequest = new CFHTTPRequest();
    openRequest.open("GET", BASE_API+"issues/list/"+aRepo.identifier+"/open"+[self _credentialsString], true);

    openRequest.oncomplete = function() {
        if (openRequest.success())
        {
            try
            {
                var issues = [[CPDictionary dictionaryWithJSObject:JSON.parse(openRequest.responseText()) recursively:YES] objectForKey:"issues"];

                [self _noteRepoChanged:aRepo];

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
            catch (e)
            {
                CPLog.error("Unable to load issues for repo: "+aRepo+" -- "+e);
            }
        }

        openIssuesLoaded = YES;
        waitForBoth();
    }

    var closedRequest = new CFHTTPRequest();
    closedRequest.open("GET", BASE_API + "issues/list/" + aRepo.identifier + "/closed" + [self _credentialsString], true);

    closedRequest.oncomplete = function() {
        if (closedRequest.success())
        {
            try
            {
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
            catch (e)
            {
                CPLog.error("Unable to load repositority with identifier: " + anIdentifier + " -- " + e);
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
    request.open("GET", BASE_API+"issues/comments/"+aRepo.identifier+"/"+[anIssue objectForKey:"number"]+[self _credentialsString], true);

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
    request.open(@"GET", [CPString stringWithFormat:@"%@issues/labels/%@/%@", BASE_API, aRepo.identifier, [self _credentialsString]], YES);

    request.oncomplete = function()
    {
        var labels = [];
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

    request.open(@"GET", [CPString stringWithFormat:@"%@issues/label/%@/%@/%@/%@%@", BASE_API, addOrRemove, aRepo.identifier, encodeURIComponent(aLabel), [anIssue objectForKey:@"number"], [self _credentialsString]], YES);

    request.oncomplete = function()
    {
        [self _checkGithubResponse:request];
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
    request.open("POST", BASE_API+"issues/close/"+aRepo.identifier+"/"+[anIssue objectForKey:"number"]+[self _credentialsString], true);

    request.oncomplete = function()
    {
        [self _checkGithubResponse:request];

        if (request.success())
        {
            [anIssue setObject:"closed" forKey:"state"];
            [aRepo.openIssues removeObject:anIssue];
            [aRepo.closedIssues addObject:anIssue];

            [self _noteRepoChanged:aRepo];
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
    request.open("POST", BASE_API+"issues/reopen/"+aRepo.identifier+"/"+[anIssue objectForKey:"number"]+[self _credentialsString], true);

    request.oncomplete = function()
    {
        [self _checkGithubResponse:request];

        if (request.success())
        {
            [anIssue setObject:"open" forKey:"state"];
            [aRepo.closedIssues removeObject:anIssue];
            [aRepo.openIssues addObject:anIssue];

            [self _noteRepoChanged:aRepo];
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
    request.open("POST", BASE_API+"issues/open/"+aRepo.identifier+[self _credentialsString]+
                                                 "&title="+encodeURIComponent(aTitle)+
                                                 "&body="+encodeURIComponent(aBody), true);

    request.oncomplete = function()
    {
        [self _checkGithubResponse:request];

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
                [self _noteRepoChanged:aRepo];
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
    request.open("POST", BASE_API + "issues/comment/"+aRepo.identifier+"/" +
                [anIssue objectForKey:"number"] + [self _credentialsString] +
                "&comment="+encodeURIComponent(commentBody), true);

    request.oncomplete = function()
    {
        [self _checkGithubResponse:request];

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
    request.open("POST", BASE_API + "issues/edit/" + aRepo.identifier + "/" + [anIssue objectForKey:"number"] + [self _credentialsString] +
                                                 "&title=" + encodeURIComponent(aTitle) +
                                                 "&body=" + encodeURIComponent(aBody), true);

    request.oncomplete = function()
    {
        [self _checkGithubResponse:request];

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

/*
because one day maybe GitHub will give this to me... :) 
- (void)setPositionForIssue:(id)anIssue inRepository:(id)aRepo to:(int)aPosition callback:(Function)aCallback
{
    var request = new CFHTTPRequest();
    request.open("POST", BASE_API+"issues/edit/"+aRepo.identifier+"/"+[anIssue objectForKey:"number"]+[self _credentialsString]+"&position="+encodeURIComponent(aPosition), true);

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
}*/

- (void)_noteIssueChanged:(id)anIssue
{
    [[CPNotificationCenter defaultCenter] postNotificationName:GitHubAPIIssueDidChangeNotification
                                                        object:anIssue
                                                      userInfo:nil];
}

- (void)_noteRepoChanged:(id)aRepo
{
    [[CPNotificationCenter defaultCenter] postNotificationName:GitHubAPIRepoDidChangeNotification
                                                        object:nil
                                                      userInfo:nil];
}

- (void)_checkGithubResponse:(CFHTTPRequest)aRequest
{
    if (aRequest.status() === 401)
    {
        try
        {
            // we got a 401 from something else... o.0
            if (JSON.parse(aRequest.responseText()).error !== "not authorized")
                return;
            else
            {
                var auth = [self isAuthenticated],
                    text = (auth) ? "Make sure your account has sufficient privileges to modify an issue or reposotory. " : "The action you tried to perfom requires you to be authenticated. Please login.";

                // this way we only get one alert at a time
                if (!warnAlert)
                {
                    warnAlert = [[CPAlert alloc] init];
                    [warnAlert setTitle:"Not Authorized"];
                    [warnAlert setMessageText:"Unauthorized Request"];
                    [warnAlert setInformativeText:text];
                    [warnAlert setAlertStyle:CPInformationalAlertStyle];
                    [warnAlert addButtonWithTitle:"Okay"];
                    [warnAlert setDelegate:self];

                    if (!auth)
                        [warnAlert addButtonWithTitle:"Login"];
                }

                [warnAlert runModal];
            }
        }catch(e){}
    }
    else if (aRequest.status() === 503)
    {
        var noteAlert = [[CPAlert alloc] init];

        [noteAlert setTitle:"Service Unavailable"];
        [noteAlert setMessageText:"Service Unavailable"];
        [noteAlert setInformativeText:"It appears the GitHub API is down at the moment. Check back in a few minutes to see if it is back online."];
        [noteAlert setAlertStyle:CPWarningAlertStyle];
        [noteAlert addButtonWithTitle:"Okay"];
    }
}

- (void)alertDidEnd:(id)sender returnCode:(int)returnCode
{
    if (sender === warnAlert && returnCode === 1)
        [self promptForAuthentication:self];
    else if (sender === logoutWarn && returnCode === 1)
        [self logout:nil];
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

@implementation CPNull (compare)
- (CPComparisonResult)compare:(id)anObj
{
    if (self === anObj)
        return CPOrderedSame;

    return CPOrderedAscending;
}
@end
