//
//  CXMainWindowController.m
//  Conto
//
//  Created by Nicola on Sun Mar 31 2002.
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

#import "CXMainWindowController.h"
#import "CXDocument.h"
#import "CXPreferencesController.h"

#define Prefs   [NSUserDefaults standardUserDefaults]

@implementation CXMainWindowController

// Initialization and deallocation
- (id)init {
  if (self = [super initWithWindowNibName:@"CXDocument"]) {
    [self setShouldCloseDocument:YES];
    isFilterOn = NO;
    //numberFormatter = [[NSNumberFormatter alloc] init];
    //dateFormatter = [[NSDateFormatter alloc] init];
  } 
  return self;
}

-(void)dealloc {
  [[self window] saveFrameUsingName:@"Main Window"];
  //[numberFormatter release];
  //[dateFormatter release];
  [super dealloc];
}

-(void)windowDidLoad {
  [super windowDidLoad];

  //[[self window] setFrameAutosaveName:@"Main Window"];
  [[self window] setFrameUsingName:@"Main Window"];
  //[self setShouldCascadeWindows:NO];
  [[self table] setAutosaveName:@"CXMainTablePosition"];
  [[self table] setAutosaveTableColumns:YES]; // Remember columns' size and position
  [[self table] registerForDraggedTypes:[NSArray arrayWithObjects:@"Conto rows",nil]];


  [navigationControl setMenu:monthsMenu forSegment:1];
    
  //[[self tickOffSwitch] setState:([[self document] tickOff] ? NSOnState : NSOffState)];
  [self updateCheckbox:[self tickOffSwitch] setting:[[self document] tickOff]];
  //[[self monthPopUpMenu] selectItemAtIndex:[[self document] currentMonth]];
//  [self updatePopUpButton:[self monthPopUpMenu] setting:[[self document] currentMonth]];
    [self updateNavigationSegment];
  //[[self inOutRadioCluster] selectCellWithTag:[[self document] transactionType]];
  [self updateRadioCluster:[self inOutRadioCluster] setting:[[self document] transactionType]];
  //[[self table] setDrawsGrid:YES]; // Well, this doesn't work if set with IB 2.2
  [self setGrid:nil];
  [self setNumberFormat:nil];
  [self setDateFormat:nil];
  [self setFontSize:nil];

  [self updateSums:nil];

  [[self table] setAction:@selector(handleClickOnTableItem)];
  
  if ([[self document] logo])
    [[self logoImageView] setImage:[[self document] logo]];

  [self updateAutocompletion:nil];

  //[[self table] setDoubleAction:@selector(doubleClickOnUneditableCell)];
  
  // Register notification observers
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(updateTableView:)
                                               name:CXTableChangedNotification
                                             object:[self document]];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                        selector:@selector(updateSums:)
                                        name:CXValueInTableChangedNotification
                                        object:[self document]];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                        selector:@selector(updateMonthPopUpMenu:)
                                        name:CXMonthChangedNotification
                                        object:[self document]];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(updateSums:)
                                               name:CXMonthChangedNotification
                                             object:[self document]];  
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(updateTickOffSwitch:)
                                               name:CXTickOffStateChangedNotification
                                             object:[self document]];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(updateInOutRadioCluster:)
                                               name:CXTransactionTypeChangedNotification
                                             object:[self document]];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(updateLogo:)
                                               name:CXLogoChangedNotification
                                             object:[self document]];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(setFontSize:)
                                               name:CXFontSizeChangedNotification
                                             object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(setNumberFormat:)
                                               name:CXNumberFormatChangedNotification
                                             object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(setDateFormat:)
                                               name:CXDateFormatChangedNotification
                                             object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(setGrid:)
                                               name:CXGridChangedNotification
                                             object:nil];  
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(updateComboBox:)
                                               name:CXDescriptionsTableChangedNotification
                                             object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(updateAutocompletion:)
                                               name:CXAutocompletionChangedNotification
                                             object:nil];  
  
  [[self window] makeKeyAndOrderFront:self];
}


// Accessor methods
- (NSButton *)addButton {
  return addButton;
}

- (NSTextField *)dateField {
  return dateField;
}

- (NSTextField *)amountField {
  return amountField;
}

- (NSComboBox *)descriptionField {
  return descriptionField;
}

- (NSTextField *)incomeField {
  return incomeField;
}

- (NSTextField *)expenseField {
  return expenseField;
}

- (NSTextField *)balanceField {
  return balanceField;
}

- (NSTextField *)monthlyBalanceField {
  return monthlyBalanceField;
}

- (NSImageView *)logoImageView {
  return logoImageView;
}

- (NSPopUpButton *)monthPopUpMenu {
  return monthPopUpMenu;
}

- (NSTableView *)table {
  return table;
}

- (NSButton *)tickOffSwitch {
  return tickOffSwitch;
}

- (NSMatrix *)inOutRadioCluster {
  return inOutRadioCluster;
}

- (NSButton *)prevButton {
  return prevButton;
}

- (NSButton *)nextButton {
  return nextButton;
}

