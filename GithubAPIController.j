
@import <Foundation/Foundation.j>
@import <AppKit/CPImage.j>
@import "md5-min.js"

//BASE_URL = "/";
//if(window.location && window.location.protocol === "file:")
    BASE_URL = "https://github.com/api/v2/json/";

var SharedController = nil,
    GravatarBaseURL = "http://www.gravatar.com/avatar/";

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

    CPURLConnection connectionWaitingOnAuthentication;

    @outlet CPView  loginView @accessors;
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

- (CPString)_credentialsString
{
    if ([self isAuthenticated])
        return "?login="+encodeURIComponent(username)+"&token="+encodeURIComponent(authenticationToken);
    else
        return "";
}

- (@action)authenticate:(id)sender
{
    var request = new CFHTTPRequest();
    request.open("GET", BASE_URL+"user/show"+[self _credentialsString], true);

    request.oncomplete = function()
    {
        if (request.success())
        {
            var response = JSON.parse(request.responseText()).user;
            emailAddress = response.email;
            emailAddressHashed = hex_md5(emailAddress);
            website = response.blog;

            var gravatarURL = GravatarBaseURL+emailAddressHashed;
            userImage = [[CPImage alloc] initWithContentsOfFile:gravatarURL+"?s=68&d=identicon"
                                                           size:CGSizeMake(68, 68)];
            userThumbnailImage = [[CPImage alloc] initWithContentsOfFile:gravatarURL+"?s=22&d=identicon"
                                                                    size:CGSizeMake(24, 24)];

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

        if (connectionWaitingOnAuthentication)
        {
            [connectionWaitingOnAuthentication cancel];
            [connectionWaitingOnAuthentication start];
        }

        connectionWaitingOnAuthentication = nil;

        [[CPRunLoop currentRunLoop] performSelectors];
    }

    request.send("");
}

- (@action)promptForAuthentication:(id)sender
{
    var contentView = [[[CPApp delegate] mainWindow] contentView];
    [loginView setFrame:[contentView bounds]];
    [contentView addSubview:loginView];
}

- (@action)dismissAuthenticationView:(id)sender
{
    connectionWaitingOnAuthentication = nil;
    [loginView removeFromSuperview];
}

- (void)connectionDidReceiveAuthenticationChallenge:(CPURLConnection)aConnection
{
    connectionWaitingOnAuthentication = aConnection;
    [self promptForAuthentication:nil];
}

- (CPDictionary)repositoryForIdentifier:(CPString)anIdentifier
{
    return [repositoriesByIdentifier objectForKey:anIdentifier];
}

- (void)loadRepositoryWithIdentifier:(CPString)anIdentifier callback:(Function)aCallback
{
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
                console.error("Unable to load repositority with identifier: "+anIdentifier+" -- "+e);
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
                aCallback(aRepo, openRequest, closedRequest);

            [[CPRunLoop currentRunLoop] performSelectors];
        };

    var openRequest = new CFHTTPRequest();
    openRequest.open("GET", BASE_URL+"issues/list/"+aRepo.identifier+"/open"+[self _credentialsString], true);

    openRequest.oncomplete = function()
    {
        if (openRequest.success())
        {
            try {
                var issues = [CPDictionary dictionaryWithJSObject:JSON.parse(openRequest.responseText()) recursively:YES];
                aRepo.openIssues = [issues objectForKey:"issues"];
            }
            catch (e) {
                console.error("Unable to load issues for repo: "+aRepo+" -- "+e);
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
                var issues = JSON.parse(closedRequest.responseText()).issues;
                aRepo.closedIssues = issues;
            }
            catch (e) {
                console.error("Unable to load repositority with identifier: "+anIdentifier+" -- "+e);
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
                console.error("Unable to load comments for issue: "+anIssue+" -- "+e);
            }
        }

        [anIssue setObject:comments forKey:"all_comments"];

        if (aCallback)
            aCallback(comments, anIssue, aRepo, request)
    }

    request.send("");
}

@end
