//
//  globals.m
//  Conto
//
//  Created by Nicola on Sun Jan 27 2002.
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

#import "globals.h"

// Notification names
NSString *CXValueInTableChangedNotification = @"CXValue Changed";
NSString *CXMonthChangedNotification = @"CXMonth Changed";
NSString *CXTickOffStateChangedNotification = @"CXTickOffSwitch Changed";
NSString *CXTransactionTypeChangedNotification = @"CXTransaction Type Changed";
NSString *CXLogoChangedNotification = @"CXLogo Deleted";
NSString *CXTableChangedNotification = @"CXTable Changed";
NSString *CXInfoTableChangedNotification = @"CXInfoTable Changed";
NSString *CXGridChangedNotification = @"CXGrid Changed";

NSString *CXFontSizeChangedNotification = @"CXFontSize Changed";
NSString *CXNumberFormatChangedNotification = @"CXNumber Format Changed";
NSString *CXDateFormatChangedNotification = @"CXDate Format Changed";

NSString *CXDescriptionsTableChangedNotification = @"CXDefault Descriptions Changed";
NSString *CXAutocompletionChangedNotification = @"CXAutocompletion Changed";

// User defaults' keys
// General
NSString *CXFontSizeKey = @"Font Size";
NSString *CXCurrencyPositionKey = @"Currency Position";
NSString *CXCurrencySymbolKey = @"Currency Symbol";
NSString *CXNumberOfDecimalsKey = @"Number of Decimals";
NSString *CXDecimalSeparatorKey = @"Decimal Separator";
NSString *CXThousandSeparatorKey = @"Thousand Separator";
NSString *CXDateFormatKey = @"Date Format";
NSString *CXGridKey = @"Grid";
// Encryption
NSString *CXUseEncryptionKey = @"Use Encryption";
NSString *CXGpgPathKey = @"Gpg Path";
NSString *CXKeyIDKey = @"Key ID";
// Descriptions
NSString *CXDescriptionsArrayKey = @"Descriptions";
NSString *CXDefaultDescriptionKey = @"Default Description";
NSString *CXIncomeOperationKey = @"Income Operation";
NSString *CXExpenseOperationKey = @"Expense Operation";
NSString *CXIncomeOpValueKey = @"Income Op Value";
NSString *CXExpenseOpValueKey = @"Expense Op Value";
NSString *CXAutocompleteKey = @"Autocomplete";
