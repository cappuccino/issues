
@implementation RepositoryView : CPView
{
    CPTextField nameField;
    CPTextField openIssueCount;
    CPImageView lockImageView;

    id  repository;
}

- (id)setObjectValue:(id)aValue
{
    if (!nameField)
    {
        var bounds = [self bounds],
            width = bounds.size.width;

        nameField = [[CPTextField alloc] initWithFrame:CGRectMake(22, 4, width - 36, 20)];

        [nameField setAutoresizingMask:CPViewWidthSizable];
        [nameField setFont:[CPFont boldSystemFontOfSize:13.0]];
        [nameField setLineBreakMode:CPLineBreakByTruncatingTail];

        [self addSubview:nameField];
        
        lockImageView = [[CPImageView alloc] initWithFrame:CGRectMake(3, 5, 16, 16)];
        
        var path = [[CPBundle mainBundle] pathForResource:"private.png"];
        [lockImageView setImage:[[CPImage alloc] initWithContentsOfFile:path size:CGSizeMake(16, 16)]];

        [self addSubview:lockImageView];
    }

    repository = aValue;

    [nameField setStringValue:[repository objectForKey:"owner"]+"/"+[repository objectForKey:"name"]];
    [lockImageView setHidden:[repository objectForKey:"private"]];
}

- (void)setThemeState:(CPThemeState)aState
{
    [super setThemeState:aState];
    if (aState === CPThemeStateSelected)
        [nameField setTextColor:[CPColor whiteColor]];
}


- (void)unsetThemeState:(CPThemeState)aState
{
    [super unsetThemeState:aState];
    if (aState === CPThemeStateSelected)
        [nameField setTextColor:[CPColor blackColor]];
}

@end
