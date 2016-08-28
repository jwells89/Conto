//
//  CXPreferencesController.h
//  Conto
//
//  Created by Nicola on Sun Apr 22 2002.
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

#import "CXPreferencesController.h"
#import "globals.h"

#define Prefs [NSUserDefaults standardUserDefaults]

static id sharedInstance = nil; // There is only one instance of this class. We keep a reference to it here.

@implementation CXPreferencesController

+ (id)sharedPreferencesController {
  if (!sharedInstance) {
    sharedInstance = [[CXPreferencesController alloc] init];
  }
  return sharedInstance;
}

- (id)init {
  self = [self initWithWindowNibName:@"CXPreferences"];
  if (self) {
    [self setWindowFrameAutosaveName:@"Prefs Window"];
    numberFormatter = [[NSNumberFormatter alloc] init];
    percentFormatter = [[NSNumberFormatter alloc] init];
    dateFormatter = [[NSDateFormatter alloc] init];
    //[self setNumberFormatterFromPrefs];
    //[self setDateFormatterFromPrefs];
    [self setDescriptions:[Prefs arrayForKey:CXDescriptionsArrayKey]];
    if (nil == [self descriptions])
      descriptions = [[NSMutableArray alloc] initWithCapacity:1]; // Released in dealloc
  }  
  return self;
}

- (void)dealloc {
  [[self window] saveFrameUsingName:@"Prefs Window"];
  [numberFormatter release];
  [percentFormatter release];
  [dateFormatter release];
  [descriptions release];
  [super dealloc];
}

- (void)windowDidLoad {
  BOOL isEncryptionEnabled;
  NSEnumerator *enumerator;
  NSTableColumn *column;
  
  [super windowDidLoad];
  [[self window] setTitle:NSLocalizedString(@"Preferences", @"Title of Preferences window")];

  [[self window] setFrameUsingName:@"Prefs Window"];
  [[self descriptionsTableView] registerForDraggedTypes:[NSArray arrayWithObjects:@"Conto descriptions",nil]];

  [self updateRadioCluster:[self currencyPositionRadioCluster] setting:[Prefs integerForKey:CXCurrencyPositionKey]];
  [self updateRadioCluster:[self decimalSeparatorRadioCluster] setting:[Prefs integerForKey:CXDecimalSeparatorKey]];
  [self updateRadioCluster:[self dateFormatRadioCluster] setting:[Prefs integerForKey:CXDateFormatKey]];
  [self updateRadioCluster:[self fontRadioCluster] setting:[Prefs integerForKey:CXFontSizeKey]];
  [self updateCheckbox:[self thousandSeparatorCheckbox] setting:[Prefs boolForKey:CXThousandSeparatorKey]];
  [[self currencyTextField] setStringValue:[Prefs stringForKey:CXCurrencySymbolKey]];
  [[self decimalTextField] setIntegerValue:[Prefs integerForKey:CXNumberOfDecimalsKey]];
  // Synchronize the decimal stepper with the text field
  [[self decimalStepper] setIntegerValue:[Prefs integerForKey:CXNumberOfDecimalsKey]];
  [self updateCheckbox:[self gridCheckbox] setting:[Prefs boolForKey:CXGridKey]];
  // Encryption items
  isEncryptionEnabled = [Prefs boolForKey:CXUseEncryptionKey];
  [self updateCheckbox:[self encryptionCheckbox] setting:isEncryptionEnabled];
  [[self gpgPathTextField] setStringValue:[Prefs stringForKey:CXGpgPathKey]];
  [[self keyIDTextField] setStringValue:[Prefs stringForKey:CXKeyIDKey]];
  [[self gpgPathTextField] setEnabled:isEncryptionEnabled];
  [[self keyIDTextField] setEnabled:isEncryptionEnabled];
  // Set description table font
  enumerator =[[[self descriptionsTableView] tableColumns] objectEnumerator];
  while (column = [enumerator nextObject]) { // Ok, there is only one column, but let's be flexible!
    [[column dataCell] setFont:
      [NSFont systemFontOfSize:[NSFont smallSystemFontSize]]];
  }
  [[self descriptionsTableView] setRowHeight:(float)13.0];

  [self setNumberFormat:nil];
  [self updateCheckbox:[self autocompleteCheckbox] setting:[Prefs boolForKey:CXAutocompleteKey]];

  // Register notification observers
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(updateDescriptionsTableView:)
                                               name:CXDescriptionsTableChangedNotification
                                             object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(setNumberFormat:)
                                               name:CXNumberFormatChangedNotification
                                             object:nil];  
}

