//
//  DashboardViewController.m
//  MoleMapper
//
//  Created by Dan Webster on 8/16/15.
// Copyright (c) 2016, OHSU. All rights reserved.
//
// Redistribution and use in source and binary forms, with or without modification,
// are permitted provided that the following conditions are met:
//
// 1.  Redistributions of source code must retain the above copyright notice, this
// list of conditions and the following disclaimer.
//
// 2.  Redistributions in binary form must reproduce the above copyright notice,
// this list of conditions and the following disclaimer in the documentation and/or
// other materials provided with the distribution.
//
// 3.  Neither the name of the copyright holder(s) nor the names of any contributors
// may be used to endorse or promote products derived from this software without
// specific prior written permission. No license is granted to the trademarks of
// the copyright holders even if such marks are included in this software.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
// ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
// FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
// DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
// SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
// CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
// OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//
//


#import "DashboardViewController.h"
#import "DashboardActivityCompletionCell.h"
#import "DashboardZoneDocumentationCell.h"
#import "DashBoardMeasurementCell.h"
#import "DashboardBiggestMoleCell.h"
#import "DashboardSizeOvertimeCell.h"
#import "DashboardMolyEstZone.h"
#import "DashboardUVExposure.h"
#import "DashboardModel.h"
#import "MoleViewController.h"
#import "AppDelegate.h"

@interface DashboardViewController ()
@end

@implementation DashboardViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _cellList = [[NSMutableArray alloc] init];
    [self setupCellList];
    self.navigationItem.titleView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"moleMapperLogo"]];
    AppDelegate *ad = (AppDelegate *)[UIApplication sharedApplication].delegate;
    self.context = ad.managedObjectContext;
    
    _refreshControl = [[UIRefreshControl alloc]init];
    [self.tableView addSubview:_refreshControl];
    [_refreshControl addTarget:self action:@selector(refreshTable) forControlEvents:UIControlEventValueChanged];
    _isLoaded = YES;
}

- (void)viewWillAppear:(BOOL)animated
{
    if (!_isLoaded)
    {
        [[DashboardModel sharedInstance] refreshContext];
        [self setupCellList];
        [self.tableView reloadData];
    }
    else _isLoaded = NO;
}

- (void)refreshTable {
    //TODO: refresh your data
    [[DashboardModel sharedInstance] refreshContext];
    [self setupCellList];
    [_refreshControl endRefreshing];
    [self.tableView reloadData];
    
    /*AppDelegate *ad = (AppDelegate *)[UIApplication sharedApplication].delegate;
    self.context = ad.managedObjectContext;*/
}

