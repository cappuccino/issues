/*
 * RLAutoCompleteTextField.j
 *
 * Created by Randall Luecke
 * Copyright 2010, Randall Luecke all rights reserved.
 *
*/


RLFillTextCompletionStyleMask = 1 << 2;
RLMenuCompletionStyleMask     = 1 << 3;

@implementation RLAutoCompleteTextField : CPControl
{
    CPTextField textfield;
    CPMenu      menu;
    CPArray     data @accessors;
    unsigned    completionStyle @accessors;
    CPString    typedValue;
}

- (id)initWithFrame:(CGRect)aRect
{
    self = [super initWithFrame:aRect];

    if (self)
    {
        textfield = [[CPTextField alloc] initWithFrame:CGRectMake(0, 0, aRect.size.width, aRect.size.height)];
        [textfield setBezeled:YES];
        [textfield setEditable:YES];
        [textfield setDelegate:self];
        [self addSubview:textfield];

        menu = [[_RLCustomMenu alloc] initWithTitle:@"autoCompletemenu"];
        [menu setDelegate:self];

        data = [@"abcdefg", @"abcdef", @"abcde", @"abcd", @"abc", @"ab"];
    }

    return self;
}

- (void)controlTextDidChange:(CPNotification)aNote
{
    var search = [textfield objectValue];
    typedValue = search;
    // do the search 
   

    // do the textfill completion
    if (completionStyle & RLFillTextCompletionStyleMask)
    {
        // search for the best thing, fill it and select the filled text
        var anEvent = [CPApp currentEvent];

        // if the event keycode isn't delete or backspace
        if([anEvent keyCode] !== CPDeleteKeyCode && [anEvent keyCode] !== 46)
        {  
            for(var i = 0; i < [data count]; i++)
            {
                var needle = [[data objectAtIndex:i] lowercaseString];

                if([needle hasPrefix:[search lowercaseString]])
                {
                    startIndex = [search length];
                    [textfield setStringValue:needle];
                    [textfield setSelectedRange:CPMakeRange(startIndex, [needle length] -1)];
                }
            }
        }
    }

    if (needle && completionStyle & RLMenuCompletionStyleMask)
    {
        [menu reset];
        // search for the best thing, fill it and select the filled text
        for(var i = 0; i < [data count]; i++)
        {
            var needle = [[data objectAtIndex:i] lowercaseString];

            if([needle hasPrefix:[search lowercaseString]])
                [menu addItem:[[CPMenuItem alloc] initWithTitle:needle action:nil keyEquivalent:nil]];
        }

        if ([menu numberOfItems] > 0)
        {
            [menu setMinimumWidth:CGRectGetWidth([self bounds]) - 10];
            [menu popUpMenuPositioningItem:[menu itemAtIndex:0] 
                            atLocation:CGPointMake(4.0, CGRectGetHeight([self bounds]) + 5) 
                                inView:self 
                                callback:function(aMenu){
                                            var item = [aMenu highlightedItem];
                                            if (item)
                                                [textfield setStringValue:[item title]];
                                        }];
        }
    }
}

- (void)keyDown:(CPEvent)anEvent
{
    console.log("down");
}

- (void)menuDidHoverOverItem:(CPMenuItem)anItem
{
    if (!anItem)
        return;

    [textfield setStringValue:[anItem title]];
    startIndex = [typedValue length];
    [textfield setSelectedRange:CPMakeRange(startIndex, [[anItem title] length] -1)];
}


@end

@implementation _RLCustomMenu : CPMenu
{}
- (void)_highlightItemAtIndex:(int)anIndex
{
    [super _highlightItemAtIndex:anIndex];

    [_delegate menuDidHoverOverItem:_items[anIndex]];
}

- (void)reset
{
    while ([self numberOfItems])
        [self removeItemAtIndex:0];

}
@end