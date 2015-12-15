//
//  SupplyHelper.m
//  AKG
//
//  Created by Fabian Ehlert on 09.03.14.
//  Copyright (c) 2014 Fabian Ehlert. All rights reserved.
//

#import "SupplyHelper.h"

@implementation SupplyHelper

+ (NSString *)displayTypeForType:(NSString *)type
{
    NSString *displayTyp;
    
    if ([type isEqualToString:@"Vertretung"]) {
        displayTyp = @"Vertretung";
    } else if ([type isEqualToString:@"Vertretung(S)"]) {
        displayTyp = @"Stattvertretung";
    } else if ([type isEqualToString:@"Fällt aus!"]) {
        displayTyp = @"Fällt aus";
    } else if ([type isEqualToString:@"Raum-Vtr."]) {
        displayTyp = @"Raumvertretung";
    } else if ([type isEqualToString:@"Veranst."]) {
        displayTyp = @"Veranstaltung";
    } else if ([type isEqualToString:@"Sondereins."]) {
        displayTyp = @"Sondereinstellung";
    } else if ([type isEqualToString:@"Unt."] || [type isEqualToString:@"Unt.-Änd."]) {
        displayTyp = @"Unterricht geändert";
    } else if ([type isEqualToString:@"Freisetzung"]) {
        displayTyp = @"Freisetzung";
    } else if ([type isEqualToString:@"Betreuung"]) {
        displayTyp = @"Betreuung";
    } else if ([type isEqualToString:@"Tausch"]) {
        displayTyp = @"Tausch";
    } else if ([type isEqualToString:@"---"]) {
        displayTyp = @"-";
    } else {
        displayTyp = type;
    }
    
    return displayTyp;
}

+ (UIColor *)colorForType:(NSString *)type
{
    NSArray *colors = @[[UIColor colorWithRed:(42.0/255.0) green:(174.0/255.0) blue:(245.0/255.0) alpha:1.0],
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
    NSArray *types = [groupDefaults objectForKey:@"vtypearray"];
    UIColor *markerColor = nil;
        
    if ([type isEqualToString:@"Vertretung"] || [type isEqualToString:@"Stattvertretung"]) {
        markerColor = colors[(NSUInteger) [[[types objectAtIndex:0] objectForKey:@"color"] integerValue]];
    } else if ([type isEqualToString:@"Fällt aus"]) {
        markerColor = colors[(NSUInteger) [[[types objectAtIndex:1] objectForKey:@"color"] integerValue]];
    } else if ([type isEqualToString:@"Raumvertretung"]) {
        markerColor = colors[(NSUInteger) [[[types objectAtIndex:2] objectForKey:@"color"] integerValue]];
    } else if ([type isEqualToString:@"Veranstaltung"]) {
        markerColor = colors[(NSUInteger) [[[types objectAtIndex:3] objectForKey:@"color"] integerValue]];
    } else if ([type isEqualToString:@"Sondereinstellung"]) {
        markerColor = colors[(NSUInteger) [[[types objectAtIndex:4] objectForKey:@"color"] integerValue]];
    } else if ([type isEqualToString:@"Unterricht geändert"]) {
        markerColor = colors[(NSUInteger) [[[types objectAtIndex:5] objectForKey:@"color"] integerValue]];
    } else if ([type isEqualToString:@"Freisetzung"]) {
        markerColor = colors[(NSUInteger) [[[types objectAtIndex:6] objectForKey:@"color"] integerValue]];
    } else if ([type isEqualToString:@"Betreuung"]) {
        markerColor = colors[(NSUInteger) [[[types objectAtIndex:7] objectForKey:@"color"] integerValue]];
    } else if ([type isEqualToString:@"Tausch"]) {
        markerColor = colors[(NSUInteger) [[[types objectAtIndex:8] objectForKey:@"color"] integerValue]];
    } else if ([type isEqualToString:@"---"]) {
        markerColor = colors[(NSUInteger) [[[types objectAtIndex:9] objectForKey:@"color"] integerValue]];
    } else {
        markerColor = colors[(NSUInteger) [[[types objectAtIndex:9] objectForKey:@"color"] integerValue]];
    }
    return markerColor;
}

@end
