
@import <AppKit/CPView.j>


@implementation UserView : CPView
{
    @outlet CPImageView imageView;
    @outlet CPImageView imageFrame;
    @outlet CPTextField usernameField;
    @outlet CPTextField emailField;
}

- (void)awakeFromCib
{
    [self loginStatusDidChange:nil];
    [usernameField setFont:[CPFont systemFontOfSize:11.0]];
    [emailField setFont:[CPFont systemFontOfSize:11.0]];
    [emailField setTextColor:[CPColor grayColor]];
    [imageFrame setBackgroundColor:[CPColor whiteColor]];
    
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
    }
    else
    {
        [usernameField setStringValue:"Not logged in"];
        [emailField setStringValue:"Click to login to Github"];
    }
}

- (void)initWithCoder:(CPCoder)aCoder
{
    self = [super initWithCoder:aCoder];

    imageView = [aCoder decodeObjectForKey:"imageView"];
    usernameField = [aCoder decodeObjectForKey:"usernameField"];
    emailField = [aCoder decodeObjectForKey:"emailField"];

    [self registerForNotifications];
    
    return self;
}

- (void)encodeWithCoder:(CPCoder)aCoder
{
    [super encodeWithCoder:aCoder];
    [aCoder encodeObject:imageView forKey:"imageView"];
    [aCoder encodeObject:usernameField forKey:"usernameField"];
    [aCoder encodeObject:emailField forKey:"emailField"];
}

@end
