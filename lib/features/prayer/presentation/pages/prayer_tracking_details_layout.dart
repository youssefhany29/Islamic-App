part of 'prayer_tracking_details_page.dart';

extension _PrayerTrackingDetailsLayout on _PrayerTrackingDetailsPageState {
  Widget _buildPrayerTrackingDetailsScaffold(BuildContext context) {
    final bool isLargeScreen = MediaQuery.sizeOf(context).width >= 600;

    if (isLargeScreen) {
      return _buildPrayerTrackingDetailsLargeScaffold(context);
    }

    return _buildPrayerTrackingDetailsPhoneScaffold(context);
  }
}
