import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/network/api_exception.dart';
import '../../../shared/services/location_service.dart';
import '../../../shared/services/session_store.dart';
import '../data/report_service.dart';

class ReportFormPage extends StatefulWidget {
  const ReportFormPage({super.key});

  static const routeName = '/report-form';

  @override
  State<ReportFormPage> createState() => _ReportFormPageState();
}

class _ReportFormPageState extends State<ReportFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();
  final _reportService = ReportService();
  final _locationService = LocationService();
  final _imagePicker = ImagePicker();

  Uint8List? _pickedImageBytes;
  String? _pickedImageName;
  bool _isLoading = false;
  bool _isDetectingLocation = false;
  bool _isPickingImage = false;
  String? _locationMessage;

  @override
  void initState() {
    super.initState();
    // Load the saved session and try to detect the current location immediately.
    SessionStore.instance.load();
    _detectCurrentLocation();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    super.dispose();
  }

  Future<void> _detectCurrentLocation() async {
    setState(() {
      _isDetectingLocation = true;
      _locationMessage = 'Detecting your location...';
    });

    try {
      // Use GPS coordinates to auto-fill the report location.
      final position = await _locationService.getCurrentPosition();
      if (!mounted) return;

      _latitudeController.text = position.latitude.toStringAsFixed(6);
      _longitudeController.text = position.longitude.toStringAsFixed(6);

      setState(() {
        _locationMessage = 'Location detected successfully.';
      });
    } on LocationServiceException catch (error) {
      if (!mounted) return;
      setState(() {
        _locationMessage = error.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _locationMessage = 'Unable to detect your location right now.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isDetectingLocation = false;
        });
      }
    }
  }

  Future<void> _pickImage() async {
    setState(() => _isPickingImage = true);

    try {
      // Let the user attach an optional photo from the gallery.
      final image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (image == null) return;

      final bytes = await image.readAsBytes();
      if (!mounted) return;

      setState(() {
        _pickedImageBytes = bytes;
        _pickedImageName = image.name;
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Image selection failed: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _isPickingImage = false);
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // The user must be logged in before the backend accepts a report.
    await SessionStore.instance.load();
    if (SessionStore.instance.accessToken == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in before creating a report.')),
      );
      return;
    }

    final latitude = double.tryParse(_latitudeController.text.trim());
    final longitude = double.tryParse(_longitudeController.text.trim());
    if (latitude == null || longitude == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location is required before submitting.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Send the report, location, and optional image to the API.
      await _reportService.createReport(
        description: _descriptionController.text.trim(),
        latitude: latitude,
        longitude: longitude,
        imageBytes: _pickedImageBytes,
        imageName: _pickedImageName,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Report submitted successfully.')),
      );
      Navigator.pop(context);
    } catch (error) {
      if (!mounted) return;
      final message = error is ApiException ? error.message : error.toString();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Report submission failed: $message')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Report Waste')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Submit a waste issue',
                        style: theme.textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Write a short report, add a photo if you have one, and let the phone auto-detect the exact location.',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Report message',
                  hintText: 'Describe the waste problem here',
                ),
                maxLines: 4,
                textInputAction: TextInputAction.newline,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Enter a description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Location',
                              style: theme.textTheme.titleMedium,
                            ),
                          ),
                          TextButton.icon(
                            onPressed: _isDetectingLocation ? null : _detectCurrentLocation,
                            icon: const Icon(Icons.my_location),
                            label: Text(
                              _isDetectingLocation ? 'Detecting...' : 'Use current location',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _locationMessage ?? 'Tap the button to detect your current location.',
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _latitudeController,
                        decoration: const InputDecoration(
                          labelText: 'Latitude',
                          hintText: 'Auto-detected latitude',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Location is required';
                          }
                          if (double.tryParse(value.trim()) == null) {
                            return 'Enter a valid number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _longitudeController,
                        decoration: const InputDecoration(
                          labelText: 'Longitude',
                          hintText: 'Auto-detected longitude',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Location is required';
                          }
                          if (double.tryParse(value.trim()) == null) {
                            return 'Enter a valid number';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Optional photo',
                              style: theme.textTheme.titleMedium,
                            ),
                          ),
                          TextButton.icon(
                            onPressed: _isPickingImage ? null : _pickImage,
                            icon: const Icon(Icons.upload_file),
                            label: Text(
                              _isPickingImage ? 'Opening...' : 'Add image',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _pickedImageName == null
                            ? 'A photo is optional, but it helps admin verify the waste faster.'
                            : 'Selected: $_pickedImageName',
                      ),
                      const SizedBox(height: 16),
                      if (_pickedImageBytes != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.memory(
                            _pickedImageBytes!,
                            height: 180,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        )
                      else
                        Container(
                          height: 140,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: theme.colorScheme.outlineVariant),
                          ),
                          child: Center(
                            child: Text(
                              'No image selected',
                              style: theme.textTheme.bodyMedium,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _isLoading ? null : _submit,
                child: Text(_isLoading ? 'Submitting...' : 'Submit Report'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
