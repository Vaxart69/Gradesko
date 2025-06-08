import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gradecalculator/components/custom_text_form_field.dart';
import 'package:gradecalculator/components/customsnackbar.dart';
import 'package:gradecalculator/models/records.dart';
import 'package:gradecalculator/models/components.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:gradecalculator/providers/course_provider.dart';

class AddComponent extends StatefulWidget {
  final Component? componentToEdit; 

  const AddComponent({super.key, this.componentToEdit}); 

  @override
  State<AddComponent> createState() => _AddComponentState();
}

class _AddComponentState extends State<AddComponent> {
  final TextEditingController componentNameController = TextEditingController();
  final TextEditingController weightController = TextEditingController();

  final List<Records> records = [];
  final Map<String, TextEditingController> nameControllers = {};
  final Map<String, TextEditingController> scoreControllers = {};
  final Map<String, TextEditingController> totalControllers = {};

  final _formKey = GlobalKey<FormState>();

  bool get isEditMode => widget.componentToEdit != null; 

  @override
  void initState() {
    super.initState();

    if (isEditMode) {
      _loadExistingData(); 
    } else {
      _addRecord(); 
    }
  }


  void _loadExistingData() async {
    final component = widget.componentToEdit!;

   
    componentNameController.text = component.componentName;
    weightController.text = component.weight.toString();

   
    final recordsSnapshot =
        await FirebaseFirestore.instance
            .collection('records')
            .where('componentId', isEqualTo: component.componentId)
            .get();

    setState(() {
      records.clear();
      nameControllers.clear();
      scoreControllers.clear();
      totalControllers.clear();

      if (recordsSnapshot.docs.isEmpty) {
       
        _addRecord();
      } else {
        // Load existing records
        for (final doc in recordsSnapshot.docs) {
          final record = Records.fromMap(doc.data());
          records.add(record);

          final recordId = record.recordId;
          nameControllers[recordId] = TextEditingController(text: record.name);
          scoreControllers[recordId] = TextEditingController(
            text: record.score.toString(),
          );
          totalControllers[recordId] = TextEditingController(
            text: record.total.toString(),
          );
        }
      }
    });
  }

  void _debugPrintRecords(String action) {
    print("=== DEBUG: Records $action ===");
    print("Total Records Count: ${records.length}");

    if (records.isEmpty) {
      print("No records found.");
    } else {
      for (int i = 0; i < records.length; i++) {
        final record = records[i];
        final recordId = record.recordId;
        final name = nameControllers[recordId]?.text ?? '';
        final score = scoreControllers[recordId]?.text ?? '';
        final total = totalControllers[recordId]?.text ?? '';

        print("Record $i:");
        print("  - ID: $recordId");
        print("  - Name: '$name'");
        print("  - Score: '$score'");
        print("  - Total: '$total'");
        print("  - Component ID: '${record.componentId}'");
      }
    }
    print("========================\n");
  }

  void _addRecord() {
    setState(() {
      final recordId = DateTime.now().millisecondsSinceEpoch.toString();
      final newRecord = Records(
        recordId: recordId,
        componentId: '',
        name: '',
        score: 0.0,
        total: 0.0,
      );

      records.add(newRecord);
      nameControllers[recordId] = TextEditingController();
      scoreControllers[recordId] = TextEditingController();
      totalControllers[recordId] = TextEditingController();
      _debugPrintRecords("ADDED");
    });
  }

  void _removeRecord(int index) {
    setState(() {
      final recordId = records[index].recordId;
      print("=== DEBUG: REMOVING Record at index $index ===");
      print("Record ID to remove: $recordId");

      nameControllers[recordId]?.dispose();
      scoreControllers[recordId]?.dispose();
      totalControllers[recordId]?.dispose();
      nameControllers.remove(recordId);
      scoreControllers.remove(recordId);
      totalControllers.remove(recordId);
      records.removeAt(index);
      _debugPrintRecords("REMOVED");
    });
  }


  Future<void> _saveComponentToFirestore() async {
    final courseProvider = Provider.of<CourseProvider>(context, listen: false);

    
    final recordsData = records.map((record) {
      final recordId = record.recordId;
      return {
        'name': nameControllers[recordId]?.text ?? '',
        'score': double.tryParse(scoreControllers[recordId]?.text ?? '0') ?? 0.0,
        'total': double.tryParse(totalControllers[recordId]?.text ?? '0') ?? 0.0,
      };
    }).toList();

    try {
      if (isEditMode) {
        await courseProvider.updateComponentWithRecords(
          componentId: widget.componentToEdit!.componentId,
          componentName: componentNameController.text,
          weight: double.tryParse(weightController.text) ?? 0.0,
          recordsData: recordsData,
        );
      } else {
        await courseProvider.createComponentWithRecords(
          componentName: componentNameController.text,
          weight: double.tryParse(weightController.text) ?? 0.0,
          recordsData: recordsData,
        );
      }
    } catch (e) {
      print("Error saving component: $e");
      rethrow;
    }
  }

