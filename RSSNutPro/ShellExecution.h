//https://stackoverflow.com/a/19014463/11161266

#import <Cocoa/Cocoa.h>

@interface NSString (ShellExecution)
- (NSString*)runAsCommand;
@end
