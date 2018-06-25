# VirtualTourist: An iOS app

The app allows users to specify travel locations around the world, and create virtual photo albums for each location. The locations and photo albums are stored in Core Data and user defaults.

## The app has two view controller scenes. ##
+ **Travel Locations Map View**: Allows the user to drop pins around the world
+ **Photo Album View**: Allows the users to download and edit an album for a location

These two scenes are described in detail below.

### Travel Locations Map View ###

When the app first starts it will open to the map view. Users will be able to zoom and scroll around the map using standard pinch and drag gestures.
The center of the map and the zoom level are persistent so ff the app is turned off, the map will return to the same state when it is turned on again.
Tapping and holding the map drops a new pin. Users can place any number of pins on the map.
When a pin is tapped, the app will navigate to the Photo Album view associated with the pin.
The login view accepts the email address and password that students use to login to the Udacity site. User credentials are not required to be saved upon successful login.

### Photo Album View ###

If the user taps a pin that does not yet have a photo album, the app will download Flickr images associated with the latitude and longitude of the pin.
If no images are found a “no image” label is displayed.
If there are images, then they will be displayed in a collection view.
While the images are downloading, the photo album is in a temporary “downloading” state in which the New Collection button is disabled. 
The app determines how many images are available for the pin location, and display a placeholder image for each.

Once all images are downloaded, the app will enable the New Collection button at the bottom of the page. 
Tapping this button will empty the photo album and fetch a new set of images. 
Note that in locations that have a fairly static set of Flickr images, “new” images might overlap with previous collections of images.
The app fetches new images from new page everytime new album is pressed to avoid overlap.
Users are able to remove photos from an album by tapping edit button on top right corner. This enables edit pictures mode and displays remove icon on each images.
Tapping on remove icon of each picture will remove that picture and other pictures will flow up to fill the space vacated by the removed photo.
All changes to the photo album are automatically made persistent.
Tapping the back button will return the user to the Map view.

If the user selects a pin that already has a photo album then the Photo Album view will display the album and the New Collection button is enabled.

REQUIREMENTS
--------------------------------------------------------------------------------

### BUILD ###
iOS 9.0 SDK or later
Swift 4.1

### RUNTIME ###
iOS 9.0 or later

================================================================================
