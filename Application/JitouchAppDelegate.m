/*
 * This file is part of Jitouch.
 *
 * Copyright 2021 Sukolsak Sakshuwong
 * Copyright 2021 Supasorn Suwajanakorn
 * Copyright 2021 Aaron Kollasch
 * Copyright 2021-2022 Daniel Herrmann
 *
 * Jitouch is free software: you can redistribute it and/or modify it under
 * the terms of the GNU General Public License as published by the Free Software
 * Foundation, either version 3 of the License, or (at your option) any later
 * version.
 *
 * Jitouch is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along with
 * Jitouch. If not, see <https://www.gnu.org/licenses/>.
 */

#import "JitouchAppDelegate.h"
#import "JitouchPref.h"
#import "Settings.h"
#import "Gesture.h"
#import "CursorWindow.h"
#import <Carbon/Carbon.h>
#import <CoreFoundation/CFPreferences.h>

CursorWindow *cursorWindow;
CGKeyCode keyMap[128]; // for dvorak support

@implementation JitouchAppDelegate

@synthesize window;

- (void)unloadJitouchLaunchAgent {
    NSString *plistPath = [@"~/Library/LaunchAgents/com.jitouch.Jitouch.plist" stringByStandardizingPath];
    NSArray *unloadArgs = [NSArray arrayWithObjects:@"unload",
                           plistPath,
                           nil];
    NSTask *unloadTask = [NSTask launchedTaskWithLaunchPath:@"/bin/launchctl" arguments:unloadArgs];
    [unloadTask waitUntilExit];
}

#pragma mark - Menu

- (BOOL)validateMenuItem:(NSMenuItem *)item {
    return YES;
}

- (void)showIcon {
    theMenu = [[NSMenu alloc] initWithTitle:@"Contextual Menu"];

    if (enAll)
        [theMenu insertItemWithTitle:@"Turn Jitouch Off" action:@selector(switchChange:) keyEquivalent:@"" atIndex:0];
    else
        [theMenu insertItemWithTitle:@"Turn Jitouch On" action:@selector(switchChange:) keyEquivalent:@"" atIndex:0];

    //[theMenu insertItem:[NSMenuItem separatorItem] atIndex:1];
    [theMenu insertItemWithTitle:@"Open Preferences..." action:@selector(preferences:) keyEquivalent:@"" atIndex:1];
    [theMenu insertItem:[NSMenuItem separatorItem] atIndex:2];
    [theMenu insertItemWithTitle:@"Quit Jitouch" action:@selector(quit:) keyEquivalent:@"" atIndex:3];

    NSStatusBar *bar = [NSStatusBar systemStatusBar];
    theItem = [bar statusItemWithLength:NSVariableStatusItemLength];
    [self updateIconImage];
    [theItem setHighlightMode:YES];
    [theItem setMenu:theMenu];
}

- (void)hideIcon {
    [[NSStatusBar systemStatusBar] removeStatusItem:theItem];
    theItem = nil;
}

- (void)updateIconImage {
    if (enAll) {
        NSImage *img = [NSImage imageNamed:@"logosmall"];
        [img setTemplate:YES];
        [theItem setImage:img];
    } else {
        NSImage *img = [NSImage imageNamed:@"logosmalloff"];
        [img setTemplate:YES];
        [theItem setImage:img];
    }
}

- (void)preferences:(id)sender  {
    [preferencesWindowController showWindow:nil];
    [NSApp activateIgnoringOtherApps:YES];
}


- (void)quit:(id)sender {
    [self unloadJitouchLaunchAgent];

    // Quit
    [NSApp terminate: sender];
}

- (void)refreshMenu {
    if (theItem == nil && [[settings objectForKey:@"ShowIcon"] intValue] == 1){
        [self showIcon];
    } else if (theItem != nil && [[settings objectForKey:@"ShowIcon"] intValue] == 0){
        [self hideIcon];
    }
    if (theItem) {
        if (enAll) {
            [[theMenu itemAtIndex:0] setTitle:@"Turn Jitouch Off"];
        } else {
            [[theMenu itemAtIndex:0] setTitle:@"Turn Jitouch On"];
        }
        [self updateIconImage];
    }
}

- (void)switchChange:(id)sender {
    enAll = !enAll;
    [self refreshMenu];
    [self saveSettings];

    if (!enAll)
        turnOffGestures();
}

#pragma mark - Settings

- (void)saveSettings {
    [Settings setKey:@"enAll" withInt:enAll];
}

- (void)settingsUpdated:(NSNotification *)aNotification {
    [Settings loadSettings];

    [self refreshMenu];

    if (!enAll)
        turnOffGestures();
}

#pragma mark - Initialization


- (void)checkAXAPI {
    AXIsProcessTrustedWithOptions((CFDictionaryRef)@{(__bridge id)kAXTrustedCheckOptionPrompt: @(YES)});
}

/*
void languageChanged(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
    for (int i = 0; i < 128; i++)
        keyMap[i] = (CGKeyCode)i;
    NSString *inputSource = (NSString*)TISGetInputSourceProperty(TISCopyCurrentKeyboardInputSource(), kTISPropertyLocalizedName);
    if ([inputSource isEqualToString:@"Dvorak"] || [inputSource isEqualToString:@"Svorak"]) {
        keyMap[13] = 43; //w -> ,
        keyMap[12] = 7;  //q -> x
        keyMap[17] = 40; //t -> k
        keyMap[4] = 38;  //h -> j
        keyMap[15] = 31; //r -> o
        keyMap[45] = 37; //n -> l
        keyMap[8] = 34; //c -> i
        keyMap[9] = 47; //v -> >
        keyMap[31] = 1; //o ->
        keyMap[37] = 45; //l -> n
        keyMap[3] = 32; // f -> u
        keyMap[40] = 17;
    } else if ([inputSource isEqualToString:@"French"]) {
        keyMap[13] = 6;  //w -> z
        keyMap[12] = 0;  //q -> a
    }
}
*/

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    preferencesWindowController = [[JitouchPref alloc] init];
    
    [Settings loadSettings];

    [self refreshMenu];

    // Move this task to prefpane instead. Starting at Sierra
    //[self addJitouchToLoginItems];

    cursorWindow = [[CursorWindow alloc] init];

    //languageChanged(NULL, NULL, NULL, NULL, NULL);

    gesture = [[Gesture alloc] init];

    //[self showIcon];

    [self checkAXAPI];

    [[NSDistributedNotificationCenter defaultCenter] addObserver: self
                                                        selector: @selector(settingsUpdated:)
                                                            name: @"My Notification"
                                                          object: @"com.jitouch.Jitouch.PrefpaneTarget"];

    [[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self selector:@selector(wokeUp:) name:NSWorkspaceDidWakeNotification object: NULL];

    //CFNotificationCenterAddObserver(CFNotificationCenterGetDistributedCenter(), self, languageChanged, kTISNotifySelectedKeyboardInputSourceChanged, NULL, CFNotificationSuspensionBehaviorDeliverImmediately);
}

- (void)wokeUp:(NSNotification *)aNotification {
    DDLogInfo(@"Woke up.");
    [self reload];
}

- (void)reload {
    [gesture reload];
}

#pragma mark -

@end
