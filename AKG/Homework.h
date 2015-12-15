//
//  Homework.h
//  AKG
//
//  Created by Fabian Ehlert on 08.03.14.
//  Copyright (c) 2014 Fabian Ehlert. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Homework : NSManagedObject

@property (nonatomic, retain) NSString * subject;
@property (nonatomic, retain) NSString * taskTitle;
@property (nonatomic, retain) NSNumber * done;
@property (nonatomic, retain) NSDate * dueDate;
@property (nonatomic, retain) NSString * identifier;
@property (nonatomic, retain) NSString * taskNote;

@end
