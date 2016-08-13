//
//  CXGraphView.m
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

#import "CXGraphView.h"
#import "CXGraphWindowController.h"
#import "CXPreferencesController.h"
#import "CXDocument.h"

#import <math.h>

#define Prefs   [NSUserDefaults standardUserDefaults]
#define GAP     10.0
#define PADH    10.0
#define PADV    25.0
#define V_OFFSET_CAPTION  7.0
#define H_OFFSET_CAPTION  190.0
#define SQUARE_SIZE 12.0

@implementation CXGraphView

// Accessor method
- (CXGraphWindowController *)graphController {
  return graphController;
}


- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
      textCell = [[NSCell alloc] init]; // Used to draw labels
      [textCell setType:NSTextCellType];
      [textCell setFont:[NSFont labelFontOfSize:[NSFont labelFontSize]]];
    }
    return self;
}

- (void)dealloc {
  [textCell release];
  [super dealloc];
}


/*
 Following this suggestion might speed up drawing in this view (keep in mind for future versions):
 From CocoaDev mailing list:
 > There is a faster way to draw strings; as a matter of fact, we gave an
 > example of this at last year's WWDC.  The problem with the string
 > drawing routines is that they generate glyphs for the string and lay
 > them out, then throw that information away after the string has been
 > drawn.  All of that work has to be redone when the string is drawn
 > again.  You can see significant improvements by preserving this
 > information instead in your own NSLayoutManager.  For ~100 strings you
 > may wish to use a single NSLayoutManager rather than a separate
 > NSLayoutManager per string; you can do this by concatenating the
 > individual strings into the NSTextStorage, separated by hard line
 > breaks, and maintaining an index of the subranges they occupy.  The
 > exact procedure used would depend a bit on what you know about your
 > strings--for example, whether they might contain line breaks within
 > themselves, whether they are to be allowed to wrap, etc.  The
 > CircleView example demonstrates basic NSLayoutManager-based drawing,
 > although in that case the drawing is done glyph by glyph rather than by
 > ranges of glyphs, as you would probably wish to do it.  If you need
 > help with this, you can probably get it on this list.
 */

