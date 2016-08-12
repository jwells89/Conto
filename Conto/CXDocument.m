//
//  CXDocument.m
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

#import "CXDocument.h"
#import "CXMainWindowController.h"
#import "CXSummaryController.h"
#import "CXGraphWindowController.h"
#import "globals.h"

// Take care with the following functions! They *assume* that the parameters are correctly typed!
// In particular, they don't check if parameters respond to used selectors.
// 'context' is used to pass the column identifier.
// This function is used to order the table wrt the Date column
int compareRecordsBasedOnDate(id obj1, id obj2, void *context) {
  NSDate *date1;
  NSDate *date2;

  date1 = [obj1 objectForKey:(NSString *)context];
  date2 = [obj2 objectForKey:(NSString *)context];
  return [date1 compare:date2];
}

// This function is used to order the table wrt a column containing NSString's
int compareRecordsBasedOnString(id obj1, id obj2, void *context) {
  NSString *string1;
  NSString *string2;

  string1 = [NSString stringWithString:[obj1 objectForKey:(NSString *)context]];
  string2 = [NSString stringWithString:[obj2 objectForKey:(NSString *)context]];
  if (([string1 length] == 0) && ([string2 length] != 0))
    return NSOrderedDescending; // We want empty strings go to the end
  else if (([string2 length] == 0) && ([string1 length] != 0))
    return NSOrderedAscending;
  else if (([string1 length] == 0) && ([string2 length] == 0)) // Both string are empty
    return NSOrderedSame; // So, the relative order is not changed
  else
    return [string1 caseInsensitiveCompare:string2];
}

// This function is used to order the table wrt a column containing numbers (Income or Expense)
int compareRecordsBasedOnNumber(id obj1, id obj2, void *context) {
  double num1;
  double num2;
  if ([[obj1 objectForKey:(NSString *)context] isKindOfClass:[NSString class]]) // Empty cell
    num1 = -1; // Any negative value will do, since Incomes and Expenses are always non-negative
  else // Well, it is (it should be!) a valid number
    num1 = [[obj1 objectForKey:(NSString *)context] doubleValue];

  if ([[obj2 objectForKey:(NSString *)context] isKindOfClass:[NSString class]]) // Empty cell
    num2 = -1; // The same as before, so two empty cells are not swapped (we return NSOrderedSame)
  else
    num2 = [[obj2 objectForKey:(NSString *)context] doubleValue];
  // Go with the comparison!
  if ((num1 >= 0) && (num2 >= 0)) { // Two valid numbers
    if (num1 < num2)
      return NSOrderedAscending;
    else if (num1 > num2)
      return NSOrderedDescending;
    else
      return NSOrderedSame;
  }
  else if ((num1 < 0) && (num2 >= 0)) // At least one is an empty cell
    return NSOrderedDescending; // We want empty cells go to the end.
  else if ((num1 >= 0) && (num2 < 0))
    return NSOrderedAscending;
  else // Both empty cells
    return NSOrderedSame;
}

#define Prefs   [NSUserDefaults standardUserDefaults]

@implementation CXDocument

// Initialization and deallocation
- (id)init {
  if ([super init]) {
    [[self undoManager] disableUndoRegistration];
    [self initializeAccountData];
    [self setCurrentMonth:January];
    [self setTransactionType:Income];
    [self setTickOff:NSOffState];
    [self setLogo:nil];
    accountInfo = [[NSMutableArray alloc] initWithCapacity:1]; // Released in dealloc
    filteredRecords = [[NSMutableArray alloc] initWithCapacity:1]; // Released in dealloc
    filter = [[NSString alloc] initWithString:@""];
    [[self undoManager] enableUndoRegistration];

    /*
    // Register to receive data from gpg task
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(gpgOutputAvailable:)
                                                 name:NSFileHandleReadCompletionNotification
                                               object:nil];
    */
    /*
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(checkGpgTaskStatus:)
                                                 name:NSTaskDidTerminateNotification
                                               object:nil];
     */
  }
  return self;
}

- (void)initializeAccountData {
  CXMonth m;
  int k;
  NSMutableArray *records;
  NSMutableArray *tempArray = [[NSMutableArray alloc] initWithCapacity:12];
  
  // Create one empty array for each month
  for (m=January;m<=December;m++) {
    records = [[NSMutableArray alloc] init];
    [tempArray addObject:records];
    [records release];
    records = nil;
  }
  accountData = [NSArray arrayWithArray:tempArray];
  // Since accountData has been created with a convenience constructor,
  // we assume it is autoreleased. But we want to keep it, so we must
  // send it a retain message. The object is released in dealloc.
  [accountData retain];
  [tempArray release];
  tempArray = nil;
  
  for (k=January;k<=LastOfYear;k++) {
    income[k] = 0.0;
    expense[k] = 0.0;
    balance[k] = 0.0;
  }
  lastMonthWithEntries = NoMonth;
}

- (void)dealloc {
  [accountData release];
  [accountInfo release];
  [filteredRecords release];
  [filter release];
  //[encryptedData release];
  [super dealloc];
}

// About implementing undo and redo (I cite, with small variations, from Vermont Recipes):
// It normally makes sense to register a change to a document's data in a so-called "primitive" method
// which performs the operation by directly altering an instance variable. Every other method that invokes the primitive
// method will thereby gain the benefit of Cocoa's undo and redo support.
// Every operation that changes the value of the variable should do so through this primitive method, except that
// initialization operations should not be undoable and therefore require special attention.

// Accessor methods
- (NSArray *)accountData {
  return accountData;
}

- (void)setAccountData:(NSArray *)data {
  CXMonth month;
  for (month=January;month<=December;month++) {
    [[[self accountData] objectAtIndex:month] setArray:[data objectAtIndex:month]];
  }
}

- (CXMonth)lastMonthWithEntries {
  return lastMonthWithEntries;
}

- (void)setLastMonthWithEntries:(CXMonth)aMonth {
  if (aMonth == CurrentMonth) {
    aMonth = [self currentMonth];
  }
  lastMonthWithEntries = aMonth;
}

- (CXMonth)currentMonth {
  return currentMonth;
}

- (void)setCurrentMonth:(CXMonth)aMonth {
  if ((aMonth == [self currentMonth]) || (aMonth == CurrentMonth) || (aMonth == NoMonth) || (aMonth == LastOfYear)) {
    return;
  }
  else {
    [[[self undoManager] prepareWithInvocationTarget:self] setCurrentMonth:currentMonth];
    currentMonth = aMonth;
    [self filterDescriptionsInMonth:currentMonth];

    // Post notification to update GUI
    [[NSNotificationCenter defaultCenter] postNotificationName:CXMonthChangedNotification
                                                        object:self];
  }
}


- (CXTransactionType)transactionType {
  return transactionType;
}

- (void)setTransactionType:(CXTransactionType)transaction {
  [[[self undoManager] prepareWithInvocationTarget:self] setTransactionType:transactionType];

  transactionType = transaction;

  // Post notification to update GUI
  [[NSNotificationCenter defaultCenter] postNotificationName:CXTransactionTypeChangedNotification
                                                      object:self];  
}

- (BOOL)tickOff {
  return tickOff;
}

- (void)setTickOff:(BOOL)value {
  [[[self undoManager] prepareWithInvocationTarget:self] setTickOff:tickOff];
  tickOff = value;

  [[NSNotificationCenter defaultCenter] postNotificationName:CXTickOffStateChangedNotification
                                                      object:self];
}

- (NSImage *)logo {
  return logo;
}

- (void)setLogo:(NSImage *)image {
  [[[self  undoManager] prepareWithInvocationTarget:self] setLogo:logo];
  [image retain];
  [logo release];
  logo = image;
  // Post notification to update GUI
  [[NSNotificationCenter defaultCenter] postNotificationName:CXLogoChangedNotification
                                                      object:self];  
}

- (NSMutableArray *)accountInfo {
  return accountInfo;
}

