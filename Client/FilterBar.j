
@import <AppKit/CPView.j>

IssuesFilterAll = 0;
IssuesFilterTitle = 1;
IssuesFilterBody = 2;
IssuesFilterLabels = 3;
IssuesFilterCreator = 4;

@implementation FilterBar : CPView
{
    id delegate @accessors;
    CPRadioGroup radioGroup;
}

- (id)initWithFrame:(CGRect)aFrame
{
    if (self = [super initWithFrame:aFrame])
    {
        var bundle = [CPBundle mainBundle],
            headerImage = [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:"filterBarBackground.png"] size:CGSizeMake(1, 32)],
            leftCapImage = [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"MediaFilterLeftCap.png"] size:CGSizeMake(9, 19)],
            rightCapImage = [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"MediaFilterRightCap.png"] size:CGSizeMake(9, 19)],
            centerImage = [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"MediaFilterCenter.png"] size:CGSizeMake(1, 19)],
            bezelImage = [[CPThreePartImage alloc] initWithImageSlices:[leftCapImage, centerImage, rightCapImage] isVertical:NO],
            radioImageReplace = [[CPImage alloc] init];

        [self setBackgroundColor:[CPColor colorWithPatternImage:headerImage]];

        var allRadio = [CPRadio radioWithTitle:@"All"],
            titleRadio = [CPRadio radioWithTitle:@"Title"],
            bodyRadio = [CPRadio radioWithTitle:@"Body"],
            labelsRadio = [CPRadio radioWithTitle:@"Labels"],
            creatorRadio = [CPRadio radioWithTitle:@"Creator"],
            radioButtons = [allRadio, titleRadio, bodyRadio, creatorRadio, labelsRadio];

        for (var i=0, count = radioButtons.length; i < count; i++)
        {
            var thisRadio = radioButtons[i];

            [thisRadio setAlignment:CPCenterTextAlignment];
            [thisRadio setValue:radioImageReplace forThemeAttribute:@"image"];
            [thisRadio setValue:1 forThemeAttribute:@"image-offset"];

            [thisRadio setValue:[CPColor colorWithPatternImage:bezelImage] forThemeAttribute:@"bezel-color" inState:CPThemeStateSelected]
            [thisRadio setValue:CGInsetMake(0.0, 10.0, 0.0, 10.0) forThemeAttribute:@"content-inset"];
            [thisRadio setValue:CGSizeMake(0.0, 19.0) forThemeAttribute:@"min-size"];

            [thisRadio setValue:CGSizeMake(0.0, 1.0) forThemeAttribute:@"text-shadow-offset" inState:CPThemeStateBordered];
            [thisRadio setValue:[CPColor colorWithCalibratedWhite:79.0 / 255.0 alpha:1.0] forThemeAttribute:@"text-color"];
            [thisRadio setValue:[CPColor colorWithCalibratedWhite:240.0 / 255.0 alpha:1.0] forThemeAttribute:@"text-shadow-color"];
            [thisRadio setValue:[CPColor colorWithCalibratedWhite:1.0 alpha:1.0] forThemeAttribute:@"text-color" inState:CPThemeStateSelected];
            [thisRadio setValue:[CPColor colorWithCalibratedWhite:79 / 255.0 alpha:1.0] forThemeAttribute:@"text-shadow-color" inState:CPThemeStateSelected];

            [thisRadio sizeToFit];

            [thisRadio setTarget:self];
            [thisRadio setAction:@selector(filterBy:)];

            [self addSubview:thisRadio];
        }

        radioGroup = [allRadio radioGroup];
        [titleRadio setRadioGroup:radioGroup];
        [bodyRadio setRadioGroup:radioGroup];
        [labelsRadio setRadioGroup:radioGroup];
        [creatorRadio setRadioGroup:radioGroup];

        [allRadio setTag:IssuesFilterAll];
        [titleRadio setTag:IssuesFilterTitle];
        [bodyRadio setTag:IssuesFilterBody];
        [creatorRadio setTag:IssuesFilterCreator];
        [labelsRadio setTag:IssuesFilterLabels];

        [allRadio setFrameOrigin:CGPointMake(8, 6)];
        [titleRadio setFrameOrigin:CGPointMake(CGRectGetMaxX([allRadio frame]) + 8, CGRectGetMinY([allRadio frame]))];
        [bodyRadio setFrameOrigin:CGPointMake(CGRectGetMaxX([titleRadio frame]) + 8, CGRectGetMinY([titleRadio frame]))];
        [creatorRadio setFrameOrigin:CGPointMake(CGRectGetMaxX([bodyRadio frame]) + 8, CGRectGetMinY([bodyRadio frame]))];
        [labelsRadio setFrameOrigin:CGPointMake(CGRectGetMaxX([creatorRadio frame]) + 8, CGRectGetMinY([creatorRadio frame]))];

        [allRadio setState:CPOnState];
    }

    return self;
}

- (unsigned)selectedFilter
{
    return [[radioGroup selectedRadio] tag];
}

- (void)filterBy:(id)sender
{
    [delegate filterBarSelectionDidChange:self];
}

@end

@implementation CPThreePartImage (foo)
- (unsigned)loadStatus
{
    return CPLoa
}
@end