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

#import <Cocoa/Cocoa.h>

// As Apple's documentation says (read NSDocument's FAQ),
// it makes perfectly sense to subclass an NSWindowController
// which is not associated with an NSDocument.
// We create a shared instance of the Preferences window.
@interface CXPreferencesController : NSWindowController
{
    // General
    IBOutlet NSMatrix *currencyPositionRadioCluster;
    IBOutlet NSTextField *currencyTextField;
    IBOutlet NSMatrix *decimalSeparatorRadioCluster;
    IBOutlet NSStepper *decimalStepper;
    IBOutlet NSTextField *decimalTextField;
    IBOutlet NSMatrix *fontRadioCluster;
    IBOutlet NSButton *thousandSeparatorCheckbox;
    IBOutlet NSMatrix *dateFormatRadioCluster;
    IBOutlet NSButton *gridCheckbox;
    // Encryption
    IBOutlet NSButton *encryptionCheckbox;
    IBOutlet NSTextField *gpgPathTextField;
    IBOutlet NSTextField *keyIDTextField;
    // Descriptions
    IBOutlet NSTableView *descriptionsTableView;
    IBOutlet NSTextField *descriptionTextField;
    IBOutlet NSTextField *incomeOpTextField;
    IBOutlet NSTextField *expenseOpTextField;
    IBOutlet NSPopUpButton *incomeOperationButton;
    IBOutlet NSPopUpButton *expenseOperationButton;
    IBOutlet NSButton *addButton;
    IBOutlet NSButton *removeButton;
    IBOutlet NSButton *autocompleteCheckbox;
    
    // Number formatter
    NSNumberFormatter *numberFormatter;
    NSNumberFormatter *percentFormatter;
    // Date formatter
    NSDateFormatter *dateFormatter;
    // Default descriptions
    NSMutableArray *descriptions;
}

+ (id)sharedPreferencesController; // Return the single instance of this class

- (void)registerDefaultPrefs; // Used the first time the application is launched

// Accessor methods
// General
- (NSMatrix *)currencyPositionRadioCluster;
- (NSTextField *)currencyTextField;
- (NSMatrix *)decimalSeparatorRadioCluster;
- (NSStepper *)decimalStepper;
- (NSTextField *)decimalTextField;
- (NSMatrix *)fontRadioCluster;
- (NSButton *)thousandSeparatorCheckbox;
- (NSMatrix *)dateFormatRadioCluster;
- (NSButton *)gridCheckbox;
// Encryption
- (NSButton *)encryptionCheckbox;
- (NSTextField *)gpgPathTextField;
- (NSTextField *)keyIDTextField;
// Descriptions
- (NSTableView *)descriptionsTableView;
- (NSTextField *)descriptionTextField;
- (NSTextField *)incomeOpTextField;
- (NSTextField *)expenseOpTextField;
- (NSPopUpButton *)incomeOperationButton;
- (NSPopUpButton *)expenseOperationButton;
- (NSButton *)addButton;
- (NSButton *)removeButton;
- (NSButton *)autocompleteCheckbox;

- (NSNumberFormatter *)numberFormatter;
- (NSDateFormatter *)dateFormatter;
- (NSMutableArray *)descriptions;
- (void)setDescriptions:(NSArray *)descr;

- (void)setNumberFormatterFromPrefs;
- (void)setDateFormatterFromPrefs;

// Action methods
// General
- (IBAction)currencyPositionAction:(id)sender;
- (IBAction)currencySymbolAction:(id)sender;
- (IBAction)decimalSeparatorAction:(id)sender;
- (IBAction)fontSizeAction:(id)sender;
- (IBAction)numberOfDecimalsAction:(id)sender;
- (IBAction)thousandSeparatorAction:(id)sender;
- (IBAction)dateFormatAction:(id)sender;
- (IBAction)gridAction:(id)sender;
// Encryption
- (IBAction)useEncryptionAction:(id)sender;
- (IBAction)gpgPathAction:(id)sender;
- (IBAction)keyIDAction:(id)sender;
// Descriptions
- (IBAction)addDescriptionAction:(id)sender;
- (IBAction)removeDescriptionAction:(id)sender;
- (IBAction)incomeOperationPopUpAction:(id)sender;
- (IBAction)expenseOperationPopUpAction:(id)sender;
- (IBAction)autocompleteAction:(id)sender;

// Generic view updaters
- (void)updateCheckbox:(NSButton *)control setting:(BOOL)value;
- (void)updateRadioCluster:(NSMatrix *)control setting:(NSInteger)value;

// Notifications
- (void)updateDescriptionsTableView:(NSNotification *)notification;
- (void)setNumberFormat:(NSNotification *)notification;

// Table view methods (this class is the data source of the Descriptions TableView)
- (NSInteger)numberOfRowsInTableView:(NSTableView *)descriptionsTableView;
- (id)tableView:(NSTableView *)descriptionsTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex;
- (void)tableView:(NSTableView *)descriptionsTableView setObjectValue:(id)anObject forTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex;


@end
