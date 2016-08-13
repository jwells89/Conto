//
//  CXSummaryController.m
//  Conto
//
//  Created by Nicola on Sat Apr 13 2002.
//  Copyright (c) 2002 by Nicola Vitacolonna. All rights reserved.
//
//  This file is part of Conto.
//
//  Conto is free software; you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation; either version 2 of the License, or
//  (at your option) any later version.
//
//  Conto is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with Conto; if not, write to the Free Software
//  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
//

#import "CXSummaryController.h"
#import "CXPreferencesController.h"
#import "CXDocument.h"

#define Prefs [NSUserDefaults standardUserDefaults]

@implementation CXSummaryController

// Initialization and deallocation
- (id)init {
  self = [super initWithWindowNibName:@"CXSummary"];
  if (self) {
   // [self setWindowFrameAutosaveName:@"Summary Window"];
   // numberFormatter = [[NSNumberFormatter alloc] init];
  }  
  return self;
}

-(void)dealloc {
  [[self window] saveFrameUsingName:@"Summary Window"];
  //[numberFormatter release];
  [super dealloc];
}

- (void)windowDidLoad {
  [super windowDidLoad];

  //[self setWindowFrameAutosaveName:@"Summary Window"];
  [[self window] setFrameUsingName:@"Summary Window"];
  //[[self window] setFrameUsingName:@"Summary Window"];
  [self setShouldCascadeWindows:NO];
  [self setNumberFormat:nil];
  [self setFontSize:nil];
  [self setGrid:nil];

  [[self infoTable] setAutosaveName:@"CXInfoTablePosition"];
  [[self infoTable] setAutosaveTableColumns:YES]; // Remember columns' size and position
  // Register Info table for drag and drop
  [[self infoTable] registerForDraggedTypes:[NSArray arrayWithObjects:@"Conto info",nil]];


  // Register notification observers
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(updateTable:)
                                               name:CXValueInTableChangedNotification
                                             object:[self document]];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(updateAccountInfoTable:)
                                               name:CXInfoTableChangedNotification
                                             object:[self document]];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(setNumberFormat:)
                                               name:CXNumberFormatChangedNotification
                                             object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(setFontSize:)
                                               name:CXFontSizeChangedNotification
                                             object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(setGrid:)
                                               name:CXGridChangedNotification
                                             object:nil];    //  [[self window] makeKeyAndOrderFront:self];
}

/*
- (void)windowDidMove: (NSNotification *)aNotification {
  [[self window] saveFrameUsingName: @"Summary Window"];
}
*/

// Overrides NSWindowController's method to customize title
- (NSString *)windowTitleForDocumentDisplayName:(NSString *)displayName {
  NSString *title = NSLocalizedString(@"Summary Info for ", @"Title of Summary Window");
  return [title stringByAppendingString:displayName];
}

// Accessor methods
- (NSTableView *)summaryTable {
  return summaryTable;
}

- (NSTableView *)infoTable {
  return infoTable;
}

- (NSButton *)addInfoButton {
  return addInfoButton;
}

- (NSButton *)removeInfoButton {
  return removeInfoButton;
}

/*
- (NSNumberFormatter *)numberFormatter {
  return numberFormatter;
}
*/

