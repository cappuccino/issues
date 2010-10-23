
@import <AppKit/CPView.j>

@implementation RepositoryView : CPView
{
    @outlet CPImageView lockView;
    @outlet CPTextField nameField;
            BadgeView   openIssuesBadge;
            CPColor     backgroundColor;
}

- (void)awakeFromCib
{
    console.log([lockView imageScaling]);
    var path = [[CPBundle mainBundle] pathForResource:"sourceListSelectionBackground.png"],
        image = [[CPImage alloc] initWithContentsOfFile:path size:CGSizeMake(1, 26)];

    backgroundColor = [CPColor colorWithPatternImage:image];

    openIssuesBadge = [[BadgeView alloc] initWithFrame:CGRectMake(0,0,30,19)];
    [self addSubview:openIssuesBadge];

    [nameField setLineBreakMode:CPLineBreakByTruncatingTail];
    [nameField setFont:[CPFont boldSystemFontOfSize:11.0]];
    [nameField setVerticalAlignment:CPCenterVerticalTextAlignment];
    [self unsetThemeState:CPThemeStateSelectedDataView];


    [nameField setValue:[CPColor colorWithCalibratedRed:71/255 green:90/255 blue:102/255 alpha:1]           forThemeAttribute:"text-color"         inState:CPThemeStateTableDataView];
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

    [openIssuesBadge setValue:CGInsetMake(1.0, 10.0, 2.0, 10.0) forThemeAttribute:"content-inset" inState:CPThemeStateBezeled];
}

- (void)setObjectValue:(Object)anObject
{
    [nameField setStringValue:anObject.identifier];
    [lockView setHidden:!anObject["private"]];

    if (anObject.open_issues > 0)
    {
        [openIssuesBadge setStringValue:anObject.open_issues];
        [openIssuesBadge sizeToFit];
        [openIssuesBadge setHidden:NO]
    }
    else
        [openIssuesBadge setHidden:YES];
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

- (void)layoutSubviews
{
    [super layoutSubviews];

    var width = CGRectGetWidth([self frame]),
        tokenWidth = CGRectGetWidth([openIssuesBadge frame]) + 5,
        maxWidth = width - CGRectGetMinX([nameField frame]) - ([openIssuesBadge isHidden] ? 3 : tokenWidth) - ([lockView isHidden] ? 0 : 16);

    [nameField sizeToFit];

    var fitWidth = CGRectGetMaxX([nameField frame]),
        nameFrameSize = CGSizeMake((fitWidth > maxWidth ? maxWidth : fitWidth) - 6, 26),
        lockOrigin = CGPointMake((fitWidth > maxWidth ? maxWidth : fitWidth) + 2, 0);


    [nameField setFrameSize:nameFrameSize];
    [openIssuesBadge setFrameOrigin:CGPointMake(width - tokenWidth, 4)];
    [lockView setFrameOrigin:lockOrigin];        
}

- (id)initWithCoder:(CPCoder)aCoder
{
    self = [super initWithCoder:aCoder];
    lockView = [aCoder decodeObjectForKey:"lockView"];
    nameField = [aCoder decodeObjectForKey:"nameField"];
    openIssuesBadge = [aCoder decodeObjectForKey:"openBadge"];
    backgroundColor = [aCoder decodeObjectForKey:"backgroundColor"];
    return self;
}

- (void)encodeWithCoder:(CPCoder)aCoder
{
    [super encodeWithCoder:aCoder];
    [aCoder encodeObject:lockView forKey:"lockView"];
    [aCoder encodeObject:nameField forKey:"nameField"];
    [aCoder encodeObject:openIssuesBadge forKey:"openBadge"];
    [aCoder encodeObject:backgroundColor forKey:"backgroundColor"];
}

@end

@implementation BadgeView : _CPTokenFieldToken
// we take this from CPTextField because we want to skip the super implementation
- (void)layoutSubviews
{
    var bezelView = [self layoutEphemeralSubviewNamed:@"bezel-view"
                                           positioned:CPWindowBelow
                      relativeToEphemeralSubviewNamed:@"content-view"];

    if (bezelView)
        [bezelView setBackgroundColor:[self currentValueForThemeAttribute:@"bezel-color"]];

    var contentView = [self layoutEphemeralSubviewNamed:@"content-view"
                                             positioned:CPWindowAbove
                        relativeToEphemeralSubviewNamed:@"bezel-view"];

    if (contentView)
    {
        var string = [self stringValue];

        [contentView setText:string];

        [contentView setTextColor:[self currentValueForThemeAttribute:@"text-color"]];
        [contentView setFont:[self currentValueForThemeAttribute:@"font"]];
        [contentView setAlignment:[self currentValueForThemeAttribute:@"alignment"]];
        [contentView setVerticalAlignment:[self currentValueForThemeAttribute:@"vertical-alignment"]];
        [contentView setLineBreakMode:[self currentValueForThemeAttribute:@"line-break-mode"]];
        [contentView setTextShadowColor:[self currentValueForThemeAttribute:@"text-shadow-color"]];
        [contentView setTextShadowOffset:[self currentValueForThemeAttribute:@"text-shadow-offset"]];
    }
}
@end