//
//  mAExampleBrowser.m
//  miniAudicle
//
//  Created by Spencer Salazar on 6/13/13.
//
//

#import "mAExampleBrowser.h"


@interface NSFileManager (isDirectory)

- (BOOL)isDirectory:(NSString *)path;

@end

@implementation NSFileManager (isDirectory)

- (BOOL)isDirectory:(NSString *)path
{
    BOOL isDirectory = NO;
    if([self fileExistsAtPath:path isDirectory:&isDirectory])
        return isDirectory;
    else
        return NO;
}


@end


@interface mAExampleBrowser ()

@end

@implementation mAExampleBrowser

- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self)
    {
        // Initialization code here.
    }
    
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    
    [_browser setDoubleAction:@selector(open:)];
    [_browser setTarget:self];
}

- (IBAction)open:(id)sender
{
    [self.window close];
    
    NSString * examplePath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"examples"];
    NSString * columnPath = [examplePath stringByAppendingFormat:@"/%@", [_browser path]];
    [[NSDocumentController sharedDocumentController] openDocumentWithContentsOfURL:[NSURL fileURLWithPath:columnPath]
                                                                           display:YES
                                                                             error:nil];
}

- (IBAction)cancel:(id)sender
{
    [self.window close];
}


#pragma mark NSBrowserDelegate

- (NSInteger)browser:(NSBrowser *)sender numberOfRowsInColumn:(NSInteger)column
{
    NSFileManager * fileManager = [NSFileManager defaultManager];
    
    NSString * examplePath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"examples"];
    NSString * columnPath = [examplePath stringByAppendingFormat:@"/%@", [sender pathToColumn:column]];
    NSArray * contents = [fileManager contentsOfDirectoryAtPath:columnPath error:nil];
    
    return [contents count];
}

- (void)browser:(NSBrowser *)sender willDisplayCell:(id)cell atRow:(NSInteger)row column:(NSInteger)column
{
    NSBundle * mainBundle = [NSBundle mainBundle];
    NSFileManager * fileManager = [NSFileManager defaultManager];

    NSString * examplePath = [[mainBundle resourcePath] stringByAppendingPathComponent:@"examples"];
    NSString * columnPath = [examplePath stringByAppendingFormat:@"/%@", [sender pathToColumn:column]];
    NSArray * files = [fileManager contentsOfDirectoryAtPath:columnPath error:nil];
    NSString * file = [files objectAtIndex:row];
    NSString * fullpath = [columnPath stringByAppendingPathComponent:file];
    
    [cell setTitle:file];
    [cell setEnabled:YES];
    [cell setImage:nil];

    if([fileManager isDirectory:fullpath])
    {
        [cell setImage:[mainBundle imageForResource:@"folder.png"]];
        [cell setLeaf:NO];
    }
    else
    {
        if([[file pathExtension] isEqualToString:@"ck"])
            [cell setImage:[mainBundle imageForResource:@"ckmini.png"]];
        else
            [cell setEnabled:NO];
        [cell setLeaf:YES];
    }
}

- (CGFloat)browser:(NSBrowser *)browser heightOfRow:(NSInteger)row inColumn:(NSInteger)columnIndex
{
    return 64;
}

@end
