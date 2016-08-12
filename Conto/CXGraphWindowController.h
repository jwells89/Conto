//
//  CXGraphWindowController.h
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

#import <Cocoa/Cocoa.h>
#import "globals.h"

@class CXGraphView;

@interface CXGraphWindowController : NSWindowController {
  IBOutlet CXGraphView *graphView;
  //NSNumberFormatter *numberFormatter;
}

// Accessor methods
- (CXGraphView *)graphView;
//- (NSNumberFormatter *)numberFormatter;

// Notifications
- (void)updateGraph:(NSNotification *)notification;
- (void)setNumberFormat:(NSNotification *)notification;

// Printing
- (IBAction)printDocumentView:(id)sender;

@end