- (NSTextField *)searchTextField {
  return searchTextField;
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
  //[numberFormatter setFormat:@"#,##0.00 €;0.00 €;-#,##0.00 €"];
  [[self numberFormatter] setFormat:formatString];
  [newAttrs setObject:[NSColor redColor] forKey:@"NSColor"];
  [[self numberFormatter] setTextAttributesForNegativeValues:newAttrs];
  //[numberFormatter setAttributedStringForNotANumber:[[[NSAttributedString alloc] initWithString:@""] autorelease]];
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

/*
- (NSDateFormatter *)dateFormatter {
  return dateFormatter;
}
*/

/*
- (void)setDateFormatterFromPrefs {
  [[self dateFormatter] release];
  dateFormatter = nil;
  
  switch ((CXDateFormat)[Prefs integerForKey:CXDateFormatKey]) {
    case DDMMYY:
      dateFormatter = [[NSDateFormatter alloc] initWithDateFormat:@"%d-%m-%y" allowNaturalLanguage:NO];
      [[self dateField] setToolTip:NSLocalizedString(@"Date must have format: dd-mm-yy (e.g. 24-12-02)",
                                                     @"Tooltip for date format dd-mm-yy")];
      break;
    case DDMMYYWithSlash:
      dateFormatter = [[NSDateFormatter alloc] initWithDateFormat:@"%d/%m/%y" allowNaturalLanguage:NO];
      [[self dateField] setToolTip:NSLocalizedString(@"Date must have format: dd/mm/yy (e.g. 24/12/02)",
                                                     @"Tooltip for date format dd/mm/yy")];
      break;
    case DDMM:
      dateFormatter = [[NSDateFormatter alloc] initWithDateFormat:@"%d-%m" allowNaturalLanguage:NO];
      [[self dateField] setToolTip:NSLocalizedString(@"Date must have format: dd-mm (e.g. 24-12)",
                                                     @"Tooltip for date format dd-mm")];
      break;
    case DDMMWithSlash:
      dateFormatter = [[NSDateFormatter alloc] initWithDateFormat:@"%d/%m" allowNaturalLanguage:NO];
      [[self dateField] setToolTip:NSLocalizedString(@"Date must have format: dd/mm (e.g. 24/12)",
                                                     @"Tooltip for date format dd/mm")];
      break;
    case DDMonthYear:
      dateFormatter = [[NSDateFormatter alloc] initWithDateFormat:@"%d %B %Y" allowNaturalLanguage:NO];
      [[self dateField] setToolTip:NSLocalizedString(@"Date must have format: day month year (e.g. 24 december 2002)",
                                                     @"Tooltip for date format day month year")];
      break;
    case DDMonYear:
      dateFormatter = [[NSDateFormatter alloc] initWithDateFormat:@"%d %b %Y" allowNaturalLanguage:NO];
      [[self dateField] setToolTip:NSLocalizedString(@"Date must have format: day abbr.month year (e.g. 24 dec 2002)",
                                                     @"Tooltip for date format day abbr.month year")];
      break;
    case DDMonth:
      dateFormatter = [[NSDateFormatter alloc] initWithDateFormat:@"%d %B" allowNaturalLanguage:NO];
      [[self dateField] setToolTip:NSLocalizedString(@"Date must have format: day month (e.g. 24 december)",
                                                     @"Tooltip for date format day month")];
      break;
    case DDMon:
      dateFormatter = [[NSDateFormatter alloc] initWithDateFormat:@"%d %b" allowNaturalLanguage:NO];
      [[self dateField] setToolTip:NSLocalizedString(@"Date must have format: day abbr.month (e.g. 24 dec)",
                                                     @"Tooltip for date format day abbr.month")];
      break;
    default:
      dateFormatter = [[NSDateFormatter alloc] initWithDateFormat:@"%d-%m-%y" allowNaturalLanguage:NO];
      [[self dateField] setToolTip:NSLocalizedString(@"Date must have format: dd-mm-yy (e.g. 24-12-02)",
                                                     @"Tooltip for date format dd-mm-yy")];
      break;
  }  
}
*/

// Generic view updaters
- (void)updateCheckbox:(NSButton *)control setting:(BOOL)value {
    if (value != [control state]) { 
        [control setState:(value ? NSOnState : NSOffState)];
    }
}

- (void)updatePopUpButton:(NSPopUpButton *)control setting:(NSInteger)value {
    if (value != [control indexOfSelectedItem]) {
        [control selectItemAtIndex:value];
    }
}

- (void)updateRadioCluster:(NSMatrix *)control setting:(NSInteger)value {
    if (value != [[control selectedCell] tag]) {
        [control selectCellWithTag:value];
    }
}

// Specific view updaters
- (void)updateTickOffSwitch:(NSNotification *)notification {
  [self updateCheckbox:[self tickOffSwitch] setting:[[self document] tickOff]];
}

- (void)updateMonthPopUpMenu:(NSNotification *)notification {
  [self updatePopUpButton:[self monthPopUpMenu] setting:[[self document] currentMonth]];
  [[self table] reloadData];
}

- (void)updateInOutRadioCluster:(NSNotification *)notification {
  [self updateRadioCluster:[self inOutRadioCluster] setting:[[self document] transactionType]];
}

- (void)updateLogo:(NSNotification *)notification {
  if ([[self logoImageView] image] != [[self document] logo])
    [[self logoImageView] setImage:[[self document] logo]];
}

- (void)updateTableView:(NSNotification *)notification {
  [[self table] reloadData];
//  [[self table] scrollRowToVisible:[[self table] numberOfRows]-1];
}

// Formatting numbers according to preferences
- (void)setNumberFormat:(NSNotification *)notification {
  NSNumberFormatter *numberFormatter;
  
  // Detach old formatters (without these instructions it doesn't seem work)
  [[[self amountField] cell] setFormatter:nil];
  [[[self balanceField] cell] setFormatter:nil];
  [[[self monthlyBalanceField] cell] setFormatter:nil];
  [[[[self table] tableColumnWithIdentifier:@"Income"] dataCell] setFormatter:nil];
  [[[[self table] tableColumnWithIdentifier:@"Expense"] dataCell] setFormatter:nil];
  [[[self incomeField] cell] setFormatter:nil];
  [[[self expenseField] cell] setFormatter:nil];

  //[self setNumberFormatterFromPrefs];
  numberFormatter = [[CXPreferencesController sharedPreferencesController] numberFormatter];
  [[[self amountField] cell] setFormatter:numberFormatter];
  [[[self balanceField] cell] setFormatter:numberFormatter];
  [[[self monthlyBalanceField] cell] setFormatter:numberFormatter];
  [[[[self table] tableColumnWithIdentifier:@"Income"] dataCell] setFormatter:numberFormatter];
  [[[[self table] tableColumnWithIdentifier:@"Expense"] dataCell] setFormatter:numberFormatter];
  [[[self incomeField] cell] setFormatter:numberFormatter];
  [[[self expenseField] cell] setFormatter:numberFormatter];

  [[self table] reloadData];
  [self updateSums:nil];
}

- (void)setDateFormat:(NSNotification *)notification {
  NSDateFormatter *dateFormatter;
  
  // Detach old formatter
  [[[[self table] tableColumnWithIdentifier:@"Date"] dataCell] setFormatter:nil];

  //[self setDateFormatterFromPrefs];
  dateFormatter = [[CXPreferencesController sharedPreferencesController] dateFormatter];
  
  [[[[self table] tableColumnWithIdentifier:@"Date"] dataCell] setFormatter:dateFormatter];
  [[[self dateField] cell] setFormatter:dateFormatter];
  switch ((CXDateFormat)[Prefs integerForKey:CXDateFormatKey]) {
    case DDMMYY:
      [[self dateField] setToolTip:NSLocalizedString(@"Date must have format: dd-mm-yy (e.g. 24-12-02)",
                                                     @"Tooltip for date format dd-mm-yy")];
      break;
    case DDMMYYWithSlash:
      [[self dateField] setToolTip:NSLocalizedString(@"Date must have format: dd/mm/yy (e.g. 24/12/02)",
                                                     @"Tooltip for date format dd/mm/yy")];
      break;
    case DDMM:
      [[self dateField] setToolTip:NSLocalizedString(@"Date must have format: dd-mm (e.g. 24-12)",
                                                     @"Tooltip for date format dd-mm")];
      break;
    case DDMMWithSlash:
      [[self dateField] setToolTip:NSLocalizedString(@"Date must have format: dd/mm (e.g. 24/12)",
                                                     @"Tooltip for date format dd/mm")];
      break;
    case DDMonthYear:
      [[self dateField] setToolTip:NSLocalizedString(@"Date must have format: day month year (e.g. 24 december 2002)",
                                                     @"Tooltip for date format day month year")];
      break;
    case DDMonYear:
      [[self dateField] setToolTip:NSLocalizedString(@"Date must have format: day abbr.month year (e.g. 24 dec 2002)",
                                                     @"Tooltip for date format day abbr.month year")];
      break;
    case DDMonth:
      [[self dateField] setToolTip:NSLocalizedString(@"Date must have format: day month (e.g. 24 december)",
                                                     @"Tooltip for date format day month")];
      break;
    case DDMon:
      [[self dateField] setToolTip:NSLocalizedString(@"Date must have format: day abbr.month (e.g. 24 dec)",
                                                     @"Tooltip for date format day abbr.month")];
      break;
    default:
      [[self dateField] setToolTip:NSLocalizedString(@"Date must have format: dd-mm-yy (e.g. 24-12-02)",
                                                     @"Tooltip for date format dd-mm-yy")];
      break;
  }
  [[self table] reloadData];
}

- (void)setGrid:(NSNotification *)notification {
  BOOL drawGrid = [Prefs boolForKey:CXGridKey];
  NSUInteger gridStyle = drawGrid ? NSTableViewSolidVerticalGridLineMask | NSTableViewSolidHorizontalGridLineMask : NSTableViewGridNone;
  [[self table] setGridStyleMask:gridStyle];
}


- (void)setFontSize:(NSNotification *)notification {
  NSTableColumn *column;
  NSEnumerator *enumerator =[[[self table] tableColumns] objectEnumerator];

  if ((CXFontSize)[Prefs integerForKey:CXFontSizeKey] == Smaller) {
    while (column = [enumerator nextObject]) {
      [[column dataCell] setFont:
        [NSFont systemFontOfSize:[NSFont smallSystemFontSize]]];
    }
    [[self table] setRowHeight:(float)13.0];
  }
  else {
    while (column = [enumerator nextObject]) {
      [[column dataCell] setFont:
        [NSFont systemFontOfSize:[NSFont systemFontSize]]];
    }
    [[self table] setRowHeight:(float)17.0];
  }
}

- (void)updateComboBox:(NSNotification *)notification {
  /*
  NSInteger nItems = [[[CXPreferencesController sharedPreferencesController] descriptions] count];
  if (nItems < 10)
    [[self descriptionField] setNumberOfVisibleItems:nItems];
  else
    [[self descriptionField] setNumberOfVisibleItems:10];
  */
  [[self descriptionField] reloadData];
}

- (void)updateAutocompletion:(NSNotification *)notification {
  [[self descriptionField] setCompletes:[Prefs boolForKey:CXAutocompleteKey]];
}


// Actions
- (IBAction)addAction:(id)sender
{
  NSMutableDictionary *record = [NSMutableDictionary dictionaryWithCapacity:5];
  double theAmount, newAmount;
  NSUInteger index;
  CXOperationType inOp, outOp;
  BOOL foundPredefinedDescription;
  NSArray *descriptions;
  NSString *newDescription;
  
  //[record setObject:[[self dateField] stringValue] forKey:@"Date"];
  if (nil == [[self dateField] objectValue]) {
    [[self dateField] setObjectValue:[NSDate date]];
  }
  [record setObject:[[self dateField] objectValue] forKey:@"Date"]; 
  [record setObject:([[self document] tickOff] ? @"✓" : @"") forKey:@"Check"];
  newDescription = [[self descriptionField] stringValue];
  [record setObject:newDescription forKey:@"Description"];

  // Check whether this is a predefined description
  index = 0;
  foundPredefinedDescription = NO;
  descriptions = [[[CXPreferencesController sharedPreferencesController] descriptions] retain];
  while ((index < [descriptions count]) && (!foundPredefinedDescription)) {
    foundPredefinedDescription = [newDescription isEqualToString:
      [[descriptions objectAtIndex:index] objectForKey:CXDefaultDescriptionKey]];
    index++;
  }
  if (foundPredefinedDescription) { // Store associated operations, if any
    index--;
    inOp = [[[descriptions objectAtIndex:index] objectForKey:CXIncomeOperationKey] intValue];
    outOp = [[[descriptions objectAtIndex:index] objectForKey:CXExpenseOperationKey] intValue];
    if (inOp != NoOperation) {
      [record setObject:[NSNumber numberWithInt:inOp] forKey:CXIncomeOperationKey];
      [record setObject:[[descriptions objectAtIndex:index] objectForKey:CXIncomeOpValueKey] forKey:CXIncomeOpValueKey];
    }
    if (outOp != NoOperation) {
      [record setObject:[NSNumber numberWithInt:outOp] forKey:CXExpenseOperationKey];
      [record setObject:[[descriptions objectAtIndex:index] objectForKey:CXExpenseOpValueKey] forKey:CXExpenseOpValueKey];
    }
  }
  [descriptions release];

  if ((nil == [[self amountField] objectValue])) // || ([[[self amountField] objectValue] isEqual:[NSDecimalNumber notANumber]]))
  {
    [[self amountField] setObjectValue:[NSDecimalNumber zero]];
  }
  theAmount = [[[self amountField] objectValue] doubleValue];
  switch ([[self document] transactionType]) {
    case Income:
      //[record setObject:[NSNumber numberWithDouble:[[self amountField] doubleValue]] forKey:@"Income"];
      //[record setObject:[NSDecimalNumber decimalNumberWithString:[[self amountField] stringValue]] forKey:@"Income"];
      if (theAmount >= 0.0) {
        newAmount = [[self document] applyOperation:[[record objectForKey:CXIncomeOperationKey] intValue]
                                          withValue:[[record objectForKey:CXIncomeOpValueKey] doubleValue]
                                           toAmount:theAmount];
        if (newAmount >= 0.0) {
          //[[self amountField] setObjectValue:[NSDecimalNumber numberWithDouble:newAmount]];
          [[self amountField] setObjectValue:[NSNumber numberWithDouble:newAmount]];
          [record setObject:[[self amountField] objectValue] forKey:@"Income"];
          [record setObject:@"" forKey:@"Expense"];
        }
        else {
          [[self amountField] setObjectValue:[NSNumber numberWithDouble:(-newAmount)]];
          [record setObject:[[self amountField] objectValue] forKey:@"Expense"];
          [record setObject:@"" forKey:@"Income"];
        }
      }
      else { // A negative income is considered as an expense
        newAmount = [[self document] applyOperation:[[record objectForKey:CXExpenseOperationKey] intValue]
                                          withValue:[[record objectForKey:CXExpenseOpValueKey] doubleValue]
                                           toAmount:(-theAmount)];
        if (newAmount >= 0.0) {
          [[self amountField] setObjectValue:[NSNumber numberWithDouble:newAmount]];
          [record setObject:[[self amountField] objectValue] forKey:@"Expense"];
          [record setObject:@"" forKey:@"Income"];
        }
        else {
          [[self amountField] setObjectValue:[NSNumber numberWithDouble:(-newAmount)]];
          [record setObject:[[self amountField] objectValue] forKey:@"Income"];
          [record setObject:@"" forKey:@"Expense"];
        }
      }
      break;
    case Expense:
      if (theAmount >= 0.0) {
        //[record setObject:[NSNumber numberWithDouble:[[self amountField] doubleValue]] forKey:@"Expense"];
        //[record setObject:[NSDecimalNumber decimalNumberWithString:[[self amountField] stringValue]] forKey:@"Expense"];
        newAmount = [[self document] applyOperation:[[record objectForKey:CXExpenseOperationKey] intValue]
                                          withValue:[[record objectForKey:CXExpenseOpValueKey] doubleValue]
                                           toAmount:theAmount];
        if (newAmount >= 0.0) {
          [[self amountField] setObjectValue:[NSNumber numberWithDouble:newAmount]];
          [record setObject:[[self amountField] objectValue] forKey:@"Expense"];
          [record setObject:@"" forKey:@"Income"];
        }
        else {
          [[self amountField] setObjectValue:[NSNumber numberWithDouble:(-newAmount)]];
          [record setObject:[[self amountField] objectValue] forKey:@"Income"];
          [record setObject:@"" forKey:@"Expense"];          
        }
      }
      else { // A negative expense is considered as an income
        newAmount = [[self document] applyOperation:[[record objectForKey:CXIncomeOperationKey] intValue]
                                          withValue:[[record objectForKey:CXIncomeOpValueKey] doubleValue]
                                           toAmount:(-theAmount)];
        if (newAmount >= 0.0) {
        [[self amountField] setObjectValue:[NSNumber numberWithDouble:newAmount]];
        [record setObject:[[self amountField] objectValue] forKey:@"Income"];
        [record setObject:@"" forKey:@"Expense"];
        }
        else {
          [[self amountField] setObjectValue:[NSNumber numberWithDouble:(-newAmount)]];
          [record setObject:[[self amountField] objectValue] forKey:@"Expense"];
          [record setObject:@"" forKey:@"Income"];
        }
      }
      break;
    default: // What?!?
      [record setObject:@"" forKey:@"Income"];
      [record setObject:@"" forKey:@"Expense"];
      break;
  }

  //[[self document] insertRecord:record atIndex:[[self table] numberOfRows] forMonth:CurrentMonth];
  [[self document] insertRecord:record atIndex:[[[self document] getRecordsForMonth:CurrentMonth] count]
                       forMonth:CurrentMonth];
  /*
   if (isFilterOn)
    [[self document] insertFilteredRecord:record atIndex:[[[self document] filteredRecords] count]];
  */
  [[[self document] undoManager] setActionName:
    NSLocalizedString(@"Add Record", @"Name of undo/redo menu item after adding a record")];

  //[[self table] reloadData];
  [table scrollRowToVisible:[[[self document] getRecordsForMonth:CurrentMonth] count]-1];
  [[self dateField] setStringValue:@""];
  [[self amountField] setStringValue:@""];
  [[self descriptionField] setStringValue:@""];
  //[[self table] scrollRowToVisible:[[self table] numberOfRows]-1];
  // Post notification to update GUI
  //[[NSNotificationCenter defaultCenter] postNotificationName:CXValueInTableChangedNotification
  //                                      object:self];

}

- (IBAction)inOutAction:(id)sender {
  if ([[sender selectedCell] tag] != [[self document] transactionType]) {
    [[self document] setTransactionType:[[sender selectedCell] tag]];

    [[[self document] undoManager] setActionName:
      NSLocalizedString(@"Set Transaction Type", @"Name of undo/redo menu item after setting transaction type")];
  }
}

- (IBAction)monthPopUpAction:(id)sender {
  NSMenuItem *selected = [monthsMenu itemAtIndex:[[self document] currentMonth]];
    [[self table] deselectAll:self];
    [[self document] setCurrentMonth:[monthsMenu indexOfItem:sender]];
    [self updateNavigationSegment];
    [[[self document] undoManager] setActionName:
     NSLocalizedString(@"Change Month", @"Name of undo/redo menu item after changing month via pop up menu")];
}

- (void)updateNavigationSegment
{
    for (int i = 0; i < [[monthsMenu itemArray] count]; i++) {
        NSMenuItem *item = [monthsMenu itemAtIndex:i];
        [item setState: NSOffState];
        if (i == [[self document] currentMonth]) {
            [item setState: NSOnState];
            [navigationControl setLabel:[item title] forSegment:1];
        }
    }
}

- (IBAction)tickOffAction:(id)sender {
  [[self document] setTickOff:([sender state] == NSOnState)];
  // Undo management
  // I quote from VR: The documentation recommends that the setActionName: method be invoked in an action method,
  // as it is done here, rather than in the primitive method that actually changes the data value in the model object.
  if ([sender state] == NSOnState) {
    [[[self document] undoManager] setActionName:
      NSLocalizedString(@"Activate Tick Off", @"Name of undo/redo menu item after tick off control was set")];
  }
  else {
    [[[self document] undoManager] setActionName:
      NSLocalizedString(@"Deactivate Tick Off", @"Name of undo/redo menu item after tick off control was cleared")];}

  
}

- (IBAction)draggedLogoAction:(id)sender {
  [[self document] setLogo:[[self logoImageView] image]];
  [[[self document] undoManager] setActionName:
    NSLocalizedString(@"Set Logo", @"Name of undo/redo menu item after dragging an image")];
}

- (IBAction)printDocumentView:(id)sender {
  [[self document] printView:[self table]];
}

- (IBAction)cut:(id)sender {
  NSMutableArray *tempArray;
  NSArray *records;
  NSPasteboard *pboard = [NSPasteboard generalPasteboard];
  NSIndexSet *rows = [[self table] selectedRowIndexes];
  NSUInteger idx = [rows firstIndex];

  if (isFilterOn) // Cut from filtered array
    records = [[self document] filteredRecords];
  else
    records = [[self document] getRecordsForMonth:CurrentMonth];  
  tempArray = [[NSMutableArray alloc] init];

  while (idx != NSNotFound) {
    [tempArray addObject:[records objectAtIndex:idx]];
      
    idx = [rows indexGreaterThanIndex:idx];
  }
  [pboard declareTypes:[NSArray arrayWithObjects:@"Conto rows", nil] owner:self];
  [pboard setPropertyList:tempArray forType:@"Conto rows"];
  [tempArray release];
  [self deleteRecords:nil];
  [[[self document] undoManager] setActionName:
    NSLocalizedString(@"Cut Record(s)", @"Name of undo/redo menu item after cutting record(s)")];  // Remove records
 /*
  i = [[self table] numberOfRows];
  while (i-- >= 0) {
    if ([[self table] isRowSelected:i])
      [[self document] removeRecordAtIndex:i forMonth:CurrentMonth];
  }
  [[self table] reloadData];
  */
}

- (IBAction)copy:(id)sender {
  NSMutableArray *tempArray;
  NSArray *records;
  NSPasteboard *pboard = [NSPasteboard generalPasteboard];
  NSIndexSet *rows = [[self table] selectedRowIndexes];
  NSUInteger idx = [rows firstIndex];
    
  if (isFilterOn) // Copy from filtered array
    records = [[self document] filteredRecords];
  else
    records = [[self document] getRecordsForMonth:CurrentMonth];
  tempArray = [[NSMutableArray alloc] init];
  while (idx != NSNotFound) {
    [tempArray addObject:[records objectAtIndex:idx]];
      
    idx = [rows indexGreaterThanIndex:idx];
  }
    
  [pboard declareTypes:[NSArray arrayWithObjects:@"Conto rows", nil] owner:self];
  [pboard setPropertyList:tempArray forType:@"Conto rows"];
  [tempArray release];  
}

- (IBAction)paste:(id)sender {
  NSArray *tempArray;
  NSPasteboard *pboard = [NSPasteboard generalPasteboard];
  NSInteger i;
  NSInteger n;
  /*
  if (isFilterOn) { // Show all before pasting
    [[self searchTextField] setStringValue:@""];
    [self filterDescriptions:@""];
  }
  */
  if ([pboard availableTypeFromArray:[NSArray arrayWithObjects:@"Conto rows", nil]] != nil) {
    [[[self document] undoManager] setActionName:
      NSLocalizedString(@"Paste Record(s)", @"Name of undo/redo menu item after pasting record(s)")];
    tempArray = [pboard propertyListForType:@"Conto rows"];
    n = [[self table] numberOfRows];
    for (i = 0; i < [tempArray count]; i++) {
      [[self document] insertRecord:[tempArray objectAtIndex:i] atIndex:(n + i) forMonth:CurrentMonth];
    }
    //[[self table] reloadData];
  }
}	

- (IBAction)copyAsText:(id)sender {
  NSPasteboard *pboard = [NSPasteboard generalPasteboard];
  NSIndexSet *rows = [[self table] selectedRowIndexes];
  NSArray *records;
  NSMutableString *copyString = [NSMutableString stringWithCapacity:1];
  NSDictionary *aRecord;
  NSNumberFormatter *numberFormatter;
  NSDateFormatter *dateFormatter;
  NSArray *tableColumns = [[self table] tableColumns];
  NSString *columnIdentifier;
  NSUInteger idx = [rows firstIndex];

  if (isFilterOn) // Copy from filtered array
    records = [[self document] filteredRecords];
  else
    records = [[self document] getRecordsForMonth:CurrentMonth];
  
  numberFormatter = [[CXPreferencesController sharedPreferencesController] numberFormatter];
  dateFormatter = [[CXPreferencesController sharedPreferencesController] dateFormatter];
  while (idx != NSNotFound) {
    aRecord = [records objectAtIndex:idx];
    //[copyString appendString:[aRecord objectForKey:@"Check"]];
    for (int i = 0; i < [tableColumns count]; i++) {
      columnIdentifier = [[tableColumns objectAtIndex:i] identifier];
      if ([columnIdentifier isEqualToString:@"Date"]) {
        [copyString appendString:[dateFormatter stringForObjectValue:[aRecord objectForKey:@"Date"]]];
      }
      else if ([columnIdentifier isEqualToString:@"Income"]) {
        if ([[aRecord objectForKey:@"Income"] respondsToSelector:@selector(stringValue)])
          [copyString appendString:[numberFormatter stringForObjectValue:[aRecord objectForKey:@"Income"]]];
      }
      else if ([columnIdentifier isEqualToString:@"Expense"]) {
        if ([[aRecord objectForKey:@"Expense"] respondsToSelector:@selector(stringValue)])
          [copyString appendString:[numberFormatter stringForObjectValue:[aRecord objectForKey:@"Expense"]]];
      }
      else if ([columnIdentifier isEqualToString:@"Description"]) {
        [copyString appendString:[aRecord objectForKey:@"Description"]];
      }
      [copyString appendString:@"\t"];
    }
    [copyString appendString:@"\n"];
      
    idx = [rows indexGreaterThanIndex:idx];
  }
  [pboard declareTypes:[NSArray arrayWithObjects:NSTabularTextPboardType,NSStringPboardType,nil] owner:nil];
  [pboard setString:copyString forType:NSStringPboardType];
}

- (IBAction)prevMonthAction:(id)sender {
  NSInteger newMonthIndex;

  newMonthIndex = [[self document] currentMonth] - 1;
  if (newMonthIndex < January)
    newMonthIndex = December;
  [[self table] deselectAll:self];
  [[self document] setCurrentMonth:newMonthIndex];
  [[[self document] undoManager] setActionName:
    NSLocalizedString(@"Change Month", @"Name of undo/redo menu item after changing month via pop up menu")];  
}

- (IBAction)nextMonthAction:(id)sender {
  NSInteger newMonthIndex;

  newMonthIndex = [[self document] currentMonth] + 1;
  if (newMonthIndex > December)
    newMonthIndex = January;
  [[self table] deselectAll:self];
  [[self document] setCurrentMonth:newMonthIndex];
  [[[self document] undoManager] setActionName:
    NSLocalizedString(@"Change Month", @"Name of undo/redo menu item after changing month via pop up menu")];  
}

- (IBAction)navigateAction:(id)sender {
    switch ([navigationControl selectedSegment]) {
        case 0:
            [self prevMonthAction:nil];
            break;
        case 2:
            [self nextMonthAction:nil];
            break;
        default:
            break;
    }
    
    [self updateNavigationSegment];
}

- (IBAction)newEntryAction:(id)sender {
    NSMutableDictionary *record = [NSMutableDictionary dictionaryWithCapacity:5];
    record[@"Check"] = @"";
    record[@"Date"] = [NSDate date];
    record[@"Income"] = @(0);
    record[@"Expense"] = @(0);
    record[@"Description"] = @"";
    
    [[self document] insertRecord:record atIndex:[[[self document] getRecordsForMonth:CurrentMonth] count]
                         forMonth:CurrentMonth];
    NSUInteger targetRow = [[[self document] getRecordsForMonth:CurrentMonth] count]-1;
    [table selectRowIndexes:[NSIndexSet indexSetWithIndex:targetRow] byExtendingSelection:NO];
//    [table scrollRowToVisible:[[[self document] getRecordsForMonth:CurrentMonth] count]-1];
    [table editColumn:1 row:targetRow withEvent:nil select:YES];
}


// Used to toggle the checkmark in Check column when the user clicks on a cell
- (void)handleClickOnTableItem {
  NSInteger column, row;
  NSMutableDictionary *theRecord;

  column = [[self table] clickedColumn];
  row = [[self table] clickedRow];
  
  if ([[[[[self table] tableColumns] objectAtIndex:column] identifier] isEqual:@"Check"]) {
    if (row > -1) { // If row == -1, no row was selected (the user clicked the header or outside the cells)
      //[[self document] triggerTickOffAtIndex:row];
      if (isFilterOn)
        theRecord = [[[self document] filteredRecords] objectAtIndex:row];
      else
        theRecord = [[[self document] getRecordsForMonth:CurrentMonth] objectAtIndex:row];
      [[self document] triggerTickOffForRecord:theRecord]; 
      if ([[theRecord objectForKey:@"Check"] isEqualToString:@""])
        [[[self document] undoManager] setActionName:
          NSLocalizedString(@"Clear Tick Off", @"Name of undo/redo menu item after switching a tick off in table")];
      else
        [[[self document] undoManager] setActionName:
          NSLocalizedString(@"Set Tick Off", @"Name of undo/redo menu item after switching a tick off in table")];
    }
  }
}

// To remove records.
// This method is called when TableView is first responder and
// the user selects the Delete menu item (or presses the Delete key).
- (void)deleteRecords:(id)sender {
  NSIndexSet *rows = [[self table] selectedRowIndexes];
  NSMutableArray *recordsToDelete;
  NSUInteger idx = [rows firstIndex];

  recordsToDelete = [[NSMutableArray alloc] init]; // Released later in this method
  if (isFilterOn) { // Picks records from filtered array
    while (idx != NSNotFound) {
      [recordsToDelete addObject:[[[self document] filteredRecords]
                                                   objectAtIndex:idx]];
        
      idx = [rows indexGreaterThanIndex:idx];
    }
    
  }
  else {
    while (idx != NSNotFound) {
      [recordsToDelete addObject:[[[self document] getRecordsForMonth:CurrentMonth]
                                                   objectAtIndex:idx]];
        
      idx = [rows indexGreaterThanIndex:idx];
    }
  }
  
  // Delete objects from account data
  for (int i = 0; i < [recordsToDelete count]; i++) {
    [[self document] removeRecordIdenticalTo:[recordsToDelete objectAtIndex:i] forMonth:CurrentMonth];
    /*
    if (isFilterOn)
      [[self document] removeFilteredRecordIdenticalTo:[recordsToDelete objectAtIndex:i]];
    */
  }
  [recordsToDelete release];
  
  [[[self document] undoManager] setActionName:
    NSLocalizedString(@"Remove Record(s)", @"Name of undo/redo menu item after removing record(s)")];
}


- (void)deleteLogo:(id)sender {
  [[self document] setLogo:nil];
  [[[self document] undoManager] setActionName:
    NSLocalizedString(@"Delete Logo", @"Name of undo/redo menu item after deleting the image")];  
}


- (void)filterDescriptions {
  isFilterOn = ![[[self document] filter] isEqualToString:@""];
  [[self document] filterDescriptionsInMonth:CurrentMonth];
}


// Validates Conto's menu items
- (BOOL)validateMenuItem:(NSMenuItem *)menuItem {
  NSString *menuTitle = [menuItem title];

  if ([menuTitle isEqualToString:NSLocalizedString(@"Delete", @"Name of Delete menu item")])
    return ([[self table] selectedRow] != -1); // One way to check whether at least one row is selected
  else if ([menuTitle isEqualToString:NSLocalizedString(@"Cut", @"Name of Cut menu item")])
    return ([[self table] numberOfSelectedRows] > 0); // A different way of doing the same
  else if ([menuTitle isEqualToString:NSLocalizedString(@"Copy", @"Name of Copy menu item")])
    return ([[self table] numberOfSelectedRows] > 0);
  else if ([menuTitle isEqualToString:NSLocalizedString(@"Copy As Text", @"Name of Copy As Text menu item")])
    return ([[self table] numberOfSelectedRows] > 0);
  else if ([menuTitle isEqualToString:NSLocalizedString(@"Delete Logo", @"Name of Delete Logo menu item")])
    return ([[self document] logo] != nil);
  else
    //return [[self nextResponder] validateMenuItem:menuItem];
    return YES;
}



#define MONTHTABLE [[self document] getRecordsForMonth:CurrentMonth]

// Table view methods
- (NSInteger)numberOfRowsInTableView:(NSTableView *)mainTableView
{
  if (isFilterOn) // Count filtered records
    return [[[self document] filteredRecords] count];
  else
    return [MONTHTABLE count];
}

- (id)tableView:(NSTableView *)mainTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
  NSArray *dataForTheTable;
  id theRecord, theValue;

  if (isFilterOn) // Show only filtered items
    dataForTheTable = [[self document] filteredRecords];
  else // Show all
    dataForTheTable = MONTHTABLE;    

  NSParameterAssert(rowIndex >= 0 && rowIndex < [dataForTheTable count]);
  theRecord = [dataForTheTable objectAtIndex:rowIndex];
  theValue = [theRecord objectForKey:[aTableColumn identifier]];
  if (theValue == nil)
    theValue = @"Boh!";
  return theValue;
}

