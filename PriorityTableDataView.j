@implementation PriorityTableDataView : CPControl
{
}
- (void)setObjectValue:(id)aValue
{
    [super setObjectValue: MAX(MIN(aValue, 1), 0)];
    [self setNeedsDisplay:YES];
}

- (void)drawRect:(CGRect)aRect
{
    // reset the master rect to draw
    aRect = CGRectMake(aRect.origin.x, aRect.origin.y + 3, aRect.size.width * [self floatValue], aRect.size.height - 6);

    var context = [[CPGraphicsContext currentContext] graphicsPort],
        rectToDraw = CGRectMake(0, aRect.origin.y, 5, aRect.size.height),
        transform = CGAffineTransformMakeTranslation(6, 0);

    // while the progress block rect doesn't intesect the edge of the drawing bounds
    while (rectToDraw.origin.x < CGRectGetMaxX(aRect))
    {
        CGContextAddRect(context, rectToDraw);

        // reposition the progress block
        rectToDraw = CGRectApplyAffineTransform(rectToDraw, transform);
    }

    if ([self hasThemeState:CPThemeStateSelected])
        var color = [CPColor whiteColor];
    else
        var color = [CPColor colorWithHexString:@"929496"];

    CGContextSetFillColor(context, color);
    CGContextFillPath(context);
}

@end
