//
//  ViewController.h
//  MGTWeather
//
//  Created by Jayant Saxena on 21/03/16.
//  Copyright © 2016 ABC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CoreLocation/CoreLocation.h"

@interface ViewController : UIViewController
{
    CLLocationManager           *_locationManager;

    IBOutlet UISearchBar*       _searchBar;
    IBOutlet UITableView*       _locations;
    IBOutlet UILabel*           _hint;
}

@end

