import 'package:flutter/material.dart';
import 'register_screen.dart';

class TermsAndConditionsScreen extends StatelessWidget {
  const TermsAndConditionsScreen({super.key});

  void _acceptTerms(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const RegisterScreen()),
    );
  }

  void _declineTerms(BuildContext context) {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms and Conditions'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CUTPulse Terms and Conditions',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Effective Date: October 2025\n',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),

                  Text(
                    '1. Purpose of the Platform',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'CUTPulse is a professional networking platform designed exclusively for the Central University of Technology (CUT) community. The platform facilitates academic and career-oriented interactions, networking, and sharing of professional updates. '
                    'It is not a personal social media platform and must be used in a manner that aligns with the academic and professional values of the university.\n',
                  ),

                  Text(
                    '2. Acceptable Use',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'By using CUTPulse, you agree to:\n'
                    '- Use the platform solely for professional and academic networking within the CUT community.\n'
                    '- Ensure that all content you post (including text, images, and links) is relevant, respectful, and appropriate to the university environment.\n'
                    '- Avoid posting or sharing content that is:\n'
                    '  • Offensive, discriminatory, or harassing in nature\n'
                    '  • False, misleading, or defamatory\n'
                    '  • Irrelevant to CUT, academics, or professional networking\n'
                    '  • Promoting personal business unrelated to academic or professional growth\n\n'
                    'CUTPulse reserves the right to remove or restrict access to any content that violates these rules and may suspend users who engage in misconduct.\n',
                  ),

                  Text(
                    '3. User Accounts and Responsibilities',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '- Each user is responsible for maintaining the confidentiality of their account credentials.\n'
                    '- Users must provide accurate and truthful information when creating or updating their profiles.\n'
                    '- Accounts are intended for individual use only and may not be shared or transferred.\n'
                    '- Misrepresentation of identity, impersonation, or creation of fake profiles is strictly prohibited.\n',
                  ),

                  Text(
                    '4. Data Privacy and Use',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'CUTPulse collects and stores user information such as names, email addresses, academic details, and activity data for authentication, communication, and personalization purposes.\n'
                    'User data will be used in accordance with CUT’s data protection and privacy policies.\n'
                    'CUTPulse will not sell or share personal data with third parties without consent, except where required by law.\n'
                    'Users are responsible for information they choose to make public on their profiles.\n',
                  ),

                  Text(
                    '5. Intellectual Property',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Users retain ownership of the content they create and post. '
                    'By posting content, users grant CUTPulse a non-exclusive license to display, share, and promote that content within the platform. '
                    'Users may not upload or share content that infringes on the intellectual property rights of others.\n',
                  ),

                  Text(
                    '6. Platform Management',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'CUTPulse administrators reserve the right to:\n'
                    '- Moderate and remove inappropriate content.\n'
                    '- Suspend or terminate accounts that violate these Terms and Conditions.\n'
                    '- Modify or update features, rules, or policies at any time to maintain a safe and professional environment.\n',
                  ),

                  Text(
                    '7. Limitation of Liability',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'CUTPulse and its administrators are not responsible for:\n'
                    '- The accuracy, reliability, or legality of user-generated content.\n'
                    '- Any damages resulting from the use or inability to use the platform.\n'
                    '- Unauthorized access to user accounts due to negligence in safeguarding credentials.\n',
                  ),

                  Text(
                    '8. Amendments',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'CUTPulse reserves the right to revise these Terms and Conditions at any time. '
                    'Continued use of the platform after such updates constitutes acceptance of the revised terms.\n',
                  ),

                  Text(
                    '9. Contact',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'For questions, concerns, or reports of misconduct, contact the CUTPulse administrative team via the CUT IT department or through the in-app support option.\n',
                  ),

                  Divider(),
                  Center(
                    child: Text(
                      '© 2025 CUTPulse | Central University of Technology',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ),
                ],
              ),
            ),
          ),

          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () => _declineTerms(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 30,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text(
                    "Decline",
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
                ElevatedButton(
                  onPressed: () => _acceptTerms(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 30,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text(
                    "Accept",
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
