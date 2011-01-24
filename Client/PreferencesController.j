var sharedController;

@implementation PreferencesController : CPWindowController
{
    @outlet CPTextField infoText;

    @outlet CPCheckBox  enableCheckbox;

    @outlet CPTextField urlLabel;
    @outlet CPTextField userLabel;
    @outlet CPTextField tokenLabel;

    @outlet CPTextField urlField;
    @outlet CPTextField userField;
    @outlet CPTextField tokenField;

    @outlet CPButton    helpButton;
}

+ (PreferencesController)sharedController
{
    if (!sharedController)
        sharedController = [[PreferencesController alloc] initWithWindowCibName:@"PreferencesWindow"];

    return sharedController;
}

- (void)awakeFromCib
{
    [helpButton setImage:[[CPImage alloc] initWithContentsOfFile:[[CPBundle mainBundle] pathForResource:"alert-help.png"] size:CGSizeMake(24,24)]];
    [helpButton setAlternateImage:[[CPImage alloc] initWithContentsOfFile:[[CPBundle mainBundle] pathForResource:"alert-help-pressed.png"] size:CGSizeMake(24,24)]];
    [helpButton setBordered:NO];

    var disabledColor = [CPColor colorWithWhite:0 alpha:.5];

    [urlLabel   setValue:disabledColor forThemeAttribute:"text-color" inState:CPThemeStateDisabled];
    [userLabel  setValue:disabledColor forThemeAttribute:"text-color" inState:CPThemeStateDisabled];
    [tokenLabel setValue:disabledColor forThemeAttribute:"text-color" inState:CPThemeStateDisabled];

    [urlLabel   setAlignment:CPRightTextAlignment];
    [userLabel  setAlignment:CPRightTextAlignment];
    [tokenLabel setAlignment:CPRightTextAlignment];

    [infoText setLineBreakMode:CPLineBreakByWordWrapping];
    [[self window] setShowsResizeIndicator:NO];


    // pull values from local storage if they exist.
    var enabled  = localStorage["github.fiEnabled"] == "yes" ? YES : NO,
        url      = localStorage["github.fiURL"],
        username = localStorage["github.fiUser"],
        token    = localStorage["github.fiToken"];

    [enableCheckbox setObjectValue:enabled];

    [urlField   setStringValue:url];
    [userField  setStringValue:username];
    [tokenField setStringValue:token];

    [self togleEnabled:nil];
}

- (@action)togleEnabled:(id)sender
{
    var flag = !![enableCheckbox objectValue];

    var color = flag ? [CPColor blackColor] : [CPColor colorWithWhite:0 alpha:.5];

    [urlLabel   setTextColor:color];
    [userLabel  setTextColor:color];
    [tokenLabel setTextColor:color];
        
    [urlField   setEnabled:flag];
    [userField  setEnabled:flag];
    [tokenField setEnabled:flag];

    flag = flag ? "yes" : "no";

    localStorage.setItem("github.fiEnabled", flag);
}

// for the sake of making life easy, just use a single method.
- (@action)valueDidChange:(id)sender
{
    localStorage.setItem("github.fiURL", [urlField stringValue]);
    localStorage.setItem("github.fiUser", [userField stringValue]);
    localStorage.setItem("github.fiToken", [tokenField stringValue]);

    var api = [GithubAPIController sharedController];
    [api setUsername:[userField stringValue]];
    [api setAuthenticationToken:[tokenField stringValue]];
    BASE_URL = [urlField stringValue];
    BASE_API = BASE_URL + "api/v2/json/";

    if ([userField stringValue] && [tokenField stringValue])
        [api authenticateWithCallback:nil];
}

- (@action)help:(id)sender
{
    // forward to the other login window thingy
    [[LoginWindow sharedLoginWindow] openAPIKeyPage:sender];
}

@end