@import <AppKit/CPView.j>

@implementation PriorityTableDataView : CPView
{
    float value;
}

- (void)setObjectValue:(id)aValue
{
    value = MAX(MIN(aValue, 1), 0);
    [self setNeedsDisplay:YES];
}

- (void)drawRect:(CGRect)aRect
{
    var bounds = [self bounds],
        maxWidth = (bounds.size.width - 2) * value,
        context = [[CPGraphicsContext currentContext] graphicsPort],
        rectToDraw = CGRectMake(2, 2, 5, bounds.size.height - 4),
        transform = CGAffineTransformMakeTranslation(6, 0);

    CGContextBeginPath(context);
    while (rectToDraw.origin.x < maxWidth)
    {
        if (CGRectGetMaxX(rectToDraw) > maxWidth)
            rectToDraw.size.width -= (CGRectGetMaxX(rectToDraw) - maxWidth);

        CGContextAddRect(context, rectToDraw);
        rectToDraw = CGRectApplyAffineTransform(rectToDraw, transform);
    }

    var color = [CPColor whiteColor];
    if (![self hasThemeState:CPThemeStateSelectedDataView])
        color = [CPColor colorWithRed:176/255 green:178/255 blue:180/255 alpha:1.0];

    CGContextSetFillColor(context, color);
    CGContextFillPath(context);
}

@end