- (void)tableView:(NSTableView *)mainTableView setObjectValue:(id)anObject forTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
  NSString *columnId;
  NSMutableDictionary *theRecord;
  //double theValue, newValue;
    
  columnId = [aTableColumn identifier];
  if (isFilterOn)
    theRecord = [[[self document] filteredRecords] objectAtIndex:rowIndex];
  else
    theRecord = [[[self document] getRecordsForMonth:CurrentMonth] objectAtIndex:rowIndex];
  //NSParameterAssert(rowIndex >= 0 && rowIndex < [[self table] numberOfRows]);
  if ([columnId isEqualToString:@"Date"]) {
    if (nil == anObject) {
      NSBeep();
      return;
    }
    else {
      if ([[self document] modifyField:columnId ofRecord:theRecord
                              forMonth:CurrentMonth newValue:anObject]) {
        [[[self document] undoManager] setActionName:
          NSLocalizedString(@"Change Date", @"Name of undo/redo menu item after changing value in table")];
      }
    }
  }
  else {
    //NSLog(NSStringFromClass([anObject class]));
    if (nil == anObject)
      anObject = @"";
    /*
    if ([columnId isEqualToString:@"Income"]) {
      theValue = [anObject doubleValue];
      // Apply operation, if any
      newValue = [[self document] applyOperation:
    }
    else if ([columnId isEqualToString:@"Expense"]) {

    }
    if (![anObject isEqual:[[[[self document] getRecordsForMonth:CurrentMonth]
             objectAtIndex:rowIndex] objectForKey:columnId]]) {
    */
    if (([columnId isEqualToString:@"Income"] || [columnId isEqualToString:@"Expense"]) &&
        ![anObject isEqual:@""])
      anObject = [NSNumber numberWithDouble:[anObject doubleValue]];
    if ([[self document] modifyField:columnId ofRecord:theRecord
                            forMonth:CurrentMonth newValue:anObject]) {
      [[[self document] undoManager] setActionName:
        NSLocalizedString(@"Change Value", @"Name of undo/redo menu item after changing value in table")];
    }
  }
}



