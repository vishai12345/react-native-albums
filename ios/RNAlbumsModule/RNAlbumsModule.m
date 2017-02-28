//
//  RNAlbumsModule.m
//  RNAlbumsModule
//
//  Created by edison on 22/02/2017.
//  Copyright © 2017 edison. All rights reserved.
//

#import "RNAlbumsModule.h"
#import "RNAlbumOptions.h"
#import <React/RCTBridge.h>
#import <React/RCTUtils.h>
#import <Photos/Photos.h>
#import <AssetsLibrary/AssetsLibrary.h>

@implementation RNAlbumsModule

RCT_EXPORT_MODULE();

RCT_EXPORT_METHOD(getAlbumList:(NSDictionary *)options
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)
{
  [RNAlbumsModule authorize:^(BOOL authorized) {
    if (authorized) {
      ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
      __block NSMutableArray<ALAssetsGroup *> *groups = [[NSMutableArray alloc] init];
      [library enumerateGroupsWithTypes:ALAssetsGroupAll
                             usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
                               if (group == nil) {
                                 [self fetchPHCollectionFromALGroup:groups resolver:resolve];
                                 *stop = YES;
                                 return;
                               }
                               
                               [groups addObject:group];
                             }
                           failureBlock:^(NSError *error) {
                             reject(@(error.code), error.localizedDescription, error);
                           }];
    } else {
      NSString *errorMessage = @"Access Photos Permission Denied";
      NSError *error = RCTErrorWithMessage(errorMessage);
      reject(@(error.code), errorMessage, error);
    }
  }];
}

- (void)fetchPHCollectionFromALGroup:(NSArray<ALAssetsGroup *> *)groups
                            resolver:(RCTPromiseResolveBlock)resolve {
  __block NSMutableArray *URLs = [[NSMutableArray alloc] init];
  [groups enumerateObjectsUsingBlock:^(ALAssetsGroup * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
    NSURL *URL = [obj valueForProperty:ALAssetsGroupPropertyURL];
    if (URL) { [URLs addObject:URL]; }
  }];
  
  PHFetchResult<PHAssetCollection *> *collections =
  [PHAssetCollection fetchAssetCollectionsWithALAssetGroupURLs:URLs options:nil];
  __block NSMutableArray<NSDictionary *> *result = [[NSMutableArray alloc] init];
  
  [collections enumerateObjectsUsingBlock:^(PHAssetCollection * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
    PHAssetCollectionSubtype type = [obj assetCollectionSubtype];
    
    PHFetchOptions *fetchOptions = [[PHFetchOptions alloc] init];
    fetchOptions.predicate = [NSPredicate predicateWithFormat:@"mediaType == %d", PHAssetMediaTypeImage];
    fetchOptions.sortDescriptors = @[ [NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:YES] ];
    PHFetchResult *fetchResult = [PHAsset fetchAssetsInAssetCollection:obj options: fetchOptions];
    PHAsset *coverAsset = fetchResult.lastObject;
    
    if (fetchResult.count > 0 && coverAsset) {
      NSDictionary *album = @{@"count": @(fetchResult.count),
                              @"name": obj.localizedTitle,
                              // Photos Framework asset scheme ph://
                              // https://github.com/facebook/react-native/blob/master/Libraries/CameraRoll/RCTPhotoLibraryImageLoader.m
                              @"cover": [NSString stringWithFormat:@"ph://%@", coverAsset.localIdentifier] };
      [result addObject:album];
    }
  }];
  
  resolve(result);
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