/*
- (void)setNumberFormatterFromPrefs {
  NSMutableDictionary *newAttrs = [NSMutableDictionary dictionary];
  NSMutableString *formatString = [[NSMutableString alloc] init];
  NSInteger i;
  NSString *decimalSeparator;
  NSString *thousandSeparator;
  CXCurrencyPosition currencyPosition = (CXCurrencyPosition)[Prefs integerForKey:CXCurrencyPositionKey];
  NSString *currencySymbol = [Prefs stringForKey:CXCurrencySymbolKey];
  NSInteger numberOfDecimals = [Prefs integerForKey:CXNumberOfDecimalsKey];
  BOOL hasThousandSeparator = [Prefs boolForKey:CXThousandSeparatorKey];

  switch ((CXSeparator)[Prefs integerForKey:CXDecimalSeparatorKey]) {
    case Comma:
      decimalSeparator = @",";
      thousandSeparator = @".";
      break;
    case Period:
      decimalSeparator = @".";
      thousandSeparator = @",";
      break;
    default:
      decimalSeparator = @",";
      thousandSeparator = @".";
      break;
  }

  [formatString appendString:@"#,##0"];
  if (numberOfDecimals > 0)
    [formatString appendString:@"."];
  // Add decimals to the format string
  for (i=1; i<=numberOfDecimals; i++)
    [formatString appendString:@"0"];
  // Add currency symbol in the position specified in the preferences
  switch (currencyPosition) {
    case Before:
      [formatString insertString:currencySymbol atIndex:0];
      break;
    case	After:
      [formatString appendString:currencySymbol];
      break;
    default:
      [formatString appendString:currencySymbol];
      break;
  }
  //[[self numberFormatter] setFormat:@"#,##0.00 Û;0.00 Û;-#,##0.00 Û"];
  [[self numberFormatter] setFormat:formatString];
  [newAttrs setObject:[NSColor redColor] forKey:@"NSColor"];
  [[self numberFormatter] setTextAttributesForNegativeValues:newAttrs];
  //[[self numberFormatter] setAttributedStringForNotANumber:[[[NSAttributedString alloc] initWithString:@""] autorelease]];
  // Set decimal separator
  [[self numberFormatter] setDecimalSeparator:decimalSeparator];
  // Set thousand separator
  if (hasThousandSeparator)
    [[self numberFormatter] setThousandSeparator:thousandSeparator];
  else // No thousand separators
    [[self numberFormatter] setHasThousandSeparators:NO];
  //[[self numberFormatter] setThousandSeparator:@"."];
  //[[self numberFormatter] setDecimalSeparator:@","];
  [[self numberFormatter] setAttributedStringForNotANumber:[[[NSAttributedString alloc] initWithString:@""] autorelease]];

  [formatString release];
  formatString = nil;
}
*/

// Action methods
- (IBAction)addInfoAction:(id)sender {
  NSMutableDictionary *newRecord = [NSMutableDictionary dictionaryWithCapacity:2]; // Autoreleased
  [newRecord setObject:NSLocalizedString(@"My info", @"Information name") forKey:@"Information name"];
  [newRecord setObject:NSLocalizedString(@"My value",@"Information value") forKey:@"Value"];
  [[self document] insertInfo:newRecord atIndex:[[self infoTable] numberOfRows]];
  [[[self document] undoManager] setActionName:
    NSLocalizedString(@"Add Account Info", @"Name of undo/redo menu item after adding an info")];

  [[self infoTable] selectRow:[[self infoTable] numberOfRows]-1 byExtendingSelection:NO];
  // If I do not select the row, then editColumn:row:withEvent:select: raises an exception
  [[self infoTable] editColumn:[[self infoTable] columnWithIdentifier:@"Information name"]
                           row:([[self infoTable] numberOfRows]-1)
                     withEvent:nil
                        select:YES];  
}

- (IBAction)removeInfoAction:(id)sender {
  NSInteger i;
  
  i = [[self infoTable] numberOfRows];
  while (i-- >= 0) {
    if ([[self infoTable] isRowSelected:i])
      [[self document] removeInfoAtIndex:i];
  }
  [[[self document] undoManager] setActionName:
    NSLocalizedString(@"Remove Account Info(s)", @"Name of undo/redo menu item after removing account info(s)")];
}

- (IBAction)printDocumentView:(id)sender {
  [[self document] printView:[self summaryTable]];
}

//---
- (void)updateTable:(NSNotification *)notification {
  [[self summaryTable] reloadData];
}

- (void)updateAccountInfoTable:(NSNotification *)notification {
  [[self infoTable] reloadData];
}

