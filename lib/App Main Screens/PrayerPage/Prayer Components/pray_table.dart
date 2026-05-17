import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class PrayTable extends StatelessWidget {
  const PrayTable({super.key, required this.prayerWeek});

  final List<Map<String, String>> prayerWeek;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 272.w,
      height: 220.h,
      padding: EdgeInsets.symmetric(vertical: 1, horizontal: 8.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(16)),
        color: Theme.of(context).colorScheme.primary,
      ),
      child: DataTable(
        dividerThickness: 0.4,
        horizontalMargin: 0.1,
        columnSpacing: 5.w,
        dataRowHeight: 27.h,
        headingRowHeight: 30.h,
        border: TableBorder(
          verticalInside: BorderSide(color: Theme.of(context).colorScheme.surface,width: 0.3.w),
        ),
        columns: [
          DataColumn(
            label: Center(
              child: Text(
                'العشاء',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
          ),
          DataColumn(
            label: Center(
              child: Text(
                'المغرب',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
          ),
          DataColumn(
            label: Center(
              child: Text(
                ' العصر',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
          ),
          DataColumn(
            label: Center(
              child: Text(
                ' الظهر',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
          ),
          DataColumn(
            label: Center(
              child: Text(
                ' الفجر',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
          ),
          DataColumn(
            label: Center(
              child: Text(
                '   اليوم',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
          ),
        ],
        rows: prayerWeek.map((day) {
          return DataRow(
            cells: [
              DataCell(
                Center(
                  child: Text(
                    day['isha'] ?? '',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
              ),
              DataCell(
                Center(
                  child: Text(
                    day['maghrib'] ?? '',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
              ),
              DataCell(
                Center(
                  child: Text(
                    day['asr'] ?? '',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
              ),
              DataCell(
                Center(
                  child: Text(
                    day['dhuhr'] ?? '',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
              ),
              DataCell(
                Center(
                  child: Text(
                    day['fajr'] ?? '',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
              ),
              DataCell(
                Center(
                  child: Text(
                    day['day'] ?? '',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}
