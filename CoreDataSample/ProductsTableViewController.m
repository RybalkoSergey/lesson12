//
//  ProductsTableViewController.m
//  CoreDataSample
//
//  Created by Sergey Zalozniy on 01/02/16.
//  Copyright © 2016 GeekHub. All rights reserved.
//

#import "CoreDataManager.h"

#import "CDBasket.h"
#import "CDProduct.h"

#import "ProductsTableViewController.h"
#import "ProductDetailViewController.h"


@interface ProductsTableViewController () <UITableViewDelegate, UIActionSheetDelegate, NSFetchedResultsControllerDelegate>

@property (strong, nonatomic) NSArray *items;
@property (strong, nonatomic) NSArray *soldItems;
@property (strong, nonatomic) NSArray *notSoldItems;
@property (nonatomic, strong) CDBasket *basket;
@property (nonatomic, strong) CDProduct *selectedProduct;
@property (strong, nonatomic) UIActionSheet *actionSheet;

@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;

@end

@implementation ProductsTableViewController

#pragma mark - Instance initialization

+(instancetype) instanceControllerWithBasket:(CDBasket *)basket {
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    ProductsTableViewController *controller = [sb instantiateViewControllerWithIdentifier:@"ProductsTableViewControllerIdentifier"];
    controller.basket = basket;
    return controller;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self fetchProducts];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addNewProduct:)];
    //[self refreshData];
    
    self.actionSheet = [[UIActionSheet alloc] initWithTitle:@"What do you want to do with current product?"
                                                   delegate:self
                                          cancelButtonTitle:@"Cancel"
                                     destructiveButtonTitle:@"Delete"
                                          otherButtonTitles:@"Edit", @"Buy", nil];
}

#pragma mark - Private methods

-(void) refreshData {
    self.items = [self fetchProducts];
    self.soldItems = [self fetchSoldProducts];
    self.notSoldItems = [self fetchNotSoldProducts];
    [self.tableView reloadData];
}


-(void) addNewProduct:(id)sender {
    UIAlertController *controller = [UIAlertController alertControllerWithTitle:@"New Basket" message:@"Enter name" preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *action = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        
    }];
    [controller addAction:action];
    [controller addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = @"Product name";
    }];
    [controller addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = @"Product count";
    }];
    action = [UIAlertAction actionWithTitle:@"Create" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        UITextField *textFieldName = controller.textFields[0];
        UITextField *textFieldCount = controller.textFields[1];
        
        [self createProductWithName:textFieldName.text andCount: [NSDecimalNumber decimalNumberWithString:textFieldCount.text]];
    }];
    
    [controller addAction:action];
    [self presentViewController:controller animated:YES completion:NULL];
}


-(void) createProductWithName:(NSString *)name {
    NSManagedObjectContext *context = [CoreDataManager sharedInstance].managedObjectContext;
    CDProduct *product = [NSEntityDescription insertNewObjectForEntityForName:[[CDProduct class] description]
                                                       inManagedObjectContext:context];
    product.name = name;
    [self.basket addProductsObject:product];
    [[CoreDataManager sharedInstance] saveContext];
    [self refreshData];
}

-(void) createProductWithName:(NSString *)name andCount:(NSDecimalNumber *)count {
    NSManagedObjectContext *context = [CoreDataManager sharedInstance].managedObjectContext;
    CDProduct *product = [NSEntityDescription insertNewObjectForEntityForName:[[CDProduct class] description]
                                                       inManagedObjectContext:context];
    product.name = name;
    product.actualPrice = count;
    [self.basket addProductsObject:product];
    [[CoreDataManager sharedInstance] saveContext];
    [self refreshData];
}

#pragma mark - NSFetch result controller

