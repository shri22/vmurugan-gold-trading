import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_border_radius.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/customer_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../main.dart';

class TermsConditionsScreen extends StatefulWidget {
  final bool showAsUpdate; // true if showing to existing user, false for onboarding

  const TermsConditionsScreen({
    super.key,
    this.showAsUpdate = false,
  });

  @override
  State<TermsConditionsScreen> createState() => _TermsConditionsScreenState();
}

class _TermsConditionsScreenState extends State<TermsConditionsScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _hasScrolledToBottom = false;
  bool _isAccepting = false;
  bool _isEnglish = true; // Default to English

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 50) {
      if (!_hasScrolledToBottom) {
        setState(() {
          _hasScrolledToBottom = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _handleAccept() async {
    // Mode 1: New User Registration (Just acknowledging)
    if (!widget.showAsUpdate) {
      if (mounted) {
        Navigator.of(context).pop(true); // Return 'true' to indicate terms were read/accepted
      }
      return;
    }

    // Mode 2: Existing User (Direct backend update required)
    setState(() {
      _isAccepting = true;
    });

    try {
      final user = await AuthService.getCurrentLoggedInUser();
      final phone = user?['phone'];

      if (phone != null) {
        // 1. Save to backend for proof
        await ApiService.acceptTerms(phone);
        
        // 2. Save locally to stop showing this screen
        await CustomerService.setTermsAccepted(true);

        if (mounted) {
          // Navigate to Home
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const HomePage()),
            (route) => false,
          );
        }
      } else {
        throw Exception('User session not found. Please log in again.');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAccepting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: const Text('Terms & Conditions'),
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: AppColors.primaryGold,
        automaticallyImplyLeading: false, // Force them to accept
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: TextButton(
              onPressed: () => setState(() => _isEnglish = true),
              child: Text(
                'EN',
                style: TextStyle(
                  color: _isEnglish ? AppColors.primaryGold : AppColors.white.withOpacity(0.5),
                  fontWeight: _isEnglish ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: TextButton(
              onPressed: () => setState(() => _isEnglish = false),
              child: Text(
                'தமிழ்',
                style: TextStyle(
                  color: !_isEnglish ? AppColors.primaryGold : AppColors.white.withOpacity(0.5),
                  fontWeight: !_isEnglish ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Header summary info
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            color: AppColors.lightGold.withOpacity(0.3),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: AppColors.darkGold),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _isEnglish 
                      ? (widget.showAsUpdate 
                          ? 'We have updated our terms. Please read and accept to continue.'
                          : 'Please read our terms carefully before joining.')
                      : (widget.showAsUpdate
                          ? 'நாங்கள் எங்களது விதிமுறைகளை புதுப்பித்துள்ளோம். தொடர தயவுசெய்து படித்து ஏற்றுக்கொள்க.'
                          : 'சேருவதற்கு முன் எங்களது விதிமுறைகளை கவனமாகப் படிக்கவும்.'),
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Main terms text
          Expanded(
            child: Scrollbar(
              controller: _scrollController,
              thumbVisibility: true,
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle(_isEnglish 
                      ? 'Terms & Conditions – V. Murugan Jewellery' 
                      : 'விதிமுறைகள் மற்றும் நிபந்தனைகள் – வி. முருகன் ஜுவல்லரி'),
                    const SizedBox(height: 16),
                    
                    _buildSectionHeader(_isEnglish ? '1. General Terms' : '1. பொதுவான விதிமுறைகள்'),
                    _buildSectionText(_isEnglish
                      ? 'The "V. Murugan Plus" and "V. Murugan Flexi" schemes are voluntary savings schemes provided by V. Murugan Jewellery to enable customers to purchase physical gold or silver.\n\nBy enrolling in any scheme or making a payment through this application, the customer agrees to be bound by these Terms and Conditions.'
                      : '"வி. முருகன் பிளஸ்" மற்றும் "வி. முருகன் பிளெக்ஸி" திட்டங்கள் வாடிக்கையாளர்கள் தங்கம் அல்லது வெள்ளியை வாங்குவதற்கு உதவும் வகையில் வி. முருகன் ஜுவல்லரியால் வழங்கப்படும் விருப்ப சேமிப்பு திட்டங்களாகும்.\n\nஎந்தவொரு திட்டத்திலும் சேருவதன் மூலம் அல்லது இந்த செயலி மூலம் பணம் செலுத்துவதன் மூலம், வாடிக்கையாளர் இந்த விதிமுறைகள் மற்றும் நிபந்தனைகளுக்கு கட்டுப்பட ஒப்புக்கொள்கிறார்.'),

                    _buildSectionHeader(_isEnglish ? '2. Payment & Installments' : '2. பணம் செலுத்துதல் மற்றும் தவணைகள்'),
                    _buildHighlightedText(_isEnglish
                      ? 'Non-Refundable Policy: All payments made towards any scheme are strictly for the purchase of gold or silver. Under no circumstances will the amount paid be refunded in cash or via bank transfer.'
                      : 'திரும்பப் பெற முடியாத கொள்கை: எந்தவொரு திட்டத்திற்கும் செலுத்தப்படும் அனைத்துத் தொகைகளும் தங்கம் அல்லது வெள்ளி வாங்குவதற்காக மட்டுமே. எந்தச் சூழ்நிலையிலும் செலுத்திய தொகை ரொக்கமாகவோ அல்லது வங்கிப் பரிமாற்றம் மூலமாகவோ திருப்பித் தரப்பட மாட்டாது.'),
                    _buildSectionText(_isEnglish
                      ? '• The minimum duration for any scheme is 12 months.\n• Plus Scheme (Fixed): Customers must pay a fixed monthly installment. Gold/Silver weight will be credited to the customer\'s account.\n• Flexi Scheme (Variable): Customers can choose to pay any amount at their convenience. The total accumulated amount will be used to purchase gold/silver at the prevailing rate on the day of redemption.'
                      : '• எந்தவொரு திட்டத்திற்கும் குறைந்தபட்ச காலம் 12 மாதங்கள் ஆகும்.\n• பிளஸ் திட்டம் (நிலையானது): வாடிக்கையாளர்கள் நிலையான மாதாந்திர தவணையைச் செலுத்த வேண்டும். தங்கம்/வெள்ளி எடை வாடிக்கையாளரின் கணக்கில் வரவு வைக்கப்படும்.\n• பிளெக்ஸி திட்டம் (மாறக்கூடியது): வாடிக்கையாளர்கள் தங்களுக்கு வசதியான எந்தத் தொகையையும் செலுத்தலாம். திரட்டப்பட்ட மொத்தத் தொகை, நகை எடுக்கும் நாளில் உள்ள விலையில் தங்கம்/வெள்ளி வாங்கப் பயன்படுத்தப்படும்.'),

                    _buildSectionHeader(_isEnglish ? '3. Scheme Maturity & Redemption' : '3. திட்ட முதிர்வு மற்றும் நகை எடுத்தல்'),
                    _buildHighlightedText(_isEnglish
                      ? '12-Month Lock-in: Redemption is only permitted after the completion of 12 successful months from the date of the first installment.'
                      : '12-மாத காலக் கட்டுப்பாடு: முதல் தவணை செலுத்திய தேதியிலிருந்து 12 மாதங்கள் வெற்றிகரமாக முடிந்த பிறகு மட்டுமே நகை எடுக்க அனுமதிக்கப்படும்.'),
                    _buildSectionText(_isEnglish
                      ? '• Physical Redemption Only: The accumulated gold/silver weight or value can only be redeemed for Physical Jewellery or Ornaments available at the V. Murugan Jewellery showroom.\n• No Cash Redemption: This scheme is not a financial deposit or investment of money. It is a pre-payment for jewellery. Cash refunds are strictly prohibited.\n• Making Charges & Wastage: Customers who successfully complete 12 full installments are entitled to special benefits on Making Charges/Wastage as per the specific scheme offer at the time of maturity.'
                      : '• நகையாக மட்டுமே எடுக்க முடியும்: திரட்டப்பட்ட தங்கம்/வெள்ளி எடை அல்லது மதிப்பை வி. முருகன் ஜுவல்லரி ஷோரூமில் உள்ள நகைகளாக மட்டுமே எடுக்க முடியும்.\n• ரொக்கமாகப் பெற முடியாது: இந்தத் திட்டம் ஒரு நிதி வைப்பு அல்லது முதலீடு அல்ல. இது நகைக்கான முன்-பணம் செலுத்துதல் மட்டுமே. ரொக்கத்தைத் திருப்பித் தருவது முற்றிலும் தடைசெய்யப்பட்டுள்ளது.\n• செய்கூலி மற்று சேதாரம்: 12 முழுத் தவணைகளை வெற்றிகரமாக முடிக்கும் வாடிக்கையாளர்கள், முதிர்வு காலத்தில் அந்தந்தத் திட்டத்தின் சலுகையின்படி செய்கூலி/சேதாரத்தில் சிறப்புப் பயன்களைப் பெறத் தகுதியுடையவர்கள்.'),

                    _buildSectionHeader(_isEnglish ? '4. Defaults & Discontinuation' : '4. தவணை தவறவிடுதல் மற்றும் நிறுத்துதல்'),
                    _buildSectionText(_isEnglish
                      ? '• If a customer fails to pay an installment in the Plus scheme, the maturity date will be extended by one month for every payment missed.\n• In case of early discontinuation (before 12 months), the customer may redeem physical gold/silver for the value paid so far, but will not be eligible for any scheme benefits (such as making charge waivers).'
                      : '• பிளஸ் திட்டத்தில் வாடிக்கையாளர் தவணை செலுத்தத் தவறினால், தவறிய ஒவ்வொரு தவணைக்கும் முதிர்வு தேதி ஒரு மாதம் நீட்டிக்கப்படும்.\n• இடையில் நிறுத்தினால் (12 மாதங்களுக்கு முன்), வாடிக்கையாளர் இதுவரை செலுத்திய மதிப்பிற்கு தங்கம்/வெள்ளி நகைகளை எடுத்துக் கொள்ளலாம், ஆனால் திட்டத்தின் எந்தப் பயன்களையும் (செய்கூலி தள்ளுபடி போன்றவை) பெற முடியாது.'),

                    _buildSectionHeader(_isEnglish ? '5. Taxes & KYC' : '5. வரிகள் மற்றும் கே.ஒய்.சி'),
                    _buildSectionText(_isEnglish
                      ? '• GST: Goods and Services Tax (GST) as per Government of India norms (currently 3%).\n• KYC: Valid Government-issued ID proof (Aadhar Card, PAN Card, etc.) is mandatory for enrollment and mandatory for redemption if the value exceeds statutory limits prescribed by the Government.'
                      : '• ஜிஎஸ்டி: இந்திய அரசு விதிமுறைகளின்படி ஜிஎஸ்டி (தற்போது 3%).\n• கே.ஒய்.சி: திட்டத்தில் சேருவதற்கும் மற்றும் அரசாங்கம் நிர்ணயித்துள்ள வரம்பிற்கு மேல் நகை எடுக்கும்போதும் செல்லுபடியாகும் அரசு அடையாளச் சான்று (ஆதார் கார்டு, பான் கார்டு போன்றவை) கட்டாயமாகும்.'),
                    
                    const SizedBox(height: 40),
                    if (!_hasScrolledToBottom)
                      Center(
                        child: Text(
                          _isEnglish 
                            ? 'Please scroll to the bottom to accept' 
                            : 'ஏற்றுக்கொள்ள தயவுசெய்து கீழே வரை செல்லவும்',
                          style: const TextStyle(
                            color: AppColors.error,
                            fontWeight: FontWeight.bold,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),

          // Bottom Action Bar
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Checkbox(
                        value: _hasScrolledToBottom && !_isAccepting,
                        onChanged: null, // Read-only checkbox
                        activeColor: AppColors.primaryGreen,
                      ),
                      Expanded(
                        child: Text(
                          _isEnglish
                            ? 'I have read and agree to all the Terms & Conditions mentioned above.'
                            : 'மேற்கூறிய அனைத்து விதிமுறைகள் மற்றும் நிபந்தனைகளை நான் படித்து ஒப்புக்கொள்கிறேன்.',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: (_hasScrolledToBottom && !_isAccepting) ? _handleAccept : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGold,
                        foregroundColor: AppColors.black,
                        disabledBackgroundColor: Colors.grey.shade300,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppBorderRadius.md),
                        ),
                      ),
                      child: _isAccepting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.black),
                          )
                        : Text(
                            widget.showAsUpdate
                              ? (_isEnglish ? 'ACCEPT & CONTINUE' : 'ஏற்றுக்கொண்டு தொடர்க')
                              : (_isEnglish ? 'I HAVE READ & AGREE' : 'நான் படித்து ஒப்புக்கொள்கிறேன்'),
                            style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2),
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: AppColors.primaryGreen,
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: AppColors.darkGold,
        ),
      ),
    );
  }

  Widget _buildSectionText(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        height: 1.5,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildHighlightedText(String text) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.05),
        border: Border(left: BorderSide(color: AppColors.error, width: 4)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          height: 1.5,
          fontWeight: FontWeight.w600,
          color: AppColors.error,
        ),
      ),
    );
  }
}