- (void)setAccountInfo:(NSMutableArray *)info {
   // Notice that some care must be put in the following assignment!
   // I quote (with small variations) from the article
   // "Very simple rules for memory management in Cocoa" which can be found at www.stepwise.com:
   // "If everyone else is playing by the same rules,
   // we have to assume 'info' is autoreleased.
   // Since we want to keep it, we have to make sure
   // it won't go away by sending a retain here.
   //[info retain];

   // Since we only alter the object that accountInfo points
   // to via this method, we can balance the retain above
   // with a call to release the current object here.
   // [nil release] is allowed in Objective-C, so this
   // will still work if accountInfo hasn't been set yet.
   // We must send this after [info retain] in case
   // the two are the same object -- we don't want to
   // inadvertently deallocate it.
   //[accountInfo release];

   // make the new assignment
   //accountInfo = info;
  if ([accountInfo isEqual:info])
    return;
  else {
    [accountInfo release];
    accountInfo = [[NSMutableArray arrayWithArray:info] retain];
  }
}

- (NSSecureTextField *)passphraseTextField {
  return passphraseTextField;
}

- (NSMutableArray *)filteredRecords {
  return filteredRecords;
}

- (NSString *)filter {
  return filter;
}

- (void)setFilter:(NSString *)newFilter {
  if ([filter isEqualToString:newFilter])
    return;
  else {
    [filter release];
    filter = [[NSString alloc] initWithString:newFilter];
  }
}

// Managing data
/*
- (void)addRecord:(NSMutableDictionary *)record forMonth:(CXMonth)aMonth {
  if ((aMonth == CurrentMonth) || (aMonth == NoMonth)) {
    aMonth = [self currentMonth];
  }
  [[[self undoManager] prepareWithInvocationTarget:self] removeRecordAtIndex:[[self getRecordsForMonth:aMonth] count] forMonth:aMonth];
  [[[self accountData] objectAtIndex:aMonth] addObject:record];
  // Update sums and balances
  [self addValueToIncome:[[record objectForKey:@"Income"] doubleValue] forMonth:aMonth];
  [self addValueToExpense:[[record objectForKey:@"Expense"] doubleValue] forMonth:aMonth];
  if ([self lastMonthWithEntries] < aMonth)
    [self setLastMonthWithEntries:aMonth];
  [self updateBalances];

  // Post notification to update GUI
  [[NSNotificationCenter defaultCenter] postNotificationName:CXValueInTableChangedNotification
                                                      object:self];  
}
*/

- (void)insertRecord:(NSMutableDictionary *)record atIndex:(unsigned)index forMonth:(CXMonth)aMonth {
  if ((aMonth == CurrentMonth) || (aMonth == NoMonth)) {
    aMonth = [self currentMonth];
  }
  if (index>=0 && index <= [[self getRecordsForMonth:aMonth] count]) {
    //[[[self undoManager] prepareWithInvocationTarget:self] removeRecordAtIndex:index forMonth:aMonth];
    [[[self undoManager] prepareWithInvocationTarget:self]
                         removeRecordIdenticalTo:record forMonth:aMonth];
    [[[self accountData] objectAtIndex:aMonth] insertObject:record atIndex:index];
    // Update sums and balances
    [self addValueToIncome:[[record objectForKey:@"Income"] doubleValue] forMonth:aMonth];
    [self addValueToExpense:[[record objectForKey:@"Expense"] doubleValue] forMonth:aMonth];
    if ([self lastMonthWithEntries] < aMonth)
      [self setLastMonthWithEntries:aMonth];
    [self updateBalances];

    /*
    if (![[self filter] isEqualToString:@""]) { // Some filter is active
      if ([[record objectForKey:@"Description"] rangeOfString:[self filter]].location != NSNotFound) {
        // This description contains the filter string
        [self insertFilteredRecord:record atIndex:[[self filteredRecords] count]];
      }
    }
    */
    [self filterDescriptionsInMonth:aMonth]; // Not very efficient, but doing like that
                                             // I don't have to bother with undo/redo subtleties
    // Post notification to update GUI
    [[NSNotificationCenter defaultCenter] postNotificationName:CXValueInTableChangedNotification
                                                        object:self];
    [[NSNotificationCenter defaultCenter] postNotificationName:CXTableChangedNotification
                                                        object:self];
  }
}


- (NSMutableArray *)getRecordsForMonth:(CXMonth)aMonth {
  if ((aMonth == CurrentMonth) || (aMonth == NoMonth)) {
    aMonth = [self currentMonth];
  }
  return [[self accountData] objectAtIndex:aMonth];
}


- (BOOL)modifyField:(id)columnIdentifier ofRecord:(NSMutableDictionary *)theRecord
           forMonth:(CXMonth)aMonth newValue:(id)anObject {
  id oldObject;
  
  if (nil != theRecord) {
    oldObject = [theRecord objectForKey:columnIdentifier];
    if (anObject == nil)
      anObject = @"";
    if ([columnIdentifier isEqualToString:@"Date"]) {
      if ([anObject compare:oldObject] == NSOrderedSame) // Replacing with same date
        return NO;
    }
    else if ([anObject isEqual:oldObject])
      return NO;

    // We are going to send a setObject:forKey message to theRecord.
    // This will cause a release message to be sent to the old object
    // => oldObject will be hanging if we do not retain it!
    [oldObject retain];
    [[[self undoManager] prepareWithInvocationTarget:self] modifyField:columnIdentifier
                                                              ofRecord:theRecord
                                                                   forMonth:aMonth
                                                                   newValue:oldObject];
    // Set new object
    // This changes both the account data array and the filtered records array,
    // because they store the same object
    [theRecord setObject:anObject forKey:columnIdentifier];

    if ([columnIdentifier isEqual:@"Income"]) {
      [self addValueToIncome:(-[oldObject doubleValue]) forMonth:aMonth]; // Subtract old value
      [self addValueToIncome:[anObject doubleValue] forMonth:aMonth]; // Add new value
      [self updateBalances];
      [[NSNotificationCenter defaultCenter] postNotificationName:CXValueInTableChangedNotification
                                                          object:self];
    }
    else if ([columnIdentifier isEqual:@"Expense"]) {
      [self addValueToExpense:(-[oldObject doubleValue]) forMonth:aMonth]; // Subtract old value
      [self addValueToExpense:[anObject doubleValue] forMonth:aMonth]; // Add new value
      [self updateBalances];
      [[NSNotificationCenter defaultCenter] postNotificationName:CXValueInTableChangedNotification
                                                          object:self];
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:CXTableChangedNotification
                                                        object:self];
    [oldObject release];
    oldObject = nil;
    return YES;
  }
  return NO;
}



// Deprecated since v1.2.0
// Returns NO if no change has been done (because anObject equals oldObject)
- (BOOL)modifyFieldAtRow:(unsigned)row column:(id)columnIdentifier forMonth:(CXMonth)aMonth newValue:(id)anObject {
  id theRecord, oldObject;

  theRecord = nil;
  if ((aMonth == CurrentMonth) || (aMonth == NoMonth)) {
    aMonth = [self currentMonth];
  }

  if ([[self filter] isEqualToString:@""]) {
    if (row >= 0 && row < [[self getRecordsForMonth:aMonth] count]) {
      theRecord = [[self getRecordsForMonth:aMonth] objectAtIndex:row];
    }
  }
  else {
    if (row >= 0 && row < [[self filteredRecords] count]) {
      theRecord = [[self filteredRecords] objectAtIndex:row];
    }
  }
  if (nil != theRecord) {
    oldObject = [theRecord objectForKey:columnIdentifier];
    if (anObject == nil)
      anObject = @"";
    if ([columnIdentifier isEqualToString:@"Date"]) {
      if ([anObject compare:oldObject] == NSOrderedSame) // Replacing with same date
        return NO;
    }
    /*
    if ([columnIdentifier isEqualToString:@"Income"]) {
      theValue = [anObject doubleValue];
      // Apply operation, if any
      newValue = [self applyOperation:[[theRecord objectForKey:CXIncomeOperationKey] intValue]
                            withValue:[[theRecord objectForKey:CXIncomeOpValueKey] doubleValue]
                             toAmount:theValue];
      anObject = [NSDecimalNumber numberWithDouble:newValue];
      if ([anObject isEqual:oldObject])
        return NO;
    }
    else if ([columnIdentifier isEqualToString:@"Expense"]) {
      theValue = [anObject doubleValue];
      // Apply operation, if any
      newValue = [self applyOperation:[[theRecord objectForKey:CXExpenseOperationKey] intValue]
                            withValue:[[theRecord objectForKey:CXExpenseOpValueKey] doubleValue]
                             toAmount:theValue];
      anObject = [NSDecimalNumber numberWithDouble:newValue];
      if ([anObject isEqual:oldObject])
        return NO;
    }
    */
    else if ([anObject isEqual:oldObject])
      return NO;

    // We are going to send a setObject:forKey message to theRecord.
    // This will cause a release message to be sent to the old object
    // => oldObject will be hanging if we do not retain it!
    [oldObject retain];
    [[[self undoManager] prepareWithInvocationTarget:self] modifyFieldAtRow:row
                                                                     column:columnIdentifier
                                                                   forMonth:aMonth
                                                                   newValue:oldObject];
    // Set new object
    [theRecord setObject:anObject forKey:columnIdentifier];
      
    if ([columnIdentifier isEqual:@"Income"]) {
      [self addValueToIncome:(-[oldObject doubleValue]) forMonth:aMonth]; // Subtract old value
      [self addValueToIncome:[anObject doubleValue] forMonth:aMonth]; // Add new value
      [self updateBalances];
      [[NSNotificationCenter defaultCenter] postNotificationName:CXValueInTableChangedNotification
                                                          object:self];
    }
    else if ([columnIdentifier isEqual:@"Expense"]) {
      [self addValueToExpense:(-[oldObject doubleValue]) forMonth:aMonth]; // Subtract old value
      [self addValueToExpense:[anObject doubleValue] forMonth:aMonth]; // Add new value
      [self updateBalances];
      [[NSNotificationCenter defaultCenter] postNotificationName:CXValueInTableChangedNotification
                                                          object:self];
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:CXTableChangedNotification
                                                        object:self];
    [oldObject release];
    oldObject = nil;
    return YES;
  }
  return NO;
}

