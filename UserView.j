
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
        [imageView setHidden:NO];
        [imageFrame setHidden:NO];
    }
    else
    {
        [usernameField setStringValue:"Not logged in"];
        [emailField setStringValue:"Click to login to Github"];
        [imageView setImage:nil];
        [imageView setHidden:YES];
        [imageFrame setHidden:YES];
    }
}

- (void)initWithCoder:(CPCoder)aCoder
{
    self = [super initWithCoder:aCoder];

    imageView = [aCoder decodeObjectForKey:"imageView"];
    imageFrame = [aCoder decodeObjectForKey:"imageFrame"];
    usernameField = [aCoder decodeObjectForKey:"usernameField"];
    emailField = [aCoder decodeObjectForKey:"emailField"];

    [self registerForNotifications];
    
    return self;
}

- (void)encodeWithCoder:(CPCoder)aCoder
{
    [super encodeWithCoder:aCoder];
    [aCoder encodeObject:imageFrame forKey:"imageFrame"];
    [aCoder encodeObject:imageView forKey:"imageView"];
    [aCoder encodeObject:usernameField forKey:"usernameField"];
    [aCoder encodeObject:emailField forKey:"emailField"];
}

@end
