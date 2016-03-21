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
    NSString*                   _lat;
    NSString*                   _long;

    IBOutlet UISearchBar*       _searchBar;
    IBOutlet UITableView*       _locations;
    IBOutlet UILabel*           _hint;

    NSURLConnection*            _serverConnection;
    NSURLConnection*            _serverConnection5DaysForecast;
    NSMutableData*              _serverData;


    NSArray*                    _arrayOfPlacesSearched;
    NSDictionary*               _searchPlaceDict;
    NSString*                   _selectedPlaceID;
    NSString*                   _searchedPlace;
    
    id                          _object;
    id                          _object5DaysForecast;
    
}

@end

