@implementation RLIndeterminateProgressIndicator : CPView
{
    CPImage progressImage;
    CPTimer timer;
    int     startX;
}

- (id)initWithFrame:(CGRect)aRect
{
    self = [super initWithFrame:aRect];
    progressImage = [[CPImage alloc] initWithContentsOfFile:[[CPBundle mainBundle] pathForResource:"indeterminateprogress.png"] size:CGSizeMake(160,13)];

    timer = [CPTimer scheduledTimerWithTimeInterval:0.05 target:self selector:@selector(setNeedsDisplay:) userInfo:{"view":self, "active":CPNotFound, "parts":progressImage, "spinner":NO} repeats:YES];
    startX = -320;
    return self;
}

- (void)drawRect:(CGRect)aRect
{
    if ([progressImage loadStatus] != CPImageLoadStatusCompleted)
        return;

    var context = [[CPGraphicsContext currentContext] graphicsPort],
        width = CGRectGetWidth(aRect),
        currentX = startX;

    CGContextAddPath(context, CGPathWithRoundedRectangleInRect(CGRectMake(aRect.origin.x + 2, aRect.origin.y + 2, aRect.size.width -4, aRect.size.height -4), 3,3, YES, YES, YES, YES));
    CGContextClip(context);

    while ((currentX += 160) <= width)
        CGContextDrawImage(context, CGRectMake(currentX, 1, 160, 13), progressImage);

    [[CPColor colorWithRed:136/255 green:175/255 blue:195/255 alpha:1] setStroke];
    CGContextSetLineWidth(context, 2);
    CGContextStrokeRoundedRectangleInRect(context, aRect, 3, YES, YES, YES, YES);

    startX = startX + 1 > -160 ? -320 : startX += 1;

}

- (id)initWithCoder:(id)aCoder
{
    self = [super initWithCoder:aCoder];

    progressImage = [[CPImage alloc] initWithContentsOfFile:[[CPBundle mainBundle] pathForResource:"indeterminateprogress.png"] size:CGSizeMake(160,13)];

    timer = [CPTimer scheduledTimerWithTimeInterval:0.05 target:self selector:@selector(setNeedsDisplay:) userInfo:{"view":self, "active":CPNotFound, "parts":progressImage, "spinner":NO} repeats:YES];
    startX = -320;

    return self;
}
@end