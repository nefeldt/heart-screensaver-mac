#import <ScreenSaver/ScreenSaver.h>
#import <OpenGL/gl.h>
#include <math.h>

static ScreenSaverDefaults *HeartDefaults(void) {
    ScreenSaverDefaults *defaults = [ScreenSaverDefaults defaultsForModuleWithName:@"de.noah.herz.screensaver"];
    [defaults registerDefaults:@{@"texts": @[@"I love my job"], @"textInterval": @10}];
    return defaults;
}

@interface HeartOpenGLView : NSOpenGLView {
    GLuint _textTexture;
    CGFloat _textAspect;
    NSString *_renderedText;
}
@property(nonatomic, copy) NSArray<NSString *> *texts;
@property(nonatomic) double textInterval;
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

static void heartVertex(int i, double z) {
    double t = 2 * M_PI * i / 12;
    double s = sin(t);
    glVertex3d(16*s*s*s / 20, (13*cos(t)-5*cos(2*t)-2*cos(3*t)-cos(4*t))/20 + 0.15, z);
}

- (void)render {
    [self.openGLContext makeCurrentContext];
    NSArray<NSString *> *texts = self.texts.count ? self.texts : @[@"I love my job"];
    NSUInteger index = (NSUInteger)(NSProcessInfo.processInfo.systemUptime / MAX(1, self.textInterval)) % texts.count;
    NSString *text = texts[index];
    if (![_renderedText isEqualToString:text]) [self createTextTexture:text];
    NSRect pixels = [self convertRectToBacking:self.bounds];
    glViewport(0, 0, (GLsizei)pixels.size.width, (GLsizei)pixels.size.height);
    glClearColor(0.1, 0.1, 0.1, 1);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    glMatrixMode(GL_PROJECTION);
    glLoadIdentity();
    glOrtho(-1, 1, -1, 1, -2, 2);
    glMatrixMode(GL_MODELVIEW);
    glLoadIdentity();
    glRotated(fmod(NSProcessInfo.processInfo.systemUptime, 2*M_PI) * 180/M_PI, 0, 1, 0);
    glEnable(GL_DEPTH_TEST);
    glDisable(GL_BLEND);
    glDisable(GL_TEXTURE_2D);
    glColor3f(0.9, 0.1, 0.2);
    for (int face = 0; face < 2; face++) {
        double z = face == 0 ? 0.15 : -0.15;
        glBegin(GL_TRIANGLE_FAN);
        glVertex3d(0, 0, z);
        for (int i = 0; i <= 12; i++) heartVertex(i, z);
        glEnd();
    }
    glColor3f(0.5, 0.05, 0.1);
    glBegin(GL_TRIANGLE_STRIP);
    for (int i = 0; i <= 12; i++) {
        heartVertex(i, 0.15);
        heartVertex(i, -0.15);
    }
    glEnd();

    glLoadIdentity();
    glDisable(GL_DEPTH_TEST);
    glEnable(GL_BLEND);
    glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);
    glEnable(GL_TEXTURE_2D);
    glBindTexture(GL_TEXTURE_2D, _textTexture);
    glColor4f(1, 1, 1, 1);
    double height = 0.15;
    double width = height * _textAspect;
    if (width > 1.85) { height *= 1.85 / width; width = 1.85; }
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
@property(nonatomic, strong) NSTextView *textsEditor;
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
    ScreenSaverDefaults *defaults = HeartDefaults();
    NSArray *stored = [defaults arrayForKey:@"texts"];
    NSMutableArray *texts = [NSMutableArray array];
    for (id value in stored) {
        if ([value isKindOfClass:NSString.class] && [value length] > 0) [texts addObject:value];
    }
    self.renderer.texts = texts;
    self.renderer.textInterval = MAX(1, [defaults doubleForKey:@"textInterval"]);
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
    NSScrollView *scroll = [[NSScrollView alloc] initWithFrame:NSMakeRect(20, 100, 440, 200)];
    scroll.borderType = NSBezelBorder;
    scroll.hasVerticalScroller = YES;
    self.textsEditor = [[NSTextView alloc] initWithFrame:scroll.contentView.bounds];
    self.textsEditor.richText = NO;
    self.textsEditor.font = [NSFont systemFontOfSize:14];
    self.textsEditor.verticallyResizable = YES;
    self.textsEditor.autoresizingMask = NSViewWidthSizable;
    self.textsEditor.textContainer.widthTracksTextView = YES;
    [self reloadOptions];
    self.textsEditor.string = [self.renderer.texts componentsJoinedByString:@"\n"];
    scroll.documentView = self.textsEditor;
    [content addSubview:scroll];
    NSTextField *intervalLabel = [NSTextField labelWithString:@"Change message every (seconds):"];
    intervalLabel.frame = NSMakeRect(20, 65, 275, 22);
    [content addSubview:intervalLabel];
    self.intervalEditor = [[NSTextField alloc] initWithFrame:NSMakeRect(300, 65, 80, 24)];
    self.intervalEditor.integerValue = (NSInteger)self.renderer.textInterval;
    NSNumberFormatter *formatter = [NSNumberFormatter new];
    formatter.numberStyle = NSNumberFormatterDecimalStyle;
    formatter.allowsFloats = NO;
    formatter.minimum = @1;
    formatter.maximum = @3600;
    self.intervalEditor.formatter = formatter;
    [content addSubview:self.intervalEditor];
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

- (void)cancelOptions:(id)sender {
    [self.optionsWindow.sheetParent endSheet:self.optionsWindow];
    [self.optionsWindow orderOut:nil];
}

- (void)saveOptions:(id)sender {
    NSMutableArray *texts = [NSMutableArray array];
    for (NSString *line in [self.textsEditor.string componentsSeparatedByCharactersInSet:NSCharacterSet.newlineCharacterSet]) {
        NSString *text = [line stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
        if (text.length) [texts addObject:text];
    }
    if (!texts.count) [texts addObject:@"I love my job"];
    ScreenSaverDefaults *defaults = HeartDefaults();
    [defaults setObject:texts forKey:@"texts"];
    [defaults setInteger:MAX(1, MIN(3600, self.intervalEditor.integerValue)) forKey:@"textInterval"];
    [defaults synchronize];
    [self reloadOptions];
    [self cancelOptions:sender];
}
@end
