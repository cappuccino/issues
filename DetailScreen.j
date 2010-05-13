
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
    @outlet CPView                  containerView;
    @outlet RepositoriesController  repositoriesController;
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

    [[GithubAPIController sharedController] loadRepositoryWithIdentifier:aString callback:function(repo)
    {
        if (repo)
            [repositoriesController addRepository:repo];
        else
            [repoNotFoundIndicator setHidden:NO];

        [self setHitTests:YES];
        [containerView setAlphaValue:1.0];
    }];
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
