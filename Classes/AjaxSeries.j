@implementation AjaxSeries : CPObject
{
    CPArray connections;
    id      delegate;
}

- (id)initWithDelegate:(id)aDelegate
{
    self = [super init];
    if (self)
    {
        connections = [CPArray array];
        delegate = aDelegate;
    }

    return self;
}

- (void)addRequest:(CPURLRequest)aRequest
{
    var connection = [[CPJSONPConnection alloc] initWithRequest:aRequest callback:@"callback" delegate:self startImmediately:YES];

    [connections addObject:connection];
}

/*
    connection delegates
*/
-(void)connection:(CPURLConnection)connection didFailWithError:(id)error
{
    [delegate connection:connection didFailWithError:error];
    [connections removeObject:connection];
}

-(void)connection:(CPURLConnection)connection didReceiveData:(CPString)data
{
    [delegate connection:connection didReceiveData:data];
    [connections removeObject:connection];
}

@end