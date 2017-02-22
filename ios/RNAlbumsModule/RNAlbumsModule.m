//
//  RNAlbumsModule.m
//  RNAlbumsModule
//
//  Created by edison on 22/02/2017.
//  Copyright © 2017 edison. All rights reserved.
//

#import "RNAlbumsModule.h"
#import "RNAlbumOptions.h"
#import <Photos/Photos.h>
#import <React/RCTBridge.h>
#import <React/RCTUtils.h>

#pragma mark - declaration
static NSString *albumNameFromType(PHAssetCollectionSubtype type);
static BOOL isAlbumTypeSupported(PHAssetCollectionSubtype type);

@implementation RNAlbumsModule

RCT_EXPORT_MODULE();

RCT_EXPORT_METHOD(getAlbumList:(NSDictionary *)options
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)
{
  [RNAlbumsModule authorize:^(BOOL authorized) {
    if (authorized) {
      PHFetchResult<PHAssetCollection *> *collections =
      [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum
                                               subtype:PHAssetCollectionSubtypeAny
                                               options:nil];
      __block NSMutableArray<NSDictionary *> *result = [[NSMutableArray alloc] init];
      [collections enumerateObjectsUsingBlock:^(PHAssetCollection * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        PHAssetCollectionSubtype type = [obj assetCollectionSubtype];
        if (!isAlbumTypeSupported(type)) {
          return;
        }
        
        PHFetchOptions *fetchOptions = [[PHFetchOptions alloc] init];
        fetchOptions.predicate = [NSPredicate predicateWithFormat:@"mediaType == %d", PHAssetMediaTypeImage];
        fetchOptions.sortDescriptors = @[ [NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:YES] ];
        PHFetchResult *fetchResult = [PHAsset fetchAssetsInAssetCollection:obj options: fetchOptions];
        PHAsset *coverAsset = fetchResult.lastObject;
        NSDictionary *album = @{@"count": @(fetchResult.count),
                                @"name": albumNameFromType(type),
                                // Photos Framework asset scheme ph://
                                // https://github.com/facebook/react-native/blob/master/Libraries/CameraRoll/RCTPhotoLibraryImageLoader.m
                                @"cover": coverAsset ? [NSString stringWithFormat:@"ph://%@", coverAsset.localIdentifier] : @"null" };
        [result addObject:album];
      }];
      resolve(result);
    } else {
      NSString *errorMessage = @"Access Photos Permission Denied";
      NSError *error = RCTErrorWithMessage(errorMessage);
      reject(@(error.code), errorMessage, error);
    }
  }];
}

typedef void (^authorizeCompletion)(BOOL);

+ (void)authorize:(authorizeCompletion)completion {
  switch ([PHPhotoLibrary authorizationStatus]) {
    case PHAuthorizationStatusAuthorized: {
      // 已授权
      completion(YES);
      break;
    }
    case PHAuthorizationStatusNotDetermined: {
      // 没有申请过权限，开始申请权限
      [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
        [RNAlbumsModule authorize:completion];
      }];
      break;
    }
    default: {
      // Restricted or Denied, 没有授权
      completion(NO);
      break;
    }
  }
}

@end

#pragma mark - 

static NSString *albumNameFromType(PHAssetCollectionSubtype type) {
  switch (type) {
    case PHAssetCollectionSubtypeSmartAlbumUserLibrary: return @"所有照片";
    case PHAssetCollectionSubtypeSmartAlbumSelfPortraits: return @"自拍";
    case PHAssetCollectionSubtypeSmartAlbumRecentlyAdded: return @"最近添加";
    case PHAssetCollectionSubtypeSmartAlbumTimelapses: return @"延时摄影";
    case PHAssetCollectionSubtypeSmartAlbumPanoramas: return @"全景照片";
    case PHAssetCollectionSubtypeSmartAlbumFavorites: return @"个人收藏";
    case PHAssetCollectionSubtypeSmartAlbumScreenshots: return @"屏幕快照";
    case PHAssetCollectionSubtypeSmartAlbumBursts: return @"连拍快照";
    case PHAssetCollectionSubtypeSmartAlbumVideos: return @"视频";
    case PHAssetCollectionSubtypeSmartAlbumSlomoVideos: return @"慢动作";
    case PHAssetCollectionSubtypeSmartAlbumDepthEffect: return @"景深效果";
    default: return @"";
  }
}

static BOOL isAlbumTypeSupported(PHAssetCollectionSubtype type) {
  switch (type) {
    case PHAssetCollectionSubtypeSmartAlbumUserLibrary:
    case PHAssetCollectionSubtypeSmartAlbumSelfPortraits:
    case PHAssetCollectionSubtypeSmartAlbumRecentlyAdded:
    case PHAssetCollectionSubtypeSmartAlbumTimelapses:
    case PHAssetCollectionSubtypeSmartAlbumPanoramas:
    case PHAssetCollectionSubtypeSmartAlbumFavorites:
    case PHAssetCollectionSubtypeSmartAlbumScreenshots:
    case PHAssetCollectionSubtypeSmartAlbumBursts:
    case PHAssetCollectionSubtypeSmartAlbumDepthEffect:
      return YES;
    default:
      return NO;
  }
}

