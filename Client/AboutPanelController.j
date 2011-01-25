
@import <AppKit/CPWindowController.j>

@implementation AboutPanelController : CPWindowController
{
    @outlet CPTextField thanksTextField;
    
    @outlet CPButton githubButton;
    @outlet CPButton randyButton;
    @outlet CPButton northButton;
    @outlet CPButton cappuccinoButton;
    @outlet CPButton herokuButton;
    @outlet CPButton nodeButton;
    @outlet CPButton mustacheButton;
    @outlet CPButton markdownButton;
    @outlet CPButton ludwigButton;
    @outlet CPButton atlasButton;
}

- (void)awakeFromCib
{
    var panel = [self window],
        contentView = [panel contentView];

    [thanksTextField setLineBreakMode:CPLineBreakByWordWrapping];

    var buttons = [githubButton, randyButton, northButton, cappuccinoButton, nodeButton, herokuButton, mustacheButton, markdownButton, ludwigButton, atlasButton],
        bundle = [CPBundle mainBundle],
        arrowImage = [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:"AboutBoxArrow.png"] size:CGSizeMake(16, 16)],
        arrowImageHighlighted = [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:"AboutBoxArrowHighlighted.png"] size:CGSizeMake(16, 16)];

    for (var i = 0, count = buttons.length; i < count; i++)
    {
        var button = buttons[i];
        [button setBordered:NO];
        [button setAlignment:CPLeftTextAlignment];
        [button setFont:[CPFont boldSystemFontOfSize:12.0]];
        [button setImage:arrowImage];
        [button setAlternateImage:arrowImageHighlighted];
        [button setImagePosition:CPImageRight];
    }
}

- (@action)downloadNativeClient:(id)sender
{
    OPEN_LINK("http://cl.ly/44R7");
}

- (@action)downloadSafariExtention:(id)sender
{
    OPEN_LINK("http://github.com/downloads/Me1000/PrettyIssues/PrettyIssues.safariextz.zip");
}

- (@action)downloadChromeExtention:(id)sender
{
    OPEN_LINK("https://chrome.google.com/webstore/detail/mlphmcafjfbcoagfoanfaljdmkcimhmi");
}

- (@action)openGithub:(id)sender
{
    OPEN_LINK("http://github.com");
}

- (@action)open280north:(id)sender
{
    OPEN_LINK("http://280north.com");
}

- (@action)openRandy:(id)sender
{
    OPEN_LINK("http://github.com/me1000");
}

- (@action)openHeroku:(id)sender
{
    OPEN_LINK("http://heroku.com");
}

- (@action)openNode:(id)sender
{
    OPEN_LINK("http://nodejs.org");
}

- (@action)openMustache:(id)sender
{
    OPEN_LINK("http://github.com/boucher/mustache.js");
}

- (@action)openMarkdown:(id)sender
{
    OPEN_LINK("http://github.github.com/github-flavored-markdown/scripts/showdown.js")
}

- (@action)openCappuccino:(id)sender
{
    OPEN_LINK("http://cappuccino.org");
}

- (@action)openLuddep:(id)sender
{
    OPEN_LINK("http://github.com/luddep");
}

- (@action)openAtlas:(id)sender
{
    OPEN_LINK("http://280atlas.com");
}

- (@action)openIssuesRepo:(id)sender
{
    OPEN_LINK("http://github.com/280north/issues");
}

@end
