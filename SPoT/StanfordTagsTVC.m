//
//  StanfordTagsTVC.m
//  SPoT
//
//  Created by Tatiana Kornilova on 2/22/13.
//  Copyright (c) 2013 Tatiana Kornilova. All rights reserved.
//

#import "StanfordTagsTVC.h"
#import "FlickrFetcher.h"
#import "NetworkIndicatorHelper.h"


@interface StanfordTagsTVC ()

@property (nonatomic, strong) NSArray *Tags;
@property (nonatomic, strong) NSDictionary *photosByTags;
@property (nonatomic, strong) NSArray *ignoredTags;
@end

@implementation StanfordTagsTVC

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self loadStanfordPhotos];
    
    // a UIRefreshControl inherits from UIControl, so we can use normal target/action
    // this is the first time you’ve seen this done without ctrl-dragging in Xcode
    [self.refreshControl addTarget:self
                            action:@selector(loadStanfordPhotos)
                  forControlEvents:UIControlEventValueChanged];

 }

-(NSDictionary *)photosByTags
{
    if (!_photosByTags)
        _photosByTags =[[NSMutableDictionary alloc] init];
    return _photosByTags;
}
- (NSArray *)ignoredTags
{
    return [[NSArray alloc] initWithObjects:@"cs193pspot", @"portrait", @"landscape", nil];
}

- (void)loadStanfordPhotos
{
    [self startRefreshControl];
    
    dispatch_queue_t flickrQ = dispatch_queue_create("Photos from flickr", NULL);
    dispatch_async(flickrQ, ^{
        
        [NetworkIndicatorHelper setNetworkActivityIndicatorVisible:YES];
        NSArray *photosStanford = [FlickrFetcher stanfordPhotos];
        [NetworkIndicatorHelper setNetworkActivityIndicatorVisible:NO];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            [self arrangedByTags:photosStanford];
            [self.tableView reloadData];
            [self stopRefreshing];
            
        });
    });
}
-(void)arrangedByTags:(NSArray *)photosStanford
{
    // We want to divide the photos up by tag, so we can use a dictionary with the
	// tag name as key and the array of photos as values
    
        NSMutableDictionary *photosByTag = [NSMutableDictionary dictionary];
        for (NSDictionary *photo in photosStanford) {
            NSMutableArray *photoTags=[[photo[FLICKR_TAGS] componentsSeparatedByString:@" "] mutableCopy]; //one photo tags
            [photoTags removeObjectsInArray:self.ignoredTags];
            for (NSString *tag in photoTags) {
                // If tag isn't already in the dictionary, add it with a new array
                
                if (![photosByTag objectForKey:tag]) {
                    [photosByTag setObject:[NSMutableArray array] forKey:tag];
                }
                // Add the photo to the tags' value array
                [(NSMutableArray *)[photosByTag  objectForKey:tag] addObject:photo];
            }
        }
            self.photosByTags =photosByTag;
            self.Tags =[[self.photosByTags allKeys] sortedArrayUsingSelector:@selector(compare:)];
}

#pragma mark - Table view data source


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
   
    return [self.Tags count];
}

-(NSString *)titleForRow:(NSUInteger)row
{
    return [self.Tags[row] capitalizedString];
}
-(NSString *)subTitleForRow:(NSUInteger)row
{
    int tagCount =[(NSMutableArray *)[self.photosByTags  objectForKey:self.Tags[row]] count];
    return [NSString stringWithFormat:@"%d photo%@",tagCount,(tagCount == 1) ? @"" : @"s"];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Tag";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    cell.textLabel.text = [self titleForRow:indexPath.row];
    cell.detailTextLabel.text = [self subTitleForRow:indexPath.row];  // 
    
    return cell;
}
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([sender isKindOfClass:[UITableViewCell class]]) {
        NSIndexPath *indexPath = [self.tableView indexPathForCell:sender];
        if (indexPath) {
            //-----------------------
            if ([segue.identifier isEqualToString:@"Show Photos For Tag"]) {
                if ([segue.destinationViewController respondsToSelector:@selector(setPhotos:)]) {
                    NSArray *photos = [NSArray arrayWithArray:(NSMutableArray *)[self.photosByTags  objectForKey:self.Tags[indexPath.row]]];
                    [segue.destinationViewController performSelector:@selector(setPhotos:) withObject:photos];
                    [segue.destinationViewController setTitle:[self titleForRow:indexPath.row]];
                }
                //----------------------------
            }
        }
    }
}
- (void)startRefreshControl
{
    [self.refreshControl beginRefreshing];
    //--------------------
	//set the title while refreshing
    self.refreshControl.attributedTitle = [[NSAttributedString alloc] initWithString:@"Refreshing the TableView"];
    //set the date and time of refreshing
    NSDateFormatter *formattedDate = [[NSDateFormatter alloc] init];
    [formattedDate setDateFormat:@"MMM d, h:mm a"];
    NSString *lastupdated = [NSString stringWithFormat:@"Last Updated on %@",[formattedDate stringFromDate:[NSDate date]]];
    self.refreshControl.attributedTitle = [[NSAttributedString alloc] initWithString:lastupdated];	
    //--------------------
}

- (void)stopRefreshing
{
	if (self.refreshControl.refreshing) {
		[self.refreshControl endRefreshing];
		[self.tableView setContentOffset:CGPointZero animated:YES];
	}
}

@end
