import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/vmurugan_logo.dart';

/// Scheme-wise Report Screen
class SchemeWiseReportScreen extends StatefulWidget {
  final String? customerPhone;

  const SchemeWiseReportScreen({Key? key, this.customerPhone}) : super(key: key);

  @override
  State<SchemeWiseReportScreen> createState() => _SchemeWiseReportScreenState();
}

class _SchemeWiseReportScreenState extends State<SchemeWiseReportScreen> {
  bool _isLoading = false;
  List<Map<String, dynamic>> _schemes = [];

  @override
  void initState() {
    super.initState();
    _loadSchemes();
  }

  Future<void> _loadSchemes() async {
    setState(() => _isLoading = true);
    try {
      // TODO: Implement API call
      await Future.delayed(const Duration(seconds: 1));
      setState(() {
        _schemes = [
          {
            'scheme_id': 'GP_P1',
            'scheme_type': 'GOLDPLUS',
            'total_invested': 12000.0,
            'total_grams': 1.2,
            'completed_installments': 12,
            'status': 'COMPLETED',
          },
          {
            'scheme_id': 'GF_P1',
            'scheme_type': 'GOLDFLEXI',
            'total_invested': 5000.0,
            'total_grams': 0.5,
            'completed_installments': 5,
            'status': 'ACTIVE',
          },
        ];
      });
    } catch (e) {
      print('❌ Error loading schemes: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const VMuruganAppBarLogo(
          logoSize: 28,
          fontSize: 16,
          textColor: AppColors.primaryGreen,
        ),
        backgroundColor: AppColors.primaryGold,
        foregroundColor: AppColors.primaryGreen,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.primaryGreen),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _schemes.length,
              itemBuilder: (context, index) {
                final scheme = _schemes[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              scheme['scheme_id'],
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: scheme['status'] == 'ACTIVE'
                                    ? Colors.green.withOpacity(0.1)
                                    : Colors.blue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                scheme['status'],
                                style: TextStyle(
                                  fontSize: 12,
                                  color: scheme['status'] == 'ACTIVE'
                                      ? Colors.green
                                      : Colors.blue,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          scheme['scheme_type'],
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                        const Divider(),
                        _buildRow('Total Invested', '₹${scheme['total_invested'].toStringAsFixed(2)}'),
                        _buildRow('Total Grams', '${scheme['total_grams'].toStringAsFixed(4)} g'),
                        _buildRow('Payments', '${scheme['completed_installments']}'),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14)),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

