//
//  RNAlbumsModule.h
//  RNAlbumsModule
//
//  Created by edison on 22/02/2017.
//  Copyright © 2017 edison. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AssetsLibrary/AssetsLibrary.h>

@protocol RCTBridgeModule;

@interface RNAlbumsModule : NSObject <RCTBridgeModule>
{
    void (^_completionHandler)(NSMutableDictionary *album);
}

- (void) getAlbumsCompletionHandler:(void(^)(NSMutableDictionary*))handler;
//- (void) getImageArray:((ALAssetsGroup *)options (void(^)(NSMutableDictionary*))handler);
@end