/*
// Multiple record deletion.
// We pass an enumeration of NSNumbers containing the indices of the records to be removed
// Note: it would be better to implement some bound check...
// KNOWN BUG: If two or more rows in the array are equal this method will remove them all,
// regardless of what has been selected.
// A better implementation would probably to make use of removeObjectsFromIndices:numIndices:
// I will use it as soon as I understand what Apple's documentation means with "the first parameter
// points to the first in a list of indices".
- (void) removeRecordsWithIndices:(NSEnumerator *)indices forMonth:(CXMonth)aMonth {
  //NSMutableArray *tempArray = [NSMutableArray array]; // Convenience constructor => autoreleased
  NSDictionary *tempRecord;
  NSNumber *index;
  unsigned int list[10]; // ABSOLUTELY UNSAFE! TO BE CHANGED! THIS CONSTRAINTS THE MAX NUMBERS OF SELECTED ITEMS TO ELEVEN!
  unsigned int i;
  CXMonth m;
  
  if ((aMonth == CurrentMonth) || (aMonth == NoMonth)) {
    aMonth = [self currentMonth];
  }
  i = 0;
  while ((index = [indices nextObject])) {
    tempRecord = [[[self accountData] objectAtIndex:aMonth] objectAtIndex:[index intValue]];
    //[tempArray addObject:tempRecord]; // keep track of the record to delete in tempArray
    
    list[i] = [index unsignedIntValue];
    i++;
    // Update incomes, expenses (if a field is empty, then doubleValue returns 0.0)
    [self addValueToIncome:(-[[tempRecord objectForKey:@"Income"] doubleValue]) forMonth:aMonth]; // Subtract from Income
    [self addValueToExpense:(-[[tempRecord objectForKey:@"Expense"] doubleValue]) forMonth:aMonth]; // Subtract from Expense
  }
  // Perform deletion
  //[[[self accountData] objectAtIndex:aMonth] removeObjectsInArray:tempArray]; // All removed at a time
  [[[self accountData] objectAtIndex:aMonth] removeObjectsFromIndices:list numIndices:i];
  // Check whether this month's array has become empty. If so, and if this was last month with entries,
  // we must update lastMonthWithEntries.
  if (([[[self accountData] objectAtIndex:aMonth] count] == 0) && (aMonth == [self lastMonthWithEntries])) {
    // Look backwards for new last month with entries
    m = aMonth;
    while ((m >= January) && ([[[self accountData] objectAtIndex:m] count] == 0))
      m--; // If the table is empty, at the end we get m == -1 == NoMonth;
    [self setLastMonthWithEntries:m];
  }
  [self updateBalances];
}
*/

- (void)removeRecordIdenticalTo:(NSMutableDictionary *)aRecord forMonth:(CXMonth)aMonth {
  CXMonth m;
  unsigned int index;
  
  if ((aMonth == CurrentMonth) || (aMonth == NoMonth) || (aMonth == LastOfYear)) {
    aMonth = [self currentMonth];
  }
  // We assume that there is only one record "identical to" (=with the same address as)
  // aRecord
  [self addValueToIncome:(-[[aRecord objectForKey:@"Income"] doubleValue]) forMonth:aMonth]; // Subtract from Income
  [self addValueToExpense:(-[[aRecord objectForKey:@"Expense"] doubleValue]) forMonth:aMonth]; // Subtract from Expense
  [aRecord retain];
  index = [[self getRecordsForMonth:aMonth] indexOfObject:aRecord];
  [[self getRecordsForMonth:aMonth] removeObjectIdenticalTo:aRecord];
  [[[self undoManager] prepareWithInvocationTarget:self] insertRecord:aRecord atIndex:index forMonth:aMonth];
  [aRecord release];
  // Check whether this month's array has become empty. If so, and if this was last month with entries,
  // we must update lastMonthWithEntries.
  if (([[[self accountData] objectAtIndex:aMonth] count] == 0) && (aMonth == [self lastMonthWithEntries])) {
    // Look backwards for new last month with entries
    m = aMonth;
    while ((m >= January) && ([[[self accountData] objectAtIndex:m] count] == 0))
      m--; // If the table is empty, at the end we get m == -1 == NoMonth;
    [self setLastMonthWithEntries:m];
  }
  [self updateBalances];

  /*
  if (![[self filter] isEqualToString:@""])
    [self removeFilteredRecordIdenticalTo:aRecord];
  */
  [self filterDescriptionsInMonth:aMonth];
  
  // Post notification to update GUI
  [[NSNotificationCenter defaultCenter] postNotificationName:CXValueInTableChangedNotification
                                                      object:self];
  [[NSNotificationCenter defaultCenter] postNotificationName:CXTableChangedNotification
                                                      object:self];
  
}

// The following method is deprecated from v1.2.0
- (void) removeRecordAtIndex:(unsigned)index forMonth:(CXMonth)aMonth {
  NSMutableDictionary *tempRecord;
  CXMonth m;
  
  if ((aMonth == CurrentMonth) || (aMonth == NoMonth) || (aMonth == LastOfYear)) {
    aMonth = [self currentMonth];
  }
  tempRecord = [[[self accountData] objectAtIndex:aMonth] objectAtIndex:index];
  // Update incomes, expenses (if a field is empty, then doubleValue returns 0.0)
  [self addValueToIncome:(-[[tempRecord objectForKey:@"Income"] doubleValue]) forMonth:aMonth]; // Subtract from Income
  [self addValueToExpense:(-[[tempRecord objectForKey:@"Expense"] doubleValue]) forMonth:aMonth]; // Subtract from Expense
  [tempRecord retain];
  // Perform deletion
  [[[self accountData] objectAtIndex:aMonth] removeObjectAtIndex:index];
  [[[self undoManager] prepareWithInvocationTarget:self] insertRecord:tempRecord atIndex:index forMonth:aMonth];
  [tempRecord release];
  // Check whether this month's array has become empty. If so, and if this was last month with entries,
  // we must update lastMonthWithEntries.
  if (([[[self accountData] objectAtIndex:aMonth] count] == 0) && (aMonth == [self lastMonthWithEntries])) {
    // Look backwards for new last month with entries
    m = aMonth;
    while ((m >= January) && ([[[self accountData] objectAtIndex:m] count] == 0))
      m--; // If the table is empty, at the end we get m == -1 == NoMonth;
    [self setLastMonthWithEntries:m];
  }
  [self updateBalances];

  // Post notification to update GUI
  [[NSNotificationCenter defaultCenter] postNotificationName:CXValueInTableChangedNotification
                                                      object:self];
  [[NSNotificationCenter defaultCenter] postNotificationName:CXTableChangedNotification
                                                      object:self];  
}