- (void)drawRect:(NSRect)rect {
    // Drawing code here.
  NSRect r;
  NSBezierPath *bp;
  float maxW,maxH, maxValue, minValue, valueRange, height, width, originH, originV;
  float labelValue, labelStepValue, labelStepV;
  CXMonth m;
  NSNumberFormatter *formatter;
  NSInteger i;

  // Get format for labels
  //formatter = [[self graphController] numberFormatter];
  formatter = [[CXPreferencesController sharedPreferencesController] numberFormatter];
  // Init cell used to draw labels
  [textCell setFormatter:formatter];
  [textCell setAlignment:NSRightTextAlignment];
  
  // Color background
  [[NSColor whiteColor] set];
  NSRectFill(rect);

  maxW = rect.size.width - 2*PADH; // View width
  maxH = rect.size.height- 2*PADV; // View height

  // Draw caption
  originV = maxH+PADV+V_OFFSET_CAPTION;
  originH = maxW-H_OFFSET_CAPTION;
  r = NSMakeRect(originH, originV, SQUARE_SIZE, SQUARE_SIZE);
  [[NSColor greenColor] set];
  NSRectFill(r);
  r = NSMakeRect(originH+70, originV, SQUARE_SIZE, SQUARE_SIZE);
  [[NSColor redColor] set];
  NSRectFill(r);  r = NSMakeRect(originH+140, originV, SQUARE_SIZE, SQUARE_SIZE);
  [[NSColor yellowColor] set];
  NSRectFill(r);
  [textCell setStringValue:NSLocalizedString(@"Income", @"Income")];
  [textCell drawWithFrame:NSMakeRect(originH+15,originV,[textCell cellSize].width,[textCell cellSize].height) inView:self];
  [textCell setStringValue:NSLocalizedString(@"Expense", @"Expense")];
  [textCell drawWithFrame:NSMakeRect(originH+85,originV,[textCell cellSize].width,[textCell cellSize].height) inView:self];
  [textCell setStringValue:NSLocalizedString(@"Balance", @"Balance")];
  [textCell drawWithFrame:NSMakeRect(originH+155,originV,[textCell cellSize].width,[textCell cellSize].height) inView:self];
      
  maxValue = [[[self graphController] document] getMaximumValue];
  minValue = [[[self graphController] document] getMinimumValue]; // Zero if balances are nonnegative, otherwise it is a negative value
  valueRange = maxValue-minValue;

  if (maxValue > 0.0) { // maxValue == 0 means that the table is either empty or it contains only zeros
    // Draw labels
    labelStepValue = valueRange / 10.0;
    labelStepV = maxH / 10.0;
    if (labelStepV<10)
      labelStepV = 10;
    labelValue = maxValue;
    [textCell setDoubleValue:minValue];
    width = [textCell cellSize].width;
    [textCell setDoubleValue:maxValue];
    if ([textCell cellSize].width > width)
      width = [textCell cellSize].width;
    height = [textCell cellSize].height;
    /* Quoted from http://cocoa.mamasam.com/MACOSXDEV/2002/04/1/30682.php
      explaining why an offset of (0.5, 0.5) is applied to coordinates:
      "The Quartz pen moves along the grid between the pixels. If you offset your coordinates by (0.5, 0.5)
      (thereby moving the pen to the center of a pixel) a line with a width of 1 will appear on the screen as just that."
      If I don't do so, lines will have a width of two pixels or so...
      */    
    originH = PADH+0.5;
    originV = maxH+PADV;
    bp = [NSBezierPath bezierPath];
    [bp setLineWidth:1.0];
    [[NSColor blackColor] set];
    for (i=0;i<=10;i++) {
      [textCell setDoubleValue:labelValue-labelStepValue*i];
      [textCell drawWithFrame:NSMakeRect(originH,originV-[textCell cellSize].height/2,width,height) inView:self];
      // Draw an horizontal line
      [bp moveToPoint:NSMakePoint(originH+width,floor(originV)+0.5)];
      [bp lineToPoint:NSMakePoint(maxW+PADH,floor(originV)+0.5)];
      [bp stroke];
      originV -= labelStepV;
    }

    // Draw bars
    originV = floor((-minValue/valueRange)*maxH+PADV)+0.5; // Leaves room for negative balances
    originH += width;
    // Draw X-axis
    [bp moveToPoint:NSMakePoint(originH,originV)];
    [bp lineToPoint:NSMakePoint(maxW+PADH,originV)];
    [bp stroke];
    width = (maxW- (width+11*GAP)) / 36; // Width of a bar
    //if (width<5)
    //  width = 5;
    for (m=January;m<=December;m++) {
      // Bar for Incomes
      height = [[[self graphController] document] incomeForMonth:m];
      height = (height/valueRange) * maxH;
      r = NSMakeRect(originH, originV, width, height);
      [[NSColor greenColor] set];
      NSRectFill(r);
      originH += width;
      // Bar for Expenses
      height = [[[self graphController] document] expenseForMonth:m];
      height = (height/valueRange) * maxH;
      r = NSMakeRect(originH, originV, width, height);
      [[NSColor redColor] set];
      NSRectFill(r);
      originH += width;
      // Bar for Balances (they can be both positive and negative)
      height = [[[self graphController] document] balanceForMonth:m];
      height = (height/valueRange) * maxH;
      if (height >= 0)
        r = NSMakeRect(originH, originV, width, height);
      else // Negative balance 
        r = NSMakeRect(originH, originV+height,width,-height);
      [[NSColor yellowColor] set];
      NSRectFill(r);
      // Draw month name
      [textCell setStringValue:[self intToMonthName:m]];
      [textCell drawWithFrame:NSMakeRect(originH-2*width,2,[textCell cellSize].width,[textCell cellSize].height) inView:self];
      originH += (width+GAP);      
    }
  }
}

- (NSString *)intToMonthName:(CXMonth)month {
  switch (month) {
    case January:
      return [NSString stringWithString:NSLocalizedString(@"Jan", @"Short name for January")];
      break;
    case February:
      return [NSString stringWithString:NSLocalizedString(@"Feb", @"Short name for February")];
      break;
    case March:
      return [NSString stringWithString:NSLocalizedString(@"Mar", @"Short name for March")];
      break;
    case April:
      return [NSString stringWithString:NSLocalizedString(@"Apr", @"Short name for April")];
      break;
    case May:
      return [NSString stringWithString:NSLocalizedString(@"May ", @"Short name for May")];
      break;
    case June:
      return [NSString stringWithString:NSLocalizedString(@"Jun", @"Short name for June")];
      break;
    case July:
      return [NSString stringWithString:NSLocalizedString(@"Jul", @"Short name for Jule")];
      break;
    case August:
      return [NSString stringWithString:NSLocalizedString(@"Aug", @"Short name for August")];
      break;
    case September:
      return [NSString stringWithString:NSLocalizedString(@"Sep", @"Short name for September")];
      break;
    case October:
      return [NSString stringWithString:NSLocalizedString(@"Oct", @"Short name for October")];
      break;
    case November:
      return [NSString stringWithString:NSLocalizedString(@"Nov", @"Short name for November")];
      break;
    case December:
      return [NSString stringWithString:NSLocalizedString(@"Dec", @"Short name for December")];
      break;
    default:
      return [NSString stringWithString:NSLocalizedString(@"Jan", @"Short name for January")];
  }
}



@end
