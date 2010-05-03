
@import <Foundation/Foundation.j>
@import <AppKit/CPImage.j>
@import "md5-min.js"

//BASE_URL = "/";
//if(window.location && window.location.protocol === "file:")
    BASE_URL = "https://github.com/api/v2/json/";

var SharedController = nil,
    GravatarBaseURL = "http://www.gravatar.com/avatar/";

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
    [[CPUserSessionManager defaultManager] setStatus:CPUserSessionLoggedOutStatus];
}

- (CPString)_credentialsString
{
    if ([self isAuthenticated])
        return "?login="+encodeURIComponent(username)+"&token="+encodeURIComponent(authenticationToken);
    else
        return "";
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

            if (response.email)
            {
                emailAddress = response.email;
                emailAddressHashed = hex_md5(emailAddress);
                website = response.blog;
                
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
                var issues = [CPDictionary dictionaryWithJSObject:JSON.parse(openRequest.responseText()) recursively:YES];
                aRepo.openIssues = [issues objectForKey:"issues"];
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
                var issues = [CPDictionary dictionaryWithJSObject:JSON.parse(closedRequest.responseText()) recursively:YES];
                aRepo.closedIssues = [issues objectForKey:"issues"];
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
    }

    request.send("");
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
        }
        if (aCallback)
            aCallback(request.success(), anIssue, aRepo, request);
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
        }

        if (aCallback)
            aCallback(request.success(), anIssue, aRepo, request);
    }

    request.send("");
}

@end
