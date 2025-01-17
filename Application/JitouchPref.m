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

#import "JitouchPref.h"
#import "KeyTextField.h"
#import "KeyTextView.h"
#import "Settings.h"
#import "TrackpadTab.h"
#import "MagicMouseTab.h"
#import "RecognitionTab.h"
#import <Carbon/Carbon.h>

@implementation JitouchPref

CFMachPortRef eventTap;

- (instancetype)init {
    return [self initWithWindowNibName:@"Preferences"];
}

- (void)enUpdated {
    [trackpadTab enUpdated];
    [magicMouseTab enUpdated];
    [recognitionTab enUpdated];
    if (enAll) {
        [sdClickSpeed setEnabled:YES];
        [sdSensitivity setEnabled:YES];
    } else {
        [sdClickSpeed setEnabled:NO];
        [sdSensitivity setEnabled:NO];
    }
}

- (IBAction)change:(id)sender {
    if (sender == scAll) {
        int value = (int)[sender selectedSegment];
        enAll = value;
        [Settings setKey:@"enAll" withInt:value];

        [self enUpdated];
        if (enAll) {
            [self loadJitouchLaunchAgent];
        }
    } else if (sender == cbShowIcon) {
        int value = [sender state] == NSControlStateValueOn ? 1: 0;
        [Settings setKey:@"ShowIcon" withInt:value];
    } else if (sender == sdClickSpeed) {
        clickSpeed = 0.5 - [sender floatValue];
        [Settings setKey:@"ClickSpeed" withFloat:0.5 - [sender floatValue]];
    } else if (sender == sdSensitivity) {
        stvt = [sender floatValue];
        [Settings setKey:@"Sensitivity" withFloat:[sender floatValue]];
    }
    [Settings noteSettingsUpdated];
}

- (id)windowWillReturnFieldEditor:(NSWindow *)sender toObject:(id)anObject {
    if ([anObject isKindOfClass:[KeyTextField class]]) {
        if (!keyTextView) {
            keyTextView = [[KeyTextView alloc] init];
            [keyTextView setFieldEditor:YES];
        }
        return keyTextView;
    }
    return nil;
}

#pragma mark -

- (BOOL)jitouchIsRunning {
    NSArray *apps = [[NSWorkspace sharedWorkspace] runningApplications];
    for (NSRunningApplication *app in apps) {
        if ([app.bundleIdentifier isEqualToString:@"com.jitouch.Jitouch"]
            | [app.bundleIdentifier isEqualToString:@"app.jitouch.Jitouch"])
            return YES;
    }
    return NO;
}

- (void)settingsUpdated:(NSNotification *)aNotification {
    NSDictionary *d = [aNotification userInfo];
    [Settings readSettings2:d];

    [scAll setSelectedSegment:enAll];
    [self enUpdated];
}


- (void)killAllJitouchs {
    NSString *script = @"killall Jitouch";
    NSArray *shArgs = [NSArray arrayWithObjects:@"-c", script, @"", nil];
    [NSTask launchedTaskWithLaunchPath:@"/bin/sh" arguments:shArgs];
}


static CGEventRef CGEventCallback(CGEventTapProxy proxy, CGEventType type, CGEventRef event, void *refcon) {
    if ([NSApp isActive] && [[[NSApp keyWindow] firstResponder] isKindOfClass:[KeyTextView class]]) {
        if (type == kCGEventKeyDown) {
            int64_t keyCode = CGEventGetIntegerValueField(event, kCGKeyboardEventKeycode);
            CGEventFlags flags = CGEventGetFlags(event);
            [(KeyTextView*)[[NSApp keyWindow] firstResponder] handleEventKeyCode:keyCode flags:flags];
            return NULL;
        } else if (type == kCGEventKeyUp) {
            return NULL;
        }
    }
    return event;
}


- (void)removeJitouchFromLoginItems{
    LSSharedFileListRef loginListRef = LSSharedFileListCreate(NULL, kLSSharedFileListSessionLoginItems, NULL);
    if (loginListRef) {
        // delete all shortcuts to jitouch in the login items
        UInt32 seedValue;
        NSArray *loginItemsArray = (NSArray *)CFBridgingRelease(LSSharedFileListCopySnapshot(loginListRef, &seedValue));
        for (id item in loginItemsArray) {
            LSSharedFileListItemRef itemRef = (__bridge LSSharedFileListItemRef)item;
            CFURLRef thePath;
            if (LSSharedFileListItemResolve(itemRef, 0, (CFURLRef*) &thePath, NULL) == noErr) {
                NSRange range = [[(__bridge NSURL*)thePath path] rangeOfString:@"Jitouch"];
                if (range.location != NSNotFound)
                    LSSharedFileListItemRemove(loginListRef, itemRef);
            }
        }
    }
}

