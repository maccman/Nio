//
//  AppController.h
//  Nio - Notify.io client
//
//  Copyright 2009 GliderLab. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Growl-WithInstaller/GrowlApplicationBridge.h"
#import "Client.h"

@interface AppController : NSObject <GrowlApplicationBridgeDelegate> {
	IBOutlet NSMenu *statusMenu;
	NSStatusItem *statusItem;
	NSImage *statusImage;
	NSImage *statusHighlightImage;
	NSMutableArray *clients;
	IBOutlet NSMenuItem *openAtLoginMenuItem;
}

-(IBAction)openHistory:(id)sender;
-(IBAction)openSources:(id)sender;
-(IBAction)openSettings:(id)sender;
-(IBAction)toggleOpenAtLogin:(id)sender;
- (void)disableLoginItemWithLoginItemsReference:(LSSharedFileListRef )theLoginItemsRefs ForPath:(CFURLRef)thePath;
- (void)enableLoginItemWithLoginItemsReference:(LSSharedFileListRef )theLoginItemsRefs ForPath:(CFURLRef)thePath;
@end
