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

#import <Cocoa/Cocoa.h>

@class CursorWindow;
@class Gesture;

@interface JitouchAppDelegate : NSObject <NSApplicationDelegate> {
    NSWindow *__weak window;
    NSWindowController *preferencesWindowController;
    Gesture *gesture;
    NSMenu *theMenu;
    NSStatusItem *theItem;
}

@property (weak) IBOutlet NSWindow *window;

- (void)reload;

@end

extern CursorWindow *cursorWindow;
extern CGKeyCode keyMap[128]; // for dvorak support
