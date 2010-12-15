/*
    Copyright 2010 RCLConcepts
    Randall Luecke

    A TableHeaderView subclass for cappuccino that lets you show and hide columns by right clicking the header.
*/

@implementation RLTableHeaderView : CPTableHeaderView
- (CPMenu)menuForEvent:(CPEvent)anEvent
{
    var contextMenu = [[CPMenu alloc] initWithTitle:@""],
        columns = [[self tableView] tableColumns];

    for (var i = 0; i < [columns count]; i++)
    {
        var columnIsHidden = [columns[i] isHidden],
            title = [[columns[i] headerView] stringValue],
            newMenuItem = [[CPMenuItem alloc] initWithTitle:title action:@selector(toggleColumnVisibility:) keyEquivalent:nil],
            stateToUse = (columnIsHidden) ? CPOffState : CPOnState;

        [newMenuItem setState:stateToUse];
        [newMenuItem setTarget:self];
        [newMenuItem setRepresentedObject:columns[i]];

        [contextMenu addItem:newMenuItem];
    }

    var descriptor = [CPSortDescriptor sortDescriptorWithKey:"title" ascending:YES];

    [[contextMenu itemArray] sortUsingDescriptors:[descriptor]];

    return contextMenu;
}

- (void)toggleColumnVisibility:(id)sender
{
    var col = [sender representedObject];
    [col setHidden:![col isHidden]];
}

@end
