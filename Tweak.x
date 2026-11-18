#include <Foundation/Foundation.h>
#include <sys/stat.h>
#include <unistd.h>
#import <substrate.h>
#include "Auth.h"
#include "RAProtocol.h"
#include "HTTPServer.h"

static void setupRelease(void) {
    NSString *home = NSHomeDirectory();
    NSString *support = @"/Library/Application Support/RedAlien/release02";
    NSString *caches = [home stringByAppendingPathComponent:@"Library/Caches"];

    NSFileManager *fm = [NSFileManager defaultManager];
    NSString *r01 = [caches stringByAppendingPathComponent:@"release01"];
    NSString *r02 = [caches stringByAppendingPathComponent:@"release02"];

    if ([fm fileExistsAtPath:r02])
        [fm removeItemAtPath:r02 error:nil];

    if (![fm copyItemAtPath:support toPath:r02 error:nil]) {
        NSLog(@"[RedAlien] Failed to copy release02");
        return;
    }

    struct stat st;
    if (lstat([r01 UTF8String], &st) == 0) {
        if (S_ISLNK(st.st_mode))
            unlink([r01 UTF8String]);
        else
            [fm removeItemAtPath:r01 error:nil];
    }

    symlink([r02 UTF8String], [r01 UTF8String]);

    NSLog(@"[RedAlien] release01 -> release02");
}

static id *injectRAProto(id cfg) {
    if (!cfg) { return nil; }

    Class raProto = NSClassFromString(@"RAProtocol");
    if (!raProto) { return cfg; }

    id origProtocols = [cfg protocolClasses];
    NSLog(@"[RedAlien][NSURLSession] protocolClasses: %@ (%@)", origProtocols, origProtocols ? NSStringFromClass([origProtocols class]) : @"nil");
    NSMutableArray *protocols = nil;

    if (!origProtocols) {
        protocols = [[NSMutableArray alloc] init];
    } else if ([origProtocols isKindOfClass:[NSArray class]]) {
        protocols = [origProtocols mutableCopy];
    } else {
        NSLog(@"[RedAlien][NSURLSession] Unexpected protocolClasses type: %@", NSStringFromClass([origProtocols class]));
        return cfg;
    }

    if (![protocols containsObject:raProto]) {
        [protocols insertObject:raProto atIndex:0];
        [cfg setProtocolClasses: protocols];
        NSLog(@"[RedAlien][NSURLSession] RAProtocol injected");
    }

    [protocols release];
    return cfg;
}

%hook NSURLSessionConfiguration

+ (id)defaultSessionConfiguration {
    NSLog(@"[RedAlien][NSURLSession] defaultSessionConfiguration");
    id cfg = %orig;
    return injectRAProto(cfg);
}

+ (id)ephemeralSessionConfiguration {
    NSLog(@"[RedAlien][NSURLSession] ephemeralSessionConfiguration");
    id cfg = %orig;
    return injectRAProto(cfg);
}

%end

%ctor {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    NSString *processName = [[NSProcessInfo processInfo] processName];
    NSString *bundleID = [[NSBundle mainBundle] bundleIdentifier];

    [NSURLProtocol registerClass:[RAProtocol class]];
    [Auth shared];

    if ([processName isEqualToString:@"com.apple.WebKit.Networking"]) {
        NSLog(@"[RedAlien] ============ WebKit conquered! ============"); // don't start the http server
    } else {
        [HTTPServer startOnPort:8080];
        NSLog(@"[RedAlien] ============ RedAlien landed! ============");
        //if ([bundleID isEqualToString:@"com.reddit.Reddit"]) { setupRelease(); }
    }

    [pool drain];
}