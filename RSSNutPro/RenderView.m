//
//  RenderView.m
//  RSSNut
//
//  Created by SamuelIH on 9/18/20.
//  Copyright © 2020 5amProductions. All rights reserved.
//

#import "RenderView.h"
#import "ShellExecution.m"
#define shadeRect(r) NSMakeRect(r.origin.x + 2, r.origin.y - 2, r.size.width, r.size.height)
Point3D Point3DMake( CGFloat xx, CGFloat yy, CGFloat zz ){
    Point3D p;
    p.x = xx; p.y = yy; p.z = zz;
    return p;
}
@implementation RenderView {
    NSImage *cachedHeadlines;
    NSDate *last;
    float saverTime;
    float readLength;
    NSWindow * myGoodyWindow;
    NSRect titleRect;
    NSRect descRect;
    NSRect fpsRect;
    NSRect linkRect;
    NSRect nextRect;
    CGFloat titleSize;
    CGFloat descSize;
    bool isFirst;
    NSImage *temp;
    NSString * rssUrl;
    NSUserDefaults * defaults;
    NSWindow * daWindow;
    CVDisplayLinkRef displayLink;
    
    bool isSettingsPanel;
}

static CVReturn MyDisplayLinkCallback(CVDisplayLinkRef displayLink, const CVTimeStamp* now, const CVTimeStamp* outputTime, CVOptionFlags flagsIn, CVOptionFlags* flagsOut, void* displayLinkContext)
{
    
    dispatch_async(dispatch_get_main_queue(), ^{
        RenderView* rView = (__bridge RenderView*)displayLinkContext;
        [rView setNeedsDisplay:YES];
    });
    return kCVReturnSuccess;
}
- (instancetype)initWithFrame:(NSRect)rframe
{
    self = [super initWithFrame:rframe];
    if (self) {
        
        isSettingsPanel = NO;
        
        CVDisplayLinkCreateWithActiveCGDisplays(&displayLink);
        CVDisplayLinkSetOutputCallback(displayLink, &MyDisplayLinkCallback, (__bridge void*)self);
        CVDisplayLinkStart(displayLink);
        
        NSRect frame = [[NSScreen mainScreen] frame];
        [self setWantsLayer:true];
        RSSItems = [NSMutableArray new];
        isFirst = true;
        hue = 0.3333;
        rssUrl = @"https://developer.apple.com/news/rss/news.rss";//http://rss.slashdot.org/Slashdot/slashdotMain";
        readingSpeed = 150;
        
        ///Extract prefs from existing instance
        //grab host UUID
        NSString* hostID = [[@"ioreg -d2 -c IOPlatformExpertDevice | awk -F\\\" '/IOPlatformUUID/{print $(NF-1)}'" runAsCommand] stringByReplacingOccurrencesOfString:@"\n" withString:@""];
        //use host UUID to guess rssnut's sandboxed pref path
        NSString* filePath = [NSString stringWithFormat:@"%@/Library/Containers/com.apple.ScreenSaver.Engine.legacyScreenSaver/Data/Library/Preferences/ByHost/com.samsolutions.RSSNut.%@.plist", NSHomeDirectory(), hostID];
        if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
            NSDictionary* dict = [NSDictionary dictionaryWithContentsOfFile: filePath];
            if (dict[@"setup"]) {
                NSNumber * hueNumb = dict[@"hue"];
                hue = [hueNumb floatValue];
                rssUrl = dict[@"rssUrl"];
                NSNumber * speedNumb = dict[@"readingSpeed"];
                readingSpeed = [speedNumb floatValue];
            }
        }
        
        temp = [[NSBundle bundleForClass:[self class]] imageForResource:@"TEMP"];
        xmlParser = [[NSXMLParser alloc] initWithContentsOfURL:[NSURL URLWithString:rssUrl]];
        xmlParser.delegate = self;
        currentElement = @"";
        foundCharacters = @"";
        currentData = [NSMutableDictionary new];
        parsedData = [NSMutableArray new];
        isHeader = true;
        currentIndex = 0;
        endDate = [NSDate new];
        headlineStuff = [NSMutableArray new];
        saverTime = 0;
        if ([xmlParser parse]) {
            [parsedData addObject:currentData];
        }
        if (parsedData.count > 0) {
            float titleTime = (float)[self countString:[(NSDictionary*)(parsedData[currentIndex]) valueForKey:@"title"]] / readingSpeed * 60.0;
            float descTime = (float)[self countString:[(NSDictionary*)(parsedData[currentIndex]) valueForKey:@"description"]] / readingSpeed * 60;
            readLength = titleTime + descTime;
            endDate = [[NSDate new] dateByAddingTimeInterval:readLength];
            int ii = 0;
            for (NSDictionary * dict in parsedData) {
                NSArray * titleParts = [[dict valueForKey:@"title"] componentsSeparatedByString:@" "];
                for (NSString * part in titleParts) {
                    if ([headlineStuff count] > 100) {
                        break;
                    }
                    float scaled = arc4random_uniform(50) + 10;
                    [headlineStuff addObject:[[NSAttributedString alloc] initWithString:part attributes:@{NSForegroundColorAttributeName : [NSColor colorWithHue:hue saturation:1 brightness:1.0 alpha:0.5], NSFontAttributeName : [NSFont fontWithName:@"PT Mono" size:scaled]}]];
                    headlinePoints[ii] = Point3DMake(arc4random_uniform(frame.size.width), arc4random_uniform(frame.size.height), scaled);
                    ii++;
                }
            }
            
            
        }
        last = [NSDate new];
        
        // set some positions
        titleRect = NSMakeRect([self sp:@"5w"], [self sp:@"80h"], [self sp:@"90w"], [self sp:@"10h"]);
        descRect = NSMakeRect([self sp:@"10w"], [self sp:@"15h"], [self sp:@"80w"], [self sp:@"50h"]);
        fpsRect = NSMakeRect([self sp:@"0w"], [self sp:@"0h"], [self sp:@"5w"], [self sp:@"5h"]);
        linkRect = NSMakeRect([self sp:@"10w"], [self sp:@"5h"], [self sp:@"30w"], [self sp:@"5h"]);
        nextRect = NSMakeRect([self sp:@"60w"], [self sp:@"5h"], [self sp:@"30w"], [self sp:@"5h"]);
        titleSize = 200;
        descSize = 100;
        
    }
    return self;
}