-(NSArray *) fetchProducts {
    NSManagedObjectContext *context = [CoreDataManager sharedInstance].managedObjectContext;
    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:[[CDProduct class] description]];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"basket = %@", self.basket.objectID];
    request.predicate = predicate;
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES];
    request.sortDescriptors = @[sortDescriptor];
    
    self.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:request managedObjectContext:context sectionNameKeyPath:@"complete" cacheName:nil];
    
    // Configure Fetched Results Controller
    [self.fetchedResultsController setDelegate:self];
    
    // Perform Fetch
    NSError *error = nil;
    [self.fetchedResultsController performFetch:&error];
    
    if (error) {
        NSLog(@"Unable to perform fetch.");
        NSLog(@"%@, %@", error, error.localizedDescription);
    }
    
    return [context executeFetchRequest:request error:nil];
}

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
    [self.tableView beginUpdates];
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    [self.tableView endUpdates];
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath {
    switch (type) {
        case NSFetchedResultsChangeInsert: {
            [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
        }
        case NSFetchedResultsChangeDelete: {
            [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
        }
        case NSFetchedResultsChangeUpdate: {
            [self configureCell:(UITableViewCell *)[self.tableView cellForRowAtIndexPath:indexPath] atIndexPath:indexPath];
            break;
        }
        case NSFetchedResultsChangeMove: {
            [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
            [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
        }
    }
}

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath {
    
    CDProduct *product;
    if (indexPath.section == 0) {
        NSArray *notSoldItems = [self getNotSoldProducts:[self.fetchedResultsController fetchedObjects]];
        product = notSoldItems[indexPath.row];
    } else {
        NSArray *soldItems = [self getSoldProducts:[self.fetchedResultsController fetchedObjects]];
        product = soldItems[indexPath.row];
    }
    
    //    product = [self.fetchedResultsController objectAtIndexPath:indexPath];
    
    //    NSLog(@"%@", [product complete]);
    cell.textLabel.text = product.name;
    if ([product.complete boolValue]) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    
}

-(NSArray *) getNotSoldProducts: (NSArray *)items {
    NSMutableArray *result = [[NSMutableArray alloc] init];
    for (CDProduct *item in items) {
        if ((int)item.complete == 0 || item.complete == nil) {
            [result addObject:item];
        }
    }
    return result;
}

-(NSArray *) getSoldProducts: (NSArray *)items {
    NSMutableArray *result = [[NSMutableArray alloc] init];
    for (CDProduct *item in items) {
        NSLog(@"%@", item.complete);
        if ([item.complete isEqual:[NSNumber numberWithInt:1]]) {
            [result addObject:item];
        }
    }
    return result;
}


-(NSArray *) fetchSoldProducts {
    NSManagedObjectContext *context = [CoreDataManager sharedInstance].managedObjectContext;
    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:[[CDProduct class] description]];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(basket = %@) AND (complete = 1)", self.basket.objectID];
    request.predicate = predicate;
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES];
    request.sortDescriptors = @[sortDescriptor];
    return [context executeFetchRequest:request error:nil];
}

-(NSArray *) fetchNotSoldProducts {
    NSManagedObjectContext *context = [CoreDataManager sharedInstance].managedObjectContext;
    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:[[CDProduct class] description]];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(basket = %@) AND (complete = 0 OR complete = nil)", self.basket.objectID];
    request.predicate = predicate;
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES];
    request.sortDescriptors = @[sortDescriptor];
    return [context executeFetchRequest:request error:nil];
}


#pragma mark - Table view data source

-(void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    self.selectedProduct = self.items[indexPath.row];
    
    [self.actionSheet showInView:self.view];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [[self.fetchedResultsController sections] count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSArray *sections = [self.fetchedResultsController sections];
    id<NSFetchedResultsSectionInfo> sectionInfo = [sections objectAtIndex:section];
    
    return [sectionInfo numberOfObjects];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == 0) {
        return @"AVAILABLE";
    } else {
        return @"SOLD";
    }
    //    if ([[self.fetchedResultsController sections] count] > 0) {
    //        id <NSFetchedResultsSectionInfo> sectionInfo = [[self.fetchedResultsController sections] objectAtIndex:section];
    //        return [sectionInfo name];
    //    } else
    //        return nil;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"CellIdentifier" forIndexPath:indexPath];
    
    [self configureCell:cell atIndexPath:indexPath];
    
    return cell;
}


/*
 // Override to support conditional editing of the table view.
 - (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
 // Return NO if you do not want the specified item to be editable.
 return YES;
 }
 */

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        CDProduct *product = self.items[indexPath.row];
        [[CoreDataManager sharedInstance].managedObjectContext deleteObject:product];
        NSMutableArray *items = [self.items mutableCopy];
        [items removeObject:product];
        self.items = [items copy];
        
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }
}

-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex{
    if (buttonIndex == 1) {
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle: nil];
        ProductDetailViewController *productViewController = [storyboard instantiateViewControllerWithIdentifier:@"ProductDetailsPage"];
        productViewController.product = self.selectedProduct;
        [self.navigationController pushViewController:productViewController animated:YES];
    } else if (buttonIndex == 2) {
        
        UIAlertController *controller = [UIAlertController alertControllerWithTitle:@"Buy product" message:@"Enter price" preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *action = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            
        }];
        [controller addAction:action];
        [controller addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
            textField.placeholder = @"Product price";
        }];
        action = [UIAlertAction actionWithTitle:@"Create" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            UITextField *textFieldPrice = controller.textFields[0];
            [self markProductAsSoldWithPrice:[NSDecimalNumber decimalNumberWithString:textFieldPrice.text]];
        }];
        
        [controller addAction:action];
        [self presentViewController:controller animated:YES completion:NULL];
    }
    //    NSLog(@"Index = %ld - Title = %@", (long)buttonIndex, [actionSheet buttonTitleAtIndex:buttonIndex]);
}

-(void) markProductAsSoldWithPrice:(NSDecimalNumber *)price {
    self.selectedProduct.price = price;
    self.selectedProduct.complete = @YES;
    
    NSError *saveError = nil;
    if (![self.selectedProduct.managedObjectContext save:&saveError]) {
        NSLog(@"Unable to save managed object context.");
        NSLog(@"%@, %@", saveError, saveError.localizedDescription);
    }
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:[self.items indexOfObject:self.selectedProduct] inSection:0];
    //    [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    [self refreshData];
}

/*
 // Override to support rearranging the table view.
 - (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
 }
 */

/*
 // Override to support conditional rearranging of the table view.
 - (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
 // Return NO if you do not want the item to be re-orderable.
 return YES;
 }
 */

/*
 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */

@end
