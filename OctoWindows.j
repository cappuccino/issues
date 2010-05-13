
@import <Foundation/CPObject.j>

@implementation OctoWindow : CPWindow
{
    @outlet CPTextField welcomeLabel @accessors;
    @outlet CPView      borderView @accessors;
    @outlet CPTextField errorMessageField @accessors;
    @outlet CPView      progressIndicator @accessors;
    @outlet CPButton    defaultButton;
    @outlet CPButton    cancelButton;
}

- (void)awakeFromCib
{
    [borderView setBackgroundColor:[CPColor lightGrayColor]];
    [welcomeLabel setFont:[CPFont systemFontOfSize:22.0]];
    [errorMessageField setTextColor:[CPColor redColor]];
}

- (id)initWithContentRect:(CGRect)aRect styleMask:(unsigned)aMask
{
    if (self = [super initWithContentRect:aRect styleMask:0])
    {
        [self center];
        [self setMovableByWindowBackground:YES];
    }

    return self;
}

- (@action)orderFront:(id)sender
{
    [super orderFront:sender];
    [errorMessageField setHidden:YES];
    [progressIndicator setHidden:YES];
}

- (void)setDefaultButton:(CPButton)aButton
{
    [super setDefaultButton:aButton];
    defaultButton = aButton;
}

@end

var SharedLoginWindow = nil;

@implementation LoginWindow : OctoWindow
{
    @outlet CPTextField usernameField @accessors;
    @outlet CPTextField apiTokenField @accessors;
    @outlet CPButton    apiTokenHelpButton @accessors;
}

+ (id)sharedLoginWindow
{
    return SharedLoginWindow;
}

- (void)awakeFromCib
{
    SharedLoginWindow = self;
    [super awakeFromCib];
    
    [apiTokenHelpButton setBordered:NO];
}

- (@action)openAPIKeyPage:(id)sender
{
    window.open("https://github.com/account");
}

- (@action)orderFront:(id)sender
{
    [super orderFront:sender];
    [usernameField setStringValue:""];
    [apiTokenField setStringValue:""];
}

- (@action)login:(id)sender
{
    var githubController = [GithubAPIController sharedController];
    [githubController setUsername:[[self usernameField] stringValue]];
    [githubController setAuthenticationToken:[[self apiTokenField] stringValue]];

    [githubController authenticateWithCallback:function(success)
    {
        [progressIndicator setHidden:YES];
        [errorMessageField setHidden:success];
        [defaultButton setEnabled:YES];
        [cancelButton setEnabled:YES];

        if (success)
        {
            [[[NewRepoWindow sharedNewRepoWindow] errorMessageField] setHidden:YES];
            [self orderOut:self];
        }
    }];
    
    [errorMessageField setHidden:YES];
    [progressIndicator setHidden:NO];
    [defaultButton setEnabled:NO];
    [cancelButton setEnabled:NO];
}

@end

var SharedRepoWindow = nil;

@implementation NewRepoWindow : OctoWindow
{
    @outlet CPTextField identifierField @accessors;
    @outlet RepositoriesController repoController;
}

+ (id)sharedNewRepoWindow
{
    return SharedRepoWindow;
}

- (void)awakeFromCib
{
    SharedRepoWindow = self;
    [super awakeFromCib];
    [identifierField setValue:[CPColor grayColor] forThemeAttribute:"text-color" inState:CPTextFieldStatePlaceholder];
}

- (@action)orderFront:(id)sender
{
    [super orderFront:sender];
    [identifierField setStringValue:""];
}

- (@action)addRepository:(id)sender
{
    var repoIdentifier = [identifierField stringValue];
    if (!repoIdentifier)
        return;

    var existingRepo = [[GithubAPIController sharedController] repositoryForIdentifier:repoIdentifier];
    if (existingRepo)
    {
        [repoController addRepository:existingRepo];
        [self orderOut:self];
        return;
    }

    [[GithubAPIController sharedController] loadRepositoryWithIdentifier:repoIdentifier callback:function(repo)
    {
        [progressIndicator setHidden:YES];
        [errorMessageField setHidden:!!repo];
        [defaultButton setEnabled:YES];
        [cancelButton setEnabled:YES];

        if (repo)
        {
            [repoController addRepository:repo];
            [self orderOut:self];
        }
    }];    

    [errorMessageField setHidden:YES];
    [progressIndicator setHidden:NO];
    [defaultButton setEnabled:NO];
    [cancelButton setEnabled:NO];
}

@end

@implementation RepoSuggestionButton : CPButton
{
}

+ (CPColor)bezelColor
{
    return [CPColor colorWithPatternImage:CPImageInBundle(@"RepoSuggestionButtonBezel.png", CGSizeMake(308.0, 52.0))];
}

+ (CPColor)highlightedBezelColor
{
    return [CPColor colorWithPatternImage:CPImageInBundle(@"RepoSuggestionButtonBezelHighlighted.png", CGSizeMake(308.0, 52.0))];
}

+ (CPColor)textColor
{
    return [CPColor colorWithRed:52.0 / 255.0 green:144.0 / 255.0 blue:226.0 / 229.0 alpha:1.0];
}

- (void)awakeFromCib
{
    [self setAlignment:CPLeftTextAlignment];
    [self setValue:CGInsetMake(0.0, 0.0, 0.0, 22.0) forThemeAttribute:@"content-inset" inState:CPThemeStateNormal];
    [self setValue:[[self class] textColor] forThemeAttribute:@"text-color" inState:CPThemeStateNormal];
    [self setValue:[[self class] bezelColor] forThemeAttribute:@"bezel-color" inState:CPThemeStateNormal];
    [self setValue:[[self class] highlightedBezelColor] forThemeAttribute:@"bezel-color" inState:CPThemeStateHighlighted];
}

@end

@implementation RepoEntryField : CPTextField
{
}

+ (CPColor)bezelColor
{
    return [CPColor colorWithPatternImage:CPImageInBundle(@"RepoEntryField.png", CGSizeMake(308.0, 52.0))];
}

+ (CPColor)highlightedBezelColor
{
    return [CPColor colorWithPatternImage:CPImageInBundle(@"RepoSuggestionButtonBezelHighlighted.png", CGSizeMake(308.0, 52.0))];
}

- (void)awakeFromCib
{
    [self setFont:[CPFont boldSystemFontOfSize:12.0]];
    [self setValue:[CPColor colorWithWhite:0.6 alpha:1.0] forThemeAttribute:@"text-color" inState:CPTextFieldStatePlaceholder];
    [self setValue:CGInsetMakeZero() forThemeAttribute:@"bezel-inset" inState:CPThemeStateNormal];
    [self setValue:CGInsetMake(0.0, 22.0, 0.0, 22.0) forThemeAttribute:@"content-inset" inState:CPThemeStateNormal];
    [self setVerticalAlignment:CPCenterVerticalTextAlignment];

    [self setValue:[[self class] bezelColor] forThemeAttribute:@"bezel-color" inState:CPThemeStateNormal];
    [self setValue:[[self class] highlightedBezelColor] forThemeAttribute:@"bezel-color" inState:CPThemeStateHighlighted];
}

@end
