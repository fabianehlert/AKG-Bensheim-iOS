//
//  SupplyTypesTableViewController.m
//  AKG
//
//  Created by Fabian Ehlert on 08.02.14.
//  Copyright (c) 2014 Fabian Ehlert. All rights reserved.
//

#import "SupplyTypesTableViewController.h"
#import "SupplyTypeColorTableViewController.h"
#import "ColorCell.h"

@interface SupplyTypesTableViewController () <ColorSettingsDelegate>

@property (strong, nonatomic) NSArray *colorsArray;
@property (strong, nonatomic) NSArray *typeArray;

@end

@implementation SupplyTypesTableViewController

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self.tableView deselectRowAtIndexPath:self.tableView.indexPathForSelectedRow animated:YES];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = FELocalized(@"COLORS_PLURAL");
    
    self.colorsArray = @[[UIColor colorWithRed:(42.0/255.0) green:(174.0/255.0) blue:(245.0/255.0) alpha:1.0],
                         [UIColor colorWithRed:(252.0/255.0) green:(40.0/255.0) blue:(40.0/255.0) alpha:1.0],
                         [UIColor colorWithRed:0.1 green:0.9 blue:0.3 alpha:1.0],
                         [UIColor colorWithRed:(252.0/255.0) green:(148.0/255.0) blue:(38.0/255.0) alpha:1.0],
                         [UIColor colorWithRed:(230.0/255.0) green:(230.0/255.0) blue:(77.0/255.0) alpha:1.0],
                         [UIColor colorWithRed:(203.0/255.0) green:(119.0/255.0) blue:(223.0/255.0) alpha:1.0],
                         [UIColor colorWithRed:(0.0/255.0) green:(145.0/255.0) blue:(60.0/255.0) alpha:1.0],
                         [UIColor colorWithRed:(115.0/255.0) green:(235.0/255.0) blue:(255.0/255.0) alpha:1.0],
                         [UIColor colorWithRed:(90.0/255.0) green:(255.0/255.0) blue:(40.0/255.0) alpha:1.0],
                         [UIColor colorWithRed:0.05 green:0.38 blue:0.725 alpha:1.0]];
    
    NSUserDefaults *groupDefaults = [NSUserDefaults standardUserDefaults];

    if (![groupDefaults objectForKey:@"vtypearray"]) {
        self.typeArray = @[@{@"name": @"Vertretung", @"color": @"0"}, @{@"name": @"Fällt aus", @"color": @"1"}, @{@"name": @"Raumvertretung", @"color": @"2"}, @{@"name": @"Veranstaltung", @"color": @"3"}, @{@"name": @"Sondereinstellung", @"color": @"4"}, @{@"name": @"Unterricht geändert", @"color": @"5"}, @{@"name": @"Freisetzung", @"color": @"6"}, @{@"name": @"Betreuung", @"color": @"7"}, @{@"name": @"Tausch", @"color": @"8"}, @{@"name": @"Andere", @"color": @"9"}];
        
        [groupDefaults setObject:self.typeArray forKey:@"vtypearray"];
        [groupDefaults synchronize];
    } else {
        self.typeArray = [groupDefaults objectForKey:@"vtypearray"];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (IBAction)closeAction:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
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
    return [self.typeArray count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    ColorCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    id type = self.typeArray[indexPath.row];
    cell.colorTitleLabel.text = [type objectForKey:@"name"];
    
    NSUInteger index = [[type objectForKey:@"color"] integerValue];
    UIColor *color = self.colorsArray[index];
    cell.colorView.backgroundColor = color;

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{

}


#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    NSUInteger selectionIndex = self.tableView.indexPathForSelectedRow.row;

    if ([segue.identifier isEqualToString:@"editcolor"]) {
        SupplyTypeColorTableViewController *controller = segue.destinationViewController;
        controller.delegate = self;
        controller.type = [self.typeArray[selectionIndex] objectForKey:@"name"];
        controller.colorIndex = [[self.typeArray[selectionIndex] objectForKey:@"color"] integerValue];
        controller.typeIndex = [self.tableView indexPathForSelectedRow].row;
    }
}

#pragma mark - ColorSettingsDelegate
- (void)cancel
{
    
}

- (void)saveColorAtIndex:(NSUInteger)color forTypeAtIndex:(NSUInteger)type
{
    NSUserDefaults *groupDefaults = [NSUserDefaults standardUserDefaults];

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSArray *types = [groupDefaults objectForKey:@"vtypearray"];
        NSMutableArray *typesMutable = [NSMutableArray new];
        
        for (id typeObject in [types mutableCopy]) {
            [typesMutable addObject:typeObject];
        }
        
        NSString *colorName = [NSString stringWithFormat:@"%lu", (unsigned long)color];
        id updatedObject = [typesMutable objectAtIndex:type];
        
        NSDictionary *updatedDictionary = @{@"name": [updatedObject objectForKey:@"name"], @"color": colorName};
        
        [typesMutable replaceObjectAtIndex:type withObject:updatedDictionary];
        
        NSArray *m = [[NSArray alloc] initWithArray:typesMutable];
        
        [groupDefaults setObject:m forKey:@"vtypearray"];
        [groupDefaults synchronize];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            self.typeArray = [groupDefaults objectForKey:@"vtypearray"];
            [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationNone];
        });
    });
}


@end
