/*
 * This file is part of Jitouch.
 *
 * Copyright 2021 Sukolsak Sakshuwong
 * Copyright 2021 Supasorn Suwajanakorn
 * Copyright 2021 Aaron Kollasch
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
#import "signal.h"
#import "JitouchAppDelegate.h"
#import "JTLogFormatter.h"

int main(int argc, const char * argv[])
{
    // Set up logging with Lumberjack
    DDOSLogger *logger = [[DDOSLogger alloc] initWithSubsystem:@"app.jitouch.Jitouch" category:@"Main"];
    logger.logFormatter = [[JTLogFormatter alloc] init];
    [DDLog addLogger:logger];
    
    // Trap SIGHUP and do reload
    // see https://stackoverflow.com/questions/50225548/trap-sigint-in-cocoa-macos-application
    // see https://www.mikeash.com/pyblog/friday-qa-2011-04-01-signal-handling.html
    // see https://fossies.org/linux/HandBrake/macosx/main.m
    dispatch_source_t source = dispatch_source_create(DISPATCH_SOURCE_TYPE_SIGNAL, SIGHUP, 0, dispatch_get_global_queue(0, 0));
    dispatch_source_set_event_handler(source, ^{
        DDLogInfo(@"Received SIGHUP.");
        dispatch_async(dispatch_get_main_queue(), ^{
            [((JitouchAppDelegate*)[NSApp delegate]) reload];
        });
    });
    dispatch_resume(source);
    
    // Ignore the SIGHUP signal because we handle it.
    // To debug SIGHUP in Xcode, add an "ignoreSIGHUP" breakpoint at this line, before `signal()`.
    // set the breakpoint action to `process handle SIGHUP -n true -p true -s false`
    // set the breakpoint to automatically continue after evaluating actions.
    signal(SIGHUP, SIG_IGN);

    return NSApplicationMain(argc, argv);
}
