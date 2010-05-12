
@import <AppKit/CPView.j>


@implementation UserView : CPControl
{
    @outlet CPImageView imageView;
    @outlet CPImageView imageFrame;
    @outlet CPTextField usernameField;
    @outlet CPTextField emailField;
            CPImage     octocatImage;
}

- (void)awakeFromCib
{
    [self setBackgroundColor:[CPColor colorWithWhite:1.0 alpha:0.1]];
    [usernameField setLineBreakMode:CPLineBreakByTruncatingTail];
    [usernameField setFont:[CPFont systemFontOfSize:11.0]];
    [usernameField setTextShadowColor:[CPColor colorWithWhite:0.9 alpha:1.0]];
    [usernameField setTextShadowOffset:CGSizeMake(0, 1)];
    [emailField setLineBreakMode:CPLineBreakByTruncatingTail];
    [emailField setFont:[CPFont systemFontOfSize:11.0]];
    [emailField setTextColor:[CPColor colorWithWhite:0.4 alpha:1.0]];
    [emailField setTextShadowColor:[CPColor colorWithWhite:0.9 alpha:1.0]];
    [emailField setTextShadowOffset:CGSizeMake(0, 1)];

    [self registerForNotifications];
    [self setTarget:[GithubAPIController sharedController]];
    [self setAction:@selector(toggleAuthentication:)];

    var path = [[CPBundle mainBundle] pathForResource:"octocat22.png"];
    octocatImage = [[CPImage alloc] initWithContentsOfFile:path size:CGSizeMake(22, 19)];

    [self loginStatusDidChange:nil];
}

- (void)registerForNotifications
{
    [[CPNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(loginStatusDidChange:) 
                                                 name:CPUserSessionManagerStatusDidChangeNotification 
                                               object:nil];
}

- (void)loginStatusDidChange:(CPNotification)aNote
{
    var githubController = [GithubAPIController sharedController],
        isLoggedIn = [githubController isAuthenticated];
    
    if (isLoggedIn)
    {
        [usernameField setStringValue:[githubController username]];
        [emailField setStringValue:[githubController emailAddress]];
        [imageView setImage:[githubController userThumbnailImage]];
    }
    else
    {
        [usernameField setStringValue:"Not logged in"];
        [emailField setStringValue:"Click to login to Github"];
        [imageView setImage:octocatImage];
    }
}

@end