- (void)drawRect:(NSRect)rect
{
    [super drawRect:rect];
    if (rect.size.width < 600) {
        NSGradient * myGrad = [[NSGradient alloc] initWithStartingColor:[NSColor colorWithHue:hue saturation:1 brightness:0.0 alpha:1] endingColor:[NSColor colorWithHue:hue saturation:1 brightness:1 alpha:1]];
        [myGrad drawFromPoint:NSMakePoint(0, 0) toPoint:NSMakePoint(rect.size.width, rect.size.height) options:0];
        [temp drawInRect:rect];
        return;
    }
    //return;
    float deltaTime = [[NSDate new] timeIntervalSinceDate:last];
    saverTime += deltaTime;
    last = [NSDate new];
    
    //draw gradient
    if (!cachedHeadlines) {
        NSLog(@"caching");
        
        if (headlineStuff.count > 0) {
            NSImage *image = [[NSImage alloc] initWithSize:rect.size];
            [image lockFocus];
            //draw the background gradient
            NSGradient * myGrad = [[NSGradient alloc] initWithStartingColor:[NSColor colorWithHue:hue saturation:1 brightness:0.0 alpha:1] endingColor:[NSColor colorWithHue:hue saturation:1 brightness:1 alpha:1]];
            [myGrad drawFromPoint:NSMakePoint(0, 0) toPoint:NSMakePoint(rect.size.width, rect.size.height) options:0];
            
            
            [image unlockFocus];
            cachedHeadlines = image;
            
            
        }
    } else {
        [cachedHeadlines drawInRect:rect];
    }
    
    //set up attribute dict
    NSMutableDictionary* md = [NSMutableDictionary dictionaryWithCapacity:1];
    
    if (parsedData.count > 0) {
        //draw the background headlines
        int i = 0;
        for (NSAttributedString * theHeadlineWord in headlineStuff) {
            float xPos = headlinePoints[i].x-(saverTime*headlinePoints[i].z);
            float yPos = headlinePoints[i].y-(saverTime*headlinePoints[i].z/4);
            [theHeadlineWord drawAtPoint:CGPointMake(xPos, yPos)];
            NSRect drawRect = [theHeadlineWord boundingRectWithSize:rect.size options:0];
            if (xPos + drawRect.size.width < 0) {
                headlinePoints[i] = Point3DMake(headlinePoints[i].x + rect.size.width, headlinePoints[i].y, headlinePoints[i].z);
            }
            if (yPos + drawRect.size.height < 0) {
                headlinePoints[i] = Point3DMake(headlinePoints[i].x, headlinePoints[i].y + rect.size.height, headlinePoints[i].z);
            }
            i++;
        }
        NSString * title = [(NSDictionary*)(parsedData[currentIndex]) valueForKey:@"title"];
        NSRange range = NSMakeRange(0, ([[NSDate new] timeIntervalSinceDate:endDate] + readLength)*50);
        if (range.length < title.length) {
            title = [title substringWithRange:range];
        }
        if (!isSettingsPanel) {
            NSString * desc = [(NSDictionary*)(parsedData[currentIndex]) valueForKey:@"description"];
            
            
            if (isFirst) {
                //calculate new sizes
                
                NSTextField *t = [[NSTextField alloc] initWithFrame:NSMakeRect(0, 0, descRect.size.width, descRect.size.height)];
                t.backgroundColor = NSColor.clearColor;
                [self addSubview:t];
                //[t.cell cellSizeForBounds:NSMakeRect(0, 0, descRect.size.width, CGFLOAT_MAX)].height
                descSize = 100;
                [md setValue:[NSFont fontWithName:@"PT Mono" size:descSize] forKey:NSFontAttributeName];
                [t setAttributedStringValue:[[NSAttributedString alloc] initWithString:desc attributes:md]];
                while ([t.cell cellSizeForBounds:NSMakeRect(0, 0, descRect.size.width, CGFLOAT_MAX)].height > descRect.size.height) {
                    descSize -= 1;
                    [md setValue:[NSFont fontWithName:@"PT Mono" size:descSize] forKey:NSFontAttributeName];
                    [t setAttributedStringValue:[[NSAttributedString alloc] initWithString:desc attributes:md]];
                }
                
                titleSize = 200;
                [md setValue:[NSFont fontWithName:@"PT Mono" size:titleSize] forKey:NSFontAttributeName];
                [t setAttributedStringValue:[[NSAttributedString alloc] initWithString:[(NSDictionary*)(parsedData[currentIndex]) valueForKey:@"title"] attributes:md]];
                while ([t.cell cellSizeForBounds:NSMakeRect(0, 0, titleRect.size.width, CGFLOAT_MAX)].height > titleRect.size.height || [t.cell cellSizeForBounds:NSMakeRect(0, 0, CGFLOAT_MAX, titleRect.size.height)].width > titleRect.size.width) {//[(NSDictionary*)(parsedData[currentIndex]) valueForKey:@"title"]
                    titleSize -= 1;
                    [md setValue:[NSFont fontWithName:@"PT Mono" size:titleSize] forKey:NSFontAttributeName];
                    [t setAttributedStringValue:[[NSAttributedString alloc] initWithString:[(NSDictionary*)(parsedData[currentIndex]) valueForKey:@"title"] attributes:md]];
                }
                [t removeFromSuperview];
                isFirst = false;
            }
            
            
            // change color
            [md setValue:[NSColor colorWithWhite:0 alpha:MIN([endDate timeIntervalSinceNow]/2, 1.0)/2] forKey:NSForegroundColorAttributeName];
            //draw the shadow
            [md setValue:[NSFont fontWithName:@"PT Mono" size:titleSize] forKey:NSFontAttributeName];
            [title drawInRect:shadeRect(titleRect) withAttributes:md];
            [md setValue:[NSFont fontWithName:@"PT Mono" size:descSize] forKey:NSFontAttributeName];
            [desc drawInRect:shadeRect(descRect) withAttributes:md];
            
            
            //change color
            [md setValue:[NSColor colorWithWhite:1 alpha:MIN([endDate timeIntervalSinceNow]/2, 1.0)] forKey:NSForegroundColorAttributeName];
            //draw the text
            [md setValue:[NSFont fontWithName:@"PT Mono" size:titleSize] forKey:NSFontAttributeName];
            [title drawInRect:titleRect withAttributes:md];
            [md setValue:[NSFont fontWithName:@"PT Mono" size: descSize] forKey:NSFontAttributeName];
            [desc drawInRect:descRect withAttributes:md];
            
            
            
            if ([[NSDate new] timeIntervalSinceDate:endDate] > 0) {
                currentIndex += 1;
                if (currentIndex > parsedData.count - 1) {
                    currentIndex = 0;
                }
                float titleTime = (float)[self countString:[(NSDictionary*)(parsedData[currentIndex]) valueForKey:@"title"]] / readingSpeed * 60.0;
                float descTime = (float)[self countString:[(NSDictionary*)(parsedData[currentIndex]) valueForKey:@"description"]] / readingSpeed * 60;
                readLength = titleTime + descTime;
                endDate = [[NSDate new] dateByAddingTimeInterval:readLength];
                
                //calculate new sizes
                NSTextField *t = [[NSTextField alloc] initWithFrame:NSMakeRect(0, 0, descRect.size.width, descRect.size.height)];
                t.backgroundColor = NSColor.clearColor;
                [self addSubview:t];
                descSize = 100;
                [md setValue:[NSFont fontWithName:@"PT Mono" size:descSize] forKey:NSFontAttributeName];
                [t setAttributedStringValue:[[NSAttributedString alloc] initWithString:[(NSDictionary*)(parsedData[currentIndex]) valueForKey:@"description"] attributes:md]];
                while ([t.cell cellSizeForBounds:NSMakeRect(0, 0, descRect.size.width, CGFLOAT_MAX)].height > descRect.size.height) {
                    descSize -= 1;
                    [md setValue:[NSFont fontWithName:@"PT Mono" size:descSize] forKey:NSFontAttributeName];
                    [t setAttributedStringValue:[[NSAttributedString alloc] initWithString:[(NSDictionary*)(parsedData[currentIndex]) valueForKey:@"description"] attributes:md]];
                }
                
                titleSize = 200;
                [md setValue:[NSFont fontWithName:@"PT Mono" size:titleSize] forKey:NSFontAttributeName];
                [t setAttributedStringValue:[[NSAttributedString alloc] initWithString:[(NSDictionary*)(parsedData[currentIndex]) valueForKey:@"title"] attributes:md]];
                while ([t.cell cellSizeForBounds:NSMakeRect(0, 0, titleRect.size.width, CGFLOAT_MAX)].height > titleRect.size.height || [t.cell cellSizeForBounds:NSMakeRect(0, 0, CGFLOAT_MAX, titleRect.size.height)].width > titleRect.size.width) {//[(NSDictionary*)(parsedData[currentIndex]) valueForKey:@"title"]
                    titleSize -= 1;
                    [md setValue:[NSFont fontWithName:@"PT Mono" size:titleSize] forKey:NSFontAttributeName];
                    [t setAttributedStringValue:[[NSAttributedString alloc] initWithString:[(NSDictionary*)(parsedData[currentIndex]) valueForKey:@"title"] attributes:md]];
                }
                [t removeFromSuperview];
            }
        }
    }
    
    if (isSettingsPanel) {
        [md setValue:[NSFont fontWithName:@"PT Mono" size:24] forKey:NSFontAttributeName];
        [md setValue:[NSColor colorWithWhite:1 alpha:1] forKey:NSForegroundColorAttributeName];
        [@"Key Command : Action\n\n          A : Install Agent; Will make sceensaver work normally\n          U : Uninstall Agent; Will disable the pseudoSaver;\n          S : Exit Settings; Will take you back to the main area" drawInRect:descRect withAttributes:md];
    }
    
    [md setValue:[NSFont fontWithName:@"PT Mono" size:18] forKey:NSFontAttributeName];
    [md setValue:[NSColor colorWithWhite:1 alpha:1] forKey:NSForegroundColorAttributeName];
    [@"Press the L key to read in your preferred browser." drawInRect:linkRect withAttributes:md];
    [@"Press the Left and Right arrow keys to navigate." drawInRect:nextRect withAttributes:md];
    [[NSString stringWithFormat:@"%f", 1.0 / deltaTime] drawInRect:fpsRect withAttributes:@{NSForegroundColorAttributeName: NSColor.whiteColor}];
}
+ (NSImage*) screenCacheImageForView:(NSView*)aView
{
    NSRect originRect = [aView convertRect:[aView bounds] toView:[[aView window] contentView]];
    
    NSRect rect = originRect;
    rect.origin.y = 0;
    rect.origin.x += [aView window].frame.origin.x;
    rect.origin.y += [[aView window] screen].frame.size.height - [aView window].frame.origin.y - [aView window].frame.size.height;
    rect.origin.y += [aView window].frame.size.height - originRect.origin.y - originRect.size.height;
    
    CGImageRef cgimg = CGWindowListCreateImage(rect,
                                               kCGWindowListOptionIncludingWindow,
                                               (CGWindowID)[[aView window] windowNumber],
                                               kCGWindowImageDefault);
    return [[NSImage alloc] initWithCGImage:cgimg size:[aView bounds].size];
}


