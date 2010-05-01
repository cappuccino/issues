
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
}

+ (id)sharedLoginWindow
{
    return SharedLoginWindow;
}

- (void)awakeFromCib
{
    SharedLoginWindow = self;
    [super awakeFromCib];
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
            [self orderOut:self];
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

@end
