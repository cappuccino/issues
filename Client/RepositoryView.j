
@import <AppKit/CPView.j>

@implementation RepositoryView : CPView
{
    @outlet CPImageView lockView;
    @outlet CPTextField nameField;
            CPColor     backgroundColor;
}

- (void)awakeFromCib
{
    var path = [[CPBundle mainBundle] pathForResource:"sourceListSelectionBackground.png"],
        image = [[CPImage alloc] initWithContentsOfFile:path size:CGSizeMake(1, 26)];

    backgroundColor = [CPColor colorWithPatternImage:image];
    [nameField setLineBreakMode:CPLineBreakByTruncatingTail];
    [nameField setFont:[CPFont systemFontOfSize:13.0]];
    [nameField setVerticalAlignment:CPCenterVerticalTextAlignment];
    [self unsetThemeState:CPThemeStateSelectedDataView];


    [nameField setValue:[CPColor colorWithCalibratedWhite:0 alpha:1]           forThemeAttribute:"text-color"         inState:CPThemeStateTableDataView];
    [nameField setValue:[CPColor colorWithCalibratedWhite:1 alpha:1]           forThemeAttribute:"text-shadow-color"  inState:CPThemeStateTableDataView];
    [nameField setValue:CGSizeMake(0,1)                                        forThemeAttribute:"text-shadow-offset" inState:CPThemeStateTableDataView];

    [nameField setValue:[CPColor colorWithCalibratedWhite:1 alpha:1.0]         forThemeAttribute:"text-color"         inState:CPThemeStateTableDataView | CPThemeStateSelectedTableDataView];
    [nameField setValue:[CPColor colorWithCalibratedWhite:0 alpha:0.5]           forThemeAttribute:"text-shadow-color"  inState:CPThemeStateTableDataView | CPThemeStateSelectedTableDataView];
    [nameField setValue:CGSizeMake(0,-1)                                       forThemeAttribute:"text-shadow-offset" inState:CPThemeStateTableDataView | CPThemeStateSelectedTableDataView];

    [nameField setValue:[CPFont boldSystemFontOfSize:12.0]                     forThemeAttribute:"font"               inState:CPThemeStateTableDataView | CPThemeStateGroupRow];
    [nameField setValue:[CPColor colorWithCalibratedWhite:125 / 255 alpha:1.0] forThemeAttribute:"text-color"         inState:CPThemeStateTableDataView | CPThemeStateGroupRow];
    [nameField setValue:[CPColor colorWithCalibratedWhite:1 alpha:1]           forThemeAttribute:"text-shadow-color"  inState:CPThemeStateTableDataView | CPThemeStateGroupRow];
    [nameField setValue:CGSizeMake(0,1)                                        forThemeAttribute:"text-shadow-offset" inState:CPThemeStateTableDataView | CPThemeStateGroupRow];
    [nameField setValue:CGInsetMake(1.0, 0.0, 0.0, 2.0)                        forThemeAttribute:"content-inset"      inState:CPThemeStateTableDataView | CPThemeStateGroupRow];
}

- (void)setObjectValue:(Object)anObject
{
    [nameField setStringValue:anObject.identifier];
    [lockView setHidden:!anObject["private"]];
}

- (void)setThemeState:(CPThemeState)aState
{
    [super setThemeState:aState];
    [nameField setThemeState:aState];

    if (aState === CPThemeStateSelectedDataView)
        [self setBackgroundColor:backgroundColor];
       
}

- (void)unsetThemeState:(CPThemeState)aState
{
    [super unsetThemeState:aState];
    [nameField unsetThemeState:aState];

    if (aState === CPThemeStateSelectedDataView)
        [self setBackgroundColor:nil];
}

- (id)initWithCoder:(CPCoder)aCoder
{
    self = [super initWithCoder:aCoder];
    lockView = [aCoder decodeObjectForKey:"lockView"];
    nameField = [aCoder decodeObjectForKey:"nameField"];
    backgroundColor = [aCoder decodeObjectForKey:"backgroundColor"];
    return self;
}

- (void)encodeWithCoder:(CPCoder)aCoder
{
    [super encodeWithCoder:aCoder];
    [aCoder encodeObject:lockView forKey:"lockView"];
    [aCoder encodeObject:nameField forKey:"nameField"];
    [aCoder encodeObject:backgroundColor forKey:"backgroundColor"];
}

@end
