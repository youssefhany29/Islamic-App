import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:islamic_app/shared/widgets/app_main_components/custom_app_bar.dart';
import 'package:islamic_app/shared/widgets/common_components/app_layout_constants.dart';
import 'package:islamic_app/core/services/app_haptics.dart';

import '../models/islamic_event_filter.dart';
import '../models/islamic_event_model.dart';
import '../services/islamic_events_service.dart';
import '../widgets/islamic_event_card.dart';
import '../widgets/islamic_events_calendar_strip.dart';
import '../widgets/islamic_events_filter_chips.dart';
import '../widgets/islamic_events_hero_card.dart';
import '../widgets/islamic_events_section_title.dart';
import '../widgets/islamic_events_state_cards.dart';
import 'islamic_event_details_page.dart';

bool _eventsPageLargeScreen(BuildContext context) {
  final Size size = MediaQuery.sizeOf(context);
  return size.shortestSide >= 600 || (size.width >= 700 && size.height >= 500);
}

class IslamicEventsPage extends StatefulWidget {
  const IslamicEventsPage({super.key});

  @override
  State<IslamicEventsPage> createState() => _IslamicEventsPageState();
}

class _IslamicEventsPageState extends State<IslamicEventsPage> {
  final IslamicEventsService _eventsService = IslamicEventsService();

  late Future<IslamicEventsResult> _eventsFuture;

  IslamicEventFilter _selectedFilter = IslamicEventFilter.all;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  void _loadEvents() {
    _eventsFuture = _eventsService.getUpcomingEventsSmart();
  }

  Future<void> _refreshEvents() async {
    AppHaptics.light(context);

    setState(() {
      _loadEvents();
    });

    try {
      await _eventsFuture;
    } catch (_) {}
  }

  void _selectFilter(IslamicEventFilter filter) {
    setState(() {
      _selectedFilter = filter;
    });
  }

  void _selectDate(DateTime date) {
    final normalizedDate = _normalizeDate(date);

    setState(() {
      if (_selectedDate == normalizedDate) {
        _selectedDate = null;
      } else {
        _selectedDate = normalizedDate;
      }
    });
  }