- (NSData *)generateJitouchLaunchAgent:(NSError**)error {
    if (error) { *error = nil; }
    NSString *pathToUs = [[NSBundle mainBundle] bundlePath];
    NSString *plistPath = [[NSBundle mainBundle]
                           pathForResource:@"app.jitouch.Jitouch" ofType:@"plist"];
    // TODO: throw error when plist is not in the bundle
    NSData *launchAgentXML = [[NSFileManager defaultManager] contentsAtPath:plistPath];
    NSString *home = NSHomeDirectory();

    NSMutableDictionary *launchAgent = [NSPropertyListSerialization
                                 propertyListWithData:launchAgentXML
                                 options:NSPropertyListMutableContainersAndLeaves
                                 format:NULL
                                 error:error];
    if (error && *error) {
        DDLogWarn(@"Error serializing Launch Agent plist");
        return launchAgentXML;
    }

    NSString *jitouchPath = [NSString
                             stringWithFormat:@"%@/Contents/MacOS/Jitouch",
                             pathToUs];
    launchAgent[@"Program"] = jitouchPath;
    launchAgent[@"StandardErrorPath"] = [NSString stringWithFormat:@"%@/Library/Logs/app.jitouch.Jitouch.log", home];
    launchAgentXML = [NSPropertyListSerialization
                      dataWithPropertyList:launchAgent format:NSPropertyListXMLFormat_v1_0 options:0 error:error];
    return launchAgentXML;
}

- (void)loadJitouchLaunchAgent {
    NSString *plistPath = [@"~/Library/LaunchAgents/app.jitouch.Jitouch.plist" stringByStandardizingPath];
    NSArray *loadArgs = [NSArray arrayWithObjects:@"load",
                         plistPath,
                         nil];
    NSTask *loadTask = [NSTask launchedTaskWithLaunchPath:@"/bin/launchctl" arguments:loadArgs];
    DDLogInfo(@"Loading %@", plistPath);
    [loadTask waitUntilExit];
}

- (void)unloadJitouchLaunchAgents {
    NSArray *plistPaths = @[
        @"~/Library/LaunchAgents/com.jitouch.Jitouch.plist",
        @"~/Library/LaunchAgents/app.jitouch.Jitouch.plist"
    ];
    for (NSString *plistPath in plistPaths) {
        if ([[NSFileManager defaultManager] fileExistsAtPath:plistPath])
        {
            NSArray *unloadArgs = [NSArray arrayWithObjects:@"unload",
                                   plistPath,
                                   nil];
            NSTask *unloadTask = [NSTask launchedTaskWithLaunchPath:@"/bin/launchctl" arguments:unloadArgs];
            DDLogInfo(@"Unloading %@", plistPath);
            [unloadTask waitUntilExit];
        }
    }
}

- (void)addJitouchLaunchAgent {
    NSError *error;
    NSData *launchAgent = [self generateJitouchLaunchAgent:&error];
    if (error) {
        DDLogInfo(@"Error generating LaunchAgent: %@", [error localizedDescription]);
        return;
    }
    NSString *plistPath = [@"~/Library/LaunchAgents/app.jitouch.Jitouch.plist" stringByStandardizingPath];
    NSString *launchAgentPath = [@"~/Library/LaunchAgents" stringByStandardizingPath];
    NSFileManager *fm = [NSFileManager defaultManager];
    // exit if the LaunchAgent plist already matches
    if ([fm fileExistsAtPath:plistPath] &&
        [launchAgent isEqualToData:[fm contentsAtPath:plistPath]]) {
        return;
    }
    // create the LaunchAgents directory
    BOOL isDir;
    BOOL exists = [fm fileExistsAtPath:launchAgentPath isDirectory:&isDir];
    if (!exists) {
        BOOL success = [fm createDirectoryAtPath:launchAgentPath withIntermediateDirectories:NO attributes:nil error:&error];
        if (!success || error) {
            DDLogInfo(@"Error creating LaunchAgents directory at %@: %@", launchAgentPath, [error localizedDescription]);
        } else {
            DDLogInfo(@"Created the LaunchAgents directory at %@", launchAgentPath);
        }
    } else if (!isDir) {
        DDLogInfo(@"Error creating LaunchAgent at %@: ~/Library/LaunchAgents is not a directory.", plistPath);
    }

    // unload LaunchAgents
    [self unloadJitouchLaunchAgents];

    // write the new LaunchAgent plist
    [launchAgent writeToFile:plistPath options:NSDataWritingAtomic error:&error];
    if (error) {
        DDLogInfo(@"Error creating LaunchAgent at %@: %@", plistPath, [error localizedDescription]);
    }
    else {
        DDLogInfo(@"Updated LaunchAgent at %@", plistPath);
    }

    // in case an older Jitouch is still around
    [self removeJitouchFromLoginItems];
    //[self killAllJitouchs];

    [self loadJitouchLaunchAgent];

    DDLogInfo(@"Reloaded LaunchAgent at %@", plistPath);
}

