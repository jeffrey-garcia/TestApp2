//
//  ViewController.m
//  TestApp2
//
//  Runtime Plugin Loader (Proof Of Concept)
//  - currently can only support runtime loading of one plugin
//
//  Created by jeffrey on 28/1/15.
//  Copyright (c) 2015 jeffrey. All rights reserved.
//

#import "ZipArchive.h"

#import "ViewController.h"

#import <MobileCoreServices/MobileCoreServices.h>

@interface NSObject (PluginInterface)

- (void)sayHello;

@end

@interface ViewController ()

@property (strong, nonatomic) NSSet *pluginIdentifiers;

@end

@implementation ViewController

static NSString * const PluginType = @"com.apple.generic-bundle";

UIButton *downloadPluginBtn;
UIButton *loadPluginBtn;
UIButton *runPluginBtn;


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    NSLog(@"viewDidLoad");
    
    downloadPluginBtn = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    downloadPluginBtn.frame = CGRectMake(80.0, 150.0, 160.0, 40.0);
    [[downloadPluginBtn layer] setBorderWidth:2.0f];
    [[downloadPluginBtn layer] setBorderColor:[UIColor grayColor].CGColor];
    [downloadPluginBtn setTitle:@"Download Plugin" forState:UIControlStateNormal];
    [downloadPluginBtn addTarget:self action:@selector(downloadPlugin:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:downloadPluginBtn];
    
    loadPluginBtn = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    loadPluginBtn.frame = CGRectMake(80.0, 210.0, 160.0, 40.0);
    [[loadPluginBtn layer] setBorderWidth:2.0f];
    [[loadPluginBtn layer] setBorderColor:[UIColor grayColor].CGColor];
    [loadPluginBtn setTitle:@"Load Plugin" forState:UIControlStateNormal];
    [loadPluginBtn addTarget:self action:@selector(loadPlugin:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:loadPluginBtn];
    
    
    runPluginBtn = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    runPluginBtn.frame = CGRectMake(80.0, 270.0, 160.0, 40.0);
    runPluginBtn.enabled = NO;
    [[runPluginBtn layer] setBorderWidth:2.0f];
    [[runPluginBtn layer] setBorderColor:[UIColor grayColor].CGColor];
    [runPluginBtn setTitle:@"Run Plugin" forState:UIControlStateNormal];
    [runPluginBtn addTarget:self action:@selector(runPlugin:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:runPluginBtn];
}

-(void)downloadPlugin:(UIButton *)sender
{
    //download file in a separate thread
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSString *urlToDownload = @"";
        #if TARGET_IPHONE_SIMULATOR
            //Simulator
            NSLog(@"running simulator...");
            urlToDownload = @"https://sites.google.com/site/jeffreygarcia/work/Plugin.bundle-sim.zip";
        #else
            // Device
            NSLog(@"running real device...");
            //urlToDownload = @"https://sites.google.com/site/jeffreygarcia/work/Plugin.bundle-real.zip";
            urlToDownload = @"https://sites.google.com/site/jeffreygarcia/work/Plugin.bundle.zip"; // unsigned bundle
        #endif
        NSLog(@"download started... %@", urlToDownload);
        
        NSURL *url = [NSURL URLWithString:urlToDownload];
        NSData *urlData = [NSData dataWithContentsOfURL:url];
        
        NSLog(@"download completed");
        
        if (urlData) {
            // retrieve the application's document directory path
            NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
            NSString *documentsDirectory = [paths objectAtIndex:0];
            
            // define target file path and name
            NSString *filePath = [documentsDirectory stringByAppendingPathComponent:@"Plugin.bundle.zip"];
            filePath = [filePath stringByStandardizingPath];
            
            // saving file to local is done on main thread
            dispatch_async(dispatch_get_main_queue(), ^{
                [urlData writeToFile:filePath atomically:YES];
                NSLog(@"file is saved to local!");
            });
            
            // unzip file is done on main thread
            dispatch_async(dispatch_get_main_queue(), ^{
                ZipArchive *zipArchive = [[ZipArchive alloc] init];
                NSLog(@"file path: %@", filePath);
                
                if([zipArchive UnzipOpenFile:filePath])
                {
                    if ([zipArchive UnzipFileTo:documentsDirectory overWrite:YES])
                    {
                        NSLog(@"unzip file is completed");
                        
                        //unzipped successfully
                        [zipArchive UnzipCloseFile];
                    }
                } else {
                    NSLog(@"FAIL to open archive");
                }
            });
        }
    });
}

