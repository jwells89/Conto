//
//  globals.h
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

#import <Foundation/Foundation.h>

// Notification names
extern NSString *CXValueInTableChangedNotification;
extern NSString *CXMonthChangedNotification;
extern NSString *CXTickOffStateChangedNotification;
extern NSString *CXTransactionTypeChangedNotification;
extern NSString *CXLogoChangedNotification;
extern NSString *CXTableChangedNotification;
extern NSString *CXInfoTableChangedNotification;
extern NSString *CXGridChangedNotification;

extern NSString *CXFontSizeChangedNotification;
extern NSString *CXNumberFormatChangedNotification;
extern NSString *CXDateFormatChangedNotification;

extern NSString *CXDescriptionsTableChangedNotification;
extern NSString *CXAutocompletionChangedNotification;

// User defaults' keys
// General
extern NSString *CXFontSizeKey;
extern NSString *CXCurrencyPositionKey;
extern NSString *CXCurrencySymbolKey;
extern NSString *CXNumberOfDecimalsKey;
extern NSString *CXDecimalSeparatorKey;
extern NSString *CXThousandSeparatorKey;
extern NSString *CXDateFormatKey;
extern NSString *CXGridKey;
// Encryption
extern NSString *CXUseEncryptionKey;
extern NSString *CXGpgPathKey;
extern NSString *CXKeyIDKey;
// Descriptions
extern NSString *CXDescriptionsArrayKey;
extern NSString *CXDefaultDescriptionKey;
extern NSString *CXIncomeOperationKey;
extern NSString *CXExpenseOperationKey;
extern NSString *CXIncomeOpValueKey;
extern NSString *CXExpenseOpValueKey;
extern NSString *CXAutocompleteKey;

typedef enum {
  CurrentMonth = 127,
  NoMonth = -1,
  January = 0,
  February,
  March,
  April,
  May,
  June,
  July,
  August,
  September,
  October,
  November,
  December,
  LastOfYear // This one is used to index totals
} CXMonth;

typedef enum {
    Income = 0,
    Expense
} CXTransactionType;

typedef enum {
  Smaller = 0,
  Bigger
} CXFontSize;

typedef enum {
  Before = 0,
  After
} CXCurrencyPosition;

typedef enum {
  Comma = 0,
  Period
} CXSeparator;

typedef enum {
  DDMMYY = 0,          // 24-12-02
  DDMMYYWithSlash,     // 24/12/02
  DDMM,                // 24-12
  DDMMWithSlash,       // 24/12
  DDMonthYear,         // 24 december 2002
  DDMonYear,           // 24 dec 2002
  DDMonth,             // 24 december
  DDMon                // 24 dec
} CXDateFormat;

typedef enum {
  NoOperation = 0,
  Add,
  Subtract,
  Multiply,
  Divide,
  AddPercent,
  SubtractPercent
} CXOperationType;

  

