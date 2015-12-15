//
//  SupplyTypeColorTableViewController.m
//  AKG
//
//  Created by Fabian Ehlert on 08.02.14.
//  Copyright (c) 2014 Fabian Ehlert. All rights reserved.
//

#import "SupplyTypeColorTableViewController.h"
#import "ColorCell.h"

@interface SupplyTypeColorTableViewController ()

@property (strong, nonatomic) NSArray *colorsArray;

@end

@implementation SupplyTypeColorTableViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if (self.type) {
        self.title = self.type;
    }
    
    self.colorsArray = @[@{@"name": @"Blau", @"color": [UIColor colorWithRed:(42.0/255.0) green:(174.0/255.0) blue:(245.0/255.0) alpha:1.0]},
                         @{@"name": @"Rot", @"color": [UIColor colorWithRed:(252.0/255.0) green:(40.0/255.0) blue:(40.0/255.0) alpha:1.0]},
                         @{@"name": @"Grün", @"color": [UIColor colorWithRed:0.1 green:0.9 blue:0.3 alpha:1.0]},
                         @{@"name": @"Orange", @"color": [UIColor colorWithRed:(252.0/255.0) green:(148.0/255.0) blue:(38.0/255.0) alpha:1.0]},
                         @{@"name": @"Gelb", @"color": [UIColor colorWithRed:(230.0/255.0) green:(230.0/255.0) blue:(77.0/255.0) alpha:1.0]},
                         @{@"name": @"Lila", @"color": [UIColor colorWithRed:(203.0/255.0) green:(119.0/255.0) blue:(223.0/255.0) alpha:1.0]},
                         @{@"name": @"Dunkelgrün", @"color": [UIColor colorWithRed:(0.0/255.0) green:(145.0/255.0) blue:(60.0/255.0) alpha:1.0]},
                         @{@"name": @"Hellblau", @"color": [UIColor colorWithRed:(115.0/255.0) green:(235.0/255.0) blue:(255.0/255.0) alpha:1.0]},
                         @{@"name": @"Hellgrün", @"color": [UIColor colorWithRed:(90.0/255.0) green:(255.0/255.0) blue:(40.0/255.0) alpha:1.0]},
                         @{@"name": @"Dunkelblau", @"color": [UIColor colorWithRed:0.05 green:0.38 blue:0.725 alpha:1.0]}];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}


#pragma mark -
- (IBAction)cancelAction:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(cancel)]){
        [self.delegate cancel];
    }
    
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)saveAction:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(saveColorAtIndex:forTypeAtIndex:)]) {
        [self.delegate saveColorAtIndex:self.colorIndex forTypeAtIndex:self.typeIndex];
    }
    
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - Table view data source

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 44.0;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.colorsArray count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    ColorCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    
    if (indexPath.row == self.colorIndex) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    } else {
        cell.accessoryType = UITableViewCellEditingStyleNone;
    }
    
    id object = self.colorsArray[indexPath.row];
    
    cell.colorTitleLabel.text = [object objectForKey:@"name"];
    cell.colorView.backgroundColor = [object objectForKey:@"color"];

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    self.colorIndex = indexPath.row;
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    [tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
}

@end
