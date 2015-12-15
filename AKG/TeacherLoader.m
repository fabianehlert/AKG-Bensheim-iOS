//
//  TeacherLoader.m
//  AKG
//
//  Created by Fabian Ehlert on 09.02.14.
//  Copyright (c) 2014 Fabian Ehlert. All rights reserved.
//

#import "TeacherLoader.h"
#import "Teacher.h"

@implementation TeacherLoader

+ (NSArray *)savedTeachers
{
    NSData *savedData = [[NSUserDefaults standardUserDefaults] objectForKey:[NSString stringWithFormat:@"TEACHERS_ARRAY"]];
    NSArray *teachersArray = @[];
    if (savedData) {
        teachersArray = [NSKeyedUnarchiver unarchiveObjectWithData:savedData];
    }
    
    return teachersArray;
}

+ (NSArray *)latestTeachers
{
    NSMutableArray *mutableTeachers = [[NSMutableArray alloc] init];
    NSData *allTeachersData = [[NSData alloc] initWithContentsOfURL:[NSURL URLWithString:@"http://akgbensheim.de/support/teachers.json"]];
    
    if (allTeachersData) {
        NSError *error;
        NSMutableDictionary *allTeachers = [NSJSONSerialization
                                            JSONObjectWithData:allTeachersData
                                            options:NSJSONReadingMutableContainers
                                            error:&error];
        
        if (error) {
            NSLog(@"ERROR= %@", [error localizedDescription]);
        } else {
            NSArray *teachersArray = allTeachers[@"teachers"];
            for (NSDictionary *tc in teachersArray)
            {
                Teacher *teacher = [[Teacher alloc] initWithFirstName:tc[@"firstname"]
                                                             lastName:tc[@"lastname"]
                                                            shortName:tc[@"shortname"]
                                                             subjects:tc[@"subjects"]
                                                                 mail:tc[@"email"]];
                [mutableTeachers addObject:teacher];
            }
            
            [[NSUserDefaults standardUserDefaults] setObject:[NSKeyedArchiver archivedDataWithRootObject:[NSArray arrayWithArray:mutableTeachers]] forKey:[NSString stringWithFormat:@"TEACHERS_ARRAY"]];
            [[NSUserDefaults standardUserDefaults] synchronize];
        }
    } else {
        NSData *savedData = [[NSUserDefaults standardUserDefaults] objectForKey:[NSString stringWithFormat:@"TEACHERS_ARRAY"]];
        NSArray *teachersArray = @[];
        if (savedData) {
            teachersArray = [NSKeyedUnarchiver unarchiveObjectWithData:savedData];
        }
        
        mutableTeachers = [NSMutableArray arrayWithArray:teachersArray];
    }
    
    return [NSArray arrayWithArray:mutableTeachers];
}

@end
