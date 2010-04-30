
@import <AppKit/CPView.j>


@implementation UserView : CPView
{
    @outlet CPImageView imageView;
    @outlet CPTextField usernameField;
    @outlet CPTextField emailField;
}

- (id)initWithFrame:(CGRect)aRect
{
    if (self = [super initWithFrame:aRect])
    {
        
    }
    return self;
}

@end
