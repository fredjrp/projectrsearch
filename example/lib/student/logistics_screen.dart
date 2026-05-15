import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/theme/stdeli_theme.dart';
import '../core/services/delivery_service.dart';
import '../core/models/delivery_model.dart';
import '../core/services/auth_service.dart';
import '../core/services/sync_service.dart';

class LogisticsScreen extends StatefulWidget {
  final DeliveryType initialType;
  const LogisticsScreen({Key? key, required this.initialType}) : super(key: key);

  @override
  State<LogisticsScreen> createState() => _LogisticsScreenState();
}

class _LogisticsScreenState extends State<LogisticsScreen> {
  late DeliveryType _selectedType;
  final TextEditingController _itemController = TextEditingController();
  final TextEditingController _pickupController = TextEditingController();
  final TextEditingController _destController = TextEditingController();
  final TextEditingController _pagesController = TextEditingController(text: "1");
  final TextEditingController _phoneController = TextEditingController(text: "254");
  
  File? _selectedDocument;
  String? _fileName;
  bool _isLoading = false;
  double _calculatedPrice = 0.0;
  
  final DeliveryService _deliveryService = DeliveryService();
  final AuthService _authService = AuthService();
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialType;
    _updatePrice();
  }

  void _updatePrice() {
    setState(() {
      _calculatedPrice = _deliveryService.calculatePrice(
        type: _selectedType,
        pageCount: int.tryParse(_pagesController.text) ?? 0,
      );
    });
  }

  Future<void> _pickDocument() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'png'],
    );

    if (result != null) {
      setState(() {
        _selectedDocument = File(result.files.single.path!);
        _fileName = result.files.single.name;
      });
    }
  }

  Future<void> _submitRequest() async {
    if (_pickupController.text.isEmpty || _destController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please fill in locations")));
      return;
    }

    if (_selectedType == DeliveryType.document && _selectedDocument == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please attach a document")));
      return;
    }

    setState(() => _isLoading = true);

    try {
      String uid = FirebaseAuth.instance.currentUser?.uid ?? "demo_user";
      String? docUrl;

      if (_selectedType == DeliveryType.document && _selectedDocument != null) {
        String extension = _fileName?.split('.').last ?? 'file';
        docUrl = await _authService.uploadImage(
          _selectedDocument!, 
          'docs/${DateTime.now().millisecondsSinceEpoch}.$extension'
        );
        if (docUrl.startsWith('local:')) {
           // Queue for sync if failed
           final localPath = docUrl.replaceFirst('local:', '');
           await SyncService().addToQueue(
             uid: uid,
             localPath: localPath,
             storagePath: 'docs/${DateTime.now().millisecondsSinceEpoch}.jpg',
             collection: 'deliveries',
             field: 'documentUrl',
           );
        }
      }

      final request = DeliveryRequest(
        id: '',
        studentId: uid,
        type: _selectedType,
        pickupAddress: _pickupController.text,
        destinationAddress: _destController.text,
        pickupLocation: const GeoPoint(-1.2921, 36.8219),
        destinationLocation: const GeoPoint(-1.3090, 36.8126),
        baseFare: DeliveryService.BASE_DELIVERY_FEE,
        serviceFee: _selectedType == DeliveryType.document 
            ? (int.tryParse(_pagesController.text) ?? 0) * DeliveryService.PRINT_PRICE_PER_PAGE 
            : 0.0,
        totalFare: _calculatedPrice,
        itemDescription: _itemController.text,
        documentUrl: docUrl,
        pageCount: int.tryParse(_pagesController.text),
        timestamp: DateTime.now(),
      );

      await _deliveryService.createRequest(request);

      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Request Sent!"),
          content: Text("Your ${_selectedType.name} request has been placed. A rider will contact you shortly."),
          actions: [
            TextButton(onPressed: () => Navigator.popUntil(context, (route) => route.isFirst), child: const Text("OK"))
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("New ${_selectedType.name.toUpperCase()} Service", style: const TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTypeSelector(),
            const SizedBox(height: 32),
            _buildLocationFields(),
            const SizedBox(height: 24),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: "M-Pesa Phone Number",
                prefixIcon: const Icon(Icons.phone_iphone),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 24),
            if (_selectedType == DeliveryType.document) _buildPrintingFields(),
            if (_selectedType == DeliveryType.package || _selectedType == DeliveryType.group) _buildPackageFields(),
            const SizedBox(height: 40),
            _buildPriceSummary(),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitRequest,
                style: ElevatedButton.styleFrom(backgroundColor: StDeliTheme.primaryGreen),
                child: _isLoading 
                  ? const CircularProgressIndicator(color: Colors.white) 
                  : const Text("Confirm & Pay with M-Pesa"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Row(
      children: DeliveryType.values.where((t) => t != DeliveryType.ride).map((type) {
        bool selected = _selectedType == type;
        return Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() => _selectedType = type);
              _updatePrice();
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: selected ? StDeliTheme.primaryGreen : Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  type.name.toUpperCase(),
                  style: TextStyle(color: selected ? Colors.white : Colors.black54, fontWeight: FontWeight.bold, fontSize: 10),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildLocationFields() {
    return Column(
      children: [
        TextField(
          controller: _pickupController,
          decoration: const InputDecoration(labelText: "Pickup Location", prefixIcon: Icon(Icons.location_on_outlined)),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _destController,
          decoration: const InputDecoration(labelText: "Drop-off Location", prefixIcon: Icon(Icons.flag_outlined)),
        ),
      ],
    );
  }

  Widget _buildPrintingFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Document Details", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 16),
        TextField(
          controller: _pagesController,
          keyboardType: TextInputType.number,
          onChanged: (_) => _updatePrice(),
          decoration: const InputDecoration(labelText: "Number of Pages", suffixText: "Pages"),
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: _pickDocument,
          icon: const Icon(Icons.upload_file),
          label: Text(_fileName ?? "Upload PDF / DOC / Image"),
          style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
        ),
        const SizedBox(height: 8),
        const Text("Supported: PDF, Word, JPG, PNG", style: TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }

  Widget _buildPackageFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Package Details", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 16),
        TextField(
          controller: _itemController,
          decoration: const InputDecoration(hintText: "What are you sending? (e.g. Graduation Gown, Folder)"),
        ),
      ],
    );
  }

  Widget _buildPriceSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Base Delivery Fee"),
              Text("KES ${DeliveryService.BASE_DELIVERY_FEE}"),
            ],
          ),
          if (_selectedType == DeliveryType.document) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Printing (${_pagesController.text} pages)"),
                Text("KES ${(int.tryParse(_pagesController.text) ?? 0) * DeliveryService.PRINT_PRICE_PER_PAGE}"),
              ],
            ),
          ],
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Total Price", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              Text("KES $_calculatedPrice", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: StDeliTheme.primaryGreen)),
            ],
          ),
        ],
      ),
    );
  }
}
