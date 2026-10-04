#import <ScreenSaver/ScreenSaver.h>
#import <OpenGL/gl.h>
#include <math.h>

static NSString *const DefaultMessage = @"I love my job";
static NSString *const MessagesKey = @"texts";
static NSString *const IntervalKey = @"textInterval";
static const NSInteger MinimumInterval = 1;
static const NSInteger MaximumInterval = 3600;
static const int HeartSegments = 12;
static const double HeartDepth = 0.15;

static NSArray<NSString *> *normalizedMessages(NSArray *values) {
    NSMutableArray<NSString *> *messages = [NSMutableArray array];
    for (id value in values) {
        if (![value isKindOfClass:NSString.class]) continue;
        NSString *message = [value stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
        if (message.length) [messages addObject:message];
    }
    return messages.count ? messages : @[DefaultMessage];
}

static NSInteger boundedInterval(NSInteger interval) {
    return MAX(MinimumInterval, MIN(MaximumInterval, interval));
}

static ScreenSaverDefaults *heartDefaults(void) {
    ScreenSaverDefaults *defaults = [ScreenSaverDefaults defaultsForModuleWithName:@"de.noah.herz.screensaver"];
    [defaults registerDefaults:@{MessagesKey: @[DefaultMessage], IntervalKey: @10}];
    return defaults;
}

@interface HeartOpenGLView : NSOpenGLView {
    GLuint _textTexture;
    CGFloat _textAspect;
    NSString *_renderedText;
}
@property(nonatomic, copy) NSArray<NSString *> *messages;
@property(nonatomic) NSInteger messageInterval;
- (void)render;
@end

@implementation HeartOpenGLView
- (instancetype)initWithFrame:(NSRect)frame {
    NSOpenGLPixelFormatAttribute attributes[] = {
        NSOpenGLPFAAccelerated, NSOpenGLPFADoubleBuffer,
        NSOpenGLPFAColorSize, 24, NSOpenGLPFAAlphaSize, 8,
        NSOpenGLPFADepthSize, 24, 0
    };
    NSOpenGLPixelFormat *format = [[NSOpenGLPixelFormat alloc] initWithAttributes:attributes];
    if (!format) return nil;
    self = [super initWithFrame:frame pixelFormat:format];
    if (self) {
        self.wantsBestResolutionOpenGLSurface = YES;
        self.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    }
    return self;
}

- (void)prepareOpenGL {
    [super prepareOpenGL];
    [self.openGLContext makeCurrentContext];
    GLint interval = 1;
    [self.openGLContext setValues:&interval forParameter:NSOpenGLContextParameterSwapInterval];
}

- (void)createTextTexture:(NSString *)text {
    NSFont *font = [NSFont fontWithName:@"ComicSansMS" size:96] ?: [NSFont systemFontOfSize:96];
    NSDictionary *attributes = @{NSFontAttributeName: font, NSForegroundColorAttributeName: NSColor.whiteColor};
    NSSize size = [text sizeWithAttributes:attributes];
    NSInteger width = (NSInteger)ceil(size.width) + 4;
    NSInteger height = (NSInteger)ceil(size.height) + 4;
    NSBitmapImageRep *bitmap = [[NSBitmapImageRep alloc]
        initWithBitmapDataPlanes:NULL pixelsWide:width pixelsHigh:height
        bitsPerSample:8 samplesPerPixel:4 hasAlpha:YES isPlanar:NO
        colorSpaceName:NSDeviceRGBColorSpace bytesPerRow:width * 4 bitsPerPixel:32];
    [NSGraphicsContext saveGraphicsState];
    [NSGraphicsContext setCurrentContext:[NSGraphicsContext graphicsContextWithBitmapImageRep:bitmap]];
    [text drawAtPoint:NSMakePoint(2, 2) withAttributes:attributes];
    [NSGraphicsContext restoreGraphicsState];
    _textAspect = (CGFloat)width / height;
    if (!_textTexture) glGenTextures(1, &_textTexture);
    glBindTexture(GL_TEXTURE_2D, _textTexture);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, (GLsizei)width, (GLsizei)height,
                 0, GL_RGBA, GL_UNSIGNED_BYTE, bitmap.bitmapData);
    _renderedText = [text copy];
}

