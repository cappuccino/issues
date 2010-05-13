
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

    [contentView setBackgroundColor:[CPColor colorWithWhite:240/255 alpha:1.0]];

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
    OPEN_LINK("http://am")
}

- (@action)openGithub:(id)sender
{
    
}

- (@action)open280north:(id)sender
{
    
}

- (@action)openRandy:(id)sender
{
    
}

- (@action)openHeroku:(id)sender
{
    
}

- (@action)openNode:(id)sender
{
    
}

- (@action)openMustache:(id)sender
{
    
}

- (@action)openMarkdown:(id)sender
{
    
}

- (@action)openCappuccino:(id)sender
{
    
}

- (@action)openLuddep:(id)sender
{
    
}

- (@action)openAtlas:(id)sender
{
    
}

@end

var OPEN_LINK = function(link)
{
    if ([CPPlatform isBrowser])
        window.open(link);
    else
        window.location = link;
}
