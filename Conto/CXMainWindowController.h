//
//  CXMainWindowController.h
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

@interface CXMainWindowController : NSWindowController
{
    IBOutlet NSButton *addButton;
    IBOutlet NSTextField *dateField;
    IBOutlet NSTextField *amountField;
    IBOutlet NSComboBox *descriptionField;
    IBOutlet NSTextField *incomeField;
    IBOutlet NSTextField *expenseField;
    IBOutlet NSTextField *balanceField;
    IBOutlet NSTextField *monthlyBalanceField;
    IBOutlet NSImageView *logoImageView;
    IBOutlet NSPopUpButton *monthPopUpMenu;
    IBOutlet NSTableView *table;
    IBOutlet NSButton *tickOffSwitch;
    IBOutlet NSMatrix *inOutRadioCluster;
    IBOutlet NSButton *prevButton;
    IBOutlet NSButton *nextButton;
    IBOutlet NSTextField *searchTextField;

    BOOL isFilterOn; // Tells whether we are filtering descriptions

    //NSNumberFormatter *numberFormatter;
    //NSDateFormatter *dateFormatter;
    // The following outlet is NOT necessary! When the NSDocument's subclass
    // creates this window controller, it sets itself as the document
    // associated to this window controller (sending a 'setDocument:' message).
    // We can obtain the NSDocument instance associated with this window controller
    // by sending a 'document' message to 'self'. 
    //CXDocument *theDocument;

}
// Accessor methods
- (NSButton *)addButton;
- (NSTextField *)dateField;
- (NSTextField *)amountField;
- (NSComboBox *)descriptionField;
- (NSTextField *)incomeField;
- (NSTextField *)expenseField;
- (NSTextField *)balanceField;
- (NSTextField *)monthlyBalanceField;
- (NSImageView *)logoImageView;
- (NSPopUpButton *)monthPopUpMenu;
- (NSTableView *)table;
- (NSButton *)tickOffSwitch;
- (NSMatrix *)inOutRadioCluster;
- (NSButton *)prevButton;
- (NSButton *)nextButton;
- (NSTextField *)searchTextField;

//- (NSNumberFormatter *)numberFormatter;
//- (void)setNumberFormatterFromPrefs;
//- (NSDateFormatter *)dateFormatter;
//- (void)setDateFormatterFromPrefs;
   
// Generic view updaters
- (void)updateCheckbox:(NSButton *)control setting:(BOOL)value;
- (void)updatePopUpButton:(NSPopUpButton *)control setting:(NSInteger)value;
- (void)updateRadioCluster:(NSMatrix *)control setting:(NSInteger)value;
// Specific view updaters
- (void)updateTickOffSwitch:(NSNotification *)notification;
- (void)updateMonthPopUpMenu:(NSNotification *)notification;
- (void)updateInOutRadioCluster:(NSNotification *)notification;
- (void)updateLogo:(NSNotification *)notification;
- (void)updateTableView:(NSNotification *)notification;

- (void)updateSums:(NSNotification *)notification;


// Notifications
- (void)setNumberFormat:(NSNotification *)notification;
- (void)setDateFormat:(NSNotification *)notification;
- (void)setGrid:(NSNotification *)notification;
- (void)setFontSize:(NSNotification *)notification;
- (void)updateComboBox:(NSNotification *)notification;
- (void)updateAutocompletion:(NSNotification *)notification;

// Actions
- (IBAction)addAction:(id)sender;
- (IBAction)inOutAction:(id)sender;
- (IBAction)monthPopUpAction:(id)sender;
- (IBAction)tickOffAction:(id)sender;
- (IBAction)draggedLogoAction:(id)sender;
- (IBAction)printDocumentView:(id)sender;
- (IBAction)prevMonthAction:(id)sender;
- (IBAction)nextMonthAction:(id)sender;
- (IBAction)newEntryAction:(id)sender;
//---
- (void)handleClickOnTableItem; // Designated selector for the setAction: method in TableView (see windowDidLoad)
- (void)deleteRecords:(id)sender;
//- (void)deleteSheetDidEnd:(NSWindow *)window returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo;
- (void)deleteLogo:(id)sender;

- (void)filterDescriptions;

// Table view methods (this class is the data source of the main TableView)
- (NSInteger)numberOfRowsInTableView:(NSTableView *)mainTableView;
- (id)tableView:(NSTableView *)mainTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex;
- (void)tableView:(NSTableView *)mainTableView setObjectValue:(id)anObject forTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex;

// Combo box methods (this class is the data source of the NSComboBox)
- (NSInteger)numberOfItemsInComboBox:(NSComboBox *)aComboBox;
- (id)comboBox:(NSComboBox *)aComboBox objectValueForItemAtIndex:(NSInteger)index;

@end
