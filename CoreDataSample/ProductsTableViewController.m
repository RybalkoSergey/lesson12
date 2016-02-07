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


@interface ProductsTableViewController () <UITableViewDelegate, UIActionSheetDelegate>

@property (strong, nonatomic) NSArray *items;
@property (strong, nonatomic) NSArray *soldItems;
@property (strong, nonatomic) NSArray *notSoldItems;
@property (nonatomic, strong) CDBasket *basket;
@property (nonatomic, strong) CDProduct *selectedProduct;
@property (strong, nonatomic) UIActionSheet *actionSheet;


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
    [self refreshData];
    
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


-(NSArray *) fetchProducts {
    NSManagedObjectContext *context = [CoreDataManager sharedInstance].managedObjectContext;
    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:[[CDProduct class] description]];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"basket = %@", self.basket.objectID];
    request.predicate = predicate;
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES];
    request.sortDescriptors = @[sortDescriptor];
    return [context executeFetchRequest:request error:nil];
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
    
    if (indexPath.section == 0) {
        self.selectedProduct = self.soldItems[indexPath.row];
    } else {
        self.selectedProduct = self.notSoldItems[indexPath.row];
    }
    
    //    if ([product.complete boolValue]) {
    //        product.complete = @NO;
    //    } else {
    //        product.complete = @YES;
    //    }
    //    [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    
    [self.actionSheet showInView:self.view];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        
        return [self.soldItems count];
        
    } else {
        
        return [self.notSoldItems count];
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == 0) {
        return @"SOLD";
    } else {
        return @"AVAILABLE";
    }
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"CellIdentifier" forIndexPath:indexPath];
    
    CDProduct *product;
    if (indexPath.section == 0) {
        product = self.soldItems[indexPath.row];
    } else {
        product = self.notSoldItems[indexPath.row];
    }
    
    
//    NSLog(@"%@", [product complete]);
    cell.textLabel.text = product.name;
    if ([product.complete boolValue]) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
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