// Drag and drop
static NSArray *rowsToBeDragged;

- (BOOL)tableView:(NSTableView *)tableView writeRows:(NSArray*)rows toPasteboard:(NSPasteboard*)pboard {
  NSMutableArray *tempArray;
  NSInteger i;

  tempArray = [[NSMutableArray alloc] init];
  if (isFilterOn) {
    for (i = 0; i < [rows count] ; i++) {
      [tempArray addObject:[[[self document] filteredRecords] objectAtIndex:[[rows objectAtIndex:i] intValue]]];
    }  
  }
  else {
    for (i = 0; i < [rows count] ; i++) {
      [tempArray addObject:[MONTHTABLE objectAtIndex:[[rows objectAtIndex:i] intValue]]];
    }
  }
  [pboard declareTypes:[NSArray arrayWithObjects:@"Conto rows", nil] owner:self];
  if ([pboard setPropertyList:tempArray forType:@"Conto rows"]) {
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
 // if (tableView == [info draggingSource]) {
    if (operation == NSTableViewDropAbove) {
      return NSDragOperationAll;
    }
  //}
  return NSDragOperationNone;
}

- (BOOL)tableView:(NSTableView*)tableView acceptDrop:(id <NSDraggingInfo>)info
                                          row:(NSInteger)row
                                          dropOperation:(NSTableViewDropOperation)operation {
  NSInteger i, index;
  NSMutableArray *tempArray;

  if (tableView == [info draggingSource]) { // Dragging within the same table
    if ([tableView numberOfRows] < 2)
      return NO; // It doesn't make sense to drag one single item
    if ([tableView numberOfSelectedRows] == [tableView numberOfRows])
      return NO; // It doesn't make sense to drag the whole table over itself
    tempArray =[[NSMutableArray alloc] init];
    if ([rowsToBeDragged count] > 0 && row != -1 && row <= [[self table] numberOfRows]) {
      // Remove all dragged elements from the table.
      // Some care must be put in the way we delete items,
      // because we must keep the right poNSInteger where to insert the dragged items
      // (and the user may be dragging multiple non-adjacent items,
      // the user may be dragging from a filtered table, and so on...)
      for (i = [rowsToBeDragged count] - 1; i >= 0 ; i--) {
        index = [[rowsToBeDragged objectAtIndex:i] intValue];
        if (isFilterOn)
          [tempArray addObject:[[[self document] filteredRecords] objectAtIndex:index]];
        else
          [tempArray addObject:[MONTHTABLE objectAtIndex:index]];
        [[self document] removeRecordIdenticalTo:[tempArray lastObject]
                                        forMonth:CurrentMonth];
        if (index < row) {
          row--;
        }
      }
      // Determine the position where to insert the dragged items when a filter is active
      // Note that, if there are n records, then there are n+1 possible positions
      if (isFilterOn) {
        if (row == [[[self document] filteredRecords] count]) {
          // After last position in a nonempty array
          row = [MONTHTABLE indexOfObject:[[[self document] filteredRecords] objectAtIndex:(row-1)]];
          row++;
        }
        else {
          row = [MONTHTABLE indexOfObject:[[[self document] filteredRecords] objectAtIndex:row]];
        }
      }

      // Insert items sequentially at the new position
      for (i = 0; i < [tempArray count]; i++) {
        [[self document] insertRecord:[tempArray objectAtIndex:i] atIndex:row
                             forMonth:CurrentMonth];
      }
      [[[self document] undoManager] setActionName:
        NSLocalizedString(@"Drag Record(s)", @"Name of undo/redo menu item after dragging record(s)")];
      [rowsToBeDragged release];
      [tempArray release];
      return YES;
    }
  }
  else { // The user is dragging rows from a different document
    if (row != -1 && row <= [[self table] numberOfRows]) {
      // Insert elements sequentially at the new position
      // We insert the elements from the pasteboard
      tempArray = [[info draggingPasteboard] propertyListForType:@"Conto rows"];
      // Determine the position where to insert the dragged items when a filter is active
      // Note that, if there are n records, then there are n+1 possible positions
      if (isFilterOn) {
        if (row == [[[self document] filteredRecords] count]) { // After last position in the array
          if (row == 0) // The filtered array is empty. Append the elements
            row = [MONTHTABLE count];
          else {
            row = [MONTHTABLE indexOfObject:[[[self document] filteredRecords] objectAtIndex:(row-1)]];
            row++;
          }
        }
        else {
          row = [MONTHTABLE indexOfObject:[[[self document] filteredRecords] objectAtIndex:row]];
        }
      }

      for (i = [tempArray count] - 1; i >= 0  ; i--) {
        [[self document] insertRecord:[tempArray objectAtIndex:i] atIndex:row forMonth:CurrentMonth];
      }
      [rowsToBeDragged release];
      //[[self table] reloadData];
      [[[self document] undoManager] setActionName:
        NSLocalizedString(@"Drag Record(s)", @"Name of undo/redo menu item after dragging record(s)")];
      return YES;
    }
  }
  return NO;
}


// Notification methods
- (void)updateSums:(NSNotification *)notification {
  double newIncome;
  double newExpense;

  if (isFilterOn) { // Show sums of filtered records only
    newIncome = [[self document] incomeOfFilteredRecords];
    newExpense = [[self document] expenseOfFilteredRecords];
  }
  else { // Show total incomes and expenses for current month
    newIncome = [[self document]  incomeForMonth:CurrentMonth];
    newExpense = [[self document] expenseForMonth:CurrentMonth];
  }
  [[self incomeField]  setDoubleValue:newIncome];
  [[self incomeField] setNeedsDisplay];
  [[self expenseField] setDoubleValue:newExpense];
  [[self expenseField] setNeedsDisplay];
  [[self monthlyBalanceField] setDoubleValue:(newIncome - newExpense)];
  [[self monthlyBalanceField] setNeedsDisplay];
  [[self balanceField] setDoubleValue:[[self document] balanceForMonth:CurrentMonth]];
  [[self balanceField] setNeedsDisplay];
}

// Delegate methods
// Undo management
- (NSUndoManager *)windowWillReturnUndoManager:(NSWindow *)window {
  return [[self document] undoManager];
}

// Delegate methods for TableView

- (BOOL)tableView:(NSTableView *)aTableView shouldEditTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex {
  [[self monthPopUpMenu] setEnabled:NO];
  return YES;
}

/*
- (void)tableView:(NSTableView*)tableView didClickTableColumn:(NSTableColumn *)tableColumn {
  NSInteger row;

  row = [[self table] clickedRow];
}
*/

// Use this for sorting according to selected column
//- (BOOL)tableView:(NSTableView *)aTableView shouldSelectTableColumn:(NSTableColumn *)aTableColumn {
- (void)tableView:(NSTableView*)tableView mouseDownInHeaderOfTableColumn:(NSTableColumn *)aTableColumn {
  NSString *field = [aTableColumn identifier];

  /*
  if (isFilterOn)
    return;
  */
  [[self document] sortRecordsField:field forMonth:CurrentMonth];
  if ([field isEqual:@"Date"])
    [[[self document] undoManager] setActionName:
      NSLocalizedString(@"Sort by Date", @"Name of undo/redo menu item after sorting by date")];
  else if ([field isEqual:@"Description"])
    [[[self document] undoManager] setActionName:
      NSLocalizedString(@"Sort by Description", @"Name of undo/redo menu item after sorting by description")];
  else if ([field isEqual:@"Check"])
    [[[self document] undoManager] setActionName:
      NSLocalizedString(@"Sort by Tick Off", @"Name of undo/redo menu item after sorting by tick off")];
  else if ([field isEqual:@"Income"])
    [[[self document] undoManager] setActionName:
      NSLocalizedString(@"Sort by Income", @"Name of undo/redo menu item after sorting by income")];
  else if ([field isEqual:@"Expense"])
    [[[self document] undoManager] setActionName:
      NSLocalizedString(@"Sort by Expense", @"Name of undo/redo menu item after sorting by expense")];
  else // This path should never be taken
    [[[self document] undoManager] setActionName:
      NSLocalizedString(@"Sort", @"Name of undo/redo menu item after sorting")];
  
 // return YES;
}

// Combo box methods (this class is the data source of the NSComboBox)
- (NSInteger)numberOfItemsInComboBox:(NSComboBox *)aComboBox {
  return [[[CXPreferencesController sharedPreferencesController] descriptions] count];
}

- (id)comboBox:(NSComboBox *)aComboBox objectValueForItemAtIndex:(NSInteger)index {
  NSArray *predefinedDescriptions;
  predefinedDescriptions = [[CXPreferencesController sharedPreferencesController] descriptions];
  return [[predefinedDescriptions objectAtIndex:index] objectForKey:CXDefaultDescriptionKey];
}


// The following method is automatically registered (see NSControl documentation) 
- (void)controlTextDidEndEditing:(NSNotification *)aNotification {
  if (![[aNotification object] isEqual:[self searchTextField]])
    [[self monthPopUpMenu] setEnabled:YES];
}

// This class is the delegate of the search text field.
- (void)controlTextDidChange:(NSNotification *)aNotification {
  if ([[aNotification object] isEqual:[self searchTextField]]) {
    [[self document] setFilter:[[self searchTextField] stringValue]];
    [self filterDescriptions];
  }
}

// Key down events
- (void)keyDown:(NSEvent *)theEvent {
  if ([theEvent keyCode] == 51) { // Delete key
    if ([[self table] numberOfSelectedRows] > 0)
      [self deleteRecords:nil];
  }
  else
    [super keyDown:theEvent];
}

/*
// Delegate methods for TextFields
- (void)control:(NSControl *)control didFailToValidatePartialString:(NSString *)string errorDescription:(NSString *)error {
  [[self addButton] setEnabled:NO];
}


- (BOOL)control:(NSControl *)control textShouldEndEditing:(NSText *)fieldEditor {
  if ([[fieldEditor string] length] == 0) {
    return NO;
  }
  else
    return YES;
}
*/

/*
- (void)doubleClickOnUneditableCell {
}
*/

@end
