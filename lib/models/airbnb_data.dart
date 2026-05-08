class AirbnbData {
  String? propertyName;
  String? description;
  double? price;
  String? address;
  double? latitude;
  double? longitude;
  

  String? placeType;
  int? maxGuests;
  int? bedrooms;
  int? bathrooms;
  double? cleaningFee;
  String? checkInTime;
  String? checkOutTime;
  List<String>? houseRules;
  List<String>? amenities;
  String? cancellationPolicy;
  int? minimumStay;
  int? maximumStay;
  bool? instantBook;
  String? propertySubType;
  double? securityDeposit;
  List<String>? safetyFeatures;
  String? wifiPassword;
  String? accessInstructions;
   List<String>? facilities; 

  int? guests;
  int? beds;

  AirbnbData({
    this.propertyName,
    this.description,
    this.price,
    this.address,
    this.latitude,
    this.longitude,
    this.placeType,
    this.maxGuests,
    this.bedrooms,
    this.bathrooms,
    this.cleaningFee,
    this.checkInTime,
    this.checkOutTime,
    this.houseRules,
    this.amenities,
    this.cancellationPolicy,
    this.minimumStay,
    this.maximumStay,
    this.instantBook,
    this.propertySubType,
    this.securityDeposit,
    this.safetyFeatures,
    this.wifiPassword,
    this.accessInstructions,
    this.guests,
    this.beds,
   this.facilities, 
  });
}
