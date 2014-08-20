//
//  PostsFeedTableViewCell.h
//  Instagram
//
//  Created by Iván Mervich on 8/19/14.
//  Copyright (c) 2014 Mobile Makers. All rights reserved.
//

#import <UIKit/UIKit.h>

@class PostsFeedTableViewCell;

@protocol PostsFeedTableViewCellDelegate

- (void)didTapLikeButtonOnCell:(PostsFeedTableViewCell *)cell;
- (void)didTapCommentButtonOnCell:(PostsFeedTableViewCell *)cell;
- (void)didTapUserImageButtonOnCell:(PostsFeedTableViewCell *)cell;

@end

@interface PostsFeedTableViewCell : UITableViewCell

@property id<PostsFeedTableViewCellDelegate> delegate;

- (void)setUserImageViewRoundCorners;

@end