  void _openEventDetails(IslamicEventModel event) {
    AppHaptics.tap(context);

    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) {
          return IslamicEventDetailsPage(event: event);
        },
        transitionDuration: const Duration(milliseconds: 240),
        reverseTransitionDuration: const Duration(milliseconds: 190),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curvedAnimation = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          );

          return FadeTransition(
            opacity: curvedAnimation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.045),
                end: Offset.zero,
              ).animate(curvedAnimation),
              child: child,
            ),
          );
        },
      ),
    );
  }

  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  List<IslamicEventModel> _applyFilters(List<IslamicEventModel> events) {
    return events.where((event) {
      final matchesDate =
          _selectedDate == null ||
          _normalizeDate(event.gregorianDate) == _selectedDate;

      bool matchesType = true;

      switch (_selectedFilter) {
        case IslamicEventFilter.all:
          matchesType = true;
          break;

        case IslamicEventFilter.fasting:
          matchesType = event.type == IslamicEventType.fasting;
          break;

        case IslamicEventFilter.ramadan:
          matchesType =
              event.title.contains('رمضان') ||
              event.title.contains('العشر الأواخر');
          break;

        case IslamicEventFilter.eid:
          matchesType =
              event.title.contains('عيد') ||
              event.title.contains('الفطر') ||
              event.title.contains('الأضحى');
          break;

        case IslamicEventFilter.special:
          matchesType =
              event.type == IslamicEventType.specialDay ||
              event.type == IslamicEventType.reminder ||
              event.type == IslamicEventType.greeting;
          break;
      }

      return matchesDate && matchesType;
    }).toList();
  }

  List<Widget> _eventsColumn({required List<IslamicEventModel> events}) {
    if (events.isEmpty) {
      return const [IslamicEventsEmptyCard()];
    }

    return events.map((event) {
      return IslamicEventCard(
        event: event,
        onTap: () => _openEventDetails(event),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool large = _eventsPageLargeScreen(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: const CustomAppBar(
        category: CustomAppBarCategory(text: 'المناسبات الإسلامية'),
      ),
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          color: theme.colorScheme.primary,
          onRefresh: _refreshEvents,
          child: FutureBuilder<IslamicEventsResult>(
            future: _eventsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.symmetric(
                    horizontal: large
                        ? 28
                        : AppLayoutConstants.pageHorizontalPadding,
                  ),
                  children: [
                    SizedBox(height: large ? 24 : 20.h),
                    const IslamicEventsLoadingCard(),
                  ],
                );
              }

              final result = snapshot.data;

              if (result == null) {
                return ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.symmetric(
                    horizontal: large
                        ? 28
                        : AppLayoutConstants.pageHorizontalPadding,
                  ),
                  children: [
                    SizedBox(height: large ? 24 : 20.h),
                    IslamicEventsErrorCard(onRefresh: _refreshEvents),
                  ],
                );
              }

              final events = result.events;
              final filteredEvents = _applyFilters(events);
              final nextEvent = events.isNotEmpty ? events.first : null;

              final todayEvents = filteredEvents
                  .where((event) => event.isToday)
                  .toList();

              final upcomingEvents = filteredEvents
                  .where((event) => !event.isToday)
                  .toList();

              if (!large) {
                return ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.symmetric(
                    horizontal: AppLayoutConstants.pageHorizontalPadding,
                  ),
                  children: [
                    SizedBox(height: 16.h),
                    IslamicEventsHeroCard(
                      event: nextEvent,
                      onRefresh: _refreshEvents,
                      onTap: nextEvent == null
                          ? null
                          : () {
                              _openEventDetails(nextEvent);
                            },
                    ),
                    SizedBox(height: 14.h),
                    IslamicEventsCalendarStrip(
                      events: events,
                      selectedDate: _selectedDate,
                      onDateSelected: _selectDate,
                    ),
                    SizedBox(height: 14.h),
                    IslamicEventsFilterChips(
                      selectedFilter: _selectedFilter,
                      onFilterSelected: _selectFilter,
                    ),
                    if (_selectedDate != null) ...[
                      SizedBox(height: 10.h),
                      IslamicEventsSelectedDateCard(
                        selectedDate: _selectedDate!,
                        onClear: () {
                          AppHaptics.tap(context);

                          setState(() {
                            _selectedDate = null;
                          });
                        },
                      ),
                    ],
                    SizedBox(height: 16.h),
                    if (todayEvents.isNotEmpty) ...[
                      const IslamicEventsSectionTitle(
                        title: 'مناسبات اليوم',
                        icon: Icons.today_rounded,
                      ),
                      SizedBox(height: 8.h),
                      ...todayEvents.map(
                        (event) => IslamicEventCard(
                          event: event,
                          onTap: () => _openEventDetails(event),
                        ),
                      ),
                      SizedBox(height: 10.h),
                    ],
                    const IslamicEventsSectionTitle(
                      title: 'المناسبات القادمة',
                      icon: Icons.event_available_rounded,
                    ),
                    SizedBox(height: 8.h),
                    if (filteredEvents.isEmpty)
                      const IslamicEventsEmptyCard()
                    else if (upcomingEvents.isEmpty && todayEvents.isEmpty)
                      const IslamicEventsEmptyCard()
                    else
                      ...upcomingEvents.map(
                        (event) => IslamicEventCard(
                          event: event,
                          onTap: () => _openEventDetails(event),
                        ),
                      ),
                    SizedBox(height: 20.h),
                  ],
                );
              }

              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(28, 18, 28, 32),
                children: [
                  IslamicEventsHeroCard(
                    event: nextEvent,
                    onRefresh: _refreshEvents,
                    onTap: nextEvent == null
                        ? null
                        : () {
                            _openEventDetails(nextEvent);
                          },
                  ),
                  const SizedBox(height: 16),
                  IslamicEventsCalendarStrip(
                    events: events,
                    selectedDate: _selectedDate,
                    onDateSelected: _selectDate,
                  ),
                  const SizedBox(height: 16),
                  IslamicEventsFilterChips(
                    selectedFilter: _selectedFilter,
                    onFilterSelected: _selectFilter,
                  ),
                  if (_selectedDate != null) ...[
                    const SizedBox(height: 12),
                    IslamicEventsSelectedDateCard(
                      selectedDate: _selectedDate!,
                      onClear: () {
                        AppHaptics.tap(context);

                        setState(() {
                          _selectedDate = null;
                        });
                      },
                    ),
                  ],
                  const SizedBox(height: 18),
                  if (todayEvents.isNotEmpty) ...[
                    const IslamicEventsSectionTitle(
                      title: 'مناسبات اليوم',
                      icon: Icons.today_rounded,
                    ),
                    const SizedBox(height: 10),
                    _EventsMasonry(
                      children: _eventsColumn(events: todayEvents),
                    ),
                    const SizedBox(height: 18),
                  ],
                  const IslamicEventsSectionTitle(
                    title: 'المناسبات القادمة',
                    icon: Icons.event_available_rounded,
                  ),
                  const SizedBox(height: 10),
                  if (filteredEvents.isEmpty ||
                      (upcomingEvents.isEmpty && todayEvents.isEmpty))
                    const IslamicEventsEmptyCard()
                  else
                    _EventsMasonry(
                      children: _eventsColumn(events: upcomingEvents),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _EventsMasonry extends StatelessWidget {
  const _EventsMasonry({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    if (children.length <= 1) {
      return Column(children: children);
    }

    final List<Widget> right = <Widget>[];
    final List<Widget> left = <Widget>[];

    for (int i = 0; i < children.length; i++) {
      if (i.isEven) {
        right.add(children[i]);
      } else {
        left.add(children[i]);
      }
    }

    return Row(
      textDirection: TextDirection.rtl,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            children: [
              for (int i = 0; i < right.length; i++) ...[
                right[i],
                if (i != right.length - 1) const SizedBox(height: 12),
              ],
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            children: [
              for (int i = 0; i < left.length; i++) ...[
                left[i],
                if (i != left.length - 1) const SizedBox(height: 12),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
