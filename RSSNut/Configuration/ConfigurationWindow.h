//
//  ConfigurationWindow.h
//  RSSNut
//
//  Created by Samuel I. Hart on 4/14/19.
//  Copyright © 2019 5amProductions. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <ScreenSaver/ScreenSaver.h>
NS_ASSUME_NONNULL_BEGIN

@interface ConfigurationWindow : NSWindow
@property (weak) IBOutlet NSButton *theDoneButton;
- (IBAction)beDone:(id)sender;
@property (weak) IBOutlet NSColorWell *theColor;
@property (weak) IBOutlet NSTextField *theLink;
@property (weak) IBOutlet NSSlider *theSpeed;
@property (weak) IBOutlet NSButton *titleFlash;


@end

NS_ASSUME_NONNULL_END
