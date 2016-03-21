//
//  ViewController.m
//  MGTWeather
//
//  Created by Jayant Saxena on 21/03/16.
//  Copyright © 2016 ABC. All rights reserved.
//

#import "ViewController.h"
#import <MBProgressHUD.h>
#import "MPCoachMarks.h"

#define     GoogleAPIKey            @"AIzaSyBk-6wFGMcYcuAPnD1OWnUX-XDNz16J3YQ"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if([[[NSUserDefaults standardUserDefaults] objectForKey:@"Help"] intValue] <= 0)
        [self showHelp];
    else
        [self enableLocationServices];

    // Do any additional setup after loading the view, typically from a nib.
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
    _locationManager.desiredAccuracy = kCLLocationAccuracyBest;

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

- (void)locationManager:(CLLocationManager *)manager
    didUpdateToLocation:(CLLocation *)newLocation
           fromLocation:(CLLocation *)oldLocation
{
    if(_lat == nil && _long == nil && [newLocation horizontalAccuracy] < 100)
    {
        [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        _lat = [NSString stringWithFormat:@"%f", manager.location.coordinate.latitude];
        _long = [NSString stringWithFormat:@"%f", manager.location.coordinate.longitude];
        [self connectServerWithLatitude:_lat andLongitude:_long];
    }
}
- (void)locationManager:(CLLocationManager *)manager
     didUpdateLocations:(NSArray<CLLocation *> *)locations
{
    if(_lat == nil && _long == nil && [locations.lastObject horizontalAccuracy] < 100)
    {
        [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        _lat = [NSString stringWithFormat:@"%f", manager.location.coordinate.latitude];
        _long = [NSString stringWithFormat:@"%f", manager.location.coordinate.longitude];
        [self connectServerWithLatitude:_lat andLongitude:_long];
    }
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    NSLog(@"...");
    if(error)
    {
//        [[[UIAlertView new] initWithTitle:nil message:@"Please enable location services." delegate:nil cancelButtonTitle:nil otherButtonTitles:@"Ok", nil] show];
        NSLog(@"Location services not enabled");
    }
    else if(_lat == nil && _long == nil)
    {
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        hud.mode = MBProgressHUDModeAnnularDeterminate;
        hud.labelText = @"weather at your location..";
        _lat = [NSString stringWithFormat:@"%f", manager.location.coordinate.latitude];
        _long = [NSString stringWithFormat:@"%f", manager.location.coordinate.longitude];
        [self connectServerWithLatitude:_lat andLongitude:_long];
    }
}


#pragma mark SearchBar Delegates
- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar
{
    searchBar.text = @"";
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    [self performSelector:@selector(findPlaces:) withObject:searchBar afterDelay:0.1];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    _searchBar.text = @"";
}

- (void)searchForText
{
    [_searchBar setShowsCancelButton:NO animated:YES];
    [_searchBar resignFirstResponder];
    
    NSLog(@"Search for : %@", [[NSString stringWithFormat:
                                @"https://maps.googleapis.com/maps/api/place/details/json?input=%@&placeid=%@&key=%@",
                                _searchBar.text,
                                _selectedPlaceID,
                                GoogleAPIKey] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]);
    _searchedPlace = _searchBar.text;

    if (_selectedPlaceID != nil && _selectedPlaceID.length > 0) {

        _serverConnection = [NSURLConnection connectionWithRequest:[NSURLRequest requestWithURL:
                                                                    [NSURL URLWithString:[[NSString stringWithFormat:
                                                                                           @"https://maps.googleapis.com/maps/api/place/details/json?input=%@&placeid=%@&key=%@",
                                                                                           _searchBar.text,
                                                                                           _selectedPlaceID,
                                                                                           GoogleAPIKey] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]]
                                                          delegate:self];
        
    }
    
    
}



- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    NSHTTPURLResponse *HTTPResponse = (NSHTTPURLResponse *)response;
    NSInteger statusCode = [HTTPResponse statusCode];
    
    NSLog(@"Status Code recved %ld", (long)statusCode);
    [_serverData setLength:0];

    if ((long)statusCode != 200)
    {
        [MBProgressHUD hideHUDForView:self.view animated:YES];
        [[[UIAlertView new] initWithTitle:nil message:[NSString stringWithFormat:@"Error Status Code - %ld", (long)statusCode] delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil] show];
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    if(_serverData == nil)
        _serverData = [[NSMutableData alloc] init];
    [_serverData appendData:data];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [MBProgressHUD hideHUDForView:self.view animated:YES];
        [[[UIAlertView new] initWithTitle:nil message:[NSString stringWithFormat:@"Error - %@", error.description] delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil] show];
    });
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
     if ([_serverData length] > 0)
     {
         NSError* error = nil;
         if(connection == _serverConnection)
             _object = [NSJSONSerialization JSONObjectWithData:_serverData options: NSJSONReadingMutableContainers error: &error];
         else
             _object5DaysForecast = [NSJSONSerialization JSONObjectWithData:_serverData options: NSJSONReadingMutableContainers error: &error];

         _serverData = nil;
         if([[[[_serverConnection currentRequest] URL] absoluteString] hasPrefix:@"http://api.openweathermap.org/data"] == NO || _object5DaysForecast == nil)
         {
             if([[[[_serverConnection currentRequest] URL] absoluteString] hasPrefix:@"http://api.openweathermap.org/data"] == NO)
                 _serverConnection = nil;
             if([[[[_object valueForKey:@"result"] valueForKey:@"geometry"] valueForKey:@"location"] valueForKey:@"lat"])
                 _lat = [[[[_object valueForKey:@"result"] valueForKey:@"geometry"] valueForKey:@"location"] valueForKey:@"lat"];
             if([[[[_object valueForKey:@"result"] valueForKey:@"geometry"] valueForKey:@"location"] valueForKey:@"lng"])
                 _long = [[[[_object valueForKey:@"result"] valueForKey:@"geometry"] valueForKey:@"location"] valueForKey:@"lng"];
                 [self connectServerWithLatitude:_lat andLongitude:_long];
         }
         else
         {
             _locations.hidden = NO;
             [_locations reloadData];
             dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
                 // Do something...
                 dispatch_async(dispatch_get_main_queue(), ^{
                     [MBProgressHUD hideHUDForView:self.view animated:YES];
                 });
             });
         }
     }
     else if ([_serverData length] == 0)
     {
         _locations.hidden = YES;
         [_locations reloadData];
         dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
             // Do something...
             dispatch_async(dispatch_get_main_queue(), ^{
                 [MBProgressHUD hideHUDForView:self.view animated:YES];
             });
         });
     }
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    [_searchBar resignFirstResponder];
    _searchBar.text = @"";
}

