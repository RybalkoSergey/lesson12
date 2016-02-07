//
//  ProductDetailViewController.h
//  CoreDataSample
//
//  Created by Sergey Rybalko on 2/6/16.
//  Copyright © 2016 GeekHub. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CDProduct.h"

@interface ProductDetailViewController : UIViewController

@property (nonatomic, strong) CDProduct *product;

@end
