//
//  User.h
//  Redmap
//
//  Created by Evo Stamatov on 18/09/13.
//  Copyright (c) 2013 Ionata. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Sighting;

@interface User : NSManagedObject

@property (nonatomic, retain) NSString * authToken;
@property (nonatomic, retain) NSDate * dateCreated;
@property (nonatomic, retain) NSDate * dateModified;
@property (nonatomic, retain) NSString * email;
@property (nonatomic, retain) NSNumber * facebookID;
@property (nonatomic, retain) NSString * firstName;
@property (nonatomic, retain) NSNumber * joinMailingList;
@property (nonatomic, retain) NSString * lastName;
@property (nonatomic, retain) NSString * password;
@property (nonatomic, retain) NSString * region;
@property (nonatomic, retain) NSNumber * status;
@property (nonatomic, retain) NSNumber * userID;
@property (nonatomic, retain) NSString * username;
@property (nonatomic, retain) NSSet *sightings;
@end

@interface User (CoreDataGeneratedAccessors)

- (void)addSightingsObject:(Sighting *)value;
- (void)removeSightingsObject:(Sighting *)value;
- (void)addSightings:(NSSet *)values;
- (void)removeSightings:(NSSet *)values;

@end