- (IBAction)resetTCC:(id)sender {
    NSAlert *alert = [[NSAlert alloc] init];
    [alert addButtonWithTitle:@"OK"];
    [alert addButtonWithTitle:@"Cancel"];
    [alert setMessageText:@"Reset accessibility permissions?"];
    [alert setInformativeText:@"Do you want to reset Jitouch's Accessibility API permissions? The app will quit."];
    [alert setAlertStyle:NSAlertStyleWarning];
    [alert beginSheetModalForWindow:[NSApp mainWindow] completionHandler:^(NSModalResponse returnCode) {
        if (returnCode == NSAlertFirstButtonReturn) {
            NSArray *resetArgs = [NSArray arrayWithObjects:
                                      @"reset",
                                      @"All",
                                      [NSBundle mainBundle].bundleIdentifier,
                                      nil
                                 ];
            NSTask *resetTask = [NSTask launchedTaskWithLaunchPath:@"/usr/bin/tccutil" arguments:resetArgs];
            [resetTask waitUntilExit];
            [NSApp terminate: sender];
        }
    }];
    
    
} 

- (void)awakeFromNib {
    [Settings loadSettings:self];

    [scAll setSelectedSegment:enAll];
    [cbShowIcon setState:[[settings objectForKey:@"ShowIcon"] intValue]];
    [sdClickSpeed setFloatValue:0.5-clickSpeed];
    [sdSensitivity setFloatValue:stvt];

    [self enUpdated];

    BOOL running = [self jitouchIsRunning];
    if (running && hasPreviousVersion) {
        [self killAllJitouchs];
        running = NO;
    }
    [self addJitouchLaunchAgent];

    NSInteger tabIndex = 0;
    if ([settings objectForKey:@"LastTab"] && (tabIndex=[mainTabView indexOfTabViewItemWithIdentifier:[settings objectForKey:@"LastTab"]]) != NSNotFound) {
        [mainTabView selectTabViewItemAtIndex:tabIndex];
    } else {
        CFMutableDictionaryRef matchingDict = IOServiceNameMatching("AppleUSBMultitouchDriver");
        io_registry_entry_t service = (io_registry_entry_t)IOServiceGetMatchingService(kIOMasterPortDefault, matchingDict);
        if (service) {
            [mainTabView selectTabViewItemWithIdentifier:@"Trackpad"];
        } else {
            [mainTabView selectTabViewItemWithIdentifier:@"Magic Mouse"];
        }
    }
}

- (SUUpdater *)updater {
    return [SUUpdater updaterForBundle:[NSBundle bundleForClass:[self class]]];
}

- (void)willSelect {
    BOOL trusted = AXIsProcessTrustedWithOptions((CFDictionaryRef)@{(__bridge id)kAXTrustedCheckOptionPrompt: @(YES)});

    if (trusted && !eventKeyboard) {
        CGEventMask eventMask = CGEventMaskBit(kCGEventKeyDown) | CGEventMaskBit(kCGEventKeyUp);
        eventKeyboard = CGEventTapCreate(kCGSessionEventTap, kCGHeadInsertEventTap, 0, eventMask, CGEventCallback, NULL);

        CGEventTapEnable(eventKeyboard, false);
        CFRunLoopSourceRef runLoopSource = CFMachPortCreateRunLoopSource( kCFAllocatorDefault, eventKeyboard, 0);
        CFRunLoopAddSource(CFRunLoopGetMain(), runLoopSource, kCFRunLoopCommonModes);
    }
}

- (void)willUnselect {
    [trackpadTab willUnselect];
    [magicMouseTab willUnselect];
    [recognitionTab willUnselect];
}

- (void)tabView:(NSTabView *)tabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem {
    [Settings setKey:@"LastTab" with:[tabViewItem identifier]];
    [settings setObject:[tabViewItem identifier] forKey:@"LastTab"];
}

- (void)showWindow:(id)sender {
    [super showWindow:sender];
    
    // Show the Dock icon
    [NSApp setActivationPolicy: NSApplicationActivationPolicyRegular];
}

- (void)windowWillClose:(NSNotification *)notification {
    // Hide the Dock icon
    [NSApp setActivationPolicy: NSApplicationActivationPolicyAccessory];
}

@end
