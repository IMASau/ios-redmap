//
//  IOAddNewSpeciesTableViewController.m
//  Redmap
//
//  Created by Evo Stamatov on 13/08/13.
//  Copyright (c) 2013 Ionata. All rights reserved.
//

#import "IOAddNewSpeciesTableViewController.h"
#import "IOCategory.h"
#import "Species.h"
#import "IOSpotKeys.h"


@interface IOAddNewSpeciesTableViewController () <UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UITextField *latinNameTextField;
@property (weak, nonatomic) IBOutlet UITextField *commonNameTextField;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *saveButton;

@end


@implementation IOAddNewSpeciesTableViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.latinNameTextField.delegate = self;
    self.commonNameTextField.delegate = self;
    
    if (self.latinName)
        self.latinNameTextField.text = self.latinName;
    
    if (self.commonName)
        self.commonNameTextField.text = self.commonName;

    self.saveButton.enabled = (self.commonNameTextField.text.length > 0 && self.latinNameTextField.text.length > 0);
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textDidChange:) name:UITextFieldTextDidChangeNotification object:self.commonNameTextField];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textDidChange:) name:UITextFieldTextDidChangeNotification object:self.latinNameTextField];
}



- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}



- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}



- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self.commonNameTextField becomeFirstResponder];
}



#pragma mark - Segues
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([sender isEqual:self.saveButton])
    {
        if (self.delegate)
            [self.delegate addNewSpeciesViewController:self commonName:self.commonNameTextField.text latinName:self.latinNameTextField.text];
    }
}



- (UIReturnKeyType)currentReturnKeyType
{
    if (self.commonNameTextField.text.length > 0 && self.latinNameTextField.text.length > 0)
        return UIReturnKeyDone;
    else
        return UIReturnKeyNext;
}



#pragma mark - UITextFieldDelegate Protocol

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    textField.returnKeyType = [self currentReturnKeyType];
}



- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (self.commonNameTextField.text.length > 0 && self.latinNameTextField.text.length > 0) {
        [self save:self];
        return YES;
    }
    
    // Go to the empty field
    UITextField *emptyTextField = (textField == self.commonNameTextField ? self.latinNameTextField : self.commonNameTextField);
    [emptyTextField becomeFirstResponder];
    return YES;
}



#pragma mark - Selectors

- (void)textDidChange:(NSNotification *)notification
{
    self.saveButton.enabled = (self.commonNameTextField.text.length > 0 || self.latinNameTextField.text.length > 0);
    
    UITextField *textField = [notification object];
    
    // Update the return key
    UIReturnKeyType returnKeyType = [self currentReturnKeyType];
    if (textField.returnKeyType != returnKeyType)
    {
        textField.returnKeyType = returnKeyType;
        [textField reloadInputViews];
    }
}



#pragma mark - Custom methods

- (void)save:(id)sender
{
    [self performSegueWithIdentifier:@"saveNewSpeciesSegue" sender:self.saveButton];
}



- (void)cancel:(id)sender
{
    [self.delegate addNewSpeciesViewControllerDidCancel:self];
}

@end
