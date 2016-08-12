//
//  CXDocument.h
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


#import <Cocoa/Cocoa.h>
#import "globals.h"

@interface CXDocument : NSDocument
{
  NSArray *accountData; // Stores an array of twelve NSDictionaries, one for each month
  double income[13]; // One entry for each month, plus one entry for totals.
  double expense[13];
  double balance[13];
  CXMonth lastMonthWithEntries;
  NSMutableArray *accountInfo; // An array of key-value pairs for storing account information

  NSMutableArray *filteredRecords; // Stores records filtered by Search text field
  NSString *filter; // The string to be searched for
  
  // Interface element values
  CXMonth currentMonth;
  CXTransactionType transactionType; // Either income or expense
  BOOL tickOff;
  NSImage *logo;

  // Passphrase panel
  IBOutlet NSPanel *passphrasePanel;
  // Secure text field for entering passphrase
  IBOutlet NSSecureTextField *passphraseTextField;
}

// Accessor methods
- (NSArray *)accountData;
- (void)setAccountData:(NSArray *)data;
- (CXMonth)lastMonthWithEntries;
- (void)setLastMonthWithEntries:(CXMonth)aMonth;
- (CXMonth)currentMonth;
- (void)setCurrentMonth:(CXMonth)aMonth;
- (CXTransactionType)transactionType;
- (void)setTransactionType:(CXTransactionType)transaction;
- (BOOL)tickOff;
- (void)setTickOff:(BOOL)value;
- (NSImage *)logo;
- (void)setLogo:(NSImage *)image;
- (NSMutableArray *)accountInfo;
- (void)setAccountInfo:(NSMutableArray *)info;
- (NSSecureTextField *)passphraseTextField;
- (NSMutableArray *)filteredRecords;
- (NSString *)filter;
- (void)setFilter:(NSString *)newFilter;

// Initialization
- (void)initializeAccountData;

// Managing controllers
- (IBAction)showSummaryWindow:(id)sender;
- (IBAction)showGraphWindow:(id)sender;

// Managing data
//- (void)addRecord:(NSMutableDictionary *)record forMonth:(CXMonth)aMonth;
- (void)insertRecord:(NSMutableDictionary *)record atIndex:(unsigned)index forMonth:(CXMonth)aMonth;
- (NSMutableArray *)getRecordsForMonth:(CXMonth)aMonth;
- (BOOL)modifyField:(id)columnIdentifier ofRecord:(NSMutableDictionary *)theRecord
           forMonth:(CXMonth)aMonth newValue:(id)anObject;
// The following is deprecated
- (BOOL)modifyFieldAtRow:(unsigned)row column:(id)columnIdentifier forMonth:(CXMonth)aMonth newValue:(id)anObject;
//- (void) removeRecordsWithIndices:(NSEnumerator *)indices forMonth:(CXMonth)aMonth;
- (void)removeRecordIdenticalTo:(NSMutableDictionary *)aRecord forMonth:(CXMonth)aMonth;
// The following is deprecated
- (void) removeRecordAtIndex:(unsigned)index forMonth:(CXMonth)aMonth;
- (void)moveRecord:(NSMutableDictionary *)record toIndex:(unsigned)newIndex forMonth:(CXMonth)aMonth;
// The following is deprecated
- (void)moveRecordFromIndex:(unsigned)index toIndex:(unsigned)newIndex forMonth:(CXMonth)aMonth;
- (void)sortRecordsField:(id)fieldIdentifier forMonth:(CXMonth)aMonth;
- (void)unsort:(NSArray *)oldArray field:(id)fieldIdentifier forMonth:(CXMonth)aMonth; // To undo sorting
- (void)insertInfo:(NSMutableDictionary *)info atIndex:(unsigned)index;
- (void)removeInfoAtIndex:(unsigned)index;
- (void)modifyInfoAtRow:(unsigned)row column:(id)columnIdentifier newValue:(id)anObject;

- (double)incomeForMonth:(CXMonth)aMonth;
- (void)addValueToIncome:(double)value forMonth:(CXMonth)aMonth;
- (double)expenseForMonth:(CXMonth)aMonth;
- (void)addValueToExpense:(double)value forMonth:(CXMonth)aMonth;
- (double)balanceForMonth:(CXMonth)aMonth;
- (void)updateBalances;
- (double)applyOperation:(CXOperationType)operation withValue:(double)value toAmount:(double)theAmount;
- (double)applyInverseOperation:(CXOperationType)operation withValue:(double)value toAmount:(double)theAmount;
- (double)getSumValueForKey:(id)field month:(int)aMonth;
- (double)getMaximumValue;
- (double)getMinimumValue;

- (void)filterDescriptionsInMonth:(CXMonth)month;
- (double)incomeOfFilteredRecords;
- (double)expenseOfFilteredRecords;
- (void)insertFilteredRecord:(NSMutableDictionary *)record atIndex:(unsigned)index;
- (void)removeFilteredRecordIdenticalTo:(NSMutableDictionary *)record;

- (void)triggerTickOffForRecord:(NSMutableDictionary *)record;
- (void)triggerTickOffAtIndex:(int)row;

- (void)printView:(NSView *)theView;

// Saving data to persistent storage (a la Vermont Recipes, Recipe 4, Step 1 :))
// The methods commented out are the old way I did things
- (NSDictionary *)setupDictionaryFromMemory;
//- (NSData *)convertForStorage;
// Loading data into memory (a la Vermont Recipes :))
- (void)restoreFromStorage:(NSDictionary *)dictionary;
// (void)restoreFromStorage:(NSData *)data;
//- (NSDictionary *)setupDictionaryFromStorage:(NSData *)data;

// Interface with gpg
- (NSData *)encryptWithGpg:(NSData *)data;
- (NSData *)decryptWithGpg:(NSData *)encryptedData usingPassphrase:(NSString *)passphrase;
//- (void)checkGpgTaskStatus:(NSNotification *)notification;
- (NSString *)getPassphrase;
- (IBAction) endPassphrasePanel:(id)sender;

@end
