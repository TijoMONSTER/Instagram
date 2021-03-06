//
//  UserProfileViewController.m
//  Instagram
//
//  Created by Iván Mervich on 8/20/14.
//  Copyright (c) 2014 Mobile Makers. All rights reserved.
//

#import "UserProfileViewController.h"
#import "TabBarViewController.h"
#import "PostsFeedTableViewCell.h"
#import "Photo.h"
#import "PhotoDetailViewController.h"
#import "CommentsViewController.h"

#define UserPhotoCollectionViewCell @"UserPhotoCollectionViewCell"

// cell id
#define postsFeedCell @"PostsFeedCell"

// segue
#define showPhotoSegue @"showPhotoSegue"
#define showCommentsSegue @"showCommentsSegue"

// cell height
#define PostsFeedTableViewCellHeight 409

@interface UserProfileViewController () <UITabBarDelegate, UICollectionViewDataSource, UICollectionViewDelegate, UITableViewDataSource, UITableViewDelegate, PostsFeedTableViewCellDelegate>

@property (weak, nonatomic) IBOutlet UIButton *userImageView;
@property (weak, nonatomic) IBOutlet UILabel *postsLabel;
@property (weak, nonatomic) IBOutlet UILabel *followersLabel;
@property (weak, nonatomic) IBOutlet UILabel *followingLabel;
@property (weak, nonatomic) IBOutlet UITabBar *tabBar;

@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;

@property NSArray *userPhotos;

@property Photo *selectedPhoto;

@end

@implementation UserProfileViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

	[self setUserImageViewRoundCorners];
	self.tabBar.selectedItem = self.tabBar.items[0];
	self.collectionView.hidden = NO;
	self.tableView.hidden = YES;
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	self.navigationController.navigationBarHidden = NO;

	// if there's a user set, search with that, otherwise use the current user
	PFUser *user = (self.user) ? self.user : [PFUser currentUser];

	// set the title
    self.navigationItem.title = user.username;

	// set the user profile pic
	PFFile *file = user[@"avatar"];
	if (file) {
		[file getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {

			if (!error) {
				if (data) {
					UIImage *image = [UIImage imageWithData:data];
					self.userImageView.imageView.image = image;
				}
			} else {
				NSLog(@"Error getting user profile pic %@ %@", error, error.userInfo);
			}
		}];
	}

	// get the number of user posts
	PFQuery *postsQuery = [PFQuery queryWithClassName:@"Photo"];
	[postsQuery whereKey:@"user" equalTo:user];

	[postsQuery countObjectsInBackgroundWithBlock:^(int number, NSError *error) {
		if (!error) {
			self.postsLabel.text = [NSString stringWithFormat:@"%d", number];
		} else {
			NSLog(@"Error getting user posts number %@ %@", error, error.userInfo);
		}

		// get the user photos
		PFQuery *photosQuery = [PFQuery queryWithClassName:@"Photo"];
		[photosQuery whereKey:@"user" equalTo:user];
		[photosQuery includeKey:@"user"];

		[self.activityIndicator startAnimating];

		[photosQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
			if (!error) {
				self.userPhotos = objects;

				[self.collectionView reloadData];
				[self.tableView reloadData];

				[self.activityIndicator stopAnimating];

			} else {
				NSLog(@"Error getting user photos %@ %@", error, error.userInfo);
			}
		}];
	}];

	// get the number of followers
	PFQuery *followersQuery = [PFQuery queryWithClassName:@"Event"];
	[followersQuery whereKey:@"type" equalTo:@"follow"];
	[followersQuery whereKey:@"destination" equalTo:user];

	[followersQuery countObjectsInBackgroundWithBlock:^(int number, NSError *error) {
		if (!error) {
			self.followersLabel.text = [NSString stringWithFormat:@"%d", number];
		} else {
			NSLog(@"Error getting followers %@ %@", error, error.userInfo);
		}

		// get the number of following
		PFQuery *followingQuery = [PFQuery queryWithClassName:@"Event"];
		[followingQuery whereKey:@"type" equalTo:@"follow"];
		[followingQuery whereKey:@"origin" equalTo:user];

		[followersQuery countObjectsInBackgroundWithBlock:^(int number, NSError *error) {
			if (!error) {
				self.followingLabel.text = [NSString stringWithFormat:@"%d", number];
			} else {
				NSLog(@"Error getting following %@ %@", error, error.userInfo);
			}
		}];
	}];
}

- (void)setUserImageViewRoundCorners
{
	self.userImageView.layer.cornerRadius = self.userImageView.bounds.size.width / 2;
	self.userImageView.layer.masksToBounds = YES;
}

- (IBAction)onLogoutButtonTap:(id)sender {
    // Logout user, this automatically clears the cache
    [PFUser logOut];
    // Return to login view controller
    [self.navigationController popToRootViewControllerAnimated:YES];

	TabBarViewController *tabBarVC = (TabBarViewController *)self.tabBarController;
	[tabBarVC checkForLoggedUser];
}

#pragma mark - UITabBar Delegate methods

-(void)tabBar:(UITabBar *)tabBar didSelectItem:(UITabBarItem *)item
{
	// item at 0 = collection view
	// item at 1 = table view

	if ([item isEqual:tabBar.items[0]]) {
		self.collectionView.hidden = NO;
		self.tableView.hidden = YES;
	} else {
		self.collectionView.hidden = YES;
		self.tableView.hidden = NO;
	}
}

#pragma mark - UICollectionView DataSource methods

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
	return self.userPhotos.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
	UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:UserPhotoCollectionViewCell forIndexPath:indexPath];
	Photo *photo = self.userPhotos[indexPath.row];

	UIImageView *imageView = (UIImageView *)[cell viewWithTag:1];

	PFFile *file = photo[@"file"];
	[file getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {

		if (!error) {
			UIImage *image = [UIImage imageWithData:data];
			imageView.image = image;
		} else {
			NSLog(@"Error getting user photos %@ %@", error, error.userInfo);
		}
	}];

	return cell;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return PostsFeedTableViewCellHeight;
}

#pragma mark - UICollectionView Delegate methods

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
	[self performSegueWithIdentifier:showPhotoSegue sender:self.userPhotos[indexPath.row]];
}

#pragma mark - UITableView DataSource methods

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return self.userPhotos.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	Photo *photo = self.userPhotos[indexPath.row];
	PostsFeedTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:postsFeedCell];
	cell.delegate = self;

	[cell setCellWithPhoto:photo];
	[cell setUserImageViewRoundCorners];

	return cell;
}

#pragma mark - PostsFeedTableViewCell Delegate methods

- (void)didTapLikeButtonOnCell:(PostsFeedTableViewCell *)cell
{
	NSLog(@"like post");
}

- (void)didTapCommentButtonOnCell:(PostsFeedTableViewCell *)cell
{
	NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
	Photo *photo = self.userPhotos[indexPath.row];
	[self performSegueWithIdentifier:showCommentsSegue sender:photo];
}

- (void)didTapUserImageButtonOnCell:(PostsFeedTableViewCell *)cell
{
	NSLog(@"go to user profile");
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(Photo *)sender
{
	// called from the collection view cell
	if ([segue.identifier isEqualToString:showPhotoSegue]) {
		PhotoDetailViewController *photoDetailVC = segue.destinationViewController;
		photoDetailVC.photo = sender;
	}
	// called from the table view cell
	else if ([segue.identifier isEqualToString:showCommentsSegue]) {
		CommentsViewController *commentsVC = segue.destinationViewController;
		commentsVC.photo = sender;
	}
}

@end