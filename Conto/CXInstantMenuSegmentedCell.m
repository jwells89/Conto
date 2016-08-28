//
//  CXInstantMenuSegmentedControl.m
//  Conto
//
//  Created by John Wells on 8/28/16.
//  Copyright © 2016 John Wells. All rights reserved.
//

#import "CXInstantMenuSegmentedCell.h"

@implementation CXInstantMenuSegmentedCell

- (SEL)action
{
    if ([self menuForSegment:[self selectedSegment]]) {
        return nil;
    } else {
        return [super action];
    }
}

@end