-(void) setupCellList
{
    if ([_cellList count] > 0)
    {
        for (int i = 0; i < [_cellList count]; ++i)
        {
            id data = [_cellList objectAtIndex:0];
            if (data != nil) data = nil;
            else continue;
        }
        
        [_cellList removeAllObjects];
    }
    
    //DashboardActivityCompletionCell
    DashboardActivityCompletionCell *cell1 = (DashboardActivityCompletionCell *)[_tableView dequeueReusableCellWithIdentifier:@"DashboardActivityCompletionCell"];
    
    cell1 = nil;
    
    if (cell1 == nil)
    {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"DashboardActivityCompletionCell" owner:self options:nil];
        cell1 = [nib objectAtIndex:0];
    }
    /////
    
    //DashboardZoneDocumentationCell
    DashboardZoneDocumentationCell *cell2 = (DashboardZoneDocumentationCell *)[_tableView dequeueReusableCellWithIdentifier:@"DashboardZoneDocumentationCell"];
    
    cell2 = nil;
    
    if (cell2 == nil)
    {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"DashboardZoneDocumentationCell" owner:self options:nil];
        cell2 = [nib objectAtIndex:0];
    }
    /////
    
    //DashBoardMeasurementCell
    DashBoardMeasurementCell *cell3 = (DashBoardMeasurementCell *)[_tableView dequeueReusableCellWithIdentifier:@"DashBoardMeasurementCell"];
    
    cell3 = nil;
    
    if (cell3 == nil)
    {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"DashBoardMeasurementCell" owner:self options:nil];
        cell3 = [nib objectAtIndex:0];
    }
    /////
    
    //DashboardBiggestMoleCell
    DashboardBiggestMoleCell *cell4 = (DashboardBiggestMoleCell*)[_tableView dequeueReusableCellWithIdentifier:@"DashboardBiggestMoleCell"];
    
    cell4 = nil;
    
    if (cell4 == nil)
    {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"DashboardBiggestMoleCell" owner:self options:nil];
        cell4 = [nib objectAtIndex:0];
    }
    /////
    
    //DashboardSizeOvertimeCell
    DashboardSizeOvertimeCell *cell5 = (DashboardSizeOvertimeCell*)[_tableView dequeueReusableCellWithIdentifier:@"DashboardSizeOvertimeCell"];
    
    cell5 = nil;
    
    if (cell5 == nil)
    {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"DashboardSizeOvertimeCell" owner:self options:nil];
        cell5 = [nib objectAtIndex:0];
    }
    
    //DashboardMolyestZone
    /*DashboardMolyEstZone *cell6 = (DashboardMolyEstZone*)[_tableView dequeueReusableCellWithIdentifier:@"DashboardMolyEstZone"];
    
    cell6 = nil;
    
    if (cell6 == nil)
    {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"DashboardMolyEstZone" owner:self options:nil];
        cell6 = [nib objectAtIndex:0];
    }*/
    
    //DashboardUVExposure
    DashboardUVExposure *cell7 = (DashboardUVExposure*)[_tableView dequeueReusableCellWithIdentifier:@"DashboardUVExposure"];
    
    cell7 = nil;
    
    if (cell7 == nil)
    {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"DashboardUVExposure" owner:self options:nil];
        cell7 = [nib objectAtIndex:0];
    }
    
    cell1.clipsToBounds = YES;
    cell2.clipsToBounds = YES;
    cell3.clipsToBounds = YES;
    cell4.clipsToBounds = YES;
    cell5.clipsToBounds = YES;
    //cell6.clipsToBounds = YES;
    cell7.clipsToBounds = YES;
    
    [_cellList addObject:cell1];
    [_cellList addObject:cell2];
    [_cellList addObject:cell3];
    [_cellList addObject:cell4];
    [_cellList addObject:cell5];
    //[_cellList addObject:cell6];
    [_cellList addObject:cell7];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [_cellList count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    if (indexPath.row == 0)
    {
        
        //[(DashboardActivityCompletionCell*)[_cellList objectAtIndex:indexPath.row] setDataToProgressView:numb];
    }
    
    if (indexPath.row == 0)
    {
        //[(DashboardZoneDocumentationCell*)[_cellList objectAtIndex:indexPath.row] setDataToProgressView:0.95];
    }
    
    /*if (indexPath.row == 5)
    {
        [(DashboardMolyEstZone*)[_cellList objectAtIndex:indexPath.row] setDataToChart];
    }*/
    
    return [_cellList objectAtIndex:indexPath.row];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return NO;
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    return NO;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSNumber *height = 0;
    
    if (indexPath.row == 0)
    {
        DashboardActivityCompletionCell* cell = (DashboardActivityCompletionCell*)[_cellList objectAtIndex:indexPath.row];
        height = @(cell.bounds.size.height);
    }
    
    if (indexPath.row == 1)
    {
        DashboardZoneDocumentationCell* cell = (DashboardZoneDocumentationCell*)[_cellList objectAtIndex:indexPath.row];
        height = @(cell.bounds.size.height);
    }
    
    if (indexPath.row == 2)
    {
        DashBoardMeasurementCell* cell = (DashBoardMeasurementCell*)[_cellList objectAtIndex:indexPath.row];
        cell.dashBoardViewController = self;
        height = @(cell.bounds.size.height);
    }
    
    if (indexPath.row == 3)
    {
        DashboardBiggestMoleCell* cell = (DashboardBiggestMoleCell*)[_cellList objectAtIndex:indexPath.row];
        height = @(cell.bounds.size.height);
    }
    
    if (indexPath.row == 4)
    {
        DashboardSizeOvertimeCell* cell = (DashboardSizeOvertimeCell*)[_cellList objectAtIndex:indexPath.row];
        
        //probably nondebug
        NSDictionary *moleDictionary = [[DashboardModel sharedInstance] rankedListOfMoleSizeChangeAndMetadata];
        cell.allMolesDicitionary = moleDictionary;
        cell.dashBoardViewController = self;
        height = @(([moleDictionary count] + 1) * 62);
        
        CGRect bounds = [cell.tableViewInside bounds];
        [cell.tableViewInside setBounds:CGRectMake(bounds.origin.x,
                                        bounds.origin.y,
                                        bounds.size.width,
                                        (bounds.size.height + [moleDictionary count] * 62))];
    }
    
    /*if (indexPath.row == 5)
    {
        DashboardMolyEstZone* cell = (DashboardMolyEstZone*)[_cellList objectAtIndex:indexPath.row];
        height = @(cell.bounds.size.height);
    }*/
    
    if (indexPath.row == 5)
    {
        DashboardUVExposure* cell = (DashboardUVExposure*)[_cellList objectAtIndex:indexPath.row];
        height = @(cell.bounds.size.height);
    }
    
    return [height floatValue];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    //Change the selected background view of the cell.
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
}


@end
