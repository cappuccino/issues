//This is class which displays a specific issue in detail

@import <Foundation/CPObject.j>

@implementation IssueView : CPView
{
    id activeIssue;
    CPView toolbar;

    CPPopUpButton actionsButton;

    CPScrollView scrollView;
    CPView       containerView;

    CPTextField title;
    CPTextField modified; 
    CPTextField body;
    CPTextField creationDate;
    CPTextField closedDate;
    CPTextField user;
    CPTextField votes;
    CPTextField updatedDate;
    CPTextField number;
    CPTextField status;
    
    CPArray comments;
}

- (id)initWithFrame:(CGRect)aFrame
{
    self = [super initWithFrame:aFrame];

    if (self)
    {
        var width = aFrame.size.width;

        toolbar = [[CPView alloc] initWithFrame:CGRectMake(0, 0, width, 32)];
        var headerImage = [[CPImage alloc] initWithContentsOfFile:@"Resources/HeaderBackground.png" size:CGSizeMake(14, 32)];
        [toolbar setBackgroundColor:[CPColor colorWithPatternImage:headerImage]];
        [toolbar setAutoresizingMask:CPViewWidthSizable];

        actionsButton = [[CPPopUpButton alloc] initWithFrame:CGRectMake(width - 140, 3, 125, 24) pullsDown:NO];
        [actionsButton setAutoresizingMask:CPViewMinXMargin];
        [actionsButton addItemWithTitle:@"Actions"];
        [actionsButton addItemWithTitle:@"Close"];
        [actionsButton addItemWithTitle:@"Open"];
        [toolbar addSubview:actionsButton];

        //content area
        var toolbarHeight = CGRectGetMaxY([toolbar frame]),
        scrollView = [[CPScrollView alloc] initWithFrame:CGRectMake(0, toolbarHeight, CGRectGetWidth([self bounds]), CGRectGetHeight([self bounds]) - toolbarHeight)];
        containerView = [[CPView alloc] initWithFrame:[scrollView bounds]];
        [scrollView setDocumentView:containerView];
        [scrollView setAutohidesScrollers:YES];
        [scrollView setAutoresizingMask:CPViewWidthSizable|CPViewHeightSizable];
        //[containerView setAutoresizingMask:CPViewWidthSizable|CPViewHeightSizable];

        title = [[CPTextField alloc] initWithFrame:CGRectMake(10, 5, width, 30)];
        [title setFont:[CPFont boldSystemFontOfSize:20]];
        [title setLineBreakMode:CPLineBreakByWordWrapping];
        

        creationDate = [[CPTextField alloc] initWithFrame:CGRectMake(10, CGRectGetMaxY([title frame]) + 10, width, 20)];
        user         = [[CPTextField alloc] initWithFrame:CGRectMake(CGRectGetMaxX([creationDate frame]) + 10, CGRectGetMaxY([title frame]) + 10, width, 20)];
        modified     = [[CPTextField alloc] initWithFrame:CGRectMake(10, CGRectGetMaxY([creationDate frame]) + 10, width, 20)];

        body = [[CPTextField alloc] initWithFrame:CGRectMake(10, CGRectGetMaxY([modified frame]) + 10, width, 30)];
        [body setLineBreakMode:CPLineBreakByWordWrapping];
        

        [user setFont:[CPFont boldSystemFontOfSize:12]];

        
        
        [self addSubview:toolbar];
        [containerView addSubview:creationDate];
        [containerView addSubview:title];
        [containerView addSubview:modified];
        [containerView addSubview:user];
        [containerView addSubview:body];
        [self addSubview:scrollView];

        //[title setStringValue:@"This is an EPIC title!"];
        //[creationDate setStringValue:@"12-31-1990"];

        [self sizeAllToFitAndLayout];   
    }

    return self;  
}

- (CGRect)nextFrameWithCurrentY:(double)aPosition height:(double)aHeight width:(double)aWidth
{   
    var newFrame = CGRectMake(10, aPosition, aWidth, aHeight);
    
    aPosition += aHeight + 10;

    return newFrame;
} 

- (void)setIssue:(id)anIssue
{
    // right now we're just passing a json object
    // after setting all the values and sizing shit to fit we resize the view itself
    // as to adjust the scrollview.
    activeIssue = anIssue;

    [title setStringValue: [anIssue valueForKey:@"title"]];
    [creationDate setStringValue:@"Created on: " + [CPDate simpleDate:[anIssue valueForKey:@"created_at"]]];
    [user setStringValue: "by " + [anIssue valueForKey:@"user"]];
    [modified setStringValue:@"Modified on: " + [CPDate simpleDate:[anIssue valueForKey:@"updated_at"]]];
    [body setStringValue: [anIssue valueForKey:@"body"]];

    [self sizeAllToFitAndLayout];
}

- (void)setComments:(CPArray)theComments
{
    var startY = CGRectGetMaxY([body frame]);
    for (var i = 0; i < [theComments count]; i++)
    {
        var comment = [theComments objectAtIndex:i],
            username = [comment valueForKey:@"user"],
            updated = [comment valueForKey:@"updated_at"],
            created = [comment valueForKey:@"created_at"],
            commentId = [comment valueForKey:@"id"],
            bodyText = [comment valueForKey:@"body"];

        //create the views
        var userField = [[CPTextField alloc] initWithFrame:CGRectMake(10, startY + 10, CGRectGetWidth([body bounds]), 25)];
        [userField setFont:[CPFont boldSystemFontOfSize:12]];
        [containerView addSubview:userField];
        [userField setStringValue: username];
        [userField sizeToFit];

        var bodyField = [[CPTextField alloc] initWithFrame:CGRectMake(10, CGRectGetMaxY([userField frame]) + 10, CGRectGetWidth([body bounds]), 25)];
        [bodyField setFont:[CPFont systemFontOfSize:12]];
        [containerView addSubview:bodyField];
        [bodyField setStringValue:bodyText];
        [bodyField sizeToFit];

        startY = CGRectGetMaxY([bodyField frame]);
    }

    var width = MAX(MAX(CGRectGetMaxX([title frame]), CGRectGetMaxX([body frame])), CGRectGetMaxX([user frame]));
    [containerView setFrameSize:CGSizeMake(width + 10, startY + 10)];
}
- (void)sizeAllToFitAndLayout
{
    [title sizeToFit];
    [creationDate sizeToFit];
    [modified sizeToFit];
    [user sizeToFit];
    [body sizeToFit];

    [title setFrameOrigin:CGPointMake(10, 5)];
    [creationDate setFrameOrigin:CGPointMake(10, CGRectGetMaxY([title frame]))];
    [user setFrameOrigin:CGPointMake(CGRectGetMaxX([creationDate frame]) + 2, CGRectGetMaxY([title frame]))];
    [modified setFrameOrigin:CGPointMake(10, CGRectGetMaxY([creationDate frame]))];
    [body setFrameOrigin:CGPointMake(10, CGRectGetMaxY([modified frame]) + 10)];

    // FIX ME: There has to be a better way to do this...
    var width = MAX(MAX(CGRectGetMaxX([title frame]), CGRectGetMaxX([body frame])), CGRectGetMaxX([user frame]));
    [containerView setFrameSize:CGSizeMake(width + 10, CGRectGetMaxY([body frame]) + 10)];
}


@end
