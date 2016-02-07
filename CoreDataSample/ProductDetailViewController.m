//
//  ProductDetailViewController.m
//  CoreDataSample
//
//  Created by Sergey Rybalko on 2/6/16.
//  Copyright © 2016 GeekHub. All rights reserved.
//

#import "ProductDetailViewController.h"
#import "CDProduct.h"

@interface ProductDetailViewController() <UIAlertViewDelegate>

@property (weak, nonatomic) IBOutlet UITextField *productName;
@property (weak, nonatomic) IBOutlet UITextField *productCount;
@property (weak, nonatomic) IBOutlet UITextField *productPrice;

@end

@implementation ProductDetailViewController

- (void)viewDidLoad {
    UIBarButtonItem *anotherButton = [[UIBarButtonItem alloc] initWithTitle:@"Save" style:UIBarButtonItemStylePlain target:self action:@selector(saveProduct)];
    self.navigationItem.rightBarButtonItem = anotherButton;
}

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    
    self.productName.text = self.product.name;
    self.productCount.text = [self.product.actualPrice stringValue];
    self.productPrice.text = [self.product.price stringValue];
}

- (void)saveProduct {
    self.product.name = self.productName.text;
    self.product.actualPrice = [NSDecimalNumber decimalNumberWithString:self.productCount.text];
    self.product.price = [NSDecimalNumber decimalNumberWithString:self.productPrice.text];
    
    NSError *saveError = nil;
    if ([self.product.managedObjectContext save:&saveError]) {
        UIAlertView * alert =[[UIAlertView alloc ] initWithTitle:@"Message"
                                                         message:@"Product was saved successfuly"
                                                        delegate:self
                                               cancelButtonTitle:@"Ok"
                                               otherButtonTitles: nil];
        [alert show];
        [self dismissViewControllerAnimated:YES completion:nil];
    } else {
        NSLog(@"Unable to save managed object context.");
        NSLog(@"%@, %@", saveError, saveError.localizedDescription);
    }
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 0) {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

@end
