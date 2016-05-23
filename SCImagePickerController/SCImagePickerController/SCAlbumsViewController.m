//
//  SCAlbumsViewController.m
//  SCImagePickerController
//
//  Created by sichenwang on 16/5/20.
//  Copyright © 2016年 sichenwang. All rights reserved.
//

#import "SCAlbumsViewController.h"
#import "SCImagePickerController.h"
#import "SCGridViewController.h"
#import "SCAlbumsViewCell.h"
#import "SCBadgeView.h"

static NSString * const SCAlbumsViewCellReuseIdentifier = @"SCAlbumsViewCellReuseIdentifier";

@interface SCAlbumsViewController()

@property (strong) NSArray *collectionsFetchResults;
@property (strong) NSArray *collectionsFetchResultsAssets;
@property (strong) NSArray *collectionsFetchResultsTitles;
@property (nonatomic, weak) SCImagePickerController *picker;
@property (strong) PHCachingImageManager *imageManager;
@property (nonatomic, strong) SCBadgeView *badgeView;

@end

@implementation SCAlbumsViewController

- (instancetype)init {
    if (self = [super initWithStyle:UITableViewStylePlain]) {
        self.title = @"相册";
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.imageManager = [[PHCachingImageManager alloc] init];
    self.tableView.rowHeight = kAlbumThumbnailSize.height + 0.5;
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"取消"
                                                                             style:UIBarButtonItemStylePlain
                                                                            target:self.picker
                                                                            action:@selector(dismiss:)];
    if (self.picker.allowsMultipleSelection) {
        UIBarButtonItem *doneButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"完成"
                                                                           style:UIBarButtonItemStyleDone
                                                                          target:self.picker
                                                                          action:@selector(finishPickingAssets:)];
        doneButtonItem.enabled = self.picker.selectedAssets.count > 0;
        
        self.badgeView = [[SCBadgeView alloc] init];
        self.badgeView.number = self.picker.selectedAssets.count;
        UIBarButtonItem *badgeButtonItem = [[UIBarButtonItem alloc] initWithCustomView:self.badgeView];
        
        self.navigationItem.rightBarButtonItems = @[doneButtonItem, badgeButtonItem];
    }

    PHFetchResult *smartAlbums = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype:PHAssetCollectionSubtypeAlbumRegular options:nil];
    PHFetchResult *userAlbums = [PHCollectionList fetchTopLevelUserCollectionsWithOptions:nil];
    self.collectionsFetchResults = @[smartAlbums, userAlbums];

    [self updateFetchResults];
}

