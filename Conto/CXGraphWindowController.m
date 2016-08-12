//
//  CXGraphWindowController.m
//  Conto
//
//  Created by Nicola on Sat May 04 2002.
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

#import "CXGraphWindowController.h"
#import "CXGraphView.h"
#import "CXDocument.h"

#define Prefs   [NSUserDefaults standardUserDefaults]

@implementation CXGraphWindowController

- (id)init {
  if (self = [super initWithWindowNibName:@"CXGraph"]) {
   // numberFormatter = [[NSNumberFormatter alloc] init];
  }
  return self;
}

-  (void)dealloc {
  [[self window] saveFrameUsingName:@"Graph Window"];
  //[numberFormatter release];
  [super dealloc];
}

- (void)windowDidLoad {
  [super windowDidLoad];

  //[self setWindowFrameAutosaveName:@"Graph Window"];
  [[self window] setFrameUsingName:@"Graph Window"];
  [self setShouldCascadeWindows:NO];
  [self setNumberFormat:nil];

  // Register notification observers
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(updateGraph:)
                                               name:CXValueInTableChangedNotification
                                             object:[self document]];
  // Register notification observers
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(setNumberFormat:)
                                               name:CXNumberFormatChangedNotification
                                             object:nil];  
}

// Overrides NSWindowController's method to customize title
- (NSString *)windowTitleForDocumentDisplayName:(NSString *)displayName {
  NSString *title = NSLocalizedString(@"Graph for ", @"Title of Graph Window");
  return [title stringByAppendingString:displayName];
}


// Accessor methods
- (CXGraphView *)graphView {
  return graphView;
}

/*
- (NSNumberFormatter *)numberFormatter {
  return numberFormatter;
}
*/

// Notifications
- (void)updateGraph:(NSNotification *)notification {
  [[self graphView] setNeedsDisplay:YES];
}

// Formatting numbers
- (void)setNumberFormat:(NSNotification *)notification {
  [[self graphView] setNeedsDisplay:YES];
}

/*
 NSMutableDictionary *newAttrs = [NSMutableDictionary dictionary];
 NSMutableString *formatString = [[NSMutableString alloc] init];
 int i;
 NSString *decimalSeparator;
 NSString *thousandSeparator;
 CXCurrencyPosition currencyPosition = (CXCurrencyPosition)[Prefs integerForKey:CXCurrencyPositionKey];
 NSString *currencySymbol = [Prefs stringForKey:CXCurrencySymbolKey];
 int numberOfDecimals = [Prefs integerForKey:CXNumberOfDecimalsKey];
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
 //[numberFormatter setFormat:@"#,##0.00 Û;0.00 Û;-#,##0.00 Û"];
 [[self numberFormatter] setFormat:formatString];
 [newAttrs setObject:[NSColor redColor] forKey:@"NSColor"];
 [[self numberFormatter] setTextAttributesForNegativeValues:newAttrs];
 // Set decimal separator
 [[self numberFormatter] setDecimalSeparator:decimalSeparator];
 // Set thousand separator
 if (hasThousandSeparator)
 [[self numberFormatter] setThousandSeparator:thousandSeparator];
 else // No thousand separators
 [[self numberFormatter] setHasThousandSeparators:NO];
 [[self numberFormatter] setAttributedStringForNotANumber:[[[NSAttributedString alloc] initWithString:@""] autorelease]];
 [[self graphView] setNeedsDisplay:YES];
*/

- (IBAction)printDocumentView:(id)sender {
  [[self document] printView:[self graphView]];
}

 
@end