- (void)moveRecord:(NSMutableDictionary *)record toIndex:(unsigned)newIndex forMonth:(CXMonth)aMonth {
  unsigned int oldIndex;

  //oldIndex = [[self getRecordsForMonth:aMonth] indexOfObject:record];
 // [[[self undoManager] prepareWithInvocationTarget:self] moveRecord:record toIndex:oldIndex forMonth:aMonth];

  [self removeRecordIdenticalTo:record forMonth:aMonth];
  [self insertRecord:record atIndex:newIndex forMonth:aMonth];
  /*
  // Perform deletion
  [[[self getRecordsForMonth:aMonth] removeObjectAtIndex:index];
  // Insert object at new index
  [[[self getRecordsForMonth:aMonth] insertObject:tempRecord atIndex:newIndex];
  */
    // Post notification to update GUI
  //[[NSNotificationCenter defaultCenter] postNotificationName:CXTableChangedNotification object:self];
}


// Deprecated since v1.2.0
- (void)moveRecordFromIndex:(unsigned)index toIndex:(unsigned)newIndex forMonth:(CXMonth)aMonth {
  NSMutableDictionary *tempRecord;

  if ((aMonth == CurrentMonth) || (aMonth == NoMonth) || (aMonth == LastOfYear)) {
    aMonth = [self currentMonth];
  }
  tempRecord = [[[self accountData] objectAtIndex:aMonth] objectAtIndex:index];
  [tempRecord retain];
  [[[self undoManager] prepareWithInvocationTarget:self] moveRecordFromIndex:newIndex toIndex:index forMonth:aMonth];
  // Perform deletion
  [[[self accountData] objectAtIndex:aMonth] removeObjectAtIndex:index];
  // Insert object at new index
  [[[self accountData] objectAtIndex:aMonth] insertObject:tempRecord atIndex:newIndex];
  [tempRecord release];
  // Post notification to update GUI
  [[NSNotificationCenter defaultCenter] postNotificationName:CXTableChangedNotification
                                                      object:self];  
}



- (void)sortRecordsField:(id)fieldIdentifier forMonth:(CXMonth)aMonth {
  NSArray *sortedArray;
  NSArray *oldArray;

  if ((aMonth == CurrentMonth) || (aMonth == NoMonth) || (aMonth == LastOfYear)) {
    aMonth = [self currentMonth];
  }

  oldArray = [NSArray arrayWithArray:[self getRecordsForMonth:aMonth]];
  
  if ([fieldIdentifier isEqual:@"Date"]) {
    sortedArray = [[self getRecordsForMonth:aMonth]
                                  sortedArrayUsingFunction:compareRecordsBasedOnDate
                                                   context:(void *)fieldIdentifier];
  }
  else if ([fieldIdentifier isEqual:@"Description"] || [fieldIdentifier isEqual:@"Check"]) {
    sortedArray = [[self getRecordsForMonth:aMonth]
                                  sortedArrayUsingFunction:compareRecordsBasedOnString
                                                   context:(void *)fieldIdentifier];
  }
  else { // It is Income or Expenses column
    sortedArray = [[self getRecordsForMonth:aMonth]
                                  sortedArrayUsingFunction:compareRecordsBasedOnNumber context:(void *)fieldIdentifier];
  }
  [[[self undoManager] prepareWithInvocationTarget:self] unsort:oldArray field:fieldIdentifier forMonth:aMonth];
  [[self getRecordsForMonth:aMonth] setArray:sortedArray];
  [self filterDescriptionsInMonth:aMonth];

  [[NSNotificationCenter defaultCenter] postNotificationName:CXTableChangedNotification
                                                      object:self];  
}

// Set back old array
- (void)unsort:(NSArray *)oldArray field:(id)fieldIdentifier forMonth:(CXMonth)aMonth {
  if ((aMonth == CurrentMonth) || (aMonth == NoMonth)) {
    aMonth = [self currentMonth];
  }
  [[[self undoManager] prepareWithInvocationTarget:self] sortRecordsField:fieldIdentifier forMonth:aMonth];
  [[self getRecordsForMonth:aMonth] setArray:oldArray];
  [self filterDescriptionsInMonth:aMonth];
  
  [[NSNotificationCenter defaultCenter] postNotificationName:CXTableChangedNotification
                                                      object:self];
}

- (void)insertInfo:(NSMutableDictionary *)info atIndex:(unsigned)index {
  [[[self undoManager] prepareWithInvocationTarget:self] removeInfoAtIndex:index];
  [[self accountInfo] insertObject:info atIndex:index];
  // Post notification to update GUI
  [[NSNotificationCenter defaultCenter] postNotificationName:CXInfoTableChangedNotification
                                                      object:self];
  
}

- (void)removeInfoAtIndex:(unsigned)index {
  NSMutableDictionary *tempInfo;

  tempInfo = [[self accountInfo] objectAtIndex:index];
  [tempInfo retain];
  // Perform deletion
  [[self accountInfo] removeObjectAtIndex:index];
  [[[self undoManager] prepareWithInvocationTarget:self] insertInfo:tempInfo atIndex:index];
  [tempInfo release];
  // Post notification to update GUI
  [[NSNotificationCenter defaultCenter] postNotificationName:CXInfoTableChangedNotification
                                                      object:self];
}

- (void)modifyInfoAtRow:(unsigned)row column:(id)columnIdentifier newValue:(id)anObject {
  id oldObject;

  oldObject = [[[self accountInfo] objectAtIndex:row] objectForKey:columnIdentifier];
  if (anObject == nil)
    anObject = @"";

  [oldObject retain];
  [[[self undoManager] prepareWithInvocationTarget:self] modifyInfoAtRow:row
                                                                  column:columnIdentifier
                                                                newValue:oldObject];
  // Set new object
  [[[self accountInfo] objectAtIndex:row] setObject:anObject forKey:columnIdentifier];
  // Post notification to update GUI
  [[NSNotificationCenter defaultCenter] postNotificationName:CXInfoTableChangedNotification
                                                      object:self];
}


- (double)incomeForMonth:(CXMonth)aMonth {
  if ((aMonth == CurrentMonth) || (aMonth == NoMonth)) {
    aMonth = [self currentMonth];
  }
  return income[aMonth];
}

- (void)addValueToIncome:(double)value forMonth:(CXMonth)aMonth {
  if ((aMonth == CurrentMonth) || (aMonth == NoMonth)) {
    aMonth = [self currentMonth];
  }
  (income[aMonth]) += value;
  if (aMonth != LastOfYear)
    (income[LastOfYear]) += value;
}

- (double)expenseForMonth:(CXMonth)aMonth {
  if ((aMonth == CurrentMonth) || (aMonth == NoMonth)) {
    aMonth = [self currentMonth];
  }
  return expense[aMonth];
}

- (void)addValueToExpense:(double)value forMonth:(CXMonth)aMonth {
  if ((aMonth == CurrentMonth) || (aMonth == NoMonth)) {
    aMonth = [self currentMonth];
  }
  (expense[aMonth]) += value;
  if (aMonth != LastOfYear)
    (expense[LastOfYear]) += value;
}

- (double)balanceForMonth:(CXMonth)aMonth {
  if ((aMonth == CurrentMonth) || (aMonth == NoMonth)) {
    aMonth = [self currentMonth];
  }
  return balance[aMonth];
}

- (void) updateBalances {
  CXMonth k;
  if ([self lastMonthWithEntries] == NoMonth) {
    for (k=January;k<=LastOfYear;k++) {
      income[k] = 0.0;
      expense[k] = 0.0;
      balance[k] = 0.0;
    }
  }
  else {
    balance[January] = income[January] - expense[January];
    for (k=February;k<=[self lastMonthWithEntries];k++) {
      balance[k] = balance[k-1] + income[k] - expense[k];
    }
    for (k=[self lastMonthWithEntries]+1;k<=December;k++) {
      income[k] = 0.0;
      expense[k] = 0.0;
      balance[k] = 0.0;
    }
    balance[LastOfYear] = income[LastOfYear] - expense[LastOfYear];
  }
}

