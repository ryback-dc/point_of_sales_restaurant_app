//
//  QuickServeController.m
//  Point IPad
//
//  Created by Developer on 4/22/13.
//  Copyright (c) 2013 Developer. All rights reserved.
//

#import "QuickServeController.h"
#import "QuickServeCell.h"
#import "ItemProperties.h"
#import "ItemColorProperties.h"
#import "QuickCollection.h"
#import "QuickCollectionFlow.h"
#import "QuickModifierController.h"
#import "QuickServeTableCell.h"
#import "QuickTable.h"
#import <QuartzCore/QuartzCore.h>

@interface QuickServeController () <UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UIActionSheetDelegate, UITableViewDataSource, UITableViewDelegate>

@property (retain, nonatomic) IBOutlet UITapGestureRecognizer *oneFingerOneTap;

@property (retain, nonatomic) IBOutlet QuickCollection *quickCollectionView;
@property (retain, nonatomic) IBOutlet UIView *quickTopView;
@property (strong, nonatomic) QuickCollectionFlow *flowLayout;
@property (retain, nonatomic) IBOutlet UIToolbar *quickToolbar;
@property (strong, nonatomic) UIPopoverController* popover;
@property (retain, nonatomic) IBOutlet UIBarButtonItem *modButton;
@property (retain, nonatomic) IBOutlet QuickTable *quickTableView;

@end

@implementation QuickServeController
@synthesize currentMenuItems;
@synthesize selectedItemIndex;
@synthesize isActualItems;
@synthesize isSubclass;
@synthesize flowLayout;
@synthesize quickCollectionView;
@synthesize oneFingerOneTap;
@synthesize stackOfMenus;
@synthesize stackOfIsActualItemBools;
@synthesize stackOfIsSubclassBools;
@synthesize order;
@synthesize nameOfSelected;
@synthesize classNameForDatabase;
@synthesize subclassNameForDatabase;
@synthesize selectedItemId;
@synthesize quickToolbar;
@synthesize modButton;
@synthesize popover;
@synthesize quickTableView;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // set source and delegates
        quickCollectionView.delegate = self;
        quickCollectionView.dataSource = self;
        quickTableView.delegate = self;
        quickTableView.dataSource = self;
    }
    return self;
}

- (void)viewDidLoad
{
    // Set up the order.
    self.order = [[Orders alloc] init];
    
    [self applyColorToBackgrounds];
    
    // The current menu items are always Class Names first.
    self.currentMenuItems = [[self database] classNames];
    
    // Initialize
    
    // Holds previous menu arrays to jump backwards
    self.stackOfMenus = [[NSMutableArray alloc] init];
    self.stackOfIsSubclassBools = [[NSMutableArray alloc] init];
    self.stackOfIsActualItemBools = [[NSMutableArray alloc] init];
    self.selectedItemId = [[NSNumber alloc] init];
    
    // set a response to one tap
    [oneFingerOneTap setNumberOfTapsRequired:1];
    [oneFingerOneTap setNumberOfTouchesRequired:1];
    //[quickCollectionView addGestureRecognizer:oneFingerOneTap];
    [self setIsSubclass:FALSE];
    [self setIsActualItems:FALSE];
    
    // test on itemproperties
    NSString *itemTestid = [[NSString alloc] initWithFormat:@"%d", 74];
    ItemProperties *itemProperties = [[ItemProperties alloc] initWithItemId:itemTestid];
    
    [super viewDidLoad];
    
}

- (void)applyColorToBackgrounds
{
    // Set up the background.
    self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"background2.png"]];
    
    self.quickTopView.backgroundColor = [UIColor clearColor];
    self.quickTopView.layer.borderColor = [UIColor orangeColor].CGColor;
    self.quickTopView.layer.borderWidth = 2.0f;
    
    
    self.quickTableView.backgroundColor = [UIColor clearColor];
    self.quickTableView.layer.borderColor = [UIColor orangeColor].CGColor;
    self.quickTableView.layer.borderWidth = 2.0f;
    
}

- (IBAction)flipBackMenuItems:(UIBarButtonItem *)sender
{
    if ([stackOfMenus count] == 0) {
        return;
    }
    // have a stack of arrays to go backwards
    currentMenuItems = [[NSMutableArray alloc] initWithArray:[stackOfMenus lastObject]];
    [stackOfMenus removeLastObject];
    
    self.isSubclass = [[stackOfIsSubclassBools lastObject] boolValue];
    [stackOfIsSubclassBools removeLastObject];
    
    self.isActualItems = [[stackOfIsActualItemBools lastObject] boolValue];
    [stackOfIsActualItemBools removeLastObject];
    
    [[self quickCollectionView] reloadData];
    [[self quickTableView] reloadData];
}


- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    
    //ignore any touches from a UIToolbar
    
    if ([touch.view.superview isKindOfClass:[UIToolbar class]]) {
        return NO;
    }
    
    return YES;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)handleOneTap:(UITapGestureRecognizer *)sender
{
    CGPoint point = [sender locationInView:[self quickCollectionView]];
    NSIndexPath *indexPath = [self.quickCollectionView indexPathForItemAtPoint:point];
    self.nameOfSelected = [[self currentMenuItems] objectAtIndex:indexPath.row];
    NSLog(@"%d", indexPath.row);
    NSLog(@"%@", nameOfSelected);
    
    
    /*
     When the QuickServe is first selected, the collection view only displays Class Names.
     if (subclass == false) AND (actualItems == false) do
     After clicking a Class, check to see if that class has a Subclass.
     To check if a Class has a Subclass, query the database and if the array returned is a 1, it means it doesn't have a subclass.
     If the selected Class doesn't have a subclass, go ahead and display the items.
     If it does have a Subclass, set the subclass variable to True and display Subclasses.
     else
     The else statement takes care of when Subclass is true, but actualItems aren't. It displays the Items
     by querying the database using the Subclass name as a parameter instead of a Classname. At this point, set the actualItems to true.
     Then refresh the view for the changes to take effect.
     */
    
    
    if (![self isSubclass] && ![self isActualItems]) {
        if ([[[self database] subclassWhereClassIs:self.nameOfSelected] count] == 1) {
            [self savePreviousState];
            [self setIsActualItems:TRUE];
            [self setIsSubclass:TRUE];
            [self setCurrentMenuItems:[[self database] itemsWhereClassIs:self.nameOfSelected]];
            self.classNameForDatabase = self.nameOfSelected;
        } else {
            [self savePreviousState];
            [self setIsSubclass:TRUE];
            [self setCurrentMenuItems:[[self database] subclassWhereClassIs:self.nameOfSelected]];
        }
    } else if ([self isSubclass] && ![self isActualItems]) {
        [self savePreviousState];
        [self setCurrentMenuItems:[[self database] itemsWhereSubclassIs:self.nameOfSelected]];
        [self setIsActualItems:TRUE];
        self.subclassNameForDatabase = self.nameOfSelected;
    } else {
        // actual items
            // show modifiers, let them pick
            // ask if they want to see toppings
            // show toppings if they want, else proceed
            
            // don't show modifiers, but ask them if they want to see toppings
        self.selectedItemId = [[self database] itemIdWhereClassIs:self.classNameForDatabase andSubclassIs:self.subclassNameForDatabase andItemIs:self.nameOfSelected];
        //NSLog(@"classname: %@, subclassname: %@, itemname: %@, id: %@", self.classNameForDatabase, self.subclassNameForDatabase, self.nameOfSelected, self.selectedItemId);
            
        [self extraItemOptions];
        NSLog(@"RETURNED");
    }
    
    
    // refresh the screen with new menu items
    [[self quickCollectionView] reloadData];
    [[self quickTableView] reloadData];
}

- (BOOL)collectionView:(UICollectionView *)collectionView shouldHighlightItemAtIndexPath:(NSIndexPath *)indexPath
{
    return NO;
}

- (void)extraItemOptions
{
    UIAlertView *modMessage = [[UIAlertView alloc] initWithTitle:@"Add To Order"
                                                      message:@"Would you like any modifiers?"
                                                     delegate:self
                                            cancelButtonTitle:@"Cancel Item"
                                            otherButtonTitles:@"Yes", @"No", nil];
    [modMessage setTag:1];
    [modMessage show];
    [modMessage release];
    
}


- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    
    // todo; put contents of each if into a separate function
    if (alertView.tag == 1) {
        if (buttonIndex == 1) {
            // yes, pull modifier information from database, then show toppings
            [alertView dismissWithClickedButtonIndex:0 animated:YES];
            
            
            //SEGUE TO NEXT VIEW AND HANDLE MODIFIERS THERE
            //AFTER HANDLING INPUT, RETURN TO THIS VIEW
            [self performSegueWithIdentifier:@"showModifiers" sender:self];
            
        } else if (buttonIndex == 2) {
            // no, proceed with order
            //CREATE AN ORDER WITHOUT ANY MODS, UPDATE THE VIEW WITH THE PRICE
            // WRITE A DATABASE FUNCTION TO GET THE PRICE self.selectedItemId;
            //NSLog(@"%@ : %@", self.selectedItemId, [[self database] getLunchPriceUsing:self.selectedItemId]);
            
            [order addToOrder:self.selectedItemId];
            [self.quickTableView reloadData];
            
        } else {
            return;
            // cancel the order
            // return without doing anything extra
        }
    }

}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"showModifiers"]) {
        QuickModifierController *destViewController = segue.destinationViewController;
        destViewController.selectedItemId = self.selectedItemId;
        destViewController.database = self.database;
        
    }
    
}


