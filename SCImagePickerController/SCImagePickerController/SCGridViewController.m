//
//  SCGridViewController.m
//  SCImagePickerController
//
//  Created by sichenwang on 16/5/20.
//  Copyright © 2016年 sichenwang. All rights reserved.
//

#import "SCGridViewController.h"
#import "SCImagePickerController.h"
#import "SCAlbumsViewController.h"
#import "SCGridViewCell.h"
#import "SCBadgeView.h"

@interface SCGridViewController()

@property (nonatomic, weak) SCImagePickerController *picker;
@property (strong) PHCachingImageManager *imageManager;
@property (nonatomic, strong) SCBadgeView *badgeView;

@end

static CGSize AssetGridThumbnailSize;
NSString * const SCGridViewCellIdentifier = @"SCGridViewCellIdentifier";

@implementation SCGridViewController
{
    CGFloat screenWidth;
    CGFloat screenHeight;
}

- (instancetype)initWithPicker:(SCImagePickerController *)picker {
    //Custom init. The picker contains custom information to create the FlowLayout
    self.picker = picker;
    
    screenWidth = CGRectGetWidth(picker.view.bounds);
    screenHeight = CGRectGetHeight(picker.view.bounds);
    
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.minimumInteritemSpacing = 1;
    NSInteger cellTotalUsableWidth = screenWidth - 3;
    layout.itemSize = CGSizeMake(cellTotalUsableWidth / 4, cellTotalUsableWidth / 4);
    CGFloat cellTotalUsedWidth = layout.itemSize.width * 4;
    CGFloat spaceTotalWidth = screenWidth - cellTotalUsedWidth;
    CGFloat spaceWidth = spaceTotalWidth / 3;
    layout.minimumLineSpacing = spaceWidth;

    if (self = [super initWithCollectionViewLayout:layout]) {
        CGFloat scale = [UIScreen mainScreen].scale;
        AssetGridThumbnailSize = CGSizeMake(layout.itemSize.width * scale, layout.itemSize.height * scale);
        self.collectionView.allowsMultipleSelection = picker.allowsMultipleSelection;
        [self.collectionView registerClass:SCGridViewCell.class
                forCellWithReuseIdentifier:SCGridViewCellIdentifier];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.imageManager = [[PHCachingImageManager alloc] init];
    self.collectionView.backgroundColor = [UIColor whiteColor];
    
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
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    NSLog(@"当前相册有%zd张图片", self.assetsFetchResults.count);
    
    dispatch_async(dispatch_get_main_queue(), ^{
        NSInteger lastRow = self.assetsFetchResults.count - 1;
        if (lastRow > 0) {
            [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForRow:lastRow inSection:0] atScrollPosition:UICollectionViewScrollPositionBottom animated:NO];
        }
    });
    return self.assetsFetchResults.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    SCGridViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:SCGridViewCellIdentifier
                                                                     forIndexPath:indexPath];
    
    // Increment the cell's tag
    NSInteger currentTag = cell.tag + 1;
    cell.tag = currentTag;
    
    PHAsset *asset = self.assetsFetchResults[indexPath.item];
    {
        [self.imageManager requestImageForAsset:asset
                                     targetSize:AssetGridThumbnailSize
                                    contentMode:PHImageContentModeAspectFill
                                        options:nil
                                  resultHandler:^(UIImage *result, NSDictionary *info) {
                                      
                                      // Only update the thumbnail if the cell tag hasn't changed. Otherwise, the cell has been re-used.
                                      if (cell.tag == currentTag) {
                                          [cell.imageView setImage:result];
                                      }
                                  }];
    }
    
    cell.asset = asset;
    cell.shouldShowSelection = self.picker.allowsMultipleSelection;
        
    if ([self.picker.selectedAssets containsObject:asset]) {
        cell.selected = YES;
    } else {
        cell.selected = NO;
    }
    
    return cell;
}

#pragma mark - UICollectionViewDelegate

- (BOOL)collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if (self.picker.maxMultipleCount > 0 && self.picker.maxMultipleCount == self.picker.selectedAssets.count) {
        if ([self.picker.delegate respondsToSelector:@selector(assetsPickerVontrollerDidOverrunMaxMultipleCount:)]) {
            [self.picker.delegate assetsPickerVontrollerDidOverrunMaxMultipleCount:self.picker];
        }
        return NO;
    } else {
        return YES;
    }
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    PHAsset *asset = self.assetsFetchResults[indexPath.item];
    
    [self.picker selectAsset:asset];
}

- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath {
    PHAsset *asset = self.assetsFetchResults[indexPath.item];
    
    [self.picker deselectAsset:asset];
}

@end