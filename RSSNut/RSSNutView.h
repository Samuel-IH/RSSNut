//
//  RSSNutView.h
//  RSSNut
//
//  Created by Samuel I. Hart on 4/8/19.
//  Copyright © 2019 5amProductions. All rights reserved.
//

#import <ScreenSaver/ScreenSaver.h>
#import <QuartzCore/QuartzCore.h>
#import "NS(Attributed)String+Geometrics.h"
#import "ConfigurationController.h"
#import "ConfigurationWindow.h"
typedef struct Point3D_ {
    CGFloat x, y, z;
} Point3D;
Point3D Point3DMake( CGFloat xx, CGFloat yy, CGFloat zz ){
    Point3D p;
    p.x = xx; p.y = yy; p.z = zz;
    return p;
}
@interface RSSNutView : ScreenSaverView <NSXMLParserDelegate> {
    NSMutableArray * RSSItems;
    float hue;
    NSXMLParser * xmlParser;
    NSString * currentElement;
    NSString * foundCharacters;
    NSMutableDictionary * currentData;
    NSMutableArray * parsedData;
    bool isHeader;
    int currentIndex;
    NSDate * endDate;
    float readingSpeed;
    NSMutableArray * headlineStuff;
    Point3D headlinePoints[1000];
}
@property (weak) IBOutlet NSSlider *speedSlider;
@property (weak) IBOutlet NSTextField *rssURL;
@property (weak) IBOutlet NSColorWell *colorTheme;
@property (strong) IBOutlet NSWindow *confiSheet;

@end
