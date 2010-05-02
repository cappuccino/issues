
@import <AppKit/CPView.j>

@implementation DetailScreen : CPView
{
	CPView backgroundView;
}

- (void)awakeFromCib
{
	var imagePath = [[CPBundle mainBundle] pathForResource:"detailScreenBackground.png"],
		backgroundImage = [[CPImage alloc] initWithContentsOfFile:imagePath size:CGSizeMake(1, 150)];

	backgroundView = [[CPView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth([self bounds]), 150)];
	[backgroundView setBackgroundColor:[CPColor colorWithPatternImage:backgroundImage]];
	[backgroundView setAutoresizingMask:CPViewWidthSizable];
	[self addSubview:backgroundView];

	[self setBackgroundColor:[CPColor colorWithRed:211/255 green:218/255 blue:223/255 alpha:1.0]];
}

@end

@implementation NoIssuesView : DetailScreen
{	
}

@end

@implementation NoReposView : DetailScreen
{
}

@end

@implementation NoSelectedRepoView : DetailScreen
{
}

@end

@implementation LoadingIssuesView : DetailScreen
{
}

@end

@implementation LoadFromURLView : DetailScreen
{    
}

@end