// Formatting numbers
- (void)setNumberFormat:(NSNotification *)notification {
  NSNumberFormatter *numberFormatter;
  // Detach old formatters (without these instructions it doesn't seem work)
  [[[[self summaryTable] tableColumnWithIdentifier:@"Income"] dataCell] setFormatter:nil];
  [[[[self summaryTable] tableColumnWithIdentifier:@"Expense"] dataCell] setFormatter:nil];
  [[[[self summaryTable] tableColumnWithIdentifier:@"Balance"] dataCell] setFormatter:nil];

  //[self setNumberFormatterFromPrefs];
  numberFormatter = [[CXPreferencesController sharedPreferencesController] numberFormatter];    
  [[[[self summaryTable] tableColumnWithIdentifier:@"Income"] dataCell] setFormatter:numberFormatter];
  [[[[self summaryTable] tableColumnWithIdentifier:@"Expense"] dataCell] setFormatter:numberFormatter];
  [[[[self summaryTable] tableColumnWithIdentifier:@"Balance"] dataCell] setFormatter:numberFormatter];

  [[self summaryTable] reloadData];
}

- (void)setFontSize:(NSNotification *)notification {
  NSTableColumn *column;
  NSEnumerator *enumerator; 
  NSEnumerator *enumerator2;
  NSRect newRect;

  enumerator = [[[self summaryTable] tableColumns] objectEnumerator];
  enumerator2 = [[[self infoTable] tableColumns] objectEnumerator];
  if ((CXFontSize)[Prefs integerForKey:CXFontSizeKey] == Smaller) {
    while (column = [enumerator2 nextObject]) {
      [[column dataCell] setFont:
        [NSFont systemFontOfSize:[NSFont smallSystemFontSize]]];
    }
    [[self infoTable] setRowHeight:13.0];
    while (column = [enumerator nextObject]) {
      [[column dataCell] setFont:
        [NSFont systemFontOfSize:[NSFont smallSystemFontSize]]];
    }
    [[self summaryTable] setRowHeight:13.0];
    [[self window] setMinSize:NSMakeSize(380.0,295.0)];
    [[self window] setMaxSize:NSMakeSize(10000.0,295.0)];
    newRect = [[self window] frame];
    (newRect.size).height = [[self window] minSize].height;
    [[self window] setFrame:newRect display:YES];
  }
  else {
    while (column = [enumerator2 nextObject]) {
      [[column dataCell] setFont:
        [NSFont systemFontOfSize:[NSFont systemFontSize]]];
    }
    [[self infoTable] setRowHeight:17.0];
    while (column = [enumerator nextObject]) {
      [[column dataCell] setFont:
        [NSFont systemFontOfSize:[NSFont systemFontSize]]];
    }
    [[self summaryTable] setRowHeight:17.0];
    [[self window] setMinSize:NSMakeSize(380.0,350.0)];
    [[self window] setMaxSize:NSMakeSize(10000.0,350.0)];
    newRect = [[self window] frame];
    (newRect.size).height = [[self window] minSize].height;
    [[self window] setFrame:newRect display:YES];
  }
}

- (void)setGrid:(NSNotification *)notification {
  [[self summaryTable] setDrawsGrid:[Prefs boolForKey:CXGridKey]];
  [[self infoTable] setDrawsGrid:[Prefs boolForKey:CXGridKey]];
}


// TableView methods
// (this class is the data source of the summary and info TableView)
- (NSInteger)numberOfRowsInTableView:(NSTableView *)theTable {
  if ([theTable isEqual:[self summaryTable]])
    return 13; // One row for each month plus one row for totals
  else // Account info table
    return [[[self document] accountInfo] count];
}

- (id)tableView:(NSTableView *)theTable objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex {
  if ([theTable isEqual:[self summaryTable]]) {
    NSParameterAssert(rowIndex >= 0 && rowIndex < 13);
    if ([[aTableColumn identifier] isEqual:@"Month"])
      return [self intToMonthName:(CXMonth)rowIndex];
    else {
      if (rowIndex <= [[self document] lastMonthWithEntries] || (CXMonth)rowIndex == LastOfYear)
        return [NSDecimalNumber numberWithDouble:[[self document] getSumValueForKey:[aTableColumn identifier] month:rowIndex]];
      else
        return @"";
    }
  }	
  else { // Account Information table
    NSParameterAssert(rowIndex >= 0 && rowIndex < [[[self document] accountInfo] count]);
    return [[[[self document] accountInfo] objectAtIndex:rowIndex] objectForKey:[aTableColumn identifier]];
  }
}

