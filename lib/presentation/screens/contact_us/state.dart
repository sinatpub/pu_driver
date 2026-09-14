/// Contact details are static today — there is no backend for them, so this
/// state holds only the values the view renders. Kept as a class (rather than
/// consts on the view) so a future `get-contact-info` endpoint has somewhere
/// to land without reshaping the screen (`14` §3.3).
class ContactUsState {
  final String smartPhone = "+855 70 427 213";
  final String cellcardPhone = "+855 12 285 048";
  final String email = "tarataxi24@gmail.com";
  final String address =
      "#74, Street 192, Sangkat Teuk Laok 3, Toul Kork District, Phnom Penh";
  // The blurb and copyright are copy, not contact data: they live in the
  // locale files (`CONTACT_BLURB`, `COPYRIGHT`) since P2.
}
