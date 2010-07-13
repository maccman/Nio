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
	Client *client;
}

-(IBAction)openHistory:(id)sender;
-(IBAction)openSources:(id)sender;
-(IBAction)openSettings:(id)sender;

@end