static void heartVertex(int index, double depth) {
    double angle = 2 * M_PI * index / HeartSegments;
    double sine = sin(angle);
    double x = 16 * sine * sine * sine / 20;
    double y = (13 * cos(angle) - 5 * cos(2 * angle) - 2 * cos(3 * angle) - cos(4 * angle)) / 20 + 0.15;
    glVertex3d(x, y, depth);
}

- (void)render {
    [self.openGLContext makeCurrentContext];
    NSArray<NSString *> *messages = self.messages.count ? self.messages : @[DefaultMessage];
    NSTimeInterval uptime = NSProcessInfo.processInfo.systemUptime;
    NSUInteger index = (NSUInteger)(uptime / boundedInterval(self.messageInterval)) % messages.count;
    NSString *message = messages[index];
    if (![_renderedText isEqualToString:message]) [self createTextTexture:message];
    NSRect pixels = [self convertRectToBacking:self.bounds];
    glViewport(0, 0, (GLsizei)pixels.size.width, (GLsizei)pixels.size.height);
    glClearColor(0.1, 0.1, 0.1, 1);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    glMatrixMode(GL_PROJECTION);
    glLoadIdentity();
    glOrtho(-1, 1, -1, 1, -2, 2);
    glMatrixMode(GL_MODELVIEW);
    [self drawHeartAtTime:uptime];
    [self drawMessage];
}

- (void)drawHeartAtTime:(NSTimeInterval)time {
    glLoadIdentity();
    glRotated(fmod(time, 2 * M_PI) * 180 / M_PI, 0, 1, 0);
    glEnable(GL_DEPTH_TEST);
    glDisable(GL_BLEND);
    glDisable(GL_TEXTURE_2D);
    glColor3f(0.9, 0.1, 0.2);
    for (int face = 0; face < 2; face++) {
        double depth = face == 0 ? HeartDepth : -HeartDepth;
        glBegin(GL_TRIANGLE_FAN);
        glVertex3d(0, 0, depth);
        for (int i = 0; i <= HeartSegments; i++) heartVertex(i, depth);
        glEnd();
    }
    glColor3f(0.5, 0.05, 0.1);
    glBegin(GL_TRIANGLE_STRIP);
    for (int i = 0; i <= HeartSegments; i++) {
        heartVertex(i, HeartDepth);
        heartVertex(i, -HeartDepth);
    }
    glEnd();
}

- (void)drawMessage {
    glLoadIdentity();
    glDisable(GL_DEPTH_TEST);
    glEnable(GL_BLEND);
    glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);
    glEnable(GL_TEXTURE_2D);
    glBindTexture(GL_TEXTURE_2D, _textTexture);
    glColor4f(1, 1, 1, 1);
    double height = 0.15;
    double width = height * _textAspect;
    if (width > 1.85) {
        height *= 1.85 / width;
        width = 1.85;
    }
    glBegin(GL_QUADS);
    glTexCoord2f(0, 1); glVertex2d(-width/2, -0.85-height/2);
    glTexCoord2f(1, 1); glVertex2d( width/2, -0.85-height/2);
    glTexCoord2f(1, 0); glVertex2d( width/2, -0.85+height/2);
    glTexCoord2f(0, 0); glVertex2d(-width/2, -0.85+height/2);
    glEnd();
    glDisable(GL_TEXTURE_2D);
}

- (void)drawRect:(NSRect)dirtyRect {
    [self render];
    [self.openGLContext flushBuffer];
}

- (void)dealloc {
    [self.openGLContext makeCurrentContext];
    if (_textTexture) glDeleteTextures(1, &_textTexture);
    [NSOpenGLContext clearCurrentContext];
}
@end

@interface HeartView : ScreenSaverView
@property(nonatomic, strong) HeartOpenGLView *renderer;
@property(nonatomic, strong) NSWindow *optionsWindow;
@property(nonatomic, strong) NSTextView *messagesEditor;
@property(nonatomic, strong) NSTextField *intervalEditor;
@end

@implementation HeartView
- (instancetype)initWithFrame:(NSRect)frame isPreview:(BOOL)isPreview {
    self = [super initWithFrame:frame isPreview:isPreview];
    if (self) {
        self.animationTimeInterval = 1.0 / 60.0;
        _renderer = [[HeartOpenGLView alloc] initWithFrame:self.bounds];
        if (!_renderer) {
            NSLog(@"Heart: could not create an OpenGL view");
            return nil;
        }
        [self addSubview:_renderer];
        [self reloadOptions];
    }
    return self;
}
- (void)animateOneFrame {
    [self.renderer setNeedsDisplay:YES];
}