- (double)getSumValueForKey:(id)key month:(CXMonth)aMonth {
  if (aMonth == CurrentMonth || aMonth == NoMonth)
    aMonth = [self currentMonth];
  if ([key isEqual:@"Income"])
    return income[aMonth];
  else if ([key isEqual:@"Expense"])
    return expense[aMonth];
  else if ([key isEqual:@"Balance"])
    return balance[aMonth];
  else // What?!?
    return 0.0;
}

// Apply an operation to the value
- (double)applyOperation:(CXOperationType)operation withValue:(double)value toAmount:(double)theAmount {
  switch (operation) {
    case NoOperation:
      return theAmount;
    case Add:
      return theAmount + value;
    case Subtract:
      return theAmount - value;
    case Multiply:
      return theAmount * value;
    case Divide:
      if (value != 0.0)
        return theAmount / value;
      else
        return theAmount;
    case AddPercent:
      return theAmount * value / 100 + theAmount;
    case SubtractPercent:
      return theAmount - (theAmount * value / 100);
    default:
      return theAmount;
  }
}

- (double)applyInverseOperation:(CXOperationType)operation withValue:(double)value toAmount:(double)theAmount {
  switch (operation) {
    case NoOperation:
      return theAmount;
    case Add:
      return theAmount - value;
    case Subtract:
      return theAmount + value;
    case Multiply:
      if (value != 0.0)
        return theAmount / value;
      else
        return theAmount;
    case Divide:
      if (value != 0.0)
        return theAmount * value;
      else
        return theAmount;
    case AddPercent:
      return theAmount * 100.0 / (value + 100.0);
    case SubtractPercent:
      return theAmount * 100.0 / (100.0 - value);
    default:
      return theAmount;
  }  
}

// Returns the maximum value of monthly incomes, expenses and balances.
// (used to draw a graph proportionally)
- (double)getMaximumValue { 
  double max = 0.0;
  CXMonth month;

  for (month=January;month<=December;month++) {
    if (income[month] > max)
      max = income[month];
    if (expense[month] > max)
      max = expense[month];
    if (balance[month] > max)
      max = balance[month];
  }
  return max;
}
// Returns the minimum value. This is the most negative monthly balance,
// or zero if all balances are positive.
// (used to draw a graph proportionally)
- (double)getMinimumValue {
  double min = 0.0;
  CXMonth month;

  for (month=January;month<=December;month++)
    if (balance[month] < min)
      min = balance[month];
  return min;
}


- (void)filterDescriptionsInMonth:(CXMonth)month {
  unsigned int i;
  unsigned int capacity;
  NSArray *records;
  
  if (![[self filter] isEqualToString:@""]) {
    // Find records containing filter
    [filteredRecords release]; // Trash old items
    // Alloc new array with enough room
    records = [self getRecordsForMonth:month];
    capacity = [records count];
    filteredRecords = [[NSMutableArray alloc] initWithCapacity:capacity];
    // Add to this array all the records whose Description field contains the filter
    for (i = 0; i < capacity; i++) {
      if ([[[records objectAtIndex:i] objectForKey:@"Description"]
                                      rangeOfString:[self filter]
                                            options:NSCaseInsensitiveSearch].location != NSNotFound)
      { // found!
        [filteredRecords addObject:[records objectAtIndex:i]];
      }
    }
  }
  // Update the table
  [[NSNotificationCenter defaultCenter] postNotificationName:CXValueInTableChangedNotification
                                                      object:self];
  [[NSNotificationCenter defaultCenter] postNotificationName:CXTableChangedNotification
                                                      object:self];
}

- (double)incomeOfFilteredRecords {
  double filteredIncome;
  unsigned int i, max;

  filteredIncome = 0.0;
  max = [[self filteredRecords] count];
  for (i = 0; i < max; i++) {
    filteredIncome += [[[[self filteredRecords] objectAtIndex:i] objectForKey:@"Income"] doubleValue];
  }
  return filteredIncome;
}

- (double)expenseOfFilteredRecords {
  double filteredExpense;
  unsigned int i, max;

  filteredExpense = 0.0;
  max = [[self filteredRecords] count];
  for (i = 0; i < max; i++) {
    filteredExpense += [[[[self filteredRecords] objectAtIndex:i] objectForKey:@"Expense"] doubleValue];
  }
  return filteredExpense;
}

// The following two methods are not used.
// There is the following problem: suppose the active filter is 'A'
// and there are three records with decription 'AB'.
// Suppose I delete the three records while the filter is 'A'.
// Then, I change the filter into 'AB' and undo the deletion.
// I get an out of bounds error because I try to insert the old three records
// into an empty array (the filtered array is empty because, before undoing, there were
// no records containing, in the description, 'AB').
// I should make some check, but I don't feel like doing it now, so I leave it for some
// future moment...
// The underlying problem is that there is an action - namely changing the filter string -
// for which I do not provide an undo facility. So, when the user undoes some action,
// there is no guarantee that the filtered records array is the same as when the user
// did the action.
// On the other hand, adding an undo when the filter changes
// seems a bit of overloading...
- (void)insertFilteredRecord:(NSMutableDictionary *)record atIndex:(unsigned)index {
  if (![[self filter] isEqualToString:@""]) { // Some filter is active
    if ([[record objectForKey:@"Description"]
                  rangeOfString:[self filter]
                        options:NSCaseInsensitiveSearch].location != NSNotFound) {
      // This description contains the filter string
      [[[self undoManager] prepareWithInvocationTarget:self] removeFilteredRecordIdenticalTo:record];
      [[self filteredRecords] insertObject:record atIndex:index];
    }
  }  
}

- (void)removeFilteredRecordIdenticalTo:(NSMutableDictionary *)record {
  unsigned int index = [[self filteredRecords] indexOfObject:record];
  if (index != NSNotFound) {
    [[[self undoManager] prepareWithInvocationTarget:self] insertFilteredRecord:record atIndex:index];
    [[self filteredRecords] removeObjectIdenticalTo:record];
  }
}


- (void)triggerTickOffForRecord:(NSMutableDictionary *)record {
  [[[self undoManager] prepareWithInvocationTarget:self] triggerTickOffForRecord:record];
  [record setObject:([[record objectForKey:@"Check"] isEqualToString:@""] ? @"Ã" : @"") forKey:@"Check"];
  // Post notification to update GUI
  [[NSNotificationCenter defaultCenter] postNotificationName:CXTableChangedNotification
                                                      object:self];
  
}

// Deprecated since 1.2.0
-(void)triggerTickOffAtIndex:(int)row {
  id theRecord;
  if ([[self filter] isEqualToString:@""])
    theRecord = [[self getRecordsForMonth:CurrentMonth] objectAtIndex:row];
  else
    theRecord = [[self filteredRecords] objectAtIndex:row];
  [[[self undoManager] prepareWithInvocationTarget:self] triggerTickOffAtIndex:row];
  [theRecord setObject:([[theRecord objectForKey:@"Check"] isEqualToString:@""] ? @"Ã" : @"") forKey:@"Check"];
  // Post notification to update GUI
  [[NSNotificationCenter defaultCenter] postNotificationName:CXTableChangedNotification
                                                      object:self];
}

- (void)printView:(NSView *)theView {
  NSPrintInfo *thePrintInfo = [self printInfo];
  [thePrintInfo setHorizontalPagination: NSFitPagination];
  [thePrintInfo setVerticallyCentered:NO];
  [[NSPrintOperation printOperationWithView:theView printInfo:[self printInfo]] runOperation];
}

  
//- (NSString *)windowNibName
//{
//    // Override returning the nib file name of the document
//    // If you need to use a subclass of NSWindowController or if your document supports multiple NSWindowControllers, you should remove this method and override -makeWindowControllers instead.
//    return @"CXDocument";
//}

-(void)makeWindowControllers {
  CXMainWindowController *controller;

  // We create only the main window controller.
  // The other are created and added to the document only when needed
  controller = [[CXMainWindowController allocWithZone:[self zone]] init];
  [self addWindowController:controller];
  [controller release];
}

