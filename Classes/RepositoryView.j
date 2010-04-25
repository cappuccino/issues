
@implementation RepositoryView : CPView
{
    CPTextField nameField;
    CPTextField typeField;
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

        nameField = [[CPTextField alloc] initWithFrame:CGRectMake(22, 3, width - 36, 20)];

        [nameField setAutoresizingMask:CPViewWidthSizable];
        [nameField setFont:[CPFont boldSystemFontOfSize:13.0]];
        [nameField setLineBreakMode:CPLineBreakByTruncatingTail];

        [self addSubview:nameField];

        typeField = [[CPTextField alloc] initWithFrame:CGRectMake(22, 19, 75, 16)];

        [typeField setFont:[CPFont systemFontOfSize:11.0]];
        [typeField setLineBreakMode:CPLineBreakByTruncatingTail];
        [typeField setTextColor:[CPColor grayColor]];

        [self addSubview:typeField];
        
        lockImageView = [[CPImageView alloc] initWithFrame:CGRectMake(3, 9, 16, 16)];
        
        var path = [[CPBundle mainBundle] pathForResource:"private.png"];
        [lockImageView setImage:[[CPImage alloc] initWithContentsOfFile:path size:CGSizeMake(16, 16)]];

        [self addSubview:lockImageView];
    }

    repository = aValue;

    [nameField setStringValue:[repository objectForKey:"owner"]+"/"+[repository objectForKey:"name"]];
    [typeField setStringValue:[repository objectForKey:"repo_type"]];
    [lockImageView setHidden:![repository objectForKey:"private"]];
}

- (void)setThemeState:(CPThemeState)aState
{
    [super setThemeState:aState];
    if (aState === CPThemeStateSelected)
    {
        [nameField setTextColor:[CPColor whiteColor]];
        [typeField setTextColor:[CPColor whiteColor]];
    }
}


- (void)unsetThemeState:(CPThemeState)aState
{
    [super unsetThemeState:aState];
    if (aState === CPThemeStateSelected)
    {
        [nameField setTextColor:[CPColor blackColor]];
        [typeField setTextColor:[CPColor grayColor]];
    }
}

@end
