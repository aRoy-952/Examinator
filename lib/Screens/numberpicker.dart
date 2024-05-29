import 'package:flutter/material.dart';
import 'package:numberpicker/numberpicker.dart';

class CustomTimePicker extends StatefulWidget {
  final int initialHours;
  final int initialMinutes;
  final Function(int hours, int minutes) onChanged;

  const CustomTimePicker({
    Key? key,
    required this.initialHours,
    required this.initialMinutes,
    required this.onChanged,
  }) : super(key: key);

  @override
  _CustomTimePickerState createState() => _CustomTimePickerState();
}

class _CustomTimePickerState extends State<CustomTimePicker> {
  late int _selectedHours;
  late int _selectedMinutes;

  @override
  void initState() {
    super.initState();
    _selectedHours = widget.initialHours;
    _selectedMinutes = widget.initialMinutes;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Hours',
              style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
            ),
            SizedBox(width: 30.0),
            Text(
              'Minutes',
              style: TextStyle(
                fontSize: 16.0,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            NumberPicker(
              value: _selectedHours,
              minValue: 0,
              maxValue: 5,
              onChanged: (value) {
                setState(() {
                  _selectedHours = value;
                  widget.onChanged(_selectedHours, _selectedMinutes);
                });
              },
              itemWidth: 60.0,
              textMapper: (value) => value.toString().padLeft(2, '0'),
            ),
            SizedBox(width: 20.0),
            // Adjust spacing between NumberPicker and Text widget
            NumberPicker(
              value: _selectedMinutes,
              minValue: 0,
              maxValue: 59,
              onChanged: (value) {
                setState(() {
                  _selectedMinutes = value;
                  widget.onChanged(_selectedHours, _selectedMinutes);
                });
              },
              itemWidth: 60.0,
              textMapper: (value) => value.toString().padLeft(2, '0'),
            ),
          ],
        ),
      ],
    );
  }
}
