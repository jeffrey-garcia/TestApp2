//
//  Plugin.m
//  TestApp3
//
//  Created by jeffrey on 29/1/15.
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
    [alertView setTitle:@"Oh Hai"];
    [alertView setMessage:message];
    [alertView addButtonWithTitle:@"OK"];
    [alertView show];
}

@end