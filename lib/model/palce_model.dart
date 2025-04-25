class Place {
  final String? displayName;
  final double lat;
  final double lon;
  final Addresss? address;
  final ExtraTags? extraTags;
  final NameDetails? nameDetails;

  Place({
    this.displayName,
    required this.lat,
    required this.lon,
    this.address,
    this.extraTags,
    this.nameDetails,
  });

  factory Place.fromGoogleJson(Map<String, dynamic> json) {
    final geometry = json['geometry']?['location'];
    final addressComponents = json['address_components'] ?? [];

    return Place(
      displayName: json['formatted_address'] ?? json['name'],
      lat: geometry != null ? geometry['lat']?.toDouble() : null,
      lon: geometry != null ? geometry['lng']?.toDouble() : null,
      address: Addresss.fromGoogleComponents(addressComponents),
      extraTags: ExtraTags.fromGoogleJson(json),
      nameDetails: NameDetails.fromGoogleJson(json),
    );
  }
}

class Addresss {
  final String? country;
  final String? state;
  final String? city;
  final String? road;
  final String? postcode;

  Addresss({
    this.country,
    this.state,
    this.city,
    this.road,
    this.postcode,
  });

  factory Addresss.fromGoogleComponents(List<dynamic> components) {
    String? getValue(List<String> targetTypes) {
      for (var comp in components) {
        final types = List<String>.from(comp['types']);
        if (types.any((type) => targetTypes.contains(type))) {
          return comp['long_name'];
        }
      }
      return null;
    }

    return Addresss(
      country: getValue(['country']),
      state: getValue(['administrative_area_level_1']),
      city: getValue(['locality', 'administrative_area_level_2']),
      road: getValue(['route']),
      postcode: getValue(['postal_code']),
    );
  }
}

class ExtraTags {
  final String? population;
  final String? place;

  ExtraTags({
    this.population,
    this.place,
  });

  factory ExtraTags.fromGoogleJson(Map<String, dynamic> json) {
    return ExtraTags(
      population: json['user_ratings_total']?.toString(),
      place: (json['types'] != null && json['types'].isNotEmpty)
          ? json['types'][0]
          : null,
    );
  }
}

class NameDetails {
  final String? name;
  final String? nameEs;
  final String? nameEn;

  NameDetails({
    this.name,
    this.nameEs,
    this.nameEn,
  });

  factory NameDetails.fromGoogleJson(Map<String, dynamic> json) {
    return NameDetails(
      name: json['name'],
      nameEs: null, // No disponible en Google API directamente
      nameEn: null, // No disponible directamente
    );
  }
}
