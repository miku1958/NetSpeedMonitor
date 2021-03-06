//
// AppDelegate.m
// SpeedMonitor
//
// Created by Charles Wu on 3/23/16.
// Copyright © 2016 Charles Wu. All rights reserved.
//

#import "AppDelegate.h"

@interface AppDelegate ()

@end

@implementation NSMutableAttributedString(change)

- (void)addSpeed:(struct human_readble_string)string prefix:(NSString *)prefix sufix:(NSString *)sufix attributes:(NSDictionary *)attributes{
	
	NSString *speed = [[NSString stringWithFormat: @"%.1Lf", string.number] stringByReplacingOccurrencesOfString: @".0" withString: @""];
	[self appendAttributedString: [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@%@%s%@", prefix , speed, string.suffix, sufix] attributes:attributes]];
}

@end

@implementation AppDelegate
@synthesize window;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	// Insert code here to initialize your application
	NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval: 3.0 target: self selector: @selector(updateStatusItem) userInfo: nil repeats: YES];
	[timer fire];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
	// Insert code here to tear down your application
}

- (id)init {
	self = [super init];
	
	NSFont *font = [NSFont systemFontOfSize:9];
	attributes = [[NSDictionary alloc] initWithObjectsAndKeys:font, NSFontAttributeName, nil];
	
	memset(&ifdata, 0, sizeof(ifdata));
	
	return self ? self : nil;
}

- (void)awakeFromNib {
	[self createStatusItem];
}

- (void)createStatusItem {
	statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:50];
	statusMenu = [[NSMenu alloc] init];
	speedString = [[NSMutableAttributedString alloc] initWithString: @""];
	quit = [[NSMenuItem alloc] initWithTitle:@"quit" action:@selector(terminate:) keyEquivalent:@"q"];
	
	[statusItem setAttributedTitle:speedString];
	[statusItem setEnabled:NO];
	[statusItem setMenu:statusMenu];
	[statusMenu insertItem:quit atIndex:0];
	
	[self updateStatusItem];
}

- (void)updateStatusItem {
	[statusItem setEnabled:YES];
	
	struct ifmibdata ifmib;
	struct human_readble_string string = {0, NULL};
	
	fill_interface_data(&ifmib);
	size_t rx_bytes = ifmib.ifmd_data.ifi_ibytes - ifdata.ifi_ibytes;
	size_t tx_bytes = ifmib.ifmd_data.ifi_obytes - ifdata.ifi_obytes;
	
	humanize_digit(tx_bytes, &string);
	[speedString setAttributedString: [[NSAttributedString alloc] initWithString: @"" attributes: attributes]];
	[speedString addSpeed: string prefix: @"⇡" sufix:@"\n" attributes: attributes];
	
	
	humanize_digit(rx_bytes, &string);
	
	[speedString addSpeed: string prefix: @"⇣" sufix:@"" attributes: attributes];
	
	[statusItem setAttributedTitle: speedString];
	
	ifdata = ifmib.ifmd_data;
}

@end