  bool _validateRecords() {
    if (records.isEmpty) return false;
    for (var record in records) {
      final recordId = record.recordId;
      
      final score = scoreControllers[recordId]?.text.trim() ?? '';
      final total = totalControllers[recordId]?.text.trim() ?? '';
      if (score.isEmpty || total.isEmpty) {
        return false;
      }
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final height = size.height;
    final width = size.width;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: width * 0.08),
            child: Form(
              key: _formKey, 
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTitle(height),
                  SizedBox(height: height * 0.03),
                  _buildComponentFields(height),
                  SizedBox(height: height * 0.025),
                  _buildRecordsSystem(height),
                  SizedBox(height: height * 0.015),
                  _buildSaveButton(size),
                  SizedBox(height: height * 0.02),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTitle(double height) {
    return RichText(
      text: TextSpan(
        style: GoogleFonts.poppins(
          fontSize: height * 0.04,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        children: [
          TextSpan(text: isEditMode ? "EDIT " : "ADD A "),
          TextSpan(
            text: "COMPONENT.",
            style: GoogleFonts.poppins(
              color: const Color(0xFF6200EE),
              fontWeight: FontWeight.bold,
              fontSize: height * 0.04,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComponentFields(double height) {
    return Column(
      children: [
        CustField(
          label: "Component",
          hintText: "Assignments",
          icon: Icons.list_alt,
          controller: componentNameController,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Component name is required';
            }
            return null;
          },
        ),
        SizedBox(height: height * 0.015),
        CustField(
          label: "Weight (%)",
          hintText: "10",
          icon: Icons.assignment,
          controller: weightController,
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Weight is required';
            }
            final weight = double.tryParse(value.trim()) ?? 0.0;
            if (weight == 0.0) {
              return 'Weight cannot be 0';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildRecordsSystem(double height) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Records",
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: height * 0.02,
          ),
        ),
        SizedBox(height: height * 0.01),
        _buildRecordsTableHeader(height),
        _buildRecordsTableRows(height),
      ],
    );
  }

  Widget _buildRecordsTableHeader(double height) {
    return Container(
      padding: EdgeInsets.all(height * 0.015),
      decoration: const BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              "Name (optional)",
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: height * 0.018,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              "Score",
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: height * 0.018,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              "Total",
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: height * 0.018,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(width: height * 0.05),
        ],
      ),
    );
  }

  Widget _buildRecordsTableRows(double height) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
      ),
      child: Column(
        children: [
          ...records.asMap().entries.map((entry) {
            final index = entry.key;
            final record = entry.value;
            return _buildRecordRow(record, index, height);
          }),
          _buildAddButton(height),
        ],
      ),
    );
  }

  Widget _buildRecordRow(Records record, int index, double height) {
    final recordId = record.recordId;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: height * 0.015,
        vertical: height * 0.01,
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: _buildTextField(
              controller: nameControllers[recordId]!,
              height: height,
              keyboardType: TextInputType.text,
            ),
          ),
          _buildSeparator(" ", height),
          Expanded(
            flex: 2,
            child: _buildTextField(
              controller: scoreControllers[recordId]!,
              height: height,
              keyboardType: TextInputType.number,
            ),
          ),
          _buildSeparator(" ", height),
          Expanded(
            flex: 2,
            child: _buildTextField(
              controller: totalControllers[recordId]!,
              height: height,
              keyboardType: TextInputType.number,
            ),
          ),
          SizedBox(width: height * 0.01),
          _buildDeleteButton(index, height),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required double height,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType ?? TextInputType.text,
      textAlign: TextAlign.center,
      style: GoogleFonts.poppins(fontSize: height * 0.018),
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: height * 0.01,
          vertical: height * 0.01,
        ),
      ),
    );
  }

  Widget _buildSeparator(String text, double height) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: height * 0.01),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.bold,
          color: Colors.white,
          fontSize: height * 0.02,
        ),
      ),
    );
  }

  Widget _buildDeleteButton(int index, double height) {
    return SizedBox(
      width: height * 0.05,
      child:
          records.length > 1
              ? IconButton(
                onPressed: () => _removeRecord(index),
                icon: Icon(
                  Icons.delete,
                  color: const Color(0xFFCF6C79),
                  size: height * 0.025,
                ),
              )
              : const SizedBox(),
    );
  }

  Widget _buildAddButton(double height) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(height * 0.01),
      child: Align(
        alignment: Alignment.centerRight,
        child: IconButton(
          onPressed: _addRecord,
          icon: Icon(
            Icons.add_circle,
            color: const Color(0xFF6200EE),
            size: height * 0.04,
          ),
        ),
      ),
    );
  }

  Widget _buildSaveButton(Size size) {
    return Center(
      child: SizedBox(
        width: size.width * 0.8,
        height: size.height * 0.06,
        child: ElevatedButton(
          onPressed: () async {
            final formValid = _formKey.currentState!.validate();
            final recordsValid = _validateRecords();

            if (!formValid || !recordsValid) {
              if (!recordsValid) {
                showCustomSnackbar(
                  context,
                  'Please complete all record rows.',
                  duration: const Duration(seconds: 2),
                );
              }
              return;
            }

            showDialog(
              context: context,
              barrierDismissible: false,
              builder:
                  (context) => const Center(child: CircularProgressIndicator()),
            );

            await _saveComponentToFirestore();

            if (mounted) {
              Navigator.of(context).pop(); 
              Navigator.of(context).pop(); 
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6200EE),
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(50),
            ),
          ),
          child: Text(
            isEditMode ? "Update Component" : "Add Component",
            style: GoogleFonts.poppins(
              fontSize: size.height * 0.020,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    componentNameController.dispose();
    weightController.dispose();
    for (final controller in nameControllers.values) {
      controller.dispose();
    }
    for (final controller in scoreControllers.values) {
      controller.dispose();
    }
    for (final controller in totalControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }
}