// Default preferences
- (void)registerDefaultPrefs {
  //NSMutableDictionary *predefinedDescription;
  NSMutableDictionary *defaultPrefs = [NSMutableDictionary dictionary];

  [defaultPrefs setObject:[NSNumber numberWithInt:(NSInteger)Smaller] forKey:CXFontSizeKey]; // Small system font
  [defaultPrefs setObject:[NSNumber numberWithInt:(NSInteger)After] forKey:CXCurrencyPositionKey]; // Currency symbol after number
  [defaultPrefs setObject:@" €" forKey:CXCurrencySymbolKey]; // Default currency is euro
  [defaultPrefs setObject:[NSNumber numberWithInt:2] forKey:CXNumberOfDecimalsKey]; // Two decimals 
  [defaultPrefs setObject:[NSNumber numberWithInt:0] forKey:CXDecimalSeparatorKey]; // Default is comma
  [defaultPrefs setObject:[NSNumber numberWithInt:(NSInteger)NSOnState] forKey:CXThousandSeparatorKey]; // Default is YES
  [defaultPrefs setObject:[NSNumber numberWithInt:0] forKey:CXDateFormatKey]; // Default is dd-mm-yy
  [defaultPrefs setObject:[NSNumber numberWithInt:(NSInteger)NSOffState] forKey:CXGridKey];
  [defaultPrefs setObject:[NSNumber numberWithInt:(NSInteger)NSOffState] forKey:CXUseEncryptionKey]; // Default is NO encryption
  [defaultPrefs setObject:@"/usr/local/bin" forKey:CXGpgPathKey]; // Default gpg path
  [defaultPrefs setObject:@"" forKey:CXKeyIDKey]; // Default key ID

  // Set default predefined descriptions
  //predefinedDescription = [NSMutableDictionary dictionaryWithCapacity:1];
  //[predefinedDescription setObject:@"Prelevamento" forKey:CXDefaultDescriptionKey];
  //[descriptions addObject:predefinedDescription];
  //[defaultPrefs setObject:[NSArray arrayWithObject:predefinedDescription] forKey:CXDescriptionsArrayKey];

  [defaultPrefs setObject:[NSNumber numberWithInt:(NSInteger)NSOnState] forKey:CXAutocompleteKey]; // Default is autocomplete
  // Register the dictionary of defaults
  [Prefs registerDefaults:defaultPrefs];
  //[Prefs synchronize];
}

// Accessor methods
// General
- (NSMatrix *)currencyPositionRadioCluster {
  return currencyPositionRadioCluster;
}

- (NSTextField *)currencyTextField {
  return currencyTextField;
}

- (NSMatrix *)decimalSeparatorRadioCluster {
  return decimalSeparatorRadioCluster;
}

- (NSStepper *)decimalStepper {
  return decimalStepper;
}

- (NSTextField *)decimalTextField {
  return decimalTextField;
}

- (NSMatrix *)fontRadioCluster {
  return fontRadioCluster;
}

- (NSButton *)thousandSeparatorCheckbox {
  return thousandSeparatorCheckbox;
}

- (NSMatrix *)dateFormatRadioCluster {
  return dateFormatRadioCluster;
}

- (NSButton *)gridCheckbox {
  return gridCheckbox;
}

// Encryption
- (NSButton *)encryptionCheckbox {
  return encryptionCheckbox;
}

- (NSTextField *)gpgPathTextField {
  return gpgPathTextField;
}

- (NSTextField *)keyIDTextField {
  return keyIDTextField;
}

// Descriptions
- (NSTableView *)descriptionsTableView {
  return descriptionsTableView;
}

- (NSTextField *)descriptionTextField {
  return descriptionTextField;
}

- (NSTextField *)incomeOpTextField {
  return incomeOpTextField;
}

- (NSTextField *)expenseOpTextField {
  return expenseOpTextField;
}

- (NSPopUpButton *)incomeOperationButton {
  return incomeOperationButton;
}

- (NSPopUpButton *)expenseOperationButton {
  return expenseOperationButton;
}

- (NSButton *)addButton {
  return addButton;
}

- (NSButton *)removeButton {
  return removeButton;
}

