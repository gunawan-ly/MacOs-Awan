// vdisplay.m — minimal CGVirtualDisplay experiment tool (Phase 3B).
//
// Creates ONE virtual display (default 1280x720@60, no HiDPI), verifies it
// appears in the macOS display list with a usable framebuffer, prints
// diagnostics, then stays alive (heartbeat) until terminated.
//
// No GUI, no menu bar, no driver, no system extension, no network.
// Everything is ephemeral: releasing the display object (process exit)
// tears the virtual display down.
//
// Private CoreGraphics classes are resolved at runtime (NSClassFromString),
// so a missing API on some macOS build fails with a clear message instead
// of a link error. Pattern verified against implementations tested on
// macOS 26 Apple Silicon.

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import <dispatch/dispatch.h>

// --- Private CoreGraphics CGVirtualDisplay API (redeclared subset) ---
@class CGVirtualDisplay;

@interface CGVirtualDisplayDescriptor : NSObject
@property(retain, nonatomic) dispatch_queue_t queue;
@property(nonatomic) unsigned int vendorID;
@property(nonatomic) unsigned int productID;
@property(nonatomic) unsigned int serialNum;
@property(copy, nonatomic) NSString *name;
@property(nonatomic) CGSize sizeInMillimeters;
@property(nonatomic) unsigned int maxPixelsWide;
@property(nonatomic) unsigned int maxPixelsHigh;
@end

@interface CGVirtualDisplayMode : NSObject
- (instancetype)initWithWidth:(unsigned int)width
                       height:(unsigned int)height
                  refreshRate:(double)refreshRate;
@end

@interface CGVirtualDisplaySettings : NSObject
@property(retain, nonatomic) NSArray *modes;
@property(nonatomic) unsigned int hiDPI;
@end

@interface CGVirtualDisplay : NSObject
- (instancetype)initWithDescriptor:(CGVirtualDisplayDescriptor *)descriptor;
- (BOOL)applySettings:(CGVirtualDisplaySettings *)settings;
@property(readonly, nonatomic) unsigned int displayID;
@end
// ----------------------------------------------------------------------

static void listDisplays(const char *tag) {
    CGDirectDisplayID ids[16];
    uint32_t online = 0, active = 0;
    memset(ids, 0, sizeof(ids));
    CGGetOnlineDisplayList(16, ids, &online);
    CGGetActiveDisplayList(16, ids, &active);
    printf("[VDISPLAY] %s online=%u active=%u ids:", tag, online, active);
    for (uint32_t i = 0; i < online && i < 16; i++) printf(" %u", ids[i]);
    printf("\n");
    fflush(stdout);
}