- (IBAction)showSummaryWindow:(id)sender {
  CXSummaryController *controller;
  NSEnumerator *enumerator;
  id obj;

  // Check whether the controller is already instantiated 
  enumerator = [[self windowControllers] objectEnumerator];
  while (obj = [enumerator nextObject]) {
    if ([obj isMemberOfClass:[CXSummaryController class]]) {
      [[obj window] makeKeyAndOrderFront:self];
      return;
    }
  }
  // Instantiate the controller and add it to the document's controllers list
  controller = [[CXSummaryController allocWithZone:[self zone]] init];
  [self addWindowController:controller];
  [controller showWindow:self];
  [controller release];
}

- (IBAction)showGraphWindow:(id)sender {
  CXGraphWindowController *controller;
  NSEnumerator *enumerator;
  id obj;

  // Check whether the controller is already instantiated
  enumerator = [[self windowControllers] objectEnumerator];
  while (obj = [enumerator nextObject]) {
    if ([obj isMemberOfClass:[CXGraphWindowController class]]) {
      [[obj window] makeKeyAndOrderFront:self];
      return;
    }
  }
  // Instantiate the controller and add it to the document's controllers list
  controller = [[CXGraphWindowController allocWithZone:[self zone]] init];
  [self addWindowController:controller];
  [controller showWindow:self];
  [controller release];
}


- (void)windowControllerDidLoadNib:(NSWindowController *) aController
{
    [super windowControllerDidLoadNib:aController];
    // Add any code here that need to be executed once the windowController has loaded the document's window.
}

// Keys and values for dictionary
NSString *CXDocumentType = @"Conto Document Type";
static NSString *CXDocumentClassKey = @"Class";
static NSString *CXDocumentVersionKey = @"Version";
static int currentCXDocumentVersion = 1;
static NSString *CXAccountDataKey = @"Account Data";
static NSString *CXIncomeDataKey = @"Incomes";
static NSString *CXExpenseDataKey = @"Expenses";
//static NSString *CXBalanceDataKey = @"Balances";
static NSString *CXLastMonthKey = @"Last Month";
static NSString *CXCurrentMonthKey = @"Current Month";
static NSString *CXTransactionTypeKey = @"Transaction Type";
static NSString *CXTickOffKey = @"Tick Off";
static NSString *CXLogoKey = @"Logo";
static NSString *CXAccountInfoKey = @"Account Info";
static NSString *CXEncryptedData = @"Encrypted Data";
// The following key is used when no encryption is applied,
// to archive the dictionary. The reason why we do not save
// the dictionary directly is that writeToFile:atomically:
// seems to break keys using NSNumbers
static NSString *CXArchivedData = @"Archived Data";

// Saving data to persistent storage (a la Vermont Recipes, Recipe 4, step 1 :))
- (BOOL)writeToFile:(NSString *)fileName ofType:(NSString *)type {
  NSData *data;
  NSData *encryptedData;
  NSDictionary *encryptedDictionary;
  NSDictionary *archivedDictionary;
  
  if ([type isEqualToString:CXDocumentType]) {
    [[self undoManager] removeAllActions];
    /*
    data = [NSPropertyListSerialization dataFromPropertyList:[self setupDictionaryFromMemory]
                                                         format:NSPropertyListXMLFormat_v1_0
                                               errorDescription:&error];
    if(xmlData)
    {
      NSLog(@"No error creating XML data.");
      [data writeToFile:path atomically:YES];
      return YES;
    }
    else
    {
      NSLog(error);
      [error release];
      return NO;
    }
    */
    
    // Archive data for storage
    data = [NSArchiver archivedDataWithRootObject:[self setupDictionaryFromMemory]];
    if ([Prefs boolForKey:CXUseEncryptionKey]) {
      // Encrypt data
      encryptedData = [self encryptWithGpg:data];
      if (encryptedData) {
        // Create a dictionary with a single object (the ciphered data) and the corresponding key
        encryptedDictionary = [NSDictionary dictionaryWithObject:encryptedData forKey:CXEncryptedData];
        // Save
        return [encryptedDictionary writeToFile:fileName atomically:YES];
      }
      else
        return NO;
    }
    else { // No encryption. Save data directly
      archivedDictionary = [NSDictionary dictionaryWithObject:data forKey:CXArchivedData];
      return [archivedDictionary writeToFile:fileName atomically:YES];
    }
  }
  else {
    return NO;
  }
}


/*
- (NSData *)dataRepresentationOfType:(NSString *)aType {
    // Insert code here to write your document from the given data.  You can also choose to override -fileWrapperRepresentationOfType: or -writeToFile:ofType: instead.
//    return nil;
  //return [[accountData description] dataUsingEncoding:NSUTF8StringEncoding];
  if ([aType isEqualToString:CXDocumentType]) {
    //[[self undoManager] removeAllActions];
    return [self convertForStorage];
  }
  else {
    return nil;
  }
}
*/
/*
- (NSData *)convertForStorage
{
    NSDictionary *dictionary = [self setupDictionaryFromMemory];
    NSString *string = [dictionary description];
    return [string dataUsingEncoding:NSUTF8StringEncoding];
}
*/

- (NSDictionary *)setupDictionaryFromMemory
{
  CXMonth month;
  NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
  NSMutableArray *incomeArray = [NSMutableArray array];
  NSMutableArray *expenseArray = [NSMutableArray array];
  //NSData *incomeData;
  //NSMutableArray *balanceArray = [NSMutableArray array]; // Balances are computed on the fly
  
  // General identification information
  [dictionary setObject:NSStringFromClass([self class]) forKey:CXDocumentClassKey];
  [dictionary setObject:[NSString stringWithFormat:@"%d", currentCXDocumentVersion] forKey:CXDocumentVersionKey];
  // Data
  [dictionary setObject:[self accountData] forKey:CXAccountDataKey];
  // Incomes, expenses, balances
  for (month=January;month<=December;month++) {
    // We save these to avoid computing them on opening the file.
    // Instead, balances are computed on the fly.
    [incomeArray addObject:[NSNumber numberWithDouble:[self incomeForMonth:month]]];
    [expenseArray addObject:[NSNumber numberWithDouble:[self expenseForMonth:month]]];
    // An equivalent way of doing that:
    //[incomeArray addObject:[NSString stringWithFormat:@"%f",  [self incomeForMonth:month]]];
    //[expenseArray addObject:[NSString stringWithFormat:@"%f", [self expenseForMonth:month]]];
  }
  //
  //incomeData = [NSArchiver archivedDataWithRootObject:incomeArray];
  //[dictionary setObject:incomeData forKey:CXIncomeDataKey];
  //
  [dictionary setObject:incomeArray forKey:CXIncomeDataKey];
  [dictionary setObject:expenseArray forKey:CXExpenseDataKey];
  //[dictionary setObject:balanceArray forKey:CXBalanceDataKey];
  // Last month containing data
  //[dictionary setObject:[NSString stringWithFormat:@"%d", [self lastMonthWithEntries]] forKey:CXLastMonthKey];
  // We can save numbers as numbers...
  [dictionary setObject:[NSNumber numberWithInt:[self lastMonthWithEntries]] forKey:CXLastMonthKey];
  // ...as well as strings
  // Currently displayed month 
  [dictionary setObject:[NSString stringWithFormat:@"%d", [self currentMonth]] forKey:CXCurrentMonthKey];
  // Income/Expense radio cluster status
  [dictionary setObject:[NSString stringWithFormat:@"%d", [self transactionType]] forKey:CXTransactionTypeKey];
  // Tick off checkbox status
  [dictionary setObject:[NSString stringWithFormat:@"%d", [self tickOff]] forKey:CXTickOffKey];
  if ([self logo]) {
    [dictionary setObject:[[self logo] TIFFRepresentationUsingCompression:NSTIFFCompressionLZW
                                                                   factor:0.0] forKey:CXLogoKey];
  }
  [dictionary setObject:[self accountInfo] forKey:CXAccountInfoKey];
  
  return dictionary;
}
 

