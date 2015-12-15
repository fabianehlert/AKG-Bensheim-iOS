//
//  AppointmentsLoader.m
//  AKG
//
//  Created by Fabian Ehlert on 08.02.14.
//  Copyright (c) 2014 Fabian Ehlert. All rights reserved.
//

#import "AppointmentsLoader.h"
#import "Appointment.h"
#import "TFHpple.h"

@implementation AppointmentsLoader

+ (NSArray *)savedAppointmentsFeed
{
    NSData *savedData = [[NSUserDefaults standardUserDefaults] objectForKey:[NSString stringWithFormat:@"TERMINE_KEY"]];
    if (savedData) {
        return [NSKeyedUnarchiver unarchiveObjectWithData:savedData];
    }
    return @[];
}

+ (NSArray *)latestAppointmentsFeed
{
    NSMutableArray *returnArray = [[NSMutableArray alloc] init];
        
    NSData *parseResult = [[NSData alloc] initWithContentsOfURL:[NSURL URLWithString:@"http://www.akg-bensheim.de/termine/year.listevents"]];
    
    if (parseResult == nil) {
        return [self savedAppointmentsFeed];
    }
    
    TFHpple *xpath = [[TFHpple alloc] initWithHTMLData:parseResult];
    
    NSArray *appointmentArray = [xpath searchWithXPathQuery:@"//div[@id='j_site']//div[@id='content']//div[@id='jevents_body']//table[@class='ev_table']/tr/td[@class='ev_td_right']/ul[@class='ev_ul']/li[@class='ev_td_li']/a[@class='ev_link_row']"];
    
    NSArray *urlArray = [xpath searchWithXPathQuery:@"//div[@id='j_site']//div[@id='content']//div[@id='jevents_body']//table[@class='ev_table']/tr/td[@class='ev_td_right']/ul[@class='ev_ul']/li[@class='ev_td_li']/a[@class='ev_link_row']"];
    
    NSMutableArray *dates = [[NSMutableArray alloc] init];
    NSMutableArray *titles = [[NSMutableArray alloc] init];
    NSMutableArray *urls = [[NSMutableArray alloc] init];
    
    for (TFHppleElement *item in appointmentArray) {
        [titles addObject:item.content];
    }
    
    for (TFHppleElement *item in urlArray) {
        NSString *raw = item.attributes[@"href"];
        
        NSString *url = [NSString stringWithFormat:@"http://www.akg-bensheim.de%@", raw];
        NSString *date = [self dateFromURLString:raw];
        
        [urls addObject:url];
        [dates addObject:date];
    }

    for (NSUInteger i = 0; i < [dates count]; i++) {
        if (![self dateIsHistory:dates[i]]) {
            Appointment *appointment = [[Appointment alloc] initWithTitle:titles[i] details:urls[i] atDate:dates[i]];
            [returnArray addObject:appointment];
        }
    }
    
    [[NSUserDefaults standardUserDefaults] setObject:[NSKeyedArchiver archivedDataWithRootObject:[NSArray arrayWithArray:returnArray]] forKey:[NSString stringWithFormat:@"TERMINE_KEY"]];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    return [NSArray arrayWithArray:returnArray];
}

+ (NSString *)dateFromURLString:(NSString *)urlString {
    NSString *date1 = [urlString stringByReplacingOccurrencesOfString:@"/termine/icalrepeat.detail/" withString:@""];
    NSString *date2 = [date1 stringByReplacingCharactersInRange:NSMakeRange(10, date1.length - 10) withString:@""];
    NSString *date3 = [NSString stringWithFormat:@"%@/09", date2];
    
    return date3;
}

+ (BOOL)dateIsHistory:(NSString *)date {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy/MM/dd/HH"];
    NSString *today = [formatter stringFromDate:[NSDate date]];

    NSString *yearNow = [today stringByReplacingCharactersInRange:NSMakeRange(4, 9) withString:@""];
    NSString *monthNow = [[today stringByReplacingCharactersInRange:NSMakeRange(0, 5) withString:@""] stringByReplacingCharactersInRange:NSMakeRange(2, 6) withString:@""];
    NSString *dayNow = [[today stringByReplacingCharactersInRange:NSMakeRange(0, 8) withString:@""] stringByReplacingCharactersInRange:NSMakeRange(2, 3) withString:@""];
    
    NSString *year = [date stringByReplacingCharactersInRange:NSMakeRange(4, 9) withString:@""];
    NSString *month = [[date stringByReplacingCharactersInRange:NSMakeRange(0, 5) withString:@""] stringByReplacingCharactersInRange:NSMakeRange(2, 6) withString:@""];
    NSString *day = [[date stringByReplacingCharactersInRange:NSMakeRange(0, 8) withString:@""] stringByReplacingCharactersInRange:NSMakeRange(2, 3) withString:@""];

    if (year.integerValue < yearNow.integerValue) {
        return YES;
    } else if (year.integerValue == yearNow.integerValue) {
        if (month.integerValue < monthNow.integerValue) {
            return YES;
        } else if (month.integerValue == monthNow.integerValue) {
            if (day.integerValue < dayNow.integerValue) {
                return YES;
            }
        }
    }
    
    return NO;
}

@end
