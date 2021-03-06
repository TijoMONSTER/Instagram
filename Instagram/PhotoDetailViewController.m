//
//  PhotoDetailViewController.m
//  Instagram
//
//  Created by Iván Mervich on 8/20/14.
//  Copyright (c) 2014 Mobile Makers. All rights reserved.
//

#import "PhotoDetailViewController.h"
#import "Photo.h"
#import "CommentsViewController.h"

// segue
#define showCommentsSegue @"showCommentsSegue"

@interface PhotoDetailViewController ()

@property (weak, nonatomic) IBOutlet UILabel *usernameLabel;
@property (weak, nonatomic) IBOutlet UIImageView *photoImageView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (weak, nonatomic) IBOutlet UILabel *likesLabel;
@property (weak, nonatomic) IBOutlet UIButton *userImageButton;

@end

@implementation PhotoDetailViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.photo.file getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {

		if (!error) {
			UIImage *image = [UIImage imageWithData:data];
			self.photoImageView.image = image;
		} else {
			NSLog(@"Error getting user photo on cell %@ %@", error, error.userInfo);
		}
	}];
    self.photoImageView.contentMode = UIViewContentModeScaleAspectFit;
	self.likesLabel.text = [NSString stringWithFormat:@"%d", self.photo.likes];
    self.usernameLabel.text = self.photo.user.username;

	if (!self.photo.likes) {
		PFQuery *eventQuery = [PFQuery queryWithClassName:@"Event"];
		[eventQuery whereKey:@"photo" equalTo:self.photo];
		[eventQuery countObjectsInBackgroundWithBlock:^(int number, NSError *error) {
			if (!error) {
				self.photo.likes = number;
				[self.photo saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
					if (!error) {
						self.likesLabel.text = [NSString stringWithFormat:@"%d", self.photo.likes];
					} else {
						NSLog(@"error setting likes for photo %@ %@", error, error.userInfo);
					}
				}];
			} else {
				NSLog(@"error getting likes %@ %@", error, error.userInfo);
			}
		}];
	}
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	self.navigationController.navigationBarHidden = NO;

	[self reload];
}

#pragma mark - IBActions
- (IBAction)onReloadButtonTapped:(UIBarButtonItem *)sender
{
	[self reload];
}

- (IBAction)onUserImageButtonTapped:(UIButton *)sender
{
	NSLog(@"load user profile");
}

- (IBAction)onLikeButtonTapped:(UIButton *)sender
{
    PFQuery *likeQuery = [PFQuery queryWithClassName:@"Event"];
    [likeQuery whereKey:@"photo" equalTo:self.photo];
    [likeQuery whereKey:@"origin" equalTo:[PFUser currentUser]];
    [likeQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error && objects.count == 0) {
            PFObject *newEvent = [PFObject objectWithClassName:@"Event"];
            [newEvent setObject:[PFUser currentUser] forKey:@"origin"];
            [newEvent setObject:self.photo.user forKey:@"destination"];
            [newEvent setObject:@"like" forKey:@"type"];
            [newEvent setObject:self.photo forKey:@"photo"];
            [newEvent setObject:@"" forKey:@"details"];

            [newEvent saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                if (!error) {
					self.photo.likes ++;
					[self.photo saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
						if (!error) {
							if (succeeded) {
								NSLog(@"like added to photo");
								self.likesLabel.text = [NSString stringWithFormat:@"%d", self.photo.likes];
							}
						} else {
							NSLog(@"error setting photo likes %@ %@", error, error.userInfo);
						}
					}];
                } else {
                    NSLog(@"Error: %@", error.userInfo);
                }
            }];
        }
    }];
}

//- (IBAction)onCommentButtonTapped:(UIButton *)sender
//{
//	NSLog(@"open comments from photo details");
//}

#pragma mark - UITableView Delegate



#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
	if ([segue.identifier isEqualToString:showCommentsSegue]) {
		CommentsViewController *commentsVC = segue.destinationViewController;
		commentsVC.photo = self.photo;
	}
}

#pragma mark - Helper methods

- (void)reload
{
	[self.activityIndicator startAnimating];

	[self.photo.file getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {

		if (!error) {
			UIImage *image = [UIImage imageWithData:data];
			self.photoImageView.image = image;
		} else {
			NSLog(@"Error getting user photo on cell %@ %@", error, error.userInfo);
		}
		[self.activityIndicator stopAnimating];
	}];

    self.photoImageView.contentMode = UIViewContentModeScaleAspectFit;
	self.likesLabel.text = [NSString stringWithFormat:@"%d", self.photo.likes];
    self.usernameLabel.text = self.photo.user.username;

	[self setUserImageViewRoundCorners];
}

- (void)setUserImageViewRoundCorners
{
	self.userImageButton.layer.cornerRadius = self.userImageButton.bounds.size.width / 2;
	self.userImageButton.layer.masksToBounds = YES;
}

@end
