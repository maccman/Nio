//
//  Client.m
//  Nio - Notify.io client
//
//  Copyright 2009 GliderLab. All rights reserved.
//

#import "Client.h"
#import "CJSONDeserializer.h"


@implementation Client

@synthesize growlData;

- (void)initRemoteHost:(NSString *)urlString {
	NSLog(@"Connecting to server...");

	NSURL *url = [NSURL URLWithString:urlString];
	notifyReq = [[NSMutableURLRequest alloc] 
									   initWithURL:url
									   cachePolicy:NSURLRequestReloadIgnoringCacheData
									   timeoutInterval:3600.0]; // Set the timeout to 60 min. It will reconnect.
	
	// Set user agent to something good
	[notifyReq setValue:@"Nio/1.0" forHTTPHeaderField:@"User-Agent"];
	
	[self makeConnection];
}

- (void)makeConnection {
	if(!notifyConn){
		[notifyConn release];
	}
	
	notifyConn = [[NSURLConnection alloc] initWithRequest:notifyReq delegate:self startImmediately:YES];
	NSLog(@"conn: %@", notifyConn);
}

-(NSURLRequest *)connection:(NSURLConnection*)connection willSendRequest:(NSURLRequest*)request redirectResponse:(NSHTTPURLResponse*)redirectResponse {
	if (redirectResponse) {
		for(NSString* key in [redirectResponse allHeaderFields]){
			if ( [@"location" caseInsensitiveCompare:key] == NSOrderedSame ) {
				NSLog(@"redirecting");
				NSURL *url = [NSURL URLWithString:[[redirectResponse allHeaderFields] objectForKey:key]];
				[notifyReq setURL: url];
				return notifyReq;
			}
		}
		return nil;
	} else {
		return request;
	}
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
	if([connection isEqualTo:notifyConn]) {
		NSLog(@"connection finished");
		[self makeConnection];
	}
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
	if([connection isEqualTo:notifyConn]) {
		NSLog(@"did fail with error: %@", error);
		// if hostname not found or net connection offline, try again after delay
		if([error code] == -1003 || [error code] == -1009) {
			[self performSelector:@selector(makeConnection) withObject:nil afterDelay:10.0];
		}
		else if([error code] != -1002) {
			[self makeConnection];
		}
	}
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
	if([connection isEqualTo:notifyConn]) {
		
		NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
		string = [string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
		if (![string hasPrefix:@"{"] || ![string hasSuffix:@"}"]) {
			return;
		}
		NSLog(@"data: %@", string);
		
		// Keep the data in case we need it to stick around because we won't be posting the growl notif
		// until we get the icon
		
		NSData *jsonData = [string dataUsingEncoding:NSUTF32BigEndianStringEncoding];
		[string release];
		NSError *error = nil;
		NSDictionary *messageDict = [[CJSONDeserializer deserializer] deserializeAsDictionary:jsonData error:&error];
		self.growlData = messageDict;
		
		// Call the hook script if it's around
		NSString *hookPath = [NSString stringWithFormat:@"%@/.NioCallback", NSHomeDirectory()];
		NSString *hookScript = [[NSString alloc] initWithContentsOfFile:hookPath encoding:NSASCIIStringEncoding error:&error];
		if ([hookScript length] != 0) {
			NSLog(@"running hook: %@", hookPath);
			
			//TODO: Relese this object, it crashes if you release it in the loop, maybe autorelease?
			NSTask *task = [[NSTask alloc] init];
			NSArray *arguments = [NSArray arrayWithObjects: [growlData objectForKey:@"text"], [growlData objectForKey:@"title"], [growlData objectForKey:@"link"], nil];
			[task setArguments: arguments];
			[task setLaunchPath: hookPath];
			[task launch];
		}
		[hookScript release];
		// Get the icon from the json data
		NSString *iconURLStr = [growlData objectForKey:@"icon"];
		
		// TODO: implement caching of icon data. check cache here
		
		if(!iconURLStr){
			[GrowlApplicationBridge notifyWithTitle:[growlData objectForKey:@"title"] 
										description:[growlData objectForKey:@"text"] 
								   notificationName:@"Nio" 
										   iconData:nil 
										   priority:1 
										   isSticky:[[growlData objectForKey:@"sticky"] isEqualToString:@"true"] 
									   clickContext:[growlData objectForKey:@"link"]];
			
			self.growlData = nil;
		} else {
			// Get the icon from the url
			
			NSURL *url = [NSURL URLWithString:iconURLStr];
			NSMutableURLRequest *urlRequest = [[NSMutableURLRequest alloc] initWithURL:url];
			iconConn = [[NSURLConnection alloc] initWithRequest:urlRequest delegate:self startImmediately:YES];
		}		
	} else if([connection isEqualTo:iconConn]) {
		// Make an image out of the received data
		NSImage *image = [[NSImage alloc] initWithData:data];
		
		[GrowlApplicationBridge notifyWithTitle:[growlData objectForKey:@"title"] 
									description:[growlData objectForKey:@"text"] 
							   notificationName:@"Nio" 
									   iconData:[image TIFFRepresentation]
									   priority:1 
									   isSticky:[[growlData objectForKey:@"sticky"] isEqualToString:@"true"]
								   clickContext:[growlData objectForKey:@"link"]];
		
		[iconConn release];
		[image release];
		iconConn = nil;
		self.growlData = nil;
	}
}

- (void) dealloc{
	[notifyReq release];
	[notifyConn release];
	[super dealloc];
}

@end