int main(int argc, const char *argv[]) {
    @autoreleasepool {
        uint32_t W = argc > 1 ? (uint32_t)atoi(argv[1]) : 1280;
        uint32_t H = argc > 2 ? (uint32_t)atoi(argv[2]) : 720;
        if (W == 0 || H == 0) { printf("[VDISPLAY] FAIL invalid size\n"); return 2; }
        printf("[VDISPLAY] start target=%ux%u@60 single display, no HiDPI\n", W, H);
        listDisplays("BEFORE");
        fflush(stdout);

        Class DescCls = NSClassFromString(@"CGVirtualDisplayDescriptor");
        Class SettingsCls = NSClassFromString(@"CGVirtualDisplaySettings");
        Class ModeCls = NSClassFromString(@"CGVirtualDisplayMode");
        Class DisplayCls = NSClassFromString(@"CGVirtualDisplay");
        if (!DescCls || !SettingsCls || !ModeCls || !DisplayCls) {
            printf("[VDISPLAY] FAIL CGVirtualDisplay private API unavailable on this macOS build\n");
            return 3;
        }

        dispatch_queue_t queue = dispatch_queue_create("awan.vdisplay", DISPATCH_QUEUE_SERIAL);
        CGVirtualDisplayDescriptor *desc = [[DescCls alloc] init];
        desc.queue = queue;
        desc.name = @"Awan Virtual Display";
        desc.vendorID = 0x1234;
        desc.productID = 0x3B01;
        desc.serialNum = arc4random();
        desc.sizeInMillimeters = CGSizeMake(344, 194);
        desc.maxPixelsWide = W;
        desc.maxPixelsHigh = H;

        CGVirtualDisplay *display = [[DisplayCls alloc] initWithDescriptor:desc];
        if (!display) { printf("[VDISPLAY] FAIL CGVirtualDisplay alloc/init returned nil\n"); return 4; }
        printf("[VDISPLAY] display object created vendor=0x1234 product=0x3B01\n");

        CGVirtualDisplayMode *mode = [[ModeCls alloc] initWithWidth:W height:H refreshRate:60.0];
        CGVirtualDisplaySettings *settings = [[SettingsCls alloc] init];
        settings.modes = @[mode];
        settings.hiDPI = 0;
        if (![display applySettings:settings]) {
            printf("[VDISPLAY] FAIL applySettings returned NO\n");
            return 5;
        }
        printf("[VDISPLAY] settings applied, waiting for displayID\n");

        // displayID + online state land asynchronously: poll.
        CGDirectDisplayID did = 0;
        for (int i = 0; i < 80 && did == 0; i++) {
            usleep(150000);
            did = display.displayID;
        }
        if (did == 0) { printf("[VDISPLAY] FAIL displayID never assigned\n"); return 6; }
        printf("[VDISPLAY] displayID=%u\n", did);

        // Ask WindowServer to serve our exact mode (session-only, not permanent).
        CFArrayRef modes = CGDisplayCopyAllDisplayModes(did, NULL);
        if (modes) {
            for (CFIndex i = 0; i < CFArrayGetCount(modes); i++) {
                CGDisplayModeRef m = (CGDisplayModeRef)CFArrayGetValueAtIndex(modes, i);
                if (CGDisplayModeGetPixelWidth(m) == W && CGDisplayModeGetPixelHeight(m) == H) {
                    CGDisplayConfigRef cfg = NULL;
                    if (CGBeginDisplayConfiguration(&cfg) == kCGErrorSuccess) {
                        CGConfigureDisplayWithDisplayMode(cfg, did, m, NULL);
                        CGCompleteDisplayConfiguration(cfg, kCGConfigureForSession);
                    }
                    break;
                }
            }
            CFRelease(modes);
        }

        // Verify served size + registration + surface.
        int settled = 0;
        for (int i = 0; i < 40; i++) {
            if (CGDisplayPixelsWide(did) == W && CGDisplayPixelsHigh(did) == H) { settled = 1; break; }
            usleep(150000);
        }
        size_t pw = CGDisplayPixelsWide(did), ph = CGDisplayPixelsHigh(did);
        CGRect bounds = CGDisplayBounds(did);
        printf("[VDISPLAY] served=%zux%zu bounds={{%g,%g},{%g,%g}} online=%d active=%d main=%d\n",
               pw, ph, bounds.origin.x, bounds.origin.y, bounds.size.width, bounds.size.height,
               CGDisplayIsOnline(did), CGDisplayIsActive(did), CGDisplayIsMain(did));
        CGDisplayModeRef cur = CGDisplayCopyDisplayMode(did);
        if (cur) {
            printf("[VDISPLAY] mode refresh=%.2f ioflags=0x%x\n",
                   CGDisplayModeGetRefreshRate(cur), (unsigned)CGDisplayModeGetIOFlags(cur));
            CFRelease(cur);
        }
        // Framebuffer proof without deprecated capture APIs: a live display
        // reports nonzero bytes-per-row and bits-per-pixel for its surface.
        size_t bpr = CGDisplayBytesPerRow(did);
        size_t bpp = CGDisplayBitsPerPixel(did);
        printf("[VDISPLAY] framebuffer bytesPerRow=%zu bitsPerPixel=%zu\n", bpr, bpp);
        if (bpr == 0 || bpp == 0) {
            printf("[VDISPLAY] WARN zero framebuffer geometry (surface may not be live yet)\n");
        }
        listDisplays("AFTER");
        fflush(stdout);

        if (!settled) {
            printf("[VDISPLAY] FAIL settled at %zux%zu, not %ux%u\n", pw, ph, W, H);
            return 7;
        }
        printf("[VDISPLAY] READY id=%u %ux%u - staying alive until terminated\n", did, W, H);
        fflush(stdout);

        // Keep the owner alive: exiting tears the virtual display down.
        for (;;) {
            sleep(60);
            if (!CGDisplayIsOnline(did)) {
                printf("[VDISPLAY] FAIL display went offline, exiting\n");
                return 8;
            }
            printf("[VDISPLAY] alive id=%u online\n", did);
            fflush(stdout);
        }
    }
    return 0;
}
