//
//  ViewController.m
//  MGTWeather
//
//  Created by Jayant Saxena on 21/03/16.
//  Copyright © 2016 ABC. All rights reserved.
//

#import "ViewController.h"
#import <MBProgressHUD.h>

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    [self enableLocationServices];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)enableLocationServices
{
    if(_locationManager == nil)
    {
        _locationManager = [[CLLocationManager alloc] init];
        _locationManager.delegate = self;
    }
    
    _locationManager.distanceFilter = kCLDistanceFilterNone; // whenever we move
    _locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters;

    NSUInteger code = [CLLocationManager authorizationStatus];
    if (code == kCLAuthorizationStatusNotDetermined && [_locationManager respondsToSelector:@selector(requestWhenInUseAuthorization)])
    {
        if([[NSBundle mainBundle] objectForInfoDictionaryKey:@"NSLocationWhenInUseUsageDescription"]) {
            [_locationManager  requestWhenInUseAuthorization];
        } else {
            NSLog(@"Info.plist does not contain NSLocationAlwaysUsageDescription or NSLocationWhenInUseUsageDescription");
        }
    }

    [_locationManager startUpdatingLocation];
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    if(error)
    {
        [[[UIAlertView new] initWithTitle:nil message:@"Please enable location services." delegate:nil cancelButtonTitle:nil otherButtonTitles:@"Ok", nil] show];
        NSLog(@"Location services not enabled");
    }
}

@end
