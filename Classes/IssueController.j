@implementation IssueController : CPObject
{
    @outlet IssueView theIssueView;
}

- (@action)addComment:(id)sender
{
    alert("add a comment");
}

- (@action)closeIssue:(id)sender
{
    alert("close the issue");
}

- (@action)editIssue:(id)sender
{
    alert("edit the issue");
}

@end