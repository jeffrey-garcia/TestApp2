//
//  Plugin.m
//  External
//
//  Created by jeffrey on 28/1/15.
//  Copyright (c) 2015 jeffrey. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "Plugin.h"

#import <UIKit/UIKit.h>

@implementation Plugin

- (void)sayHello
{
    NSURL *plistLocation = [[NSBundle bundleForClass:[self class]] URLForResource:@"Data" withExtension:@"plist"];
    NSDictionary *data = [NSDictionary dictionaryWithContentsOfURL:plistLocation];
    NSString *message = data[@"message"];
    
    UIAlertView *alertView = [[UIAlertView alloc] init];
    [alertView setTitle:@"Congratulations"];
    [alertView setMessage:message];
    [alertView addButtonWithTitle:@"OK"];
    [alertView show];
}

@end