//
//  ConfigurationWindow.m
//  RSSNut
//
//  Created by Samuel I. Hart on 4/14/19.
//  Copyright © 2019 5amProductions. All rights reserved.
//

#import "ConfigurationWindow.h"

@implementation ConfigurationWindow {
    NSUserDefaults * defaults;
}

- (IBAction)beDone:(id)sender {
    
    if (self.titleFlash.state == NSControlStateValueOn) {
        [defaults setFloat:1900 forKey:@"readingSpeed"];
    } else {
        [defaults setFloat:self.theSpeed.floatValue - 100 forKey:@"readingSpeed"];
    }

    [defaults setObject:self.theLink.stringValue forKey:@"rssUrl"];
    [defaults setFloat:self.theColor.color.hueComponent forKey:@"hue"];
    [defaults setBool:true forKey:@"setup"];
    [defaults synchronize];
    
    [[self sheetParent] endSheet:self];
}
- (void)awakeFromNib{
    [super awakeFromNib];
    defaults = [ScreenSaverDefaults defaultsForModuleWithName:[NSBundle bundleForClass:[self class]].bundleIdentifier];
    if ([defaults boolForKey:@"setup"]) {
        self.theColor.color = [NSColor colorWithHue:[defaults floatForKey:@"hue"] saturation:1 brightness:1 alpha:1];
        self.theLink.stringValue = [defaults objectForKey:@"rssUrl"];
        float speed = [defaults floatForKey:@"readingSpeed"] + 100;
        if (speed == 2000) {
            [self.titleFlash setState:NSControlStateValueOn];
        } else {
            self.theSpeed.floatValue = speed;
        }
    }
}
@end
