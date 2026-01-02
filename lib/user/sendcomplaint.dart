import 'package:flutter/material.dart';



class ComplaintPage extends StatefulWidget {
  @override
  State<ComplaintPage> createState() => _ComplaintPageState();
}

class _ComplaintPageState extends State<ComplaintPage> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  String attachment = "";

  void _pickAttachment() {
    // TODO: Integrate file picker
    setState(() {
      attachment = "Attachment selected";
    });
  }

  void _submitComplaint() {
    if (_titleController.text.isEmpty || _descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please fill all fields")),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Complaint submitted successfully")),
    );

    // Clear fields
    _titleController.clear();
    _descriptionController.clear();
    setState(() {
      attachment = "";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue.shade700,
        title: Center(
          child: Text(
            "Send Complaint",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: "Complaint Title",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 10),
            TextFormField(
              controller: _descriptionController,
              maxLines: 5,
              decoration: InputDecoration(
                labelText: "Description",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 10),
            OutlinedButton.icon(
              icon: Icon(Icons.upload_file),
              label: Text(
                  attachment.isEmpty ? "Attach File (Optional)" : "$attachment ✅"),
              onPressed: _pickAttachment,
            ),
            SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade700),
                onPressed: _submitComplaint,
                child: Text(
                  "Submit Complaint",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