// Load data from persistent storage into memory (a la Vermont Recipes, Recipe 4, Step 1 :))
- (BOOL)readFromFile:(NSString *)fileName ofType:(NSString *)type {
  NSDictionary *dictionary = nil;
  NSDictionary *firstDictionary = nil;
  NSData *data = nil;
  NSData *encryptedData;
  NSString *passphrase;
  
  if ([type isEqualToString:CXDocumentType]) {
    firstDictionary = [NSDictionary dictionaryWithContentsOfFile:fileName];
    if (encryptedData = [firstDictionary objectForKey:CXEncryptedData]) { // File was encrypted
      while (!data) {
        // Get passphrase from user
        if (passphrase = [self getPassphrase])
          data = [self decryptWithGpg:encryptedData usingPassphrase:passphrase];
        else
          return NO;
      }
      if (data) {
        dictionary = [NSUnarchiver unarchiveObjectWithData:data];
        [self restoreFromStorage:dictionary];
        return (dictionary != nil);
      }
      else
        return NO;
    }
    else { // No encryption
      if (data = [firstDictionary objectForKey:CXArchivedData]) {
        dictionary = [NSUnarchiver unarchiveObjectWithData:data];
        [self restoreFromStorage:dictionary];
        return (dictionary != nil);
      }
      else { // This happens only with files saved with version < 1.1.1
        [self restoreFromStorage:firstDictionary];
        return (firstDictionary != nil);
      }
    }
  }
  else {
    return NO;
  }
}

- (void)restoreFromStorage:(NSDictionary *)dictionary {
  CXMonth month;
  NSArray *incomeArray;
  NSArray *expenseArray;
  //NSArray *balanceArray;
  
  if (dictionary) {
    [[self undoManager] disableUndoRegistration];
    [self setCurrentMonth:(CXMonth)[[dictionary objectForKey:CXCurrentMonthKey] intValue]];
    [self setTransactionType:(CXTransactionType)[[dictionary objectForKey:CXTransactionTypeKey] intValue]];
    [self setTickOff:(BOOL)[[dictionary objectForKey:CXTickOffKey] intValue]];
    [self setAccountData:[dictionary objectForKey:CXAccountDataKey]];
    [self setLastMonthWithEntries:[[dictionary objectForKey:CXLastMonthKey] intValue]];
    //
    //incomeArray = [NSUnarchiver unarchiveObjectWithData:[dictionary objectForKey:CXIncomeDataKey]];
    //
    incomeArray = [dictionary objectForKey:CXIncomeDataKey];
    expenseArray = [dictionary objectForKey:CXExpenseDataKey];
    //balanceArray = [dictionary objectForKey:CXBalanceDataKey];
    income[LastOfYear] = 0.0;
    expense[LastOfYear] = 0.0;
    for (month=January;month<=December;month++) {
      income[month] = 0.0;  // These are necessary to make things work
      expense[month] = 0.0; // when reverting a document
      [self addValueToIncome:[[incomeArray objectAtIndex:month] doubleValue] forMonth:month];
      [self addValueToExpense:[[expenseArray objectAtIndex:month] doubleValue] forMonth:month];
      //[self addValueToBalance:[[balanceArray objectAtIndex:month] doubleValue] forMonth:month];
    }
    [self updateBalances];

    if ([dictionary objectForKey:CXLogoKey]) {
      [self setLogo:[[[NSImage alloc] initWithData:[dictionary objectForKey:CXLogoKey]] autorelease]];
    }
    if ([dictionary objectForKey:CXAccountInfoKey])
      [self setAccountInfo:[dictionary objectForKey:CXAccountInfoKey]];
    [[self undoManager] enableUndoRegistration];

    // Post notification to update GUI
    [[NSNotificationCenter defaultCenter] postNotificationName:CXValueInTableChangedNotification
                                                        object:self];
  }
}


/*
- (BOOL)loadDataRepresentation:(NSData *)data ofType:(NSString *)aType {
    // Insert code here to read your document from the given data.  You can also choose to override -loadFileWrapperRepresentation:ofType: or -readFromFile:ofType: instead.
    
    //NSString *string = [[NSString allocWithZone:[self zone]] initWithData:data
   //                              encoding:NSUTF8StringEncoding];
   // accountData = [NSArray arrayWithArray:[string propertyList]];
   // // accountData is released in dealloc
   // [accountData retain];
   // [string release];
   // return YES;
    
  if ([aType isEqualToString:CXDocumentType]) {
    [self restoreFromStorage:[self setupDictionaryFromStorage:data]];
    return YES;
  }
  else {
    return NO;
  }
}
*/
/*
- (void)restoreFromStorage:(NSData *)data {
  CXMonth month;
  NSDictionary *dictionary = [self setupDictionaryFromStorage:data];
  NSArray *incomeArray;
  NSArray *expenseArray;
  NSArray *balanceArray;
  
  [self setCurrentMonth:(CXMonth)[[dictionary objectForKey:CXCurrentMonthKey] intValue]];
  [self setTransactionType:(CXTransactionType)[[dictionary objectForKey:CXTransactionTypeKey] intValue]];
  [self setTickOff:(BOOL)[[dictionary objectForKey:CXTickOffKey] intValue]];
  [self setAccountData:[dictionary objectForKey:CXAccountDataKey]];
  [self setLastMonthWithEntries:[[dictionary objectForKey:CXLastMonthKey] intValue]];
  incomeArray = [dictionary objectForKey:CXIncomeDataKey];
  expenseArray = [dictionary objectForKey:CXExpenseDataKey];
  balanceArray = [dictionary objectForKey:CXBalanceDataKey];
  for (month=January;month<=December;month++) {
    // This (adding a value) works because they are always initialized to zero
    [self addValueToIncome:[[incomeArray objectAtIndex:month] doubleValue] forMonth:month];
    [self addValueToExpense:[[expenseArray objectAtIndex:month] doubleValue] forMonth:month];
    //[self addValueToBalance:[[balanceArray objectAtIndex:month] doubleValue] forMonth:month];
  }
  [self updateBalances];
  
}
*/
/*
- (NSDictionary *)setupDictionaryFromStorage:(NSData *)data
{
    NSString *string = [[NSString allocWithZone:[self zone]] initWithData:data encoding:NSUTF8StringEncoding];
    NSDictionary *dictionary = [string propertyList];
    [string release];
    return dictionary;
}
*/

// Tells whether to keep the old version of the file. See NSDocument's documentation.
- (BOOL)keepBackupFile {
  return NO;
}

/*
- (BOOL)validateMenuItem:(NSMenuItem *)menuItem {
  NSEnumerator *enumerator;
  id obj;
  
  if ([[menuItem title] isEqualToString:NSLocalizedString(@"Graph", @"Name of Graph menu item")]) {
    enumerator = [[self windowControllers] objectEnumerator];
    while (obj = [enumerator nextObject])
      if ([obj isMemberOfClass:[CXGraphWindowController class]])
        return NO;
  }
  return YES;
}
*/