- (void)reloadOptions {
    ScreenSaverDefaults *defaults = heartDefaults();
    self.renderer.messages = normalizedMessages([defaults arrayForKey:MessagesKey]);
    self.renderer.messageInterval = boundedInterval([defaults integerForKey:IntervalKey]);
}

- (void)startAnimation {
    [self reloadOptions];
    [super startAnimation];
}

- (BOOL)hasConfigureSheet { return YES; }

- (NSWindow *)configureSheet {
    self.optionsWindow = [[NSWindow alloc] initWithContentRect:NSMakeRect(0, 0, 480, 350)
        styleMask:NSWindowStyleMaskTitled backing:NSBackingStoreBuffered defer:NO];
    self.optionsWindow.title = @"Heart – Options";
    NSView *content = self.optionsWindow.contentView;
    NSTextField *label = [NSTextField labelWithString:@"Messages – one per line:"];
    label.frame = NSMakeRect(20, 310, 440, 20);
    [content addSubview:label];
    [content addSubview:[self messageEditor]];
    [content addSubview:[self intervalControl]];
    NSButton *cancel = [NSButton buttonWithTitle:@"Cancel" target:self action:@selector(cancelOptions:)];
    cancel.frame = NSMakeRect(250, 15, 100, 32);
    cancel.keyEquivalent = @"\e";
    [content addSubview:cancel];
    NSButton *save = [NSButton buttonWithTitle:@"Save" target:self action:@selector(saveOptions:)];
    save.frame = NSMakeRect(355, 15, 105, 32);
    save.keyEquivalent = @"\r";
    [content addSubview:save];
    return self.optionsWindow;
}

- (NSScrollView *)messageEditor {
    NSScrollView *scroll = [[NSScrollView alloc] initWithFrame:NSMakeRect(20, 100, 440, 200)];
    scroll.borderType = NSBezelBorder;
    scroll.hasVerticalScroller = YES;
    self.messagesEditor = [[NSTextView alloc] initWithFrame:scroll.contentView.bounds];
    self.messagesEditor.richText = NO;
    self.messagesEditor.font = [NSFont systemFontOfSize:14];
    self.messagesEditor.verticallyResizable = YES;
    self.messagesEditor.autoresizingMask = NSViewWidthSizable;
    self.messagesEditor.textContainer.widthTracksTextView = YES;
    [self reloadOptions];
    self.messagesEditor.string = [self.renderer.messages componentsJoinedByString:@"\n"];
    scroll.documentView = self.messagesEditor;
    return scroll;
}

- (NSView *)intervalControl {
    NSView *control = [[NSView alloc] initWithFrame:NSMakeRect(20, 65, 440, 24)];
    NSTextField *intervalLabel = [NSTextField labelWithString:@"Change message every (seconds):"];
    intervalLabel.frame = NSMakeRect(0, 0, 275, 22);
    [control addSubview:intervalLabel];
    self.intervalEditor = [[NSTextField alloc] initWithFrame:NSMakeRect(280, 0, 80, 24)];
    self.intervalEditor.integerValue = (NSInteger)self.renderer.messageInterval;
    NSNumberFormatter *formatter = [NSNumberFormatter new];
    formatter.numberStyle = NSNumberFormatterDecimalStyle;
    formatter.allowsFloats = NO;
    formatter.minimum = @(MinimumInterval);
    formatter.maximum = @(MaximumInterval);
    self.intervalEditor.formatter = formatter;
    [control addSubview:self.intervalEditor];
    return control;
}

- (void)cancelOptions:(id)sender {
    [self.optionsWindow.sheetParent endSheet:self.optionsWindow];
    [self.optionsWindow orderOut:nil];
}

- (void)saveOptions:(id)sender {
    if (![self.optionsWindow makeFirstResponder:nil]) return;
    NSArray *lines = [self.messagesEditor.string componentsSeparatedByCharactersInSet:NSCharacterSet.newlineCharacterSet];
    ScreenSaverDefaults *defaults = heartDefaults();
    [defaults setObject:normalizedMessages(lines) forKey:MessagesKey];
    [defaults setInteger:boundedInterval(self.intervalEditor.integerValue) forKey:IntervalKey];
    [defaults synchronize];
    [self reloadOptions];
    [self cancelOptions:sender];
}
@end
