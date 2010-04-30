
@import <AppKit/CPView.j>

@implementation RepositoryView : CPView
{
    @outlet CPImageView lockView;
    @outlet CPTextField nameField;
}

- (void)awakeFromCib
{
    [nameField setLineBreakMode:CPLineBreakByTruncatingTail];
    [nameField setFont:[CPFont systemFontOfSize:13.0]];
	[nameField setVerticalAlignment:CPCenterVerticalTextAlignment];
	[self unsetThemeState:CPThemeStateSelected];
}

- (void)setObjectValue:(Object)anObject
{
    [nameField setStringValue:anObject.identifier];
    [lockView setHidden:!anObject["private"]];
}

- (void)setThemeState:(CPThemeState)aState
{
    [super setThemeState:aState];
    if (aState === CPThemeStateSelected)
	{
        [nameField setTextColor:[CPColor whiteColor]];
		[nameField setTextShadowColor:[CPColor blackColor]];
		[nameField setTextShadowOffset:CGSizeMake(0.0, -1.0)];
	}
}

- (void)unsetThemeState:(CPThemeState)aState
{
    [super unsetThemeState:aState];
    if (aState === CPThemeStateSelected)
	{
        [nameField setTextColor:[CPColor blackColor]];
		[nameField setTextShadowColor:[CPColor whiteColor]];
		[nameField setTextShadowOffset:CGSizeMake(0.0, 1.0)];
	}
}

- (id)initWithCoder:(CPCoder)aCoder
{
    self = [super initWithCoder:aCoder];
    lockView = [aCoder decodeObjectForKey:"lockView"];
    nameField = [aCoder decodeObjectForKey:"nameField"];
    return self;
}

- (void)encodeWithCoder:(CPCoder)aCoder
{
    [super encodeWithCoder:aCoder];
    [aCoder encodeObject:lockView forKey:"lockView"];
    [aCoder encodeObject:nameField forKey:"nameField"];
}

@end
