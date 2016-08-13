//
//  CXSummaryController.h
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

#import <Cocoa/Cocoa.h>
#import "globals.h"

@interface CXSummaryController : NSWindowController {
  IBOutlet NSTableView *summaryTable;
  IBOutlet NSTableView *infoTable;
  IBOutlet NSButton *addInfoButton;
  IBOutlet NSButton *removeInfoButton;
  //NSNumberFormatter *numberFormatter;
}

// Accessor methods
- (NSTableView *)summaryTable;
- (NSTableView *)infoTable;
- (NSButton *)addInfoButton;
- (NSButton *)removeInfoButton;
//- (NSNumberFormatter *)numberFormatter;
//- (void)setNumberFormatterFromPrefs;

// Convenience method
- (NSString *)intToMonthName:(CXMonth)month;

// Action methods
- (IBAction)addInfoAction:(id)sender;
- (IBAction)removeInfoAction:(id)sender;
- (IBAction)printDocumentView:(id)sender;
// Notifications
- (void)updateTable:(NSNotification *)notification;
- (void)updateAccountInfoTable:(NSNotification *)notification;
// Setting up number format
- (void)setNumberFormat:(NSNotification *)notification;
// Setting font size
- (void)setFontSize:(NSNotification *)notification;
- (void)setGrid:(NSNotification *)notification;

// TableView methods
// (this class is the data source of the summary and info TableView)
- (NSInteger)numberOfRowsInTableView:(NSTableView *)summaryTableView;
- (id)tableView:(NSTableView *)summaryTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex;

@end