//screen percentage
-(CGFloat)sp:(NSString*)f{
    NSRect frame = [[NSScreen mainScreen] frame];
    if ([f containsString:@"w"]) {
        return [[f stringByReplacingOccurrencesOfString:@"w" withString:@""] floatValue] / 100 * frame.size.width;
    } else {
        return [[f stringByReplacingOccurrencesOfString:@"h" withString:@""] floatValue] / 100 * frame.size.height;
    }
}

- (NSSize)sizeForString:(NSString*)text attributes:(NSDictionary*)attr width:(CGFloat)myWidth{
    
    CGRect rect = [text boundingRectWithSize:CGSizeMake(myWidth, CGFLOAT_MAX)
                                     options:NSStringDrawingUsesLineFragmentOrigin
                                  attributes:attr
                                     context:nil];
    rect.size.width = ceil(rect.size.width);
    rect.size.height = ceil(rect.size.height);
    return rect.size;
}


- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary<NSString *,NSString *> *)attributeDict {
    currentElement = elementName;
    if ([currentElement isEqualToString:@"item"] || [currentElement isEqualToString:@"entry"]) {
        if (!isHeader) {
            [parsedData addObject:currentData.copy];
        }
        isHeader = false;
    }
    if (!isHeader) {
        if ([currentElement isEqualToString:@"media:thumbnail"] || [currentElement isEqualToString:@"media:content"]) {
            foundCharacters = [foundCharacters stringByAppendingString:attributeDict[@"url"]];
        }
    }
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {
    if (!isHeader) {
        if ([currentElement isEqualToString:@"title"] || [currentElement isEqualToString:@"link"] || [currentElement isEqualToString:@"description"] || [currentElement isEqualToString:@"content"] || [currentElement isEqualToString:@"pubDate"] || [currentElement isEqualToString:@"author"] || [currentElement isEqualToString:@"dc:creator"] || [currentElement isEqualToString:@"content:encoded"]) {
            foundCharacters = [foundCharacters stringByAppendingString:string];
            foundCharacters = [foundCharacters stringByReplacingOccurrencesOfString:@"<[^>]+>" withString:@"" options:NSRegularExpressionSearch range:NSMakeRange(0, foundCharacters.length)];
        }
    }
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName {
    if (foundCharacters.length > 0) {
        foundCharacters = [foundCharacters stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
        [currentData setValue:foundCharacters forKey:currentElement];
        foundCharacters = @"";
    }
}
-(NSUInteger)countString:(NSString*)theString {
    return [[NSSpellChecker sharedSpellChecker] countWordsInString:theString language:nil];
}
- (void)keyDown:(NSEvent *)event{
    NSLog(@"%d", event.keyCode);
    
    if (isSettingsPanel) {
        NSString * plist = [NSHomeDirectory() stringByAppendingString:@"/Library/LaunchAgents/com.samsolutions.RSSNutPro.keepAlive.plist"];
        if (event.keyCode == 0) {//A
            NSString * launchAgent = [NSString stringWithFormat:@"<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">\n<plist version=\"1.0\">\n  <dict>\n    <key>KeepAlive</key>\n      <true/>\n    <key>Label</key>\n      <string>com.samsolutions.RSSNutPro.keepAlive</string>\n    <key>Program</key>\n      <string>%@</string>\n  </dict>\n</plist>", NSProcessInfo.processInfo.arguments[0]];
            
            [launchAgent writeToFile:plist atomically:false encoding:NSUTF8StringEncoding error:nil];
            [[NSString stringWithFormat:@"launchctl load \"%@\"", plist] runAsCommand];
            return;
        }
        if (event.keyCode == 3) {//U
            [[NSString stringWithFormat:@"launchctl unload \"%@\"", plist] runAsCommand];
            [[NSFileManager defaultManager] removeItemAtPath:plist error:nil];
            return;
        }
    }
    
    if (event.keyCode == 41) {//S
        isSettingsPanel = !isSettingsPanel;
        return;
    }
    if (event.keyCode == 124) {//right arrow
        endDate = [NSDate new];
        return;
    }
    if (event.keyCode == 123) {//right arrow
        currentIndex -= 2;
        if (currentIndex < 0) {
            currentIndex = parsedData.count - 2;
        }
        
        endDate = [NSDate new];
        return;
    }
    if (event.keyCode == 35) {//L
        [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:(NSString*)[(NSDictionary*)(parsedData[currentIndex]) valueForKey:@"link"]]];
    }
    NSLog(@"closing");
    CVDisplayLinkRelease(displayLink);
    [NSCursor unhide];
    [self.window close];
}

//support mouseMoved events
- (void)updateTrackingAreas {
    NSTrackingAreaOptions options = (NSTrackingActiveAlways | NSTrackingInVisibleRect |
                                     NSTrackingMouseEnteredAndExited | NSTrackingMouseMoved);
    
    NSTrackingArea *area = [[NSTrackingArea alloc] initWithRect:[self bounds]
                                                        options:options
                                                          owner:self
                                                       userInfo:nil];
    [self addTrackingArea:area];
}
- (void)mouseMoved:(NSEvent *)event {
    NSLog(@"closing");
    CVDisplayLinkRelease(displayLink);
    [NSCursor unhide];
    [self.window close];
}
- (void)mouseDown:(NSEvent *)event {
    NSLog(@"closing");
    CVDisplayLinkRelease(displayLink);
    [NSCursor unhide];
    [self.window close];
}
- (BOOL)acceptsFirstResponder {
    return YES;
}
@end
