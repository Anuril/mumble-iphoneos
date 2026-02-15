// Copyright 2009-2010 The 'Mumble for iOS' Developers. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

#import "MUWelcomeScreenPhone.h"

#import "MUPublicServerListController.h"
#import "MUFavouriteServerListController.h"
#import "MULanServerListController.h"
#import "MUPreferencesViewController.h"
#import "MUServerRootViewController.h"
#import "MUNotificationController.h"
#import "MUConnectionController.h"
#import "MULegalViewController.h"
#import "MUImage.h"
#import "MUBackgroundView.h"
#import "MUDatabase.h"

@interface MUWelcomeScreenPhone () {
    NSInteger    _aboutWebsiteButton;
    NSInteger    _aboutContribButton;
    NSInteger    _aboutLegalButton;
}
@end

#define MUMBLE_LAUNCH_IMAGE_CREATION 0

@implementation MUWelcomeScreenPhone

- (id) init {
    if (@available(iOS 13.0, *)) {
        self = [super initWithStyle:UITableViewStyleInsetGrouped];
    } else {
        self = [super initWithStyle:UITableViewStyleGrouped];
    }
    if (self) {
        // ...
    }
    return self;
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    self.navigationItem.title = @"Mumble";
    self.navigationController.toolbarHidden = YES;
    
    if (@available(iOS 11.0, *)) {
        self.navigationController.navigationBar.prefersLargeTitles = YES;
        self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeAlways;
    }

    self.tableView.backgroundView = [MUBackgroundView backgroundView];
    self.tableView.scrollEnabled = NO;
    
#if MUMBLE_LAUNCH_IMAGE_CREATION != 1
    UIBarButtonItem *about = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"About", nil)
                                                              style:UIBarButtonItemStylePlain
                                                             target:self
                                                             action:@selector(aboutClicked:)];
    [self.navigationItem setRightBarButtonItem:about];
    
    UIBarButtonItem *prefs = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Preferences", nil)
                                                              style:UIBarButtonItemStylePlain
                                                             target:self
                                                             action:@selector(prefsClicked:)];
    [self.navigationItem setLeftBarButtonItem:prefs];
#endif
}

#pragma mark -
#pragma mark TableView

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

// Customize the number of rows in the table view.
- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
#if MUMBLE_LAUNCH_IMAGE_CREATION == 1
    return 1;
#endif
    if (section == 0)
        return 4;
    return 0;
}

- (UIView *) tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UIImage *img = [MUImage imageNamed:@"WelcomeScreenIcon"];
    UIImageView *imgView = [[UIImageView alloc] initWithImage:img];
    [imgView setContentMode:UIViewContentModeCenter];
    [imgView setFrame:CGRectMake(0, 0, img.size.width, img.size.height)];
    return imgView;
}

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
#if MUMBLE_LAUNCH_IMAGE_CREATION == 1
    CGFloat statusBarAndTitleBarHeight = 64;
    return [UIScreen mainScreen].bounds.size.height - statusBarAndTitleBarHeight;
#endif
    UIImage *img = [MUImage imageNamed:@"WelcomeScreenIcon"];
    return img.size.height;
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 44.0;
}

// Customize the appearance of table view cells.
- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"welcomeItem"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"welcomeItem"];
    }
    
    cell.selectionStyle = UITableViewCellSelectionStyleGray;
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    /* Servers section. */
    if (indexPath.section == 0) {
        if (indexPath.row == 0) {
            cell.textLabel.text = NSLocalizedString(@"Join a Server", nil);
            if (@available(iOS 13.0, *)) {
                cell.imageView.image = [UIImage systemImageNamed:@"plus.circle.fill"];
                cell.imageView.tintColor = [UIColor systemBlueColor];
            }
            cell.accessoryType = UITableViewCellAccessoryNone;
        } else if (indexPath.row == 1) {
            cell.textLabel.text = NSLocalizedString(@"Public Servers", nil);
            if (@available(iOS 13.0, *)) {
                cell.imageView.image = [UIImage systemImageNamed:@"globe"];
                cell.imageView.tintColor = [UIColor systemIndigoColor];
            }
        } else if (indexPath.row == 2) {
            cell.textLabel.text = NSLocalizedString(@"Favourite Servers", nil);
            if (@available(iOS 13.0, *)) {
                cell.imageView.image = [UIImage systemImageNamed:@"star.fill"];
                cell.imageView.tintColor = [UIColor systemYellowColor];
            }
        } else if (indexPath.row == 3) {
            cell.textLabel.text = NSLocalizedString(@"LAN Servers", nil);
            if (@available(iOS 13.0, *)) {
                cell.imageView.image = [UIImage systemImageNamed:@"wifi"];
                cell.imageView.tintColor = [UIColor systemGreenColor];
            }
        }
    }

    [[cell textLabel] setHidden: NO];

    return cell;
}

// Override to support row selection in the table view.
- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    /* Servers section. */
    if (indexPath.section == 0) {
        if (indexPath.row == 0) {
            [self showJoinServerDialog];
            [tableView deselectRowAtIndexPath:indexPath animated:YES];
        } else if (indexPath.row == 1) {
            MUPublicServerListController *serverList = [[MUPublicServerListController alloc] init];
            [self.navigationController pushViewController:serverList animated:YES];
        } else if (indexPath.row == 2) {
            MUFavouriteServerListController *favList = [[MUFavouriteServerListController alloc] init];
            [self.navigationController pushViewController:favList animated:YES];
        } else if (indexPath.row == 3) {
            MULanServerListController *lanList = [[MULanServerListController alloc] init];
            [self.navigationController pushViewController:lanList animated:YES];
        }
    }
}

