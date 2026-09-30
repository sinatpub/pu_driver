/// Splits a reverse-geocoded address (`getAddressFromLatLng`) into the place
/// and the area, for the two-line address rows (`DD-35`):
/// "Central Market, Daun Penh, Phnom Penh" reads as "Central Market" over
/// "Daun Penh, Phnom Penh".
///
/// The geocoder's parts are not all worth showing, so before splitting:
/// - a plus code ("8M5X+2Q") is dropped — alone, or ahead of a place name;
/// - the postcode and the country are dropped — every trip is in Cambodia;
/// - a repeated part is dropped — `name` often equals `street`;
/// - a bare house number is joined to the part after it, so the bold line
///   reads "12 Street 13" rather than "12".
///
/// An address with nothing left after that is returned whole, as the place.
(String, String?) splitAddress(String address) {
  final List<String> parts = <String>[];
  for (final String raw in address.split(',')) {
    final String part = raw.trim().replaceFirst(_plusCode, '').trim();
    if (part.isEmpty ||
        _postcode.hasMatch(part) ||
        _countries.contains(part.toLowerCase()) ||
        parts.contains(part)) {
      continue;
    }
    parts.add(part);
  }
  if (parts.isEmpty) return (address.trim(), null);

  if (parts.length > 1 && _houseNumber.hasMatch(parts.first)) {
    final String number = parts.removeAt(0);
    parts[0] = '$number ${parts[0]}';
  }
  final String area = parts.skip(1).join(', ');
  return (parts.first, area.isEmpty ? null : area);
}

/// Western or Khmer digits.
const String _digit = r'[0-9០-៩]';

/// An Open Location Code at the start of a part, with anything after it.
final RegExp _plusCode = RegExp(
  r'^[23456789CFGHJMPQRVWX]{2,8}\+[23456789CFGHJMPQRVWX]{0,3}(\s+|$)',
  caseSensitive: false,
);

/// Cambodian postcodes are five digits; six covers the odd older one.
final RegExp _postcode = RegExp('^$_digit{5,6}\$');

/// "12", "12A", "#12", "No. 12".
final RegExp _houseNumber = RegExp(
  '^(#|No\\.?\\s*)?$_digit{1,4}[A-Za-z]?\$',
  caseSensitive: false,
);

const Set<String> _countries = <String>{
  'cambodia',
  'កម្ពុជា',
  'ព្រះរាជាណាចក្រកម្ពុជា',
};
