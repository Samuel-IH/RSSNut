//
//  ConfigurationController.m
//  RSSNut
//
//  Created by Samuel I. Hart on 4/12/19.
//  Copyright © 2019 5amProductions. All rights reserved.
//

#import "ConfigurationController.h"

@interface ConfigurationController ()
@property (weak) IBOutlet NSColorWell *theColorWell;

@end

@implementation ConfigurationController

- (void)windowDidLoad {
    [super windowDidLoad];
    NSButton * mb = (NSButton *)[self.window.contentView viewWithTag:5];
    //[mb setTarget:self];
    //[mb setAction:@selector(ooglaboogla:)];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}
- (IBAction)doneAction:(id)sender {
    [self showSimpleAlert];
    //[[self.window sheetParent] endSheet:self.window];
    [NSApp endSheet:[self window] returnCode:NSCancelButton];
}
- (IBAction)ooglaboogla:(id)sender {
}
-(void)showSimpleAlert
{
    NSAlert *alert = [[NSAlert alloc] init];
    [alert addButtonWithTitle:@"Continue"];
    [alert addButtonWithTitle:@"Cancel"];
    [alert setMessageText:@"Alert"];
     [alert setAlertStyle:NSWarningAlertStyle];
     [alert beginSheetModalForWindow:[self window] modalDelegate:self didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:) contextInfo:nil];
     }
@end