- (void)tableView:(NSTableView *)infoTableView setObjectValue:(id)anObject forTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex {
  NSParameterAssert(rowIndex >= 0 && rowIndex < [[[self document] accountInfo] count]);
  if (![[[[[self document] accountInfo] objectAtIndex:rowIndex] objectForKey:[aTableColumn identifier]] isEqual:anObject]) {
    [[self document] modifyInfoAtRow:rowIndex column:[aTableColumn identifier] newValue:anObject];
    [[[self document] undoManager] setActionName:
      NSLocalizedString(@"Change Info", @"Name of undo/redo menu item after changing info in info table")];
  }
}

// This class is the delegate of the Info TableView, so it is automatically
// registered to receive NSTableViewSelectionDidChangeNotification.
- (void)tableViewSelectionDidChange:(NSNotification *)aNotification {
  [[self removeInfoButton] setEnabled:([[self infoTable] selectedRow] > -1)];
}

// Drag and drop in Info Table
static NSArray *rowsToBeDragged;

- (BOOL)tableView:(NSTableView *)tableView writeRows:(NSArray*)rows toPasteboard:(NSPasteboard*)pboard {
  NSMutableArray *tempArray;
  NSInteger i;

  if (tableView == [self summaryTable])
    return NO;
  
  tempArray = [[NSMutableArray alloc] init];
  for (i = 0; i < [rows count] ; i++) {
    [tempArray addObject:[[[self document] accountInfo] objectAtIndex:[[rows objectAtIndex:i] intValue]]];
  }
  [pboard declareTypes:[NSArray arrayWithObjects:@"Conto info", nil] owner:self];
  if ([pboard setPropertyList:tempArray forType:@"Conto info"]) {
    rowsToBeDragged = rows;
    [rowsToBeDragged retain]; // Released in tableView:acceptDrop:row:dropOperation
    /* Note that rowsToBeDragged is declared static,
      * so it is released even if rows are dragged upon a different document.
      */
    [tempArray release];
    return YES;
  }
  else {
    [tempArray release];
    return NO;
  }
}

- (NSDragOperation)tableView:(NSTableView*)tableView
                validateDrop:(id <NSDraggingInfo>)info
                 proposedRow:(NSInteger)row
       proposedDropOperation:(NSTableViewDropOperation)operation {
  if (operation == NSTableViewDropAbove) {
    return NSDragOperationAll;
  }
  return NSDragOperationNone;
}

- (BOOL)tableView:(NSTableView*)tableView acceptDrop:(id <NSDraggingInfo>)info
              row:(NSInteger)row
    dropOperation:(NSTableViewDropOperation)operation {
  NSInteger i, index;
  NSMutableArray *tempArray;

  if (tableView == [info draggingSource]) { // Dragging within the same table
    tempArray =[[NSMutableArray alloc] init];
    if ([rowsToBeDragged count] > 0 && row != -1 && row <= [[[self document] accountInfo] count]) {
      [[[self document] undoManager] setActionName:
        NSLocalizedString(@"Drag Info(s)", @"Name of undo/redo menu item after dragging info(s)")];
      // Remove all dragged elements from the table and put them in a temporary array
      for (i = [rowsToBeDragged count] - 1; i >= 0 ; i--) {
        index = [[rowsToBeDragged objectAtIndex:i] intValue];
        [tempArray addObject:[[[self document] accountInfo] objectAtIndex:index]];
        [[self document] removeInfoAtIndex:index];
        if (index < row) {
          row--;
        }
      }
      // Insert elements sequentially at the new position
      for (i = 0; i < [rowsToBeDragged count] ; i++) {
        [[self document] insertInfo:[tempArray objectAtIndex:i] atIndex:row];
      }
      [rowsToBeDragged release];
      [tempArray release];
      [[self infoTable] reloadData];
      return YES;
    }
  }
  else { // The user is dragging rows from a different document
    if (row != -1 && row <= [[[self document] accountInfo] count]) {
      [[[self document] undoManager] setActionName:
        NSLocalizedString(@"Drag Info(s)", @"Name of undo/redo menu item after dragging info(s)")];
      // Insert elements sequentially at the new position
      // We insert the elements from the pasteboard
      tempArray = [[info draggingPasteboard] propertyListForType:@"Conto info"];
      for (i = [tempArray count] - 1; i >= 0  ; i--) {
        [[self document] insertInfo:[tempArray objectAtIndex:i] atIndex:row];
      }
      [rowsToBeDragged release];
      [[self infoTable] reloadData];
      return YES;
    }
  }
  return NO;
}