// Receives data to be encrypted.
// Returns data encrypted with (public) key specified in the Preferences
// If an error occurs, return nil.
- (NSData *)encryptWithGpg:(NSData *)data
{
  NSTask *gpgTask = [[NSTask alloc] init]; // Remember that it must be released!
  NSMutableArray *args = [NSMutableArray array];
  NSPipe *outputPipe;
  NSPipe *inputPipe;
  NSFileHandle *readHandle;
  NSFileHandle *writeHandle;
  NSData *inData;
  NSMutableData *encryptedData;
  NSString *gpgDirectoryPath; // gpg directory (e.g. /usr/local/bin)
  NSString *gpgPath; // gpg executable path (e.g. /usr/local/bin/gpg)
  NSString *identity; // key ID
  int exitStatus; // exit value returned from gpg
  
  /* Set arguments */
  [args addObject:@"--batch"]; // No interaction
  [args addObject:@"--no-tty"]; // No use of terminal
  [args addObject:@"-q"]; // Run as quiet as possible
  [args addObject:@"--no-verbose"]; // Verbose level set to 0 (see man gpg)
  [args addObject:@"--no-options"]; // Avoids using options file
  identity = [Prefs stringForKey:CXKeyIDKey]; // key ID to encrypt to
  if ([identity isEqualToString:@""])
    [args addObject:@"--default-recipient-self"];
  else {
    [args addObject:@"--recipient"];
    [args addObject:identity];
  }
  [args addObject:@"--encrypt"];
  [gpgTask setArguments:args];

  // Set path
  gpgDirectoryPath = [Prefs stringForKey:CXGpgPathKey];
  if (![gpgDirectoryPath isAbsolutePath]) {
  //  [gpgTask setCurrentDirectoryPath:gpgDirectoryPath];
  //else {
    NSBeep();
    NSRunAlertPanel(NSLocalizedString(@"Gpg directory path is not correct", @"Title of absolute path error"),
                    NSLocalizedString(@"The path you have specified in the Preferences is not a valid absolute path. Please check it and try again.", @"Text of absolute path error"), @"OK",NULL,NULL);
    //NSLog(@"Not a correct path\n");
    return nil;
  }
  gpgPath = [gpgDirectoryPath stringByAppendingPathComponent:@"gpg"];
  if ([[NSFileManager defaultManager] fileExistsAtPath:gpgPath])
    [gpgTask setLaunchPath:gpgPath];
  else {
    NSBeep();
    NSRunAlertPanel(NSLocalizedString(@"I cannot find the gpg executable", @"Title of gpg not found error"),
                    NSLocalizedString(@"Please check the path in the Preferences and try again.", @"Text of gpg not found error"), @"OK",NULL,NULL);

    //NSLog(@"I cannot find gpg.\n");
    return nil;
  }

  outputPipe = [NSPipe pipe];
  readHandle = [outputPipe fileHandleForReading];
  [gpgTask setStandardOutput:outputPipe];
  inputPipe = [NSPipe pipe];
  writeHandle = [inputPipe fileHandleForWriting];
  [gpgTask setStandardInput:inputPipe];

  //[readHandle readInBackgroundAndNotify];

  [gpgTask launch];

  [writeHandle writeData:data];
  [writeHandle closeFile]; // Closing file handle signals gpg that input has ended

  encryptedData = [[[NSMutableData alloc] init] autorelease]; 
  while ((inData = [readHandle availableData]) && [inData length]) {
    [encryptedData appendData:inData];
  }
  [gpgTask waitUntilExit];
  exitStatus = [gpgTask terminationStatus];
  [gpgTask release];
  switch (exitStatus) {
    case 0: // Success
      //NSLog(@"Task succeeded.");
      return encryptedData;
      break;
    default: // Ops... failure
      NSRunAlertPanel(NSLocalizedString(@"Encryption failed",
                                        @"Title of encryption failed error"),
                      NSLocalizedString(@"Public key not found. Please check the Preferences and try again.",
                                      @"Text of encryption failed error"), @"OK",NULL,NULL);
      //NSLog(@"Task failed. Exit status: %d", exitStatus);
      return nil;
  }
}

// Returns deciphered data, or nil upon failure
- (NSData *)decryptWithGpg:(NSData *)encryptedData usingPassphrase:(NSString *)passphrase
{
  NSTask *gpgTask = [[NSTask alloc] init]; // Remember that it must be released!
  NSMutableArray *args = [NSMutableArray array];
  NSPipe *outputPipe;
  NSPipe *inputPipe;
  NSFileHandle *writeHandle;
  NSFileHandle *readHandle;
  NSData *inData;
  NSMutableData *decipheredData;
  NSString *gpgDirectoryPath;
  NSString *gpgPath;
  int exitStatus;
  
  /* Set arguments */
  [args addObject:@"--batch"];
  [args addObject:@"--no-tty"];
  [args addObject:@"-q"];
  [args addObject:@"--no-verbose"];
  [args addObject:@"--no-options"];
  [args addObject:@"--decrypt"];
  [args addObject:@"--passphrase-fd"];
  [args addObject:@"0"]; // Read passphrase from stdin
  [gpgTask setArguments:args];

  // Set path
  gpgDirectoryPath = [Prefs stringForKey:CXGpgPathKey];
  if (![gpgDirectoryPath isAbsolutePath]) {
  //  [gpgTask setCurrentDirectoryPath:gpgDirectoryPath];
  //else {
    NSBeep();
    NSRunAlertPanel(NSLocalizedString(@"Gpg directory path is not correct", @"Title of absolute path error"),
                    NSLocalizedString(@"The path you have specified in the Preferences is not a valid absolute path. Please check it and try again.", @"Text of absolute path error"), @"OK",NULL,NULL);
    //NSLog(@"Not a correct path\n");
    return nil;
  }
  gpgPath = [gpgDirectoryPath stringByAppendingPathComponent:@"gpg"];
  if ([[NSFileManager defaultManager] fileExistsAtPath:gpgPath])
    [gpgTask setLaunchPath:gpgPath];
  else {
    NSBeep();
    NSRunAlertPanel(NSLocalizedString(@"I cannot find the gpg executable", @"Title of gpg not found error"),
                    NSLocalizedString(@"Please check the path in the Preferences and try again.", @"Text of gpg not found error"), @"OK",NULL,NULL);

    //NSLog(@"I cannot find gpg.\n");
    return nil;
  }
  
  outputPipe = [NSPipe pipe];
  readHandle = [outputPipe fileHandleForReading];
  [gpgTask setStandardOutput:outputPipe];
  inputPipe = [NSPipe pipe];
  writeHandle = [inputPipe fileHandleForWriting];
  [gpgTask setStandardInput:inputPipe];

  //[readHandle readInBackgroundAndNotify];

  [gpgTask launch];
  [writeHandle writeData:[[NSString stringWithString:passphrase]
                          dataUsingEncoding:NSASCIIStringEncoding]];
  [writeHandle writeData:[[NSString stringWithString:@"\n"] // End of passphrase
                          dataUsingEncoding:NSASCIIStringEncoding]];
  [writeHandle writeData:encryptedData];
  [writeHandle closeFile]; // End of input

  decipheredData = [[[NSMutableData alloc] init] autorelease];
  while ((inData = [readHandle availableData]) && [inData length]) {
    [decipheredData appendData:inData];
  }
  [gpgTask waitUntilExit];
  exitStatus = [gpgTask terminationStatus];
  [gpgTask release];
  switch (exitStatus) {
    case 0: // Success
            //NSLog(@"Task succeeded.");
      return decipheredData;  
      break;
    default: // Ops... failure
      NSRunAlertPanel(NSLocalizedString(@"Decryption failed",
                                        @"Title of decryption failed error"),
                      NSLocalizedString(@"Passphrase not valid.",
                                        @"Text of decryption failed error"), @"OK",NULL,NULL);
      NSLog(@"Decryption failed. Exit status: %d", exitStatus);
      return nil;
  }
}

// Prompts user for a passphrase.
// Returns the passphrase, or nil if the user canceled the action
// ******************************************************************************
// There are some issues I do not take care of here.
// Namely, the fact that passphrase stays in memory more than it is necessary...
// ...that it can potentially be swapped on disk... etc...
// ******************************************************************************
- (NSString *)getPassphrase {
  // Load a panel to ask for a passphrase
  if ([NSBundle loadNibNamed:@"CXPassphrase" owner:self]) {
    [[self passphraseTextField] setStringValue:@""]; // passphraseTextField is connected to the NSSecureTextField in nib file 
    // passphrasePanel is an outlet linked to the NSPanel in the nib file
    if([[NSApplication sharedApplication] runModalForWindow:passphrasePanel] == NSOKButton){
      return [[self passphraseTextField] stringValue];
    }
    else
      return nil;
  }
  else { // Wasn't able to open the nib file. This should never happen!
    NSLog(@"Couldn't open CXPassphrase.nib!\n");
    return nil;
  }
}

- (IBAction)endPassphrasePanel:(id)sender {
  [passphrasePanel orderOut:sender];
  [[NSApplication sharedApplication] stopModalWithCode:[sender tag]];
}
  

/*
 - (void)checkGpgTaskStatus:(NSNotification *)notification {
  int status = [[notification object] terminationStatus];
  if (status == 0)
    NSLog(@"Task succeeded.");
  else {
    NSLog(@"Task failed. Exit status: %d", status);
  }
}
*/

/*
- (void)gpgOutputAvailable:(NSNotification *)notification {
  NSData *data;
  data = [[notification userInfo] objectForKey:@"NSFileHandleNotificationDataItem"];
  if ([data length]) {
    // [...]
    [readHandle readInBackgroundAndNotify];
  }
}
*/

@end
