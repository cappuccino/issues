
@import <AppKit/CPView.j>

@implementation DetailScreen : CPView
{
    CPView backgroundView;
}

- (void)awakeFromCib
{
    var imagePath = [[CPBundle mainBundle] pathForResource:"detailScreenBackground.png"],
        backgroundImage = [[CPImage alloc] initWithContentsOfFile:imagePath size:CGSizeMake(1, 150)];

    backgroundView = [[CPView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth([self bounds]), 150)];
    [backgroundView setBackgroundColor:[CPColor colorWithPatternImage:backgroundImage]];
    [backgroundView setAutoresizingMask:CPViewWidthSizable];
    [self addSubview:backgroundView positioned:CPWindowBelow relativeTo:nil];

    [self setBackgroundColor:[CPColor colorWithRed:211/255 green:218/255 blue:223/255 alpha:1.0]];
}

@end

@implementation NoIssuesView : DetailScreen
{
}

@end

@implementation NoReposView : DetailScreen
{
    @outlet CPImageView             repoNotFoundIndicator;
            CPButton                repoIsProtectedButton;
    @outlet CPView                  containerView;
    @outlet RepositoriesController  repositoriesController;
    @outlet RepoEntryField          repoField;
}

- (void)awakeFromCib
{
    [super awakeFromCib];

    var frame = [repoNotFoundIndicator frame];
    frame.size.width  = 16;
    frame.size.height = 16;
    frame.origin.y = frame.origin.y - 2;
    repoIsProtectedButton = [[CPButton alloc] initWithFrame:frame];
    [repoIsProtectedButton setTarget:self];
    [repoIsProtectedButton setAction:@selector(promptForPrivateRepo:)];
    [repoIsProtectedButton setBordered:NO];
    [repoIsProtectedButton setImage:[[CPImage alloc] initWithContentsOfFile:[[CPBundle mainBundle] pathForResource:"private.png"] size:CGSizeMake(16, 16)]];
    [[repoNotFoundIndicator superview] addSubview:repoIsProtectedButton];
    [repoIsProtectedButton setHidden:YES];
}

- (@action)takeRepoFromButton:(id)aSender
{
    [self loadRepositoryWithIdentifier:[aSender tag]];
}

- (@action)takeRepoFromTextField:(id)aSender
{
    [self loadRepositoryWithIdentifier:[aSender stringValue]];
}

- (void)controlTextDidChange:(CPNotification)aNotification
{
    [repoNotFoundIndicator setHidden:YES];
    [repoIsProtectedButton setHidden:YES];
}

- (void)loadRepositoryWithIdentifier:(CPString)aString
{
    if (!aString)
        return;

    var repository = [[GithubAPIController sharedController] repositoryForIdentifier:aString];

    if (repository)
        return [repositoriesController addRepository:repository];

    [self setHitTests:NO];
    [containerView setAlphaValue:0.8];

    [[GithubAPIController sharedController] loadRepositoryWithIdentifier:aString callback:function(repo, request)
    {
        if (repo)
            [repositoriesController addRepository:repo];
        else if (request.status() === 401)
            [repoIsProtectedButton setHidden:NO];
        else
            [repoNotFoundIndicator setHidden:NO];

        [self setHitTests:YES];
        [containerView setAlphaValue:1.0];
    }];
}

- (void)promptForPrivateRepo:(id)sender
{
    var api = [GithubAPIController sharedController];

    [api setNextAuthCallback:function(){
        [self takeRepoFromTextField:repoField];
    }];

    [[GithubAPIController sharedController] promptForAuthentication:self];
}

@end

@implementation NoSelectedRepoView : DetailScreen
{
}

@end

@implementation LoadingIssuesView : DetailScreen
{
}

@end

@implementation LoadFromURLView : DetailScreen
{    
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
    [self setVerticalAlignment:CPCenterVerticalTextAlignment];

    [self setValue:[[self class] bezelColor] forThemeAttribute:@"bezel-color" inState:CPThemeStateNormal];
    [self setValue:[[self class] highlightedBezelColor] forThemeAttribute:@"bezel-color" inState:CPThemeStateHighlighted];
}

@end