- (IBAction)copyAsText:(id)sender {
  NSPasteboard *pboard = [NSPasteboard generalPasteboard];
  NSEnumerator *rows = [[self summaryTable] selectedRowEnumerator];
  NSMutableString *copyString = [NSMutableString stringWithCapacity:1];
  NSNumber *aRow;
  NSNumberFormatter *numberFormatter;

  numberFormatter = [[CXPreferencesController sharedPreferencesController] numberFormatter];
  while (aRow = [rows nextObject]) {
    [copyString appendString:[self intToMonthName:(CXMonth)[aRow intValue]]];
    [copyString appendString:@"\t"];
    [copyString appendString:[numberFormatter stringForObjectValue:
      [NSDecimalNumber numberWithDouble:[[self document] getSumValueForKey:@"Income" month:(CXMonth)[aRow intValue]]]]];
    [copyString appendString:@"\t"];
    [copyString appendString:[numberFormatter stringForObjectValue:
      [NSDecimalNumber numberWithDouble:[[self document] getSumValueForKey:@"Expense" month:(CXMonth)[aRow intValue]]]]];
    [copyString appendString:@"\t"];
    [copyString appendString:[numberFormatter stringForObjectValue:
      [NSDecimalNumber numberWithDouble:[[self document] getSumValueForKey:@"Balance" month:(CXMonth)[aRow intValue]]]]];
    [copyString appendString:@"\n"];
  }
  [pboard declareTypes:[NSArray arrayWithObjects:NSTabularTextPboardType,NSStringPboardType,nil] owner:nil];
  [pboard setString:copyString forType:NSStringPboardType];
}

- (NSString *)intToMonthName:(CXMonth)month {
  switch (month) {
    case January:
      return NSLocalizedString(@"January", @"Name of month January");
      break;
    case February:
      return NSLocalizedString(@"February", @"Name of month February");
      break;
    case March:
      return NSLocalizedString(@"March", @"Name of month March");
      break;
    case April:
      return NSLocalizedString(@"April", @"Name of month April");
      break;
    case May:
      return NSLocalizedString(@"May", @"Name of month May");
      break;
    case June:
      return NSLocalizedString(@"June", @"Name of month June");
      break;
    case July:
      return NSLocalizedString(@"July", @"Name of month July");
      break;
    case August:
      return NSLocalizedString(@"August", @"Name of month August");
      break;
    case September:
      return NSLocalizedString(@"September", @"Name of month September");
      break;
    case October:
      return NSLocalizedString(@"October", @"Name of month October");
      break;
    case November:
      return NSLocalizedString(@"November", @"Name of month November");
      break;
    case December:
      return NSLocalizedString(@"December", @"Name of month December");
      break;
    case LastOfYear:
      return NSLocalizedString(@"Total", @"Total");
      break;
    default: // What?!?
      return @"";
      break;
  }
}

// Validates Conto's menu items
- (BOOL)validateMenuItem:(NSMenuItem *)menuItem {
  if ([[menuItem title] isEqualToString:NSLocalizedString(@"Copy As Text", @"Name of Copy As Text menu item")])
    return ([[self summaryTable] numberOfSelectedRows] > 0);
  else
    return YES;
}

@end