- (NSButton *)autocompleteCheckbox {
  return autocompleteCheckbox;
}

- (NSNumberFormatter *)numberFormatter {
  return numberFormatter;
}

- (NSNumberFormatter *)percentFormatter {
  return percentFormatter;
}

- (NSDateFormatter *)dateFormatter {
  return dateFormatter;
}

/*
- (void)setNumberFormatter:(NSNumberFormatter *)newFormatter {  
}
*/

 - (NSMutableArray *)descriptions {
  return descriptions;
}

- (void)setDescriptions:(NSArray *)descr {
  if ([descriptions isEqual:descr])
    return;
  else {
    [descriptions release];
    descriptions = [[NSMutableArray arrayWithArray:descr] retain];
  }
}

- (void)setNumberFormatterFromPrefs {
  NSMutableDictionary *newAttrs = [NSMutableDictionary dictionary];
  NSMutableString *formatString = [[NSMutableString alloc] init];
  NSMutableString *percentFormatString;
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

  percentFormatString = [NSMutableString stringWithString:formatString];
  // Add percent symbol
  [percentFormatString appendString:@"%"];
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
  [[self numberFormatter] setFormat:formatString];
  [[self percentFormatter] setFormat:percentFormatString];
  [newAttrs setObject:[NSColor redColor] forKey:@"NSColor"];
  [[self numberFormatter] setTextAttributesForNegativeValues:newAttrs];
  [[self percentFormatter] setTextAttributesForNegativeValues:newAttrs];
  //[[self numberFormatter] setAttributedStringForNotANumber:[[[NSAttributedString alloc] initWithString:@""] autorelease]];
  // Set decimal separator
  [[self numberFormatter] setDecimalSeparator:decimalSeparator];
  [[self percentFormatter] setDecimalSeparator:decimalSeparator];
  // Set thousand separator
  if (hasThousandSeparator) {
    [[self numberFormatter] setThousandSeparator:thousandSeparator];
    [[self percentFormatter] setThousandSeparator:thousandSeparator];
  }
  else { // No thousand separators
    [[self numberFormatter] setHasThousandSeparators:NO];
    [[self percentFormatter] setHasThousandSeparators:NO];
  //[[self numberFormatter] setThousandSeparator:@"."];
  //[[self numberFormatter] setDecimalSeparator:@","];
  }
  [[self numberFormatter] setAttributedStringForNotANumber:[[[NSAttributedString alloc] initWithString:@""] autorelease]];
  [[self percentFormatter] setAttributedStringForNotANumber:[[[NSAttributedString alloc] initWithString:@""] autorelease]];

  [formatString release];
  formatString = nil;
}

- (void)setDateFormatterFromPrefs {
  [[self dateFormatter] release];
  dateFormatter = nil;

  switch ((CXDateFormat)[Prefs integerForKey:CXDateFormatKey]) {
    case DDMMYY:
      dateFormatter = [[NSDateFormatter alloc] initWithDateFormat:@"%d-%m-%y" allowNaturalLanguage:NO];
      break;
    case DDMMYYWithSlash:
      dateFormatter = [[NSDateFormatter alloc] initWithDateFormat:@"%d/%m/%y" allowNaturalLanguage:NO];
      break;
    case DDMM:
      dateFormatter = [[NSDateFormatter alloc] initWithDateFormat:@"%d-%m" allowNaturalLanguage:NO];
      break;
    case DDMMWithSlash:
      dateFormatter = [[NSDateFormatter alloc] initWithDateFormat:@"%d/%m" allowNaturalLanguage:NO];
      break;
    case DDMonthYear:
      dateFormatter = [[NSDateFormatter alloc] initWithDateFormat:@"%d %B %Y" allowNaturalLanguage:NO];
      break;
    case DDMonYear:
      dateFormatter = [[NSDateFormatter alloc] initWithDateFormat:@"%d %b %Y" allowNaturalLanguage:NO];
      break;
    case DDMonth:
      dateFormatter = [[NSDateFormatter alloc] initWithDateFormat:@"%d %B" allowNaturalLanguage:NO];
      break;
    case DDMon:
      dateFormatter = [[NSDateFormatter alloc] initWithDateFormat:@"%d %b" allowNaturalLanguage:NO];
      break;
    default:
      dateFormatter = [[NSDateFormatter alloc] initWithDateFormat:@"%d-%m-%y" allowNaturalLanguage:NO];
      break;
  }
}

// Action methods
// General
- (IBAction)currencyPositionAction:(id)sender {
  [Prefs setInteger:[[[self currencyPositionRadioCluster] selectedCell] tag] forKey:CXCurrencyPositionKey];
  [self setNumberFormatterFromPrefs];
  [[NSNotificationCenter defaultCenter] postNotificationName:CXNumberFormatChangedNotification object:self];
}

- (IBAction)currencySymbolAction:(id)sender {
  [Prefs setObject:[[self currencyTextField] stringValue] forKey:CXCurrencySymbolKey];
  [self setNumberFormatterFromPrefs];
  [[NSNotificationCenter defaultCenter] postNotificationName:CXNumberFormatChangedNotification object:self];  
}

- (IBAction)decimalSeparatorAction:(id)sender {
  [Prefs setInteger:[[[self decimalSeparatorRadioCluster] selectedCell] tag] forKey:CXDecimalSeparatorKey];
  [self setNumberFormatterFromPrefs];
  [[NSNotificationCenter defaultCenter] postNotificationName:CXNumberFormatChangedNotification object:self];
}

- (IBAction)fontSizeAction:(id)sender {
  [Prefs setInteger:[[[self fontRadioCluster] selectedCell] tag] forKey:CXFontSizeKey];
  [[NSNotificationCenter defaultCenter] postNotificationName:CXFontSizeChangedNotification object:self];
}

- (IBAction)numberOfDecimalsAction:(id)sender {
  [[self decimalTextField] setIntValue:[sender intValue]];
  [Prefs setInteger:[sender intValue] forKey:CXNumberOfDecimalsKey];
  [self setNumberFormatterFromPrefs];
  [[NSNotificationCenter defaultCenter] postNotificationName:CXNumberFormatChangedNotification object:self];
}

- (IBAction)thousandSeparatorAction:(id)sender {
  [Prefs setBool:([[self thousandSeparatorCheckbox] state] == NSOnState) forKey:CXThousandSeparatorKey];
  [self setNumberFormatterFromPrefs];
  [[NSNotificationCenter defaultCenter] postNotificationName:CXNumberFormatChangedNotification object:self];
}

- (IBAction)dateFormatAction:(id)sender {
  [Prefs setInteger:[[[self dateFormatRadioCluster] selectedCell] tag] forKey:CXDateFormatKey];
  [self setDateFormatterFromPrefs];
  [[NSNotificationCenter defaultCenter] postNotificationName:CXDateFormatChangedNotification object:self];  
}

- (IBAction)gridAction:(id)sender {
  [Prefs setBool:([[self gridCheckbox] state] == NSOnState) forKey:CXGridKey];
  [[NSNotificationCenter defaultCenter] postNotificationName:CXGridChangedNotification object:self];  
}


// Encryption
- (IBAction)useEncryptionAction:(id)sender {
  BOOL isEncryptionEnabled = ([[self encryptionCheckbox] state] == NSOnState);
  [Prefs setBool:isEncryptionEnabled forKey:CXUseEncryptionKey];
  // Enable/disable subsidiary items
  [[self gpgPathTextField] setEnabled:isEncryptionEnabled];
  [[self keyIDTextField] setEnabled:isEncryptionEnabled];
}

- (IBAction)gpgPathAction:(id)sender {
  [Prefs setObject:[[self gpgPathTextField] stringValue] forKey:CXGpgPathKey];
}

- (IBAction)keyIDAction:(id)sender{
  [Prefs setObject:[[self keyIDTextField] stringValue] forKey:CXKeyIDKey];
}

