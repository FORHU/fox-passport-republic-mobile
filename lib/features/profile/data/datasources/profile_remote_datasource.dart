import 'package:dio/dio.dart';
import 'package:flutter_template/core/constants/api_endpoints.dart';
import 'package:flutter_template/core/services/api_service.dart';
import 'package:flutter_template/features/messages/data/photo_picker.dart';
import 'package:flutter_template/features/profile/data/models/profile_model.dart';
import 'package:flutter_template/features/profile/domain/entities/profile_update.dart';

/// Talks to the remote API. Knows nothing about state or UI.
abstract class ProfileRemoteDataSource {
  Future<ProfileModel> getProfile();

  Future<void> updateProfile(ProfileUpdate update);

  /// Uploads a photo and returns its public URL.
  Future<String> uploadPhoto(PickedPhoto photo);

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  });

  Future<void> deleteAccount(String password);
}

class ProfileRemoteDataSourceImpl implements ProfileRemoteDataSource {
  ProfileRemoteDataSourceImpl(this._api);

  final ApiService _api;

  @override
  Future<ProfileModel> getProfile() async {
    final data = await _api.get(ApiEndpoints.me);
    return ProfileModel.fromJson((data as Map).cast<String, dynamic>());
  }

  @override
  Future<void> updateProfile(ProfileUpdate update) async {
    await _api.put(ApiEndpoints.profile, update.toJson());
  }

  @override
  Future<String> uploadPhoto(PickedPhoto photo) async {
    final form = FormData.fromMap({
      'file': MultipartFile.fromBytes(photo.bytes, filename: photo.name),
    });
    final body = await _api.post(ApiEndpoints.uploadFile, form);
    final file = body is Map ? body['file'] : null;
    final url = (file is Map ? file['url'] : null) ??
        (body is Map ? body['url'] : null);
    if (url is! String) throw const FormatException('No url in the upload');
    return url;
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    // The API wants the confirmation too, and checks it matches.
    await _api.post(ApiEndpoints.changePassword, {
      'currentPassword': currentPassword,
      'newPassword': newPassword,
      'confirmPassword': newPassword,
    });
  }

  @override
  Future<void> deleteAccount(String password) async {
    await _api.delete(ApiEndpoints.profile, {
      'password': password,
      'confirmation': 'DELETE',
    });
  }
}
