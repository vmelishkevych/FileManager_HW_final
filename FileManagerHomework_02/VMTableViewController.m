//
//  VMTableViewController.m
//  FileManagerHomework_02
//
//  Created by Torris on 4/22/17.
//  Copyright © 2017 Vasiliy Melishkevych. All rights reserved.
//

#import "VMTableViewController.h"
#import "VMFileCell.h"
#import "VMGroup.h"

@interface UIView (UITableViewCell)

- (UITableViewCell*) superCell;

@end

@implementation UIView (UITableViewCell)

- (UITableViewCell*) superCell {
    
    if (!self.superview) {
        
        return nil;
    }
    
    if ([self.superview isKindOfClass:[UITableViewCell class]]) {
        
        return (UITableViewCell*)self.superview;
        
    }
    
    return [self.superview superCell];
    
}

@end




@interface VMTableViewController () <UITextFieldDelegate>

@property (strong,nonatomic) NSMutableArray* groups;

@property (strong,nonatomic) NSString* nameFolder;


@end

@implementation VMTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    if (!self.path) {
    
        NSURL* urlApplicationDirectory =  [[[NSFileManager defaultManager]
                                            URLsForDirectory:NSLibraryDirectory
                                            inDomains:NSUserDomainMask] lastObject];
        
        self.path = [urlApplicationDirectory path];
        
       // self.path = [[[NSFileManager defaultManager] temporaryDirectory] path];

    }
    
    
    [self.tableView setEditing:NO animated:NO];
    
    UIBarButtonItem* editButton = [[UIBarButtonItem alloc]
                                   initWithBarButtonSystemItem:UIBarButtonSystemItemEdit
                                   target:self
                                   action:@selector(actionEditStyleButton:)];
    
    [self.navigationItem setRightBarButtonItem:editButton animated:NO];
    
   
    
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Help Methods

- (UIColor*) chooseCellTextColorAtIndexPath:(NSIndexPath*) indexPath {
    
    VMGroup* group = [self.groups objectAtIndex:indexPath.section];
    NSString* fileName = [group.items objectAtIndex:indexPath.row];
    
    NSString* firstLetter = [fileName substringToIndex:1];
    
    UIColor* textColor =
        ([firstLetter isEqualToString:@"."]) ?
        [UIColor colorWithRed:0.f green:0.f blue:1.f alpha:0.4f] : [UIColor blackColor];
    
    
    return textColor;
    
}


- (NSString*) fileSizeFromValue:(unsigned long long) value {
    
    static NSString* unit[] = {@"B", @"KB", @"MB", @"GB", @"TB"};
    static int unitsCount = 5;
    
    int index = 0;
    
    double size = (double)value;
    
    while (size > 1024 && index < unitsCount) {
        
        size /= 1024;
        
        index++;
    }
    
    return  [NSString stringWithFormat:@"%.2f %@", size, unit[index]];
    
}


- (NSMutableArray*) takeComponentsAtPath:(NSString*) path {
    
    NSError* error = nil;
    
    NSArray* components = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:&error];
    
    if (error) {
        
        NSLog(@"%@", [error localizedDescription]);
        
        return nil;
        
    } else {
    
    VMGroup* folders = [[VMGroup alloc] init];
    folders.name = @"Folders";
    
    folders.items = [self chooseItemsFromArray:components itemIsFolder:YES];
    
    VMGroup* files = [[VMGroup alloc] init];
    files.name = @"Files";
    
    files.items = [self chooseItemsFromArray:components itemIsFolder:NO];
    
    NSMutableArray* sortComponents = [NSMutableArray arrayWithObjects:folders, files, nil];
    
    return sortComponents;
        
    }
}


- (NSArray*) chooseItemsFromArray:(NSArray*) components itemIsFolder:(BOOL) typeItemIsFolder {
    
    NSMutableArray* itemsArray = [NSMutableArray array];
    
    for (NSString* fileName in components) {
        
        NSString* filePath =[self.path stringByAppendingPathComponent:fileName];
        
        BOOL isDirectory = NO;
        
        [[NSFileManager defaultManager] fileExistsAtPath:filePath isDirectory:&isDirectory];
        
        if (!(isDirectory ^ typeItemIsFolder)) {
            
            [itemsArray addObject:fileName];
            
        }
        
    }
    
    [itemsArray sortUsingComparator:^NSComparisonResult(NSString* obj1, NSString* obj2) {
        
        return [obj1 compare:obj2 options:NSCaseInsensitiveSearch | NSNumericSearch];
    }];
    
    
    return itemsArray;
    
}



- (void) setPath:(NSString *)path {
    
    _path = path;
    
    NSString* lastComponent = [self.path lastPathComponent];
    
    self.groups = [self takeComponentsAtPath:self.path];
    
    self.navigationItem.title = lastComponent;
    
    [self.tableView reloadData];
    
}