#pragma mark -
#pragma mark UITableView Delegates

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (tableView == _locations) {
        [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        NSLog(@"Place selected : %ld = %@", (long)indexPath.row, [_arrayOfPlacesSearched objectAtIndex:indexPath.row]);
        _searchBar.text = [_arrayOfPlacesSearched objectAtIndex:indexPath.row];
//        [self hideResults: tableView];
        _selectedPlaceID = [[[_searchPlaceDict valueForKey:@"predictions"] objectAtIndex:indexPath.row] valueForKey:@"place_id"];
        
        [self searchForText];
        //        [self searchBarSearchButtonClicked:_search];
        return;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if([[[[_serverConnection currentRequest] URL] absoluteString] hasPrefix:@"http://api.openweathermap.org/data"] == NO)
        return 35.0f;
    return 60.0f;
}

- (nullable UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    if([[[[_serverConnection currentRequest] URL] absoluteString] hasPrefix:@"http://api.openweathermap.org/data"] == NO)
        return [UILabel new];
    UILabel* lb = [UILabel new];
    lb.textColor = [UIColor blueColor];
    lb.font = [UIFont boldSystemFontOfSize:17.0f];
    lb.backgroundColor = [UIColor colorWithRed:158.0f/255.0f green:163.0f/255.0f blue:170.0f/255.0f alpha:0.7];
    lb.text = section == 0 ? @" Now" : @" 5 Days Forecast";
    return lb;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if([[[[_serverConnection currentRequest] URL] absoluteString] hasPrefix:@"http://api.openweathermap.org/data"] == NO)
        return 0.0f;
    return 25.0f;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if([[[[_serverConnection currentRequest] URL] absoluteString] hasPrefix:@"http://api.openweathermap.org/data"] == NO)
        return 1;
    return 2;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if([[[[_serverConnection currentRequest] URL] absoluteString] hasPrefix:@"http://api.openweathermap.org/data"] == NO)
        return _arrayOfPlacesSearched.count;
    
    return section == 0 ? 1 : [[_object5DaysForecast valueForKey:@"list"] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString* ide = @"textCell";
    UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:ide];
    if (cell == nil)
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:ide];

    cell.textLabel.numberOfLines = 0;
    if([[[[_serverConnection currentRequest] URL] absoluteString] hasPrefix:@"http://api.openweathermap.org/data"] == NO)
    {
        cell.textLabel.text = [_arrayOfPlacesSearched objectAtIndex:indexPath.row];
        cell.textLabel.font = [UIFont systemFontOfSize:12.0f];
    }
    else
    {
        cell.textLabel.text = @"";
        if (indexPath.section == 0) {
            NSString* desc          = [NSString stringWithFormat:@"%@ (Temperature: %@˚c)",
                                       [[[[_object valueForKey:@"weather"] firstObject] valueForKey:@"description"] uppercaseString],
                                       [NSString stringWithFormat:@"%.2f", [[[_object valueForKey:@"main"] valueForKey:@"temp"] doubleValue] - 273.15]];
            NSString* minTemp       = [NSString stringWithFormat:@"%.2f", [[[_object valueForKey:@"main"] valueForKey:@"temp_min"] doubleValue] - 273.15];
            NSString* maxTemp       = [NSString stringWithFormat:@"%.2f", [[[_object valueForKey:@"main"] valueForKey:@"temp_max"] doubleValue] - 273.15];
            
            NSString* d = [NSString stringWithFormat:@"%@\nMin:%@˚c\tMax:%@˚c",
                           desc,
                           minTemp,
                           maxTemp];
            
            NSMutableAttributedString* strr = [[NSMutableAttributedString alloc] initWithString:d];
            [strr addAttribute:NSFontAttributeName value:[UIFont boldSystemFontOfSize:14.0] range:NSMakeRange(0, desc.length)];
            [strr addAttribute:NSFontAttributeName value:[UIFont boldSystemFontOfSize:11.0] range:NSMakeRange(desc.length,d.length - desc.length)];
            cell.textLabel.attributedText = strr;
        }
        else
        {
            NSDate* dt = [NSDate dateWithTimeIntervalSince1970:[[[[_object5DaysForecast valueForKey:@"list"] objectAtIndex:indexPath.row] valueForKey:@"dt"] doubleValue]];
            NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
            [dateFormatter setLocale:[NSLocale currentLocale]];
            [dateFormatter setDateFormat:@"EEE, dd MMM yyyy h:mma"];

            NSTimeZone *timeZone = [NSTimeZone systemTimeZone];
            timeZone = [NSTimeZone localTimeZone];
            timeZone = [NSTimeZone defaultTimeZone];
            [dateFormatter setTimeZone:timeZone];
            NSLog(@"JS Date CURRENT: %@", [[NSDate new] descriptionWithLocale:[NSLocale currentLocale]]);

            NSString* desc          = [NSString stringWithFormat:@"On %@ - %@\n",
                                       [dateFormatter stringFromDate:dt],
                                       [[[[[[_object5DaysForecast valueForKey:@"list"] objectAtIndex:indexPath.row] valueForKey:@"weather"] firstObject] valueForKey:@"description"] uppercaseString]];

            NSString* Temp       = [NSString stringWithFormat:@"Temperature: %.2f˚c, ", [[[[[_object5DaysForecast valueForKey:@"list"] objectAtIndex:indexPath.row] valueForKey:@"main"] valueForKey:@"temp"] doubleValue] - 273.15];
            
            NSString* humid       = [NSString stringWithFormat:@"Humidity:%.1f%%", [[[[[_object5DaysForecast valueForKey:@"list"] objectAtIndex:indexPath.row] valueForKey:@"main"] valueForKey:@"humidity"] doubleValue]];

            NSString* d = [NSString stringWithFormat:@"%@%@%@",
                           desc,
                           Temp,
                           humid];

            NSMutableAttributedString* strr = [[NSMutableAttributedString alloc] initWithString:d];
            [strr addAttribute:NSFontAttributeName value:[UIFont boldSystemFontOfSize:14.0] range:NSMakeRange(0, desc.length)];
            [strr addAttribute:NSFontAttributeName value:[UIFont boldSystemFontOfSize:11.0] range:NSMakeRange(desc.length,d.length - desc.length)];
            cell.textLabel.attributedText = strr;
        }
    }
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    return cell;
}

