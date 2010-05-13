@implementation CPDate (parts)
- (CPString)monthByName
{
        //returns the month by it's actual name
        var month = self.getMonth();
        switch(month){
                case 0: month = @"January";
                        break;

                case 1: month = @"February";
                        break;

                case 2: month = @"March";
                        break;

                case 3: month = @"April";
                        break;

                case 4: month = @"May";
                        break;

                case 5: month = @"June";
                        break;

                case 6: month = @"July";
                        break;

                case 7: month = @"August";
                        break;

                case 8: month = @"September";
                        break;

                case 9: month = @"October";
                        break;

                case 10:month = @"November";
                        break;

                case 11:month = @"December";
                        break;
        }
        return month;
}

+ (CPString)simpleDate:(CPString)aDate
{
    if(!aDate)
        return;

    aDate = [aDate stringByReplacingOccurrencesOfString:@"/" withString:@"-"];
    aDate = [[CPDate alloc] initWithString:aDate];

    return [aDate simpleDate];
}

- (CPString)simpleDate
{
    return self.getDate() + " " + [self monthByName] + ", " + self.getFullYear();
}

@end