- (void)savePreviousState
{
    [[self stackOfMenus] addObject:currentMenuItems];
    [[self stackOfIsActualItemBools] addObject:[NSNumber numberWithBool:self.isActualItems]];
    [[self stackOfIsSubclassBools] addObject:[NSNumber numberWithBool:self.isSubclass]];
}

#pragma mark - Collection view data source

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return [[self currentMenuItems] count];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    
    /* The collection view cells get filled with names of classes like 'LUNCH'. */
    static NSString *CellIdentifier = @"quickServe";
    QuickServeCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:CellIdentifier forIndexPath:indexPath];
    int row = [indexPath row];
    NSString * menuItemName = [[self currentMenuItems] objectAtIndex:row];
    cell.itemLabel.text = menuItemName;
    [cell changeBorders:cell.frame];
    //NSLog(@"%@", cell.itemLabel.text);
    return cell;
    
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
   // NSLog(@"%d", [[self currentMenuItems] count]);
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [[order currentNames] count];
}

#define STEPPER_MAX_VALUE 20
#define STEPPER_MIN_VALUE 1

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"quickTableCell";
    QuickServeTableCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    UIStepper *stepperView = [[UIStepper alloc] initWithFrame:CGRectZero];
    cell.accessoryView = stepperView;
    stepperView.minimumValue = STEPPER_MIN_VALUE;
    stepperView.maximumValue = STEPPER_MAX_VALUE;
    stepperView.stepValue = 1;
    stepperView.wraps = YES;
    stepperView.autorepeat = YES;
    stepperView.continuous = YES;
    [stepperView addTarget:self action:@selector(stepperValueChanged:) forControlEvents:UIControlEventValueChanged];
    [stepperView release];
    
    cell.itemNameLabel.text = [[order currentNames] objectAtIndex:indexPath.row];
    NSLog(@"%@", [[order currentNames] objectAtIndex:indexPath.row]);
    
    // currentPrices returns an NSNumber, so convert it to a string while changing the label's text.
    cell.priceLabel.text = [NSString stringWithFormat:@"$%@", [[order currentPrices] objectAtIndex:indexPath.row] ];
    NSLog(@"%@", [[order currentPrices] objectAtIndex:indexPath.row]);
    
    // currentQuantities returns an NSNumber, so convert it to a string while changing the label's text.
    cell.qtyLabel.text = [NSString stringWithFormat:@"%@", [[order currentQtys] objectAtIndex:indexPath.row]];
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return @"---------Name----------------------------Price-----Quantity--------------";
}

- (IBAction)stepperValueChanged:(UIStepper *)sender
{
    // Update the model with updated quantity, then display it.
    QuickServeTableCell *parentCell = (QuickServeTableCell *)sender.superview;
    NSIndexPath *indexPath = [self.quickTableView indexPathForCell:parentCell];
    [[order currentQtys] replaceObjectAtIndex:indexPath.row withObject:[NSNumber numberWithInt:(int)sender.value]];
    parentCell.qtyLabel.text = [NSString stringWithFormat:@"%@", [[order currentQtys] objectAtIndex:indexPath.row]];
    
    // If the stepper reached the max value, it means the item should be removed from the table/order.
    if (sender.value == STEPPER_MAX_VALUE) {
        
        // TODO: WHEN REMOVING THE ITEMS, MAKE SURE TO SUBTRACT THE PRICE FROM THE TOTAL PRICE
        // AND UPDATE THE VIEW ACCORDINGLY
        [[order currentQtys] removeObjectAtIndex:indexPath.row];
        [[order currentNames] removeObjectAtIndex:indexPath.row];
        [[order currentPrices] removeObjectAtIndex:indexPath.row];
        [[self quickTableView] reloadData];
    }
}

- (void)dealloc
{
    [quickToolbar release];
    [modButton release];
    [quickTableView release];
    [super dealloc];
}

- (void)printStringsFromArray:(NSMutableArray *)array
{
    for (int i=0; i<[array count]; i++) {
        NSLog(@"%@", [array objectAtIndex:i]);
    }
}



@end