- (void)viewDidLayoutSubviews
{
    if ([_locations respondsToSelector:@selector(setSeparatorInset:)]) {
        [_locations setSeparatorInset:UIEdgeInsetsZero];
    }
    
    if ([_locations respondsToSelector:@selector(setLayoutMargins:)]) {
        [_locations setLayoutMargins:UIEdgeInsetsZero];
    }
}
- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([cell respondsToSelector:@selector(setSeparatorInset:)]) {
        [cell setSeparatorInset:UIEdgeInsetsZero];
    }
    
    if ([cell respondsToSelector:@selector(setLayoutMargins:)]) {
        [cell setLayoutMargins:UIEdgeInsetsZero];
    }
}

- (void)connectServerWithLatitude:(NSString*)lat andLongitude:(NSString*)lng
{
    if(_serverConnection == nil)
        _serverConnection = [NSURLConnection connectionWithRequest:
                         [NSURLRequest requestWithURL:[NSURL URLWithString:[[NSString stringWithFormat:@"http://api.openweathermap.org/data/2.5/weather?lat=%@&lon=%@&APPID=74dcb9f1fd811380427a706c2636e379", lat, lng] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]]
                                                      delegate:self];
    else
        _serverConnection5DaysForecast = [NSURLConnection connectionWithRequest:
                                      [NSURLRequest requestWithURL:[NSURL URLWithString:[[NSString stringWithFormat:@"http://api.openweathermap.org/data/2.5/forecast?lat=%@&lon=%@&APPID=74dcb9f1fd811380427a706c2636e379", lat, lng] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]]
                                                                   delegate:self];
}

- (void)findPlaces:(UISearchBar*)sb
{
    _lat            = @"";
    _long           = @"";
    _serverConnection                   = nil;
    _serverConnection5DaysForecast      = nil;
    _serverData                         = nil;
    _arrayOfPlacesSearched              = nil;
    _searchPlaceDict                    = nil;
    _selectedPlaceID                    = nil;
    _searchedPlace                      = nil;
    _object                             = nil;
    _object5DaysForecast                = nil;

    
    [NSURLConnection sendAsynchronousRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:[[NSString stringWithFormat:
                                                                                                 @"https://maps.googleapis.com/maps/api/place/autocomplete/json?input=%@&location=%f,%f&radius=%ld&key=%@",
                                                                                                 sb.text,
                                                                                                 _locationManager.location.coordinate.latitude,
                                                                                                 _locationManager.location.coordinate.longitude,
                                                                                                 10000000,
                                                                                                 GoogleAPIKey] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]]
                                       queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error)
     {
         _arrayOfPlacesSearched = nil;
         if ([data length] > 0 && error == nil)
         {
             NSError* err = nil;
             _searchPlaceDict = [NSJSONSerialization JSONObjectWithData:data options: NSJSONReadingMutableContainers error: &err];
             _arrayOfPlacesSearched = [[_searchPlaceDict valueForKey:@"predictions"] valueForKey:@"description"];
             
             if (_arrayOfPlacesSearched.count > 0) {
                 _locations.hidden = NO;
                 [_locations performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:YES];
                 [_locations scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:YES];
             }
             else
             {
                 [_locations performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:YES];
                 _locations.hidden = YES;
             }
         }
         else if (([data length] == 0 && error == nil) ||
                  (error != nil && error.code > 0) ||
                  (error != nil))
         {
             _locations.hidden = YES;
             [_locations reloadData];
         }
     }];
}

