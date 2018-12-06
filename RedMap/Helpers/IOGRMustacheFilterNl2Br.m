//
//  IOGRMustacheFilterNl2Br.m
//  Redmap
//
//  Created by Evo Stamatov on 2/10/13.
//  Copyright (c) 2013 Ionata. All rights reserved.
//

#import "IOGRMustacheFilterNl2Br.h"

@implementation IOGRMustacheFilterNl2Br

- (id)transformedValue:(id)object
{
    if ([object isKindOfClass:[NSString class]])
    {
        NSString *string = (NSString *)object;
        NSArray *paragraphs = [string componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
        paragraphs = [paragraphs filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"length > 0"]];
        return [paragraphs componentsJoinedByString:@"<br/><br/>"];
    }
    
    return object;
}

@end
