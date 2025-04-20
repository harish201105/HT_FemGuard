import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ComplaintScreen extends StatefulWidget {
  @override
  _ComplaintScreenState createState() => _ComplaintScreenState();
}

class _ComplaintScreenState extends State<ComplaintScreen> {
  // Replace with your actual backend endpoint
  final String _backendUrl = "https://your-backend.com/complaints";

  // Form data
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String? _selectedSeverity;
  TextEditingController _remarksController = TextEditingController();

  // Optional File
  PlatformFile? _pickedFile;

  // Confirmation Checkbox
  bool _confirmDetails = false;

  // Shortened Severity options (to prevent overflow)
  final List<String> _severityOptions = [
    "1 - Objectification",
    "2 - Glass Ceiling",
    "3 - Harassments",
    "4 - Abuse"
  ];

  /// Picks a date from the native date picker
  Future<void> _pickDate() async {
    DateTime now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 2),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  /// Picks a time from the native time picker
  Future<void> _pickTime() async {
    TimeOfDay nowTime = TimeOfDay.now();
    final picked = await showTimePicker(
      context: context,
      initialTime: nowTime,
    );
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  /// Picks a file (optional proof)
  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles();
    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _pickedFile = result.files.first;
      });
    }
  }

  /// Submits the complaint to the backend
  Future<void> _submitComplaint() async {
    // Validate required fields
    if (_selectedDate == null ||
        _selectedTime == null ||
        _selectedSeverity == null ||
        _remarksController.text.isEmpty ||
        !_confirmDetails) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please fill all required fields & confirm.")),
      );
      return;
    }

    // Merge date & time
    final dateTime = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );

    try {
      // Convert file to base64 if picked
      String? fileBase64;
      String? fileName;
      if (_pickedFile != null) {
        final bytes = _pickedFile!.bytes; // Uint8List
        fileBase64 = base64Encode(bytes!);
        fileName = _pickedFile!.name;
      }

      final bodyData = {
        "date_of_incident": dateTime.toIso8601String(),
        "severity": _selectedSeverity,
        "remarks": _remarksController.text,
        // Optional file
        "proofFileName": fileName,
        "proofFileData": fileBase64,
      };

      final response = await http.post(
        Uri.parse(_backendUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(bodyData),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Complaint Registered Successfully!")),
        );

        // Clear form
        setState(() {
          _selectedDate = null;
          _selectedTime = null;
          _selectedSeverity = null;
          _remarksController.clear();
          _pickedFile = null;
          _confirmDetails = false;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text("Failed to register complaint. Code: ${response.statusCode}"),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: $e"),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateDisplay = _selectedDate == null
        ? "Select Date"
        : DateFormat("dd/MM/yyyy").format(_selectedDate!);

    final timeDisplay = _selectedTime == null
        ? "Select Time"
        : _selectedTime!.format(context);

    return Scaffold(
      appBar: AppBar(title: Text("Complaint Registration")),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [

            // Date of incident
            Text("Date of Incident:", style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade400),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(dateDisplay),
                  ),
                ),
                SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _pickDate,
                  child: Text("Pick Date"),
                ),
              ],
            ),
            SizedBox(height: 16),

            // Time of incident
            Text("Time of Incident:", style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade400),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(timeDisplay),
                  ),
                ),
                SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _pickTime,
                  child: Text("Pick Time"),
                ),
              ],
            ),
            SizedBox(height: 16),

            // Severity
            Text("Severity of Incident:", style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 4),
            DropdownButtonFormField<String>(
              value: _selectedSeverity,
              isExpanded: true, // Allows the dropdown to expand horizontally
              hint: Text("Select Severity"),
              items: _severityOptions.map((option) {
                return DropdownMenuItem<String>(
                  value: option,
                  child: Text(option, style: TextStyle(fontSize: 14)),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedSeverity = value;
                });
              },
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              ),
            ),
            SizedBox(height: 16),

            // Remarks
            Text("Remarks (required):", style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 4),
            TextField(
              controller: _remarksController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: "Describe the incident briefly...",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),

            // Upload proof (optional)
            Text("Upload Proof (optional):", style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _pickedFile == null
                        ? "No file chosen"
                        : "File: ${_pickedFile!.name}",
                  ),
                ),
                ElevatedButton(
                  onPressed: _pickFile,
                  child: Text("Choose File"),
                ),
              ],
            ),
            SizedBox(height: 16),

            // Confirmation Checkbox
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Checkbox(
                  value: _confirmDetails,
                  onChanged: (bool? value) {
                    setState(() {
                      _confirmDetails = value ?? false;
                    });
                  },
                ),
                Expanded(
                  child: Text(
                    "I confirm that all details are true to the best of my knowledge.",
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),

            // Register Complaint button
            ElevatedButton(
              onPressed: _submitComplaint,
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text("Register Complaint"),
            ),
          ],
        ),
      ),
    );
  }
}
