//
//  RSSNutView.m
//  RSSNut
//
//  Created by Samuel I. Hart on 4/8/19.
//  Copyright © 2019 5amProductions. All rights reserved.
//

#import "RSSNutView.h"
#define shadeRect(r) NSMakeRect(r.origin.x + 2, r.origin.y - 2, r.size.width, r.size.height)
@implementation RSSNutView {
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
}

- (instancetype)initWithFrame:(NSRect)frame isPreview:(BOOL)isPreview
{
    self = [super initWithFrame:frame isPreview:isPreview];
    if (self) {
        [self setWantsLayer:true];
        RSSItems = [NSMutableArray new];
        isFirst = true;
        hue = 0.3333;
        rssUrl = @"https://developer.apple.com/news/rss/news.rss";//http://rss.slashdot.org/Slashdot/slashdotMain";
        readingSpeed = 150;
        defaults = [ScreenSaverDefaults defaultsForModuleWithName:[NSBundle bundleForClass:[self class]].bundleIdentifier];
        if ([defaults boolForKey:@"setup"]) {
            hue = [defaults floatForKey:@"hue"];
            rssUrl = [defaults objectForKey:@"rssUrl"];
            readingSpeed = [defaults floatForKey:@"readingSpeed"];
        }
        temp = [[NSBundle bundleForClass:[self class]] imageForResource:@"TEMP"];
        if (frame.size.width > 600) {
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
        [self setAnimationTimeInterval:1/60.0];
    }
    return self;
}

- (void)startAnimation
{
    [super startAnimation];
}

- (void)stopAnimation
{
    [super stopAnimation];
}
- (BOOL)hasConfigureSheet{
    return true;
}
-(void)saveSettings {
    NSLog(@"Button pressed!");
    [[NSApplication sharedApplication] endSheet:myGoodyWindow];
    
    //Do what You want here...
}
-(void)stopSettings {
    NSLog(@"Button pressed!");
    [[NSApp keyWindow] endSheet:myGoodyWindow];
    
    //Do what You want here...
}
- (NSWindow *)configureSheet
{
    
    daWindow = [[[ConfigurationController alloc] initWithWindowNibName:@"ConfigurationController"] window];
    return daWindow;
    
}
- (void)drawRect:(NSRect)rect
{
    [super drawRect:rect];
    if (rect.size.width < 600) {
        if (daWindow) {
            hue = [(ConfigurationWindow *)daWindow theColor].color.hueComponent;
        }
        NSGradient * myGrad = [[NSGradient alloc] initWithStartingColor:[NSColor colorWithHue:hue saturation:1 brightness:0.0 alpha:1] endingColor:[NSColor colorWithHue:hue saturation:1 brightness:1 alpha:1]];
        [myGrad drawFromPoint:NSMakePoint(0, 0) toPoint:NSMakePoint(rect.size.width, rect.size.height) options:0];
        [temp drawInRect:rect];
        return;
    }
    //return;
    float deltaTime = [[NSDate new] timeIntervalSinceDate:last];
    saverTime += deltaTime;
    last = [NSDate new];
    
    
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
        
        
        
        //[[(NSDictionary*)(parsedData[currentIndex]) valueForKey:@"description"]
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
    
    
    [md setValue:[NSFont fontWithName:@"PT Mono" size:18] forKey:NSFontAttributeName];
    [md setValue:[NSColor colorWithWhite:1 alpha:1] forKey:NSForegroundColorAttributeName];
    [@"Press the L key to read in your preferred browser." drawInRect:linkRect withAttributes:md];
    [@"Press the N key to skip to the next." drawInRect:nextRect withAttributes:md];
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

- (void)animateOneFrame
{
    //NSLog(@"%f", goobga);
    [self setNeedsDisplay:YES];
    return;
}
//screen percentage
-(CGFloat)sp:(NSString*)f{
    if ([f containsString:@"w"]) {
        return [[f stringByReplacingOccurrencesOfString:@"w" withString:@""] floatValue] / 100 * self.bounds.size.width;
    } else {
        return [[f stringByReplacingOccurrencesOfString:@"h" withString:@""] floatValue] / 100 * self.bounds.size.height;
    }
}
- (void)keyDown:(NSEvent *)event{
    if (event.keyCode == 37) {//N
        endDate = [NSDate new];
    } else {
        if (event.keyCode == 35) {//L
            [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:(NSString*)[(NSDictionary*)(parsedData[currentIndex]) valueForKey:@"link"]]];
        }
        [super keyDown:event];
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
@end