// Descriptions
- (IBAction)addDescriptionAction:(id)sender {
  NSInteger inOp = [[self incomeOperationButton] indexOfSelectedItem];
  NSInteger outOp = [[self expenseOperationButton] indexOfSelectedItem];
  NSMutableDictionary *newDescription = [NSMutableDictionary dictionaryWithCapacity:5]; // Autoreleased

  [newDescription setObject:[[self descriptionTextField] stringValue] forKey:CXDefaultDescriptionKey];
  if (inOp != NoOperation) {
    [newDescription setObject:[NSNumber numberWithInteger:inOp] forKey:CXIncomeOperationKey];
    if ((nil == [[self incomeOpTextField] objectValue]) ||
        ([[[self incomeOpTextField] objectValue] isEqual:[NSDecimalNumber notANumber]])) {
      [[self incomeOpTextField] setObjectValue:[NSDecimalNumber zero]];
    }
    [newDescription setObject:[[self incomeOpTextField] objectValue] forKey:CXIncomeOpValueKey];
  }
  if (outOp != NoOperation) {
    [newDescription setObject:[NSNumber numberWithInteger:outOp] forKey:CXExpenseOperationKey];
    if ((nil == [[self expenseOpTextField] objectValue]) ||
        ([[[self expenseOpTextField] objectValue] isEqual:[NSDecimalNumber notANumber]])) {
      [[self expenseOpTextField] setObjectValue:[NSDecimalNumber zero]];
    }
    [newDescription setObject:[[self expenseOpTextField] objectValue] forKey:CXExpenseOpValueKey];
  }
  [[self descriptions] addObject:newDescription];

  [[self descriptionTextField] setStringValue:@""];
  [[self incomeOpTextField] setStringValue:@""];
  [[self expenseOpTextField] setStringValue:@""];
  // Notify
  [[NSNotificationCenter defaultCenter] postNotificationName:CXDescriptionsTableChangedNotification
                                                      object:self];
}

- (IBAction)removeDescriptionAction:(id)sender {
  [descriptions removeObjectAtIndex:[[self descriptionsTableView] selectedRow]];
  if ([descriptions count] == 0) // No descriptions, let's clean user defaults
    [Prefs removeObjectForKey:CXDescriptionsArrayKey];
  else
    [Prefs setObject:descriptions forKey:CXDescriptionsArrayKey];

  // Notify
  [[NSNotificationCenter defaultCenter] postNotificationName:CXDescriptionsTableChangedNotification
                                                      object:self];
}

- (IBAction)incomeOperationPopUpAction:(id)sender {
  [[self incomeOpTextField] setEnabled:([sender indexOfSelectedItem] != NoOperation)];
  [self setNumberFormat:nil];
  if ([sender indexOfSelectedItem] == NoOperation)
    [[self incomeOpTextField] setStringValue:@""];
}

- (IBAction)expenseOperationPopUpAction:(id)sender {
  [[self expenseOpTextField] setEnabled:([sender indexOfSelectedItem] != NoOperation)];
  [self setNumberFormat:nil];
  if ([sender indexOfSelectedItem] == NoOperation)
    [[self expenseOpTextField] setStringValue:@""];

}

- (IBAction)autocompleteAction:(id)sender {
  BOOL autocompletionEnabled = ([[self autocompleteCheckbox] state] == NSOnState);
  [Prefs setBool:autocompletionEnabled forKey:CXAutocompleteKey];
  [[NSNotificationCenter defaultCenter] postNotificationName:CXAutocompletionChangedNotification object:self];
}




// Generic view updaters
- (void)updateCheckbox:(NSButton *)control setting:(BOOL)value {
  if (value != [control state]) {
    [control setState:(value ? NSOnState : NSOffState)];
  }
}

- (void)updateRadioCluster:(NSMatrix *)control setting:(NSInteger)value {
  if (value != [[control selectedCell] tag]) {
    [control selectCellWithTag:value];
  }
}

// Notifications
- (void)updateDescriptionsTableView:(NSNotification *)notification {
  [Prefs setObject:descriptions forKey:CXDescriptionsArrayKey];
  [[self descriptionsTableView] reloadData];
}

- (void)setNumberFormat:(NSNotification *)notification {
  CXOperationType inOp, outOp;
  
  inOp = [[self incomeOperationButton] indexOfSelectedItem];
  outOp = [[self expenseOperationButton] indexOfSelectedItem];

  // Detach formatters
  [[[self incomeOpTextField] cell] setFormatter:nil];
  [[[self expenseOpTextField] cell] setFormatter:nil];
  // Set new formatters
  if (inOp == AddPercent || inOp == SubtractPercent)
    [[[self incomeOpTextField] cell] setFormatter:[self percentFormatter]];
  else
    [[[self incomeOpTextField] cell] setFormatter:[self numberFormatter]];
  if (outOp == AddPercent || outOp == SubtractPercent)
    [[[self expenseOpTextField] cell] setFormatter:[self percentFormatter]];
  else
    [[[self expenseOpTextField] cell] setFormatter:[self numberFormatter]];

  /*
  if (![[[self incomeOpTextField] cell] hasValidObjectValue])
    [[self incomeOpTextField] setStringValue:@""];
  if (![[[self expenseOpTextField] cell] hasValidObjectValue])
    [[self expenseOpTextField] setStringValue:@""];
  */
}


