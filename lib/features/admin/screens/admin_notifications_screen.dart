import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_border_radius.dart';
import '../../../core/widgets/gradient_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../notifications/models/notification_model.dart';
import '../../notifications/services/notification_service.dart';

class AdminNotificationsScreen extends StatefulWidget {
  const AdminNotificationsScreen({super.key});

  @override
  State<AdminNotificationsScreen> createState() => _AdminNotificationsScreenState();
}

class _AdminNotificationsScreenState extends State<AdminNotificationsScreen> {
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _actionUrlController = TextEditingController();
  
  NotificationType _selectedType = NotificationType.adminMessage;
  NotificationPriority _selectedPriority = NotificationPriority.normal;
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    _imageUrlController.dispose();
    _actionUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Send Notifications'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: AppSpacing.xl),
            _buildNotificationForm(),
            const SizedBox(height: AppSpacing.xl),
            _buildPreviewSection(),
            const SizedBox(height: AppSpacing.xl),
            _buildSendButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary.withOpacity(0.1), Colors.transparent],
        ),
        borderRadius: BorderRadius.circular(AppBorderRadius.lg),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.admin_panel_settings, color: AppColors.primary, size: 32),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Admin Notification Center',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Send important notifications to all customers. Use this feature responsibly for announcements, updates, and important information.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationForm() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppBorderRadius.lg),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Notification Details',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            
            // Notification Type
            _buildDropdownField(
              label: 'Notification Type',
              value: _selectedType,
              items: [
                NotificationType.adminMessage,
                NotificationType.announcement,
                NotificationType.systemUpdate,
                NotificationType.maintenance,
                NotificationType.promotional,
                NotificationType.general,
              ],
              onChanged: (value) => setState(() => _selectedType = value!),
              itemBuilder: (type) => Text(type.displayName),
            ),
            
            const SizedBox(height: AppSpacing.lg),
            
            // Priority
            _buildDropdownField(
              label: 'Priority',
              value: _selectedPriority,
              items: NotificationPriority.values,
              onChanged: (value) => setState(() => _selectedPriority = value!),
              itemBuilder: (priority) => Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: _getPriorityColor(priority),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(priority.displayName),
                ],
              ),
            ),
            
            const SizedBox(height: AppSpacing.lg),
            
            // Title
            CustomTextField(
              controller: _titleController,
              label: 'Notification Title',
              hint: 'Enter notification title',
              maxLength: 100,
            ),
            
            const SizedBox(height: AppSpacing.lg),
            
            // Message
            CustomTextField(
              controller: _messageController,
              label: 'Message',
              hint: 'Enter notification message',
              maxLines: 4,
              maxLength: 500,
            ),
            
            const SizedBox(height: AppSpacing.lg),
            
            // Optional fields
            ExpansionTile(
              title: const Text('Optional Settings'),
              children: [
                const SizedBox(height: AppSpacing.md),
                CustomTextField(
                  controller: _imageUrlController,
                  label: 'Image URL (Optional)',
                  hint: 'https://example.com/image.jpg',
                ),
                const SizedBox(height: AppSpacing.md),
                CustomTextField(
                  controller: _actionUrlController,
                  label: 'Action URL (Optional)',
                  hint: 'https://example.com/action',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdownField<T>({
    required String label,
    required T value,
    required List<T> items,
    required ValueChanged<T?> onChanged,
    required Widget Function(T) itemBuilder,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        DropdownButtonFormField<T>(
          value: value,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppBorderRadius.md),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
          ),
          items: items.map((item) => DropdownMenuItem<T>(
            value: item,
            child: itemBuilder(item),
          )).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildPreviewSection() {
    if (_titleController.text.isEmpty && _messageController.text.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppBorderRadius.lg),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Preview',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            _buildNotificationPreview(),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationPreview() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(AppBorderRadius.md),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _getPriorityColor(_selectedPriority).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Text(
                _selectedType.icon,
                style: const TextStyle(fontSize: 20),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_titleController.text.isNotEmpty)
                  Text(
                    _titleController.text,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                if (_messageController.text.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    _messageController.text,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
                const SizedBox(height: AppSpacing.xs),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Just now',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[500],
                      ),
                    ),
                    if (_selectedPriority == NotificationPriority.high ||
                        _selectedPriority == NotificationPriority.urgent)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _getPriorityColor(_selectedPriority),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          _selectedPriority.displayName.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSendButton() {
    return SizedBox(
      width: double.infinity,
      child: GradientButton(
        text: _isLoading ? 'Sending...' : 'Send Notification to All Customers',
        onPressed: _isLoading || _titleController.text.isEmpty || _messageController.text.isEmpty
            ? null
            : _sendNotification,
        gradient: AppColors.primaryGradient,
        icon: _isLoading ? null : Icons.send,
        isFullWidth: true,
      ),
    );
  }

  Color _getPriorityColor(NotificationPriority priority) {
    switch (priority) {
      case NotificationPriority.low:
        return Colors.grey;
      case NotificationPriority.normal:
        return AppColors.primary;
      case NotificationPriority.high:
        return Colors.orange;
      case NotificationPriority.urgent:
        return Colors.red;
    }
  }

  Future<void> _sendNotification() async {
    if (_titleController.text.isEmpty || _messageController.text.isEmpty) {
      _showErrorDialog('Please fill in both title and message fields.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Create admin notification
      await NotificationTemplates.adminMessage(
        title: _titleController.text.trim(),
        message: _messageController.text.trim(),
        priority: _selectedPriority,
        imageUrl: _imageUrlController.text.trim().isEmpty ? null : _imageUrlController.text.trim(),
        actionUrl: _actionUrlController.text.trim().isEmpty ? null : _actionUrlController.text.trim(),
      );

      // Show success dialog
      _showSuccessDialog();
      
      // Clear form
      _clearForm();
    } catch (e) {
      _showErrorDialog('Failed to send notification: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _clearForm() {
    _titleController.clear();
    _messageController.clear();
    _imageUrlController.clear();
    _actionUrlController.clear();
    setState(() {
      _selectedType = NotificationType.adminMessage;
      _selectedPriority = NotificationPriority.normal;
    });
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 32),
            SizedBox(width: 12),
            Text('Notification Sent!'),
          ],
        ),
        content: const Text('Your notification has been sent to all customers successfully.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error, color: Colors.red, size: 32),
            SizedBox(width: 12),
            Text('Error'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
