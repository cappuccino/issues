
@import <Foundation/CPObject.j>

@implementation Repository : CPObject
{
    CPString identifier @accessors;
    CPString description @accessors;
    CPString name @accessors;
    CPString URL @accessors;
    CPString owner @accessors;
    CPString homepage @accessors;
    BOOL     hasWiki @accessors;
    BOOL     hasIssues @accessors;
    BOOL     hasDownloads @accessors;
    BOOL     isFork @accessors;
    BOOL     isPrivate @accessors;
    unsigned forks @accessors;
    unsigned watched @accessors;

    CPArray  openIssues @accessors;
    CPArray  closedIssues @accessors;
    CPArray  filteredIssues @accessors;
    CPArray  labels @accessors;
}

+ (id)repositoryWithObject:(JSObject)anObject
{
    var repo = [[self alloc] init];

    [repo setDescription:anObject.description];
    [repo setName:anObject.name];
    [repo setURL:anObject.URL];
    [repo setOwner:anObject.owner];
    [repo setHomepage:anObject.homepage];
    [repo setHasWiki:anObject.has_wiki];
    [repo setHasIssues:anObject.has_issues];
    [repo setHasDownloads:anObject.has_downloads];
    [repo setIsFork:anObject.fork];
    [repo setIsPrivate:anObject["private"]];
    [repo setForks:anObject.forks];
    [repo setWatched:anObject.watched];
    [repo setIdentifier:[self owner]+"/"+[self name]];

    labels = [];
    [[GithubAPIController sharedController] loadLabelsForRepository:self];

    return repo;
}

- (CPArray)openIssues
{
    return openIssues || [];
}

- (CPArray)closedIssues
{
    return closedIssues || [];
}

- (CPArray)filteredIssues
{
    return filteredIssues || [self openIssues];
}

@end