- (void) showJoinServerDialog {
    NSString *title = NSLocalizedString(@"Join a Server", nil);
    NSString *msg = NSLocalizedString(@"Enter a server address or paste a mumble:// link", nil);
    
    UIAlertController *alertCtrl = [UIAlertController alertControllerWithTitle:title
                                                                       message:msg
                                                                preferredStyle:UIAlertControllerStyleAlert];
    
    [alertCtrl addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = NSLocalizedString(@"mumble.example.com or mumble://...", nil);
        textField.keyboardType = UIKeyboardTypeURL;
        textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
        textField.autocorrectionType = UITextAutocorrectionTypeNo;
    }];
    
    [alertCtrl addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = [[NSUserDefaults standardUserDefaults] objectForKey:@"DefaultUserName"];
        textField.text = [[NSUserDefaults standardUserDefaults] objectForKey:@"DefaultUserName"];
    }];
    
    [alertCtrl addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil)
                                                  style:UIAlertActionStyleCancel
                                                handler:nil]];
    
    [alertCtrl addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Connect", nil)
                                                  style:UIAlertActionStyleDefault
                                                handler:^(UIAlertAction * _Nonnull action) {
        NSString *addressText = [[[alertCtrl textFields] objectAtIndex:0] text];
        NSString *username = [[[alertCtrl textFields] objectAtIndex:1] text];
        
        if (!addressText || [addressText length] == 0) return;
        if (!username || [username length] == 0) {
            username = [[NSUserDefaults standardUserDefaults] objectForKey:@"DefaultUserName"];
        }
        
        [self connectWithAddress:addressText username:username];
    }]];
    
    [self presentViewController:alertCtrl animated:YES completion:nil];
}

- (void) connectWithAddress:(NSString *)addressText username:(NSString *)username {
    NSString *hostname = nil;
    NSInteger port = 64738;
    NSString *password = nil;
    
    // Try parsing as mumble:// URL
    if ([addressText hasPrefix:@"mumble://"]) {
        NSURL *url = [NSURL URLWithString:addressText];
        if (url) {
            hostname = [url host];
            if ([url port]) port = [[url port] integerValue];
            if ([url user]) username = [url user];
            if ([url password]) password = [url password];
        }
    }
    
    // Parse as host:port
    if (!hostname) {
        NSArray *parts = [addressText componentsSeparatedByString:@":"];
        hostname = [parts firstObject];
        if ([parts count] > 1) {
            port = [[parts objectAtIndex:1] integerValue];
            if (port == 0) port = 64738;
        }
    }
    
    if (hostname && [hostname length] > 0) {
        MUConnectionController *connCtrlr = [MUConnectionController sharedController];
        [connCtrlr connetToHostname:hostname port:port withUsername:username andPassword:password withParentViewController:self];
    }
}

- (void) aboutClicked:(id)sender {
#ifdef MUMBLE_BETA_DIST
    NSString *aboutTitle = [NSString stringWithFormat:@"Mumble %@ (%@)",
                            [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"],
                            [[NSBundle mainBundle] objectForInfoDictionaryKey:@"MumbleGitRevision"]];
#else
    NSString *aboutTitle = [NSString stringWithFormat:@"Mumble %@",
                            [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"]];
#endif
    NSString *aboutMessage = NSLocalizedString(@"Low latency, high quality voice chat", nil);
    
    UIAlertController* aboutAlert = [UIAlertController alertControllerWithTitle:aboutTitle message:aboutMessage preferredStyle:UIAlertControllerStyleAlert];
    
    [aboutAlert addAction: [UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil)
                                                    style:UIAlertActionStyleCancel
                                                  handler:nil]];
    [aboutAlert addAction: [UIAlertAction actionWithTitle:NSLocalizedString(@"Website", nil)
                                                    style:UIAlertActionStyleDefault
                                                  handler:^(UIAlertAction * _Nonnull action) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://www.mumble.info/"] options:@{} completionHandler:nil];
    }]];
    [aboutAlert addAction: [UIAlertAction actionWithTitle:NSLocalizedString(@"Legal", nil)
                                                    style:UIAlertActionStyleDefault
                                                  handler:^(UIAlertAction * _Nonnull action) {
        MULegalViewController *legalView = [[MULegalViewController alloc] init];
        UINavigationController *navController = [[UINavigationController alloc] init];
        [navController pushViewController:legalView animated:NO];
        [[self navigationController] presentViewController:navController animated:YES completion:nil];
    }]];
    [aboutAlert addAction: [UIAlertAction actionWithTitle:NSLocalizedString(@"Support", nil)
                                                    style:UIAlertActionStyleDefault
                                                  handler:^(UIAlertAction * _Nonnull action) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://github.com/mumble-voip/mumble-iphoneos/issues"] options:@{} completionHandler:nil];
    }]];
    
    [self presentViewController:aboutAlert animated:YES completion:nil];
}

- (void) prefsClicked:(id)sender {
    MUPreferencesViewController *prefs = [[MUPreferencesViewController alloc] init];
    [self.navigationController pushViewController:prefs animated:YES];
}

@end