// Table view methods (this class is the data source of the Descriptions TableView)
- (NSInteger)numberOfRowsInTableView:(NSTableView *)descriptionsTableView {
  if (nil == descriptions)
    return 0;
  else
    return [descriptions count];
}

- (id)tableView:(NSTableView *)descriptionsTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex {
  id theValue;

  NSParameterAssert(rowIndex >= 0 && rowIndex < [descriptions count]);
  theValue = [[descriptions objectAtIndex:rowIndex] objectForKey:CXDefaultDescriptionKey];
  if (theValue == nil)
    theValue = @"Boh!";
  return theValue;
  
}

- (void)tableView:(NSTableView *)descriptionsTableView setObjectValue:(id)anObject
   forTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex {
}

// This class is the delegate of the Descriptions TableView, so it is automatically
// registered to receive NSTableViewSelectionDidChangeNotification.
- (void)tableViewSelectionDidChange:(NSNotification *)aNotification {
  NSInteger row = [[self descriptionsTableView] selectedRow];
  [[self removeButton] setEnabled:(row > -1)]; // Enable Remove button if a selection is active
  if (row > -1 && row < [[self descriptions] count]) {
    [[self descriptionTextField] setStringValue:
      [[descriptions objectAtIndex:row] objectForKey:CXDefaultDescriptionKey]];
    [[self incomeOperationButton] selectItemAtIndex:
      [[[descriptions objectAtIndex:row] objectForKey:CXIncomeOperationKey] intValue]];
    [[self expenseOperationButton] selectItemAtIndex:
      [[[descriptions objectAtIndex:row] objectForKey:CXExpenseOperationKey] intValue]];
    [[self incomeOpTextField] setEnabled:([[self incomeOperationButton] indexOfSelectedItem] != NoOperation)];
    [[self expenseOpTextField] setEnabled:([[self expenseOperationButton] indexOfSelectedItem] != NoOperation)];
    [self setNumberFormat:nil];
    [[self incomeOpTextField] setObjectValue:
      [[descriptions objectAtIndex:row] objectForKey:CXIncomeOpValueKey]];
    [[self expenseOpTextField] setObjectValue:
      [[descriptions objectAtIndex:row] objectForKey:CXExpenseOpValueKey]];
  }
}

// Drag and drop in Descriptions Table
- (BOOL)tableView:(NSTableView *)tableView writeRows:(NSArray*)rows toPasteboard:(NSPasteboard*)pboard {
  [pboard declareTypes:[NSArray arrayWithObjects:@"Conto descriptions", nil] owner:self];
  if ([pboard setPropertyList:rows forType:@"Conto descriptions"])
    return YES;
  else
    return NO;
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
  NSArray *rows;

  if (tableView == [info draggingSource]) { // Dragging within the same table (superfluous check, btw)
    tempArray =[[NSMutableArray alloc] init];
    rows = [[info draggingPasteboard] propertyListForType:@"Conto descriptions"];
    if ([rows count] > 0 && row != -1 && row <= [[self descriptions] count]) {
      // Remove all dragged elements from the table and put them in a temporary array
      // (Ok, in this case the user can select one row at a time, but the following
      // code works even with multiple non-contiguous selections!)
      for (i = [rows count] - 1; i >= 0 ; i--) {
        index = [[rows objectAtIndex:i] intValue];
        [tempArray addObject:[[self descriptions] objectAtIndex:index]];
        [[self descriptions] removeObjectAtIndex:index];
        if (index < row) {
          row--;
        }
      }
      // Insert elements sequentially at the new position
      for (i = 0; i < [rows count] ; i++) {
        [[self descriptions] insertObject:[tempArray objectAtIndex:i] atIndex:row];
      }
      // Notify change
      [[NSNotificationCenter defaultCenter] postNotificationName:CXDescriptionsTableChangedNotification
                                                          object:self];
      [tempArray release];
      return YES;
    }
  }
  return NO;
}


// This class is the delegate of the Descriptions TextField, so it is automatically
// registered to receive NSControlTextDidChangeNotification's.
- (void)controlTextDidChange:(NSNotification *)aNotification {
  [[self addButton] setEnabled:([[[self descriptionTextField] stringValue] length] > 0)];
}

@end