-(void)loadPlugin:(UIButton *)sender
{
    NSLog(@"loadPlugin");
    
    NSURL *documentsLocation = [NSURL fileURLWithPath:[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject]];
    NSLog(@"documentLocation %@", documentsLocation);
    
    NSArray *contents = [[NSFileManager defaultManager] contentsOfDirectoryAtURL:documentsLocation includingPropertiesForKeys:@[NSFileType] options:(NSDirectoryEnumerationOptions)0 error:NULL];
    
    __block BOOL foundPlugin = NO;
    __block NSURL *foundPluginUrl;
    
    [contents enumerateObjectsUsingBlock:^ (NSURL *fileURL, NSUInteger idx, BOOL *stop) {
        NSLog(@"file URL %@", fileURL);
        NSString *fileType = [fileURL resourceValuesForKeys:@[NSURLTypeIdentifierKey] error:NULL][NSURLTypeIdentifierKey];
        NSLog(@"fileType %@", fileType);
        if (fileType == nil) {
            return;
        }
        
        if (UTTypeConformsTo((__bridge CFStringRef)fileType, (__bridge CFStringRef)PluginType)) {
            foundPlugin = YES;
            foundPluginUrl = fileURL;
            return; // quit the loop if found
        }
    }];
    
    if (!foundPlugin) {
        NSLog(@"Plugin is NOT found");
        [self _showAlert:@"Could not find plugin" message:@"No plugin could be found. Make sure that you manually copy a plugin into the Documents directory."];
    } else {
        NSLog(@"Plugin is found");
        [self _loadPluginAtLocation:foundPluginUrl];
    }
}

- (void)_loadPluginAtLocation:(NSURL *)pluginLocation
{
    NSLog(@"Loading Plugin: %@", pluginLocation);
    NSBundle *plugin = [[NSBundle alloc] initWithURL:pluginLocation];
    
    NSError *preflightError = nil;
    BOOL preflight = [plugin preflightAndReturnError:&preflightError];
    if (!preflight) {
        [self _showAlert:@"Cannot Load Plugin" message:[NSString stringWithFormat:@"The plugin could not be preflighted: %@", [preflightError localizedDescription]]];
        return;
    }
    
    BOOL loaded = [plugin load];
    if (!loaded) {
        [self _showAlert:@"Cannot Load Plugin" message:@"The plugin could not be loaded."];
        return;
    }
    
    Class pluginClass = [plugin principalClass];
    if (pluginClass == nil) {
        [self _showAlert:@"Cannot Load plugin" message:@"The plugin principal class could not be retrieved."];
        return;
    }
    
    NSString *pluginIdentifier = [plugin bundleIdentifier];
    if (pluginIdentifier == nil) {
        [self _showAlert:@"Cannot Load plugin" message:@"The plugin bundle identifier could not be retrieved."];
        return;
    }
    
    NSMutableSet *pluginIdentifiers = [NSMutableSet setWithSet:[self pluginIdentifiers]];
    [pluginIdentifiers addObject:pluginIdentifier];
    [self setPluginIdentifiers:pluginIdentifiers];
    
    [self _showAlert:@"Plugin Loaded!" message:[NSString stringWithFormat:@"The plugin with bundle identifier %@ was loaded.", pluginIdentifier]];
    
    runPluginBtn.enabled = YES;
}

- (void)_showAlert:(NSString *)title message:(NSString *)message
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alert show];
}

-(void)runPlugin:(UIButton *)sender
{
    NSLog(@"runPlugin");
    
    NSString *pluginIdentifier = [[self pluginIdentifiers] anyObject];
    if (pluginIdentifier == nil) {
        [self _showAlert:@"No Plugin Loaded" message:@"Please load the plugins first."];
        return;
    }
    
    NSBundle *plugin = [NSBundle bundleWithIdentifier:pluginIdentifier];
    
    id pluginInstance = [[[plugin principalClass] alloc] init];
    if (![pluginInstance respondsToSelector:@selector(sayHello)]) {
        [self _showAlert:@"Unexpected Plugin" message:@"The plugin does not contain the expected type."];
        return;
    }
    
    [pluginInstance sayHello];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
