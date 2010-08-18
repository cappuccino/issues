/*
 * NewTagController.j
 * GitHubIssues
 *
 * Created by Nicholas Small on August 17, 2010.
 * Copyright 2010, 280 North. All rights reserved.
 */

@import <AppKit/CPWindowController.j>


@implementation NewTagController : CPWindowController
{
    CPTextField     nameField;
    CPButton        submitButton;
    
    id              sender;
}

- (void)loadWindow
{
    var theWindow = [[CPWindow alloc] initWithContentRect:CGRectMake(0.0, 0.0, 300.0, 120.0) styleMask:CPTitledWindowMask | CPClosableWindowMask | CPMiniaturizableWindowMask];
    [theWindow setAutoresizingMask:CPViewMinXMargin | CPViewMinYMargin | CPViewMaxXMargin | CPViewMaxYMargin];
    [theWindow setTitle:@"New Tag"];

    var contentView = [theWindow contentView],
        bounds = [contentView bounds];

    var label = [[CPTextField alloc] initWithFrame:CGRectMake(15.0, 15.0, 100.0, 20.0)];
    [label setFont:[CPFont boldSystemFontOfSize:12]];
    [label setTextColor:[CPColor colorWithCalibratedWhite:0.3 alpha:1.0]];
    [label setTextShadowColor:[CPColor whiteColor]];
    [label setTextShadowOffset:CGSizeMake(0.0, 1.0)];
    [label setStringValue:@"Tag Name:"];
    [contentView addSubview:label];

    nameField = [CPTextField textFieldWithStringValue:@"" placeholder:@"" width:CGRectGetWidth(bounds) - 30.0];
    [nameField setAutoresizingMask:CPViewWidthSizable];
    [nameField setFrameOrigin:CGPointMake(CGRectGetMinX([label frame]), CGRectGetMaxY([label frame]) + 2.0)];
    [nameField setDelegate:self];
    [contentView addSubview:nameField];

    submitButton = [[CPButton alloc] initWithFrame:CGRectMake(CGRectGetWidth(bounds) - 90.0, CGRectGetHeight(bounds) - 39.0, 70.0, 24.0)];
    [submitButton setAutoresizingMask:CPViewMinXMargin | CPViewMinYMargin];
    [submitButton setTitle:@"Add"];
    [submitButton setTarget:self];
    [submitButton setAction:@selector(submit:)];
    [contentView addSubview:submitButton];

    [theWindow setDefaultButton:submitButton];
    [self setWindow:theWindow];
}

- (@action)showWindow:(id)aSender
{
    [super showWindow:aSender];
    [self controlTextDidChange:nil];

    sender = aSender;

    [_window center];
    [_window makeFirstResponder:nameField];
}

- (void)controlTextDidChange:(CPNotification)aNotification
{
    [submitButton setEnabled:[[nameField stringValue] length] > 0];
}

- (@action)submit:(id)aSender
{
    [sender setTagForSelectedIssue:[nameField stringValue]];
    [_window performClose:aSender];
}

@end
