import 'dart:typed_data';
import '../validation/password_policy.dart';
import 'package:flutter/foundation.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

/// Thin wrapper around the Supabase client used across the app.
/// Call [SupabaseService.init] once in main() before runApp().
class SupabaseService {
  SupabaseService._();

  static final profileRevision = ValueNotifier<int>(0);

  static SupabaseClient get client => Supabase.instance.client;

  static Future<void> init() async {
    await Supabase.initialize(
      url: 'https://sldjrjmlvboqqnzpsxsy.supabase.co',
      publishableKey: 'sb_publishable_goilsZcRhU8rzLowAmIbaQ_iSFm1ZPS',
    );
  }

  // ---------------- Auth ----------------

  static Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) {
    return client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  static Future<AuthResponse> signUp({
    required String fullName,
    required String email,
    required String password,
  }) {
    return client.auth.signUp(
      email: email,
      password: password,
      data: {'full_name': fullName},
    );
  }

  static String? _recoveryUserId;

  static Future<void> sendPasswordReset(String email) async {
    _recoveryUserId = null;
    await client.auth.resetPasswordForEmail(email.trim());
  }

  static Future<void> verifyPasswordResetOtp(String email, String token) async {
    _recoveryUserId = null;
    final response = await client.auth.verifyOTP(
      email: email.trim(), token: token.trim(), type: OtpType.recovery,
    );
    if (response.session == null || response.user == null) {
      throw StateError('Verification failed. Request a new code.');
    }
    _recoveryUserId = response.user!.id;
  }

  static Future<void> setRecoveredPassword(String password) async {
    final error = validateNewPassword(password);
    if (error != null) throw ArgumentError(error);
    if (_recoveryUserId == null || currentUser?.id != _recoveryUserId) {
      throw StateError('Verify your email code first.');
    }
    await client.auth.updateUser(UserAttributes(password: password));
    _recoveryUserId = null;
  }

  static Future<void> endPasswordRecovery() async {
    _recoveryUserId = null;
    await client.auth.signOut(scope: SignOutScope.local);
  }

  static Future<void> signOut() {
    _recoveryUserId = null;
    return client.auth.signOut();
  }

  static Future<void> updateFullName(String fullName) async {
    final userId = currentUser!.id;

    await client.from('profiles').upsert({
      'id': userId,
      'full_name': fullName.trim(),
    });
    profileRevision.value++;
  }

  static User? get currentUser => client.auth.currentUser;

  /// Read the signed-in account, never a demo user's name.
  static Future<String> getMyFullName() async {
    final user = currentUser;
    if (user == null) return '';
    final metadataName = (user.userMetadata?['full_name'] as String? ?? '').trim();
    try {
      final row = await client.from('profiles').select('full_name')
          .eq('id', user.id).maybeSingle();
      final name = (row?['full_name'] as String? ?? '').trim();
      return name.isNotEmpty ? name : metadataName;
    } catch (_) {
      return metadataName;
    }
  }


// ---------------- User profiles and roles ----------------
  static Future<void> setRole(
  String role, {
  required String fullName,
}) async {
  final user = currentUser!;

  await client.from('profiles').upsert({
    'id': user.id,
    'role': role,
    'full_name': fullName,
  });
}


  /// Reads back the current user's role ('help_seeker' or 'volunteer'),
  /// or null if no profile row / role has been set yet.
  static Future<String?> getMyRole() async {
    final userId = currentUser?.id;

    if (userId == null) return null;

    final row = await client
        .from('profiles')
        .select('role')
        .eq('id', userId)
        .maybeSingle();

    return row?['role'] as String?;
  }

  /// Returns the current Volunteer's application status.
  /// Possible values: pending_review, approved, or rejected.
  static Future<String?> getMyVolunteerApplicationStatus() async {
    final userId = currentUser?.id;

    if (userId == null) return null;

    final row = await client
        .from('volunteer_profiles')
        .select('status')
        .eq('user_id', userId)
        .maybeSingle();

    return row?['status'] as String?;
  }

  // ---------------- Volunteer application details ----------------

  /// Returns the current Volunteer's application status together with
  /// the rejection reason provided by the Admin, when available.
  ///
  /// Returned data can contain:
  /// status: pending_review, approved, or rejected
  /// rejection_reason: the reason entered by the Admin
  static Future<Map<String, dynamic>?> getMyVolunteerApplication() async {
    final userId = currentUser?.id;

    if (userId == null) return null;

    final row = await client
        .from('volunteer_profiles')
        .select('status, rejection_reason')
        .eq('user_id', userId)
        .maybeSingle();

    if (row == null) return null;

    return Map<String, dynamic>.from(row);
  }

  static Future<Map<String, dynamic>> loadProfileForEdit({
    required String role,
  }) async {
    final userId = currentUser?.id;

    if (userId == null) return {};

    final profileRow = await client
        .from('profiles')
        .select('full_name')
        .eq('id', userId)
        .maybeSingle();

    Map<String, dynamic> data = {
      'full_name': profileRow?['full_name'] as String?,
    };

    if (role == 'help_seeker') {
      final row = await client
          .from('help_seeker_profiles')
          .select(
            'chronic_condition, preferred_language, description',
          )
          .eq('user_id', userId)
          .maybeSingle();

      data = {
        ...data,
        'condition': row?['chronic_condition'] as String?,
        'preferred_language': row?['preferred_language'] as String?,
        'description': row?['description'] as String?,
      };
    } else {
      final row = await client
          .from('volunteer_profiles')
          .select(
            'condition_experience, preferred_language, experience_description',
          )
          .eq('user_id', userId)
          .maybeSingle();

      data = {
        ...data,
        'condition': row?['condition_experience'] as String?,
        'preferred_language': row?['preferred_language'] as String?,
        'experience': row?['experience_description'] as String?,
      };
    }

    return data;
  }

  /// Completes the Help Seeker registration form.
  static Future<void> submitHelpSeekerRegistration({
    required String chronicCondition,
    required String preferredLanguage,
    String? description,
  }) async {
    final userId = currentUser!.id;

    await client.from('help_seeker_profiles').upsert({
      'user_id': userId,
      'chronic_condition': chronicCondition,
      'preferred_language': preferredLanguage,
      'description': description,
    });
  }

  static Future<void> updateHelpSeekerProfile({
    required String chronicCondition,
    required String preferredLanguage,
    String? description,
  }) async {
    final userId = currentUser!.id;

    await client.from('help_seeker_profiles').upsert({
      'user_id': userId,
      'chronic_condition': chronicCondition,
      'preferred_language': preferredLanguage,
      'description': description,
    });
  }

  static Future<void> updateVolunteerProfile({
    required String conditionExperience,
    required String preferredLanguage,
    required String experienceDescription,
  }) async {
    final userId = currentUser!.id;

    await client.from('volunteer_profiles').upsert({
      'user_id': userId,
      'condition_experience': conditionExperience,
      'preferred_language': preferredLanguage,
      'experience_description': experienceDescription,
    });
  }

  /// Uploads a verification document (as raw bytes, which works on every
  /// platform including web) and returns its public URL.
  static Future<String> uploadVerificationDocument({
    required List<int> fileBytes,
    required String fileName,
  }) async {
    final userId = currentUser!.id;

    final path =
        '$userId/${DateTime.now().millisecondsSinceEpoch}_$fileName';

    await client.storage
        .from('verification-documents')
        .uploadBinary(
          path,
          Uint8List.fromList(fileBytes),
        );

    return client.storage
        .from('verification-documents')
        .getPublicUrl(path);
  }

  /// Completes the Volunteer registration form.
  /// Pass [verificationDocumentUrl] from [uploadVerificationDocument]
  /// if the user attached a file.
  static Future<void> submitVolunteerRegistration({
    required String conditionExperience,
    required String preferredLanguage,
    required String experienceDescription,
    String? verificationDocumentUrl,
  }) async {
    final userId = currentUser!.id;

    await client.from('volunteer_profiles').upsert({
      'user_id': userId,
      'condition_experience': conditionExperience,
      'preferred_language': preferredLanguage,
      'experience_description': experienceDescription,
      'verification_document_url': verificationDocumentUrl,
      'status': 'pending_review',
    });
  }

  // ---------------- Volunteer reapplication ----------------

  /// Resubmits an existing Volunteer application after rejection.
  ///
  /// This updates the existing application without creating a new account.
  /// The application status is returned to pending_review so the Admin
  /// can review it again.
  ///
  /// If [verificationDocumentUrl] is null, the previous verification
  /// document is kept and is not overwritten.
  static Future<void> resubmitVolunteerApplication({
    required String conditionExperience,
    required String preferredLanguage,
    required String experienceDescription,
    String? verificationDocumentUrl,
  }) async {
    final userId = currentUser!.id;

    // Prepare the fields that must always be updated
    // when the Volunteer submits a new application.
    final Map<String, dynamic> updatedData = {
      'condition_experience': conditionExperience,
      'preferred_language': preferredLanguage,
      'experience_description': experienceDescription,

      // The new application must be reviewed again by the Admin.
      'status': 'pending_review',

      // Remove the reason from the previous rejected application.
      'rejection_reason': '',
    };

    // Only replace the verification document if the Volunteer
    // uploaded a new one during reapplication.
    //
    // If no new document was selected, the old document remains
    // unchanged in the database.
    if (verificationDocumentUrl != null) {
      updatedData['verification_document_url'] =
          verificationDocumentUrl;
    }

    // Update the existing Volunteer application.
    await client
        .from('volunteer_profiles')
        .update(updatedData)
        .eq('user_id', userId);
  }
    // ---------------- Admin ----------------
    // These methods are used by the Admin to review and decide
    // on Volunteer applications.

    /// Returns every Volunteer application, newest first,
    /// together with the Volunteer's name from the profiles table.
    static Future<List<Map<String, dynamic>>>
        getVolunteerApplications() async {
      final response = await client
          .from('volunteer_profiles')
          .select('''
            *,
            profiles!volunteer_profiles_user_id_fkey1 (
                full_name
            )
          ''')
          .order(
            'created_at',
            ascending: false,
          );

      return List<Map<String, dynamic>>.from(response);
    }

    /// Marks one Volunteer's application as approved.
    /// Any previous rejection reason is removed.
    static Future<void> approveVolunteerApplication(
      String userId,
    ) async {
      await client
          .from('volunteer_profiles')
          .update({
            'status': 'approved',
            'rejection_reason': null,
          })
          .eq('user_id', userId);
    }

    /// Marks one Volunteer's application as rejected
    /// and stores the Admin's reason.
    static Future<void> rejectVolunteerApplication({
      required String userId,
      required String reason,
    }) async {
      await client
          .from('volunteer_profiles')
          .update({
            'status': 'rejected',
            'rejection_reason': reason,
          })
          .eq('user_id', userId);
    }
}
