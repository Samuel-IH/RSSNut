//
//  AppDelegate.m
//  RSSNutPro
//
//  Created by SamuelIH on 9/18/20.
//  Copyright © 2020 5amProductions. All rights reserved.
//

#import "AppDelegate.h"
#import "ShellExecution.h"
#import "RenderWindow.h"
#import "RenderView.h"
@interface AppDelegate () {
    NSInteger screenSaverTime;
    IOReturn success;
}

@property  (nonatomic) NSWindow  *window;
@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    //Get to work! we need to frequently check if the screensaver has started
    NSDictionary *options = @{(__bridge id) kAXTrustedCheckOptionPrompt : @YES};
    //hey user! Trust us for accessibility, we need it to disable the native screensaver.
    AXIsProcessTrustedWithOptions((__bridge CFDictionaryRef) options);
    [NSTimer scheduledTimerWithTimeInterval:0.5f target:self selector:@selector(testActivity:) userInfo:nil repeats:YES];
}


- (void)testActivity:(NSTimer *)timer
{
    //cleaner, used to invalidate window when it's closed
    if (self.window) {
        if (!self.window.isVisible) {
            self.window = nil;
        }
    }
    //if the window is not nil, our screensaver is already up! (do nothing)
    if (self.window) {
        [NSApp activateIgnoringOtherApps:YES];
        return;
    }
    
    //our screensaver is not up, check and see if the system's one is
    NSString* screenSaverIsUp = [@"ps -axc -o comm | grep ScreenSaverEngine" runAsCommand];
    if (![screenSaverIsUp isEqualToString:@""]) {
        
        //screensaver is up. Is it ours?
        if ([[@"defaults -currentHost read com.apple.screensaver moduleDict | grep RSSNut" runAsCommand] isEqualToString:@""]) {
            return; //rssnut is not the screensaver, do nothing
        }

        // we do this after a delay because we want our screensaver to actually load before replacing the existing one
        [self performSelector:@selector(killScreenSaver) withObject:nil afterDelay:1];
        
        //bring up our screensaver
        self.window = [[RenderWindow alloc] init];
        //we manually release by setting to `nil`
        [self.window setReleasedWhenClosed:NO];
        //remove the title bar
        [self.window setStyleMask:NSWindowStyleMaskBorderless];
        //make higher than everything else
        [self.window setLevel:NSScreenSaverWindowLevel];
        //fullscreen
        [self.window setFrame:[[NSScreen mainScreen] frame] display:YES];
        [self.window setContentView:[[RenderView alloc] initWithFrame:NSZeroRect]];
        [self.window makeKeyAndOrderFront:NULL];
        //ugly so we hide it
        [NSCursor hide];
        NSLog(@"Coming to front");
        
    }
    
}
/// This will kill the running screensaver, and replace it with ours.
- (void)killScreenSaver {

    CGEventRef keyup, keydown;
    keydown = CGEventCreateKeyboardEvent (NULL, (CGKeyCode)123, true);
    keyup = CGEventCreateKeyboardEvent (NULL, (CGKeyCode)123, false);

    CGEventPost(kCGHIDEventTap, keydown);
    CGEventPost(kCGHIDEventTap, keyup);
    CFRelease(keydown);
    CFRelease(keyup);
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}


@end