- (void)updateFetchResults {
    
    self.collectionsFetchResultsAssets = nil;
    self.collectionsFetchResultsTitles = nil;
    
    //Fetch PHAssetCollections:
    PHFetchResult *smartAlbums = [self.collectionsFetchResults objectAtIndex:0];
    PHFetchResult *userAlbums = [self.collectionsFetchResults objectAtIndex:1];
    
    //Smart albums: Sorted by descending creation date.
    NSMutableArray *smartFetchResultArray = [[NSMutableArray alloc] init];
    NSMutableArray *smartFetchResultLabel = [[NSMutableArray alloc] init];
    for (PHAssetCollection *collection in smartAlbums)
    {
        PHFetchOptions *options = [[PHFetchOptions alloc] init];
        options.predicate = [NSPredicate predicateWithFormat:@"mediaType in %@", self.picker.mediaTypes];
        options.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:YES]];
        
        PHFetchResult *assetsFetchResult = [PHAsset fetchAssetsInAssetCollection:collection options:options];
        if (assetsFetchResult.count > 0)
        {
            if (collection.assetCollectionSubtype == PHAssetCollectionSubtypeSmartAlbumUserLibrary) {
                [smartFetchResultArray insertObject:assetsFetchResult atIndex:0];
                [smartFetchResultLabel insertObject:collection.localizedTitle atIndex:0];
            } else {
                [smartFetchResultArray addObject:assetsFetchResult];
                [smartFetchResultLabel addObject:collection.localizedTitle];
            }
        }
    }

    //User albums:
    NSMutableArray *userFetchResultArray = [[NSMutableArray alloc] init];
    NSMutableArray *userFetchResultLabel = [[NSMutableArray alloc] init];
    for (PHCollection *collection in userAlbums)
    {
        if ([collection isKindOfClass:[PHAssetCollection class]])
        {
            PHFetchOptions *options = [[PHFetchOptions alloc] init];
            options.predicate = [NSPredicate predicateWithFormat:@"mediaType in %@", self.picker.mediaTypes];
            PHAssetCollection *assetCollection = (PHAssetCollection *)collection;
            
            PHFetchResult *assetsFetchResult = [PHAsset fetchAssetsInAssetCollection:assetCollection options:options];
            [userFetchResultArray addObject:assetsFetchResult];
            [userFetchResultLabel addObject:collection.localizedTitle];
        }
    }
    
    self.collectionsFetchResultsAssets = @[smartFetchResultArray, userFetchResultArray];
    self.collectionsFetchResultsTitles = @[smartFetchResultLabel, userFetchResultLabel];
    
    if (self.picker.sourceType == SCImagePickerControllerSourceTypeSavedPhotosAlbum && smartFetchResultArray.count > 0 && smartFetchResultLabel.count > 0) {
        SCGridViewController *cameraRollViewController = [[SCGridViewController alloc] initWithPicker:[self picker]];
        cameraRollViewController.title = smartFetchResultLabel[0];
        cameraRollViewController.assetsFetchResults = smartFetchResultArray[0];
        [self.navigationController pushViewController:cameraRollViewController animated:NO];
    }
}

- (SCImagePickerController *)picker {
    return (SCImagePickerController *)self.navigationController.parentViewController;
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.collectionsFetchResultsAssets.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    PHFetchResult *fetchResult = self.collectionsFetchResultsAssets[section];
    return fetchResult.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    SCAlbumsViewCell *cell = [tableView dequeueReusableCellWithIdentifier:SCAlbumsViewCellReuseIdentifier];
    if (cell == nil) {
        cell = [[SCAlbumsViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:SCAlbumsViewCellReuseIdentifier];
    }
    // Increment the cell's tag
    NSInteger currentTag = cell.tag + 1;
    cell.tag = currentTag;

    PHFetchResult *assetsFetchResult = (self.collectionsFetchResultsAssets[indexPath.section])[indexPath.row];
    NSString *text = (self.collectionsFetchResultsTitles[indexPath.section])[indexPath.row];
    NSMutableAttributedString *attrStrM = [[NSMutableAttributedString alloc] initWithString:text attributes:@{NSFontAttributeName : [UIFont boldSystemFontOfSize:16]}];
    [attrStrM appendAttributedString:[[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"  (%ld)", (long)[assetsFetchResult count]] attributes:@{NSForegroundColorAttributeName : [UIColor grayColor]}]];
    cell.textLabel.attributedText = [attrStrM copy];
    
    if ([assetsFetchResult count] > 0) {
        CGFloat scale = [UIScreen mainScreen].scale;
        PHAsset *asset = assetsFetchResult.lastObject;
        [self.imageManager requestImageForAsset:asset
                                     targetSize:CGSizeMake(self.tableView.rowHeight * scale, self.tableView.rowHeight * scale)
                                    contentMode:PHImageContentModeAspectFill
                                        options:nil
                                  resultHandler:^(UIImage *result, NSDictionary *info) {
                                      if (cell.tag == currentTag) {
                                          cell.thumbnailView.image = result;
                                      }
                                  }];
    }
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    SCGridViewController *gridViewController = [[SCGridViewController alloc] initWithPicker:[self picker]];
    gridViewController.title = (self.collectionsFetchResultsTitles[indexPath.section])[indexPath.row];
    gridViewController.assetsFetchResults = (self.collectionsFetchResultsAssets[indexPath.section])[indexPath.row];
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    [self.navigationController pushViewController:gridViewController animated:YES];
}

@end
