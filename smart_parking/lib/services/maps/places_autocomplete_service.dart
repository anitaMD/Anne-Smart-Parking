// ignore_for_file: avoid_print

class MyPlacesService {
  //using google place autocomplete won't work with myAPI key because I haven't enabled billing. Need to find another way.
  //allows me to display all smart parkings available from the search (pour contourner maps billing)
//BILLING : Before you start developing with the Geocoding API, review the authentication requirements (you need an API key) and the API usage and billing information (you need to enable billing on your project).
// check this for last position history : https://pub.dev/packages/geolocator

  Map<String, dynamic> placesList = {};
  Map<String, Set<String>> mappedPlacesList = {};
  String searchWord = "smart p";
  Map<String, dynamic> fetchedParkingsInfo = {};

  Map<String, Set<String>> showPlacesList(
      Map<String, dynamic> allParkingsInfo) {
    print("GOT IT: $allParkingsInfo");
    fetchedParkingsInfo.addAll(allParkingsInfo);
    Set<String> parkingIdList = {};
    for (var locationInfo in fetchedParkingsInfo.entries) {
      parkingIdList.add(locationInfo.key);
      placesList.addAll(locationInfo.value);
      print("LIST PLACES : $placesList");
      for (var id in parkingIdList) {
        // ignore: unused_local_variable
        for (var place in placesList.entries) {
          if (id == locationInfo.key) {
            mappedPlacesList.addAll({
              id: {
                placesList["StreetAddress"],
                placesList["City"],
                placesList["CountryCode"]
              }
            });
          }
        }
      }
    }
    print(" LENGTH OF LIST ${placesList.length}");
    print("MAPPED INF: $mappedPlacesList");
    return mappedPlacesList;
  }
}
