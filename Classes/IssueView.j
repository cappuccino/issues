/*
 * AppController.j
 * GitIssues
 *
 * Created by Randall Luecke on February 20, 2010.
 * Copyright 2010, Randall Luecke All rights reserved.
 */
//This is class which displays a specific issue in detail

@import <Foundation/CPObject.j>

@implementation IssueView : CPView
{
    id issueController;
    id activeIssue;
    CPView toolbar;

    CPPopUpButton actionsButton;

    CPScrollView scrollView;
    CPView       containerView;
    
    CPArray comments;

    CPString    issueHTML;
}

- (id)initWithFrame:(CGRect)aFrame controller:(id)aController
{
    self = [super initWithFrame:aFrame];

    if (self)
    {
        issueController = aController;
        var width = aFrame.size.width;

        toolbar = [[CPView alloc] initWithFrame:CGRectMake(0, 0, width, 32)];
        var headerImage = [[CPImage alloc] initWithContentsOfFile:@"Resources/HeaderBackground.png" size:CGSizeMake(14, 32)];
        [toolbar setBackgroundColor:[CPColor colorWithPatternImage:headerImage]];
        [toolbar setAutoresizingMask:CPViewWidthSizable];

        actionsButton = [[CPPopUpButton alloc] initWithFrame:CGRectMake(width - 140, 3, 125, 24) pullsDown:NO];
        [actionsButton setAutoresizingMask:CPViewMinXMargin];
        [actionsButton addItemWithTitle:@"Open"];
        [actionsButton addItemWithTitle:@"Close"];
        [actionsButton setTarget:self];
        [actionsButton setAction:@selector(doAction:)];
        [toolbar addSubview:actionsButton];

        var commentButton = [[CPButton alloc] initWithFrame:CGRectMake(10, 3, 100, 24)];
        [commentButton setTitle:@"Comment"];
        [commentButton setTarget:issueController];
        [commentButton setAction:@selector(promptUserForComment:)];
        [toolbar addSubview:commentButton];

        //content area
        var toolbarHeight = 0;//CGRectGetMaxY([toolbar frame]);
        containerView = [[CPWebView alloc] initWithFrame:CGRectMake(0, toolbarHeight, CGRectGetWidth([self bounds]), CGRectGetHeight([self bounds]) - toolbarHeight)];

        [containerView setAutoresizingMask:CPViewWidthSizable|CPViewHeightSizable];
        //[self addSubview:toolbar];
        [self addSubview:containerView]; 
    }

    return self;  
}

- (void)setIssue:(id)anIssue
{
    activeIssue = anIssue;

    if(!activeIssue)
        [containerView loadHTMLString:@""];
    // parse the html, but don't do anything with it.

    if([anIssue valueForKey:@"state"] === "open")
        [actionsButton selectItemWithTitle:@"Open"];
    else
        [actionsButton selectItemWithTitle:@"Close"];

    [self parseIssueIntoHTML:anIssue];
}

- (void)setComments:(CPArray)theComments
{
    // parse the comments then assign the parsed html to the webview. 
    [containerView loadHTMLString:[self parseCommentsIntoHTML:theComments]];
}

- (CPString)parseIssueIntoHTML:(id)anIssue
{
    var title = [anIssue valueForKey:@"title"],
        creationDate = @"Created on: " + [CPDate simpleDate:[anIssue valueForKey:@"created_at"]],
        user = "by " + [anIssue valueForKey:@"user"],
        modified = @"Modified on: " + [CPDate simpleDate:[anIssue valueForKey:@"updated_at"]],
        body = [anIssue valueForKey:@"body"];

    var html = "<style>body{font-family:\"Helvetica Neue\", Arial, Helvetica, Geneva, sans-serif}h1{margin:0}.subinfo{font-size:10px;line-height:10px}.issueBody{margin-bottom:20px;font-size:13px}.commentUser{font-weight:700;font-size:12px}.commentBody{font-size:12px;margin-bottom:10px}</style>";
        html += "<h1>" + title + "</h1><br />";
        html += "<span class='subinfo'>" + creationDate + " <strong>" + user + "</strong> <br />";
        html += modified + "</span> <br /><br />";
        html += "<div class='issueBody'>" + body + "</div>";

    issueHTML = html;
    return html;
}

- (CPString)parseCommentsIntoHTML:(CPArray)theComments
{
    var html = "";
    for (var i = 0; i < [theComments count]; i++)
    {
        var comment = [theComments objectAtIndex:i],
            username = [comment valueForKey:@"user"],
            updated = [comment valueForKey:@"updated_at"],
            created = [comment valueForKey:@"created_at"],
            commentId = [comment valueForKey:@"id"],
            bodyText = [comment valueForKey:@"body"];

        html += "<span class='commentUser'>" + username + "</span><br />";
        html += "<div class='commentBody'>" + bodyText + "</div>";
    }
    issueHTML += html;
    return issueHTML;
}

@end