#pragma mark Coachmarks
- (void)showHelp
{
    // Setup coach marks
    CGRect coachmark1 = CGRectMake(5, 150, [[UIScreen mainScreen] bounds].size.width - 10, 0);
    // Setup coach marks
    NSArray *coachMarks = @[
                            @{
                                @"rect": [NSValue valueWithCGRect:coachmark1],
                                @"caption": @"Application will try to get your location to fetch weather details on launch",
                                @"position":[NSNumber numberWithInteger:LABEL_POSITION_BOTTOM]
                                },
                            @{
                                @"rect": [NSValue valueWithCGRect:_searchBar.frame],
                                @"caption": @"type in location or region name or zipcode to get weather details",
                                @"position":[NSNumber numberWithInteger:LABEL_POSITION_BOTTOM],
                                @"showArrow":[NSNumber numberWithBool:YES]
                                }
                            ];

    MPCoachMarks *coachMarksVi = [[MPCoachMarks alloc] initWithFrame:self.view.bounds coachMarks:coachMarks];
    coachMarksVi.maskColor = [UIColor colorWithRed:0.0f green:0.0f blue:0.0f alpha:0.6f];
    [self.view addSubview:coachMarksVi];
    coachMarksVi.delegate = self;
    coachMarksVi.animationDuration = 0.5f;
    coachMarksVi.enableContinueLabel = NO;
    coachMarksVi.enableSkipButton = NO;
    [coachMarksVi start];
    coachMarksVi = nil;
}

- (void)coachMarksView:(MPCoachMarks *)coachMarksView willNavigateToIndex:(NSUInteger)index
{
    if(index == 1)
        [self enableLocationServices];
}

- (void)coachMarksViewDidCleanup:(MPCoachMarks *)coachMarksView
{
    [[NSUserDefaults standardUserDefaults] setObject:@"1" forKey:@"Help"];
}

@end