- (BOOL) isDirectoryAtIndexPath:(NSIndexPath*) indexPath {
    
    VMGroup* group = [self.groups objectAtIndex:indexPath.section];
    
    NSString* fileName = [group.items objectAtIndex:indexPath.row];
    
    NSString* filePath = [self.path stringByAppendingPathComponent:fileName];
    
    BOOL isDirectory = NO;
    
    [[NSFileManager defaultManager] fileExistsAtPath:filePath isDirectory:&isDirectory];
    
    return isDirectory;
}




#pragma mark - UITableViewDataSource


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    
    return self.groups.count;
}


- (nullable NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    
    VMGroup* group = [self.groups objectAtIndex:section];
    
    return group.name;
    
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {

    VMGroup* group = [self.groups objectAtIndex:section];
    
    return group.items.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString* folderIdentifier = @"FolderCell";
    static NSString* fileIdentifier = @"FileCell";
    
    VMGroup* group = [self.groups objectAtIndex:indexPath.section];
    NSString* fileName = [group.items objectAtIndex:indexPath.row];
    NSString* filePath = [self.path stringByAppendingPathComponent:fileName];
    
    
    if ([self isDirectoryAtIndexPath:indexPath]) {
        
        UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:folderIdentifier];
        
        UIColor* cellTextColor = [self chooseCellTextColorAtIndexPath:indexPath];
        
        cell.textLabel.text = fileName;
        cell.textLabel.textColor = cellTextColor;
        
        
        cell.detailTextLabel.text = @"error";
        cell.detailTextLabel.textColor = cellTextColor;

        
        NSError* error = nil;
       
        
        NSArray* subPathsArray = [[NSFileManager defaultManager] subpathsOfDirectoryAtPath:filePath error:&error];
        
        if (error) {
            
            NSLog(@"%@", [error localizedDescription]);
            
        } else {
            
            NSOperationQueue* queue = [[NSOperationQueue alloc] init];
            
            [queue addOperationWithBlock:^{
                
                unsigned long long sizeFolder = 0;
                
                for (NSString* subPath in subPathsArray) {
                    
                    NSString* fullPath = [filePath stringByAppendingPathComponent:subPath];
                    
                    NSDictionary* attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:fullPath error:nil];
                    
                    sizeFolder += [attributes fileSize];
                    
                }
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    cell.detailTextLabel.text = [self fileSizeFromValue:sizeFolder];
                });
              

            }];
            
            
            }
    
        
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.editingAccessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
        return cell;
        
    } else {
        
        VMFileCell* cell = [tableView dequeueReusableCellWithIdentifier:fileIdentifier];

        UIColor* cellTextColor = [self chooseCellTextColorAtIndexPath:indexPath];
        
        NSDictionary* attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:nil];
        
        cell.nameLabel.text = fileName;
        cell.nameLabel.textColor = cellTextColor;
        

        cell.sizeLabel.text = [self fileSizeFromValue:[attributes fileSize]];
        cell.sizeLabel.textColor = cellTextColor;
        
        static NSDateFormatter* dateFormatter = nil;
        
        if (!dateFormatter) {
            
            dateFormatter = [[NSDateFormatter alloc] init];
            [dateFormatter setDateFormat:@"MM/dd/yyyy hh/mm a"];
            
        }
        
        cell.dateLabel.text = [dateFormatter stringFromDate:[attributes fileModificationDate]];
        cell.dateLabel.textColor = cellTextColor;
        
        return cell;
        
        
    }
    
    return nil;
 }

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {

    if (editingStyle == UITableViewCellEditingStyleDelete) {
        
        VMGroup* group = [self.groups objectAtIndex:indexPath.section];
        
        NSString* fileName = [group.items objectAtIndex:indexPath.row];
        NSString* filePath = [self.path stringByAppendingPathComponent:fileName];
        
        NSError* error = nil;
        
        [[NSFileManager defaultManager] removeItemAtPath:filePath error:&error];
        
        
        if (error) {
            
            NSLog(@"%@", [error localizedDescription]);
            
            self.groups = [self takeComponentsAtPath:self.path];
            
            [self.tableView reloadData];

        } else {
            
            
            self.groups = [self takeComponentsAtPath:self.path];
            
            if (self.groups) {
                
                [self.tableView beginUpdates];
                
                [self.tableView deleteRowsAtIndexPaths:@[indexPath]
                                      withRowAnimation:UITableViewRowAnimationRight];
                [self.tableView endUpdates];

            } else {
                
                [self.tableView reloadData];
            }
        }
    }
    
}
    

        
#pragma mark - UITableViewDelegate

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    return UITableViewCellEditingStyleDelete;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if ([self isDirectoryAtIndexPath:indexPath]) {
        
        VMGroup* group = [self.groups objectAtIndex:indexPath.section];
        
        NSString* fileName = [group.items objectAtIndex:indexPath.row];
        NSString* filePath = [self.path stringByAppendingPathComponent:fileName];
        
        VMTableViewController* vc = [self.storyboard instantiateViewControllerWithIdentifier:@"VMTableViewController"];
        vc.path = filePath;
        [self.navigationController pushViewController:vc animated:YES];
        
        
    }
}



- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    
    if ([self isDirectoryAtIndexPath:indexPath]) {
        
        return 44.f;
    } else {
        
        return 80.f;
    }
    
}


#pragma mark - Actions


- (void) actionEditStyleButton:(UIBarButtonItem *)sender {
    
    BOOL isEditing =  self.tableView.editing;
    
    [self.tableView setEditing:!isEditing animated:YES];
    
    UIBarButtonSystemItem item = UIBarButtonSystemItemEdit;
    
    if (self.tableView.editing) {
       
        item = UIBarButtonSystemItemDone;
    
    }
        
        UIBarButtonItem* button = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:item target:self action:@selector(actionEditStyleButton:)];
        
        [self.navigationItem setRightBarButtonItem:button animated:YES];
        
}


- (IBAction)actionAddFolderButton:(UIBarButtonItem *)sender {

    
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Add folder"
                                                                   message:@"Insert name of folder:"
                                                            preferredStyle:UIAlertControllerStyleAlert];

    UIAlertAction* actionCancel = [UIAlertAction actionWithTitle:@"Cancel"
                                                           style:(UIAlertActionStyleCancel)
                                                         handler:^(UIAlertAction * _Nonnull action) {
                                                             
                                                             NSLog(@"Cancel");
                                                         }];
    
    
    [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        
        textField.returnKeyType = UIReturnKeyDone;
        textField.enablesReturnKeyAutomatically = YES;
        
        textField.placeholder = @"Insert name of folder:";
        
        textField.delegate = self;
        
        textField.clearButtonMode = UITextFieldViewModeWhileEditing;
    }];
    

    [alert addAction:actionCancel];
    
    [self presentViewController:alert animated:YES completion:nil];

    
}


#pragma mark - UITextFieldDelegate


- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    

    NSMutableCharacterSet* unionSet = [NSMutableCharacterSet alphanumericCharacterSet];
 

 
    NSCharacterSet* validationSet = [unionSet invertedSet];
 
    NSArray* components = [string componentsSeparatedByCharactersInSet:validationSet];

 
    if (components.count > 1) {
 
        return NO;
 
    }
 
 
    NSString* newString = [textField.text stringByReplacingCharactersInRange:range withString:string];
 
 
    if (newString.length > 15) {
 
        return NO;
    }
 
 
 return YES;
 
}


- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    
    
        self.nameFolder = textField.text;

        NSString* filePath = [self.path stringByAppendingPathComponent:self.nameFolder];
        
        NSError* error = nil;
        
        [[NSFileManager defaultManager] createDirectoryAtPath:filePath withIntermediateDirectories:NO attributes:nil error:&error];
        
        
        if (error) {
            
            NSLog(@"%@", [error localizedDescription]);
            
            self.groups = [self takeComponentsAtPath:self.path];
            
            [self.tableView reloadData];
            
        } else {
            
            
            self.groups = [self takeComponentsAtPath:self.path];
            
            if (self.groups) {
                
                NSString* fileNameFromPath = [filePath lastPathComponent];
                
                VMGroup* foldersGroup = [self.groups objectAtIndex:0];
                
                NSInteger index = NSNotFound;
                
                for (NSString* nameFolder in foldersGroup.items) {
                    
                    if ([nameFolder isEqualToString:fileNameFromPath]) {
                        
                        index = [foldersGroup.items indexOfObject:nameFolder];
                        
                        break;
                    }
                    
                }
                
                if (index == NSNotFound) {
                    
                    NSLog(@"Error adding folder!!!");
                    
                } else {
                    
                    NSIndexPath* indexPath = [NSIndexPath indexPathForRow:index inSection:0];
                    
                    [self.tableView beginUpdates];
                    
                    [self.tableView insertRowsAtIndexPaths:@[indexPath]
                                          withRowAnimation:UITableViewRowAnimationLeft];
                    [self.tableView endUpdates];
                    
                    [[UIApplication sharedApplication] beginIgnoringInteractionEvents];
                    
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        if ([[UIApplication sharedApplication] isIgnoringInteractionEvents]) {
                            [[UIApplication sharedApplication] endIgnoringInteractionEvents];
                        }
                    });
                    
                }
                
            }
            
        }
        
        return YES;
    
}


@end
