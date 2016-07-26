/*----------------------------------------------------------------------------
 miniAudicle iOS
 iOS GUI to chuck audio programming environment
 
 Copyright (c) 2005-2012 Spencer Salazar.  All rights reserved.
 http://chuck.cs.princeton.edu/
 http://soundlab.cs.princeton.edu/
 
 This program is free software; you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation; either version 2 of the License, or
 (at your option) any later version.
 
 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with this program; if not, write to the Free Software
 Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307
 U.S.A.
 -----------------------------------------------------------------------------*/

#import "mASocialFileViewController.h"

#import "mADetailViewController.h"
#import "mAAnalytics.h"
#import "mASocialTableViewCell.h"
#import "mASocialDetailItem.h"

#import "UIAlert.h"

#import "ChuckpadSocial.h"
#import "Patch.h"


static NSString *SocialCellIdentifier = @"SocialCell";

NSString *mASocialCategoryGetTitle(mASocialCategory category)
{
    switch(category)
    {
        case SOCIAL_CATEGORY_ALL:
            return @"All";
        case SOCIAL_CATEGORY_FEATURED:
            return @"Featured";
            break;
        case SOCIAL_CATEGORY_MYPATCHES:
            return @"My Patches";
        case SOCIAL_CATEGORY_DOCUMENTATION:
            return @"Documentation";
        default:
            NSCAssert(1, @"mASocialFileViewController: invalid category");
    }
}

@interface mASocialFileViewController ()
{
    IBOutlet UIView *_loadingView;
    IBOutlet UILabel *_loadingStatusLabel;
}

@property (strong, nonatomic) IBOutlet UITableView * tableView;

@property (strong, nonatomic) NSArray<Patch *> *patches;

@property (copy, nonatomic) NSString *loadingStatus;
@property (nonatomic) BOOL showsLoading;

- (void)_getPatchesForCategory:(GetPatchesCallback)callback;

@end


@implementation mASocialFileViewController

- (void)setLoadingStatus:(NSString *)loadingStatus
{
    _loadingStatus = loadingStatus;
    
    if(_loadingStatus)
        _loadingStatusLabel.text = _loadingStatus;
}

- (void)setShowsLoading:(BOOL)showsLoading
{
    _showsLoading = showsLoading;
    
    if(showsLoading)
    {
        [UIView animateWithDuration:0.25
                         animations:^{
                             _loadingView.alpha = 1.0;
                         }];
    }
    else
    {
        [UIView animateWithDuration:0.25
                         animations:^{
                             _loadingView.alpha = 0.0;
                         }];
    }
}

- (void)setCategory:(mASocialCategory)category
{
    _category = category;
    
    self.title = [mASocialCategoryGetTitle(category) uppercaseString];
}

- (id)init
{
    // force load from associated nib
    if(self = [self initWithNibName:@"mASocialFileViewController" bundle:nil]) { }
    
    return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if(self)
    {
        if([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
        {
            self.preferredContentSize = CGSizeMake(320.0, 600.0);
        }
    }
    return self;
}

#pragma mark - UIViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.tableView registerNib:[UINib nibWithNibName:@"mASocialTableViewCell"
                                               bundle:NULL]
         forCellReuseIdentifier:SocialCellIdentifier];
    
    self.loadingStatus = @"";
    self.showsLoading = NO;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
    } else {
        return YES;
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    if(self.patches == nil)
    {
//        ChuckPadSocial *chuckPad = [ChuckPadSocial sharedInstance];
        
        GetPatchesCallback gotPatches = ^(NSArray *patchesArray, NSError *error) {
            NSAssert([NSThread isMainThread], @"Network callback not on main thread");
            
            if(error == nil)
            {
                NSLog(@"Got patches");
                self.patches = patchesArray;
                
                self.showsLoading = NO;
                [self.tableView reloadData];
            }
            else
            {
                mAAnalyticsLogError(error);
                self.loadingStatus = @"Failed to load patches";
            }
        };

        [self _getPatchesForCategory:gotPatches];
        
        self.loadingStatus = @"Loading Chuckpad Social";
        self.showsLoading = YES;
    }
    
    [self.navigationController setToolbarHidden:YES animated:YES];
}

- (void)viewWillDisappear:(BOOL)animated
{
}

- (UINavigationItem *)navigationItem
{
    UINavigationItem *navigationItem = super.navigationItem;
    
    navigationItem.title = mASocialCategoryGetTitle(self.category);
    
    return navigationItem;
}

- (void)_getPatchesForCategory:(GetPatchesCallback)callback
{
    ChuckPadSocial *chuckPad = [ChuckPadSocial sharedInstance];
    
    switch (_category)
    {
        case SOCIAL_CATEGORY_ALL:
            [chuckPad getAllPatches:callback];
            break;
        case SOCIAL_CATEGORY_DOCUMENTATION:
            [chuckPad getDocumentationPatches:callback];
            break;
        case SOCIAL_CATEGORY_FEATURED:
            [chuckPad getFeaturedPatches:callback];
            break;
        case SOCIAL_CATEGORY_MYPATCHES:
            if([chuckPad isLoggedIn])
                [chuckPad getMyPatches:callback];
            else
                UIAlertMessage(@"You must be logged in to see your patches", ^{});
            break;
        default:
            NSAssert(1, @"mASocialFileViewController: invalid category");
            break;
    }
}

#pragma mark - IBActions


#pragma mark - UITableViewDataSource / UITableViewDelegate

// Customize the number of sections in the table view.
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView 
 numberOfRowsInSection:(NSInteger)section
{
    if(self.patches)
        return self.patches.count;
    else
        return 0;
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView 
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger index = indexPath.row;
    mASocialTableViewCell *cell = (mASocialTableViewCell *) [tableView dequeueReusableCellWithIdentifier:SocialCellIdentifier];
        
    cell.name = self.patches[index].name;
    // cell.desc = self.patches[index].description;
    cell.category = [NSString stringWithFormat:@"by %@", self.patches[index].creatorUsername];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger index = indexPath.row;
    mASocialDetailItem *item = [mASocialDetailItem socialDetailItemWithPatch:self.patches[index]];
    [self.detailViewController showDetailItem:item];
}


- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return UITableViewCellEditingStyleNone;
}

@end

