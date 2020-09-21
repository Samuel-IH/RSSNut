//
//  RenderView.h
//  RSSNut
//
//  Created by SamuelIH on 9/18/20.
//  Copyright © 2020 5amProductions. All rights reserved.
//

#import <Cocoa/Cocoa.h>

typedef struct Point3D_ {
    CGFloat x, y, z;
} Point3D;


NS_ASSUME_NONNULL_BEGIN

@interface RenderView : NSView <NSXMLParserDelegate> {
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

@end

NS_ASSUME_NONNULL_END
