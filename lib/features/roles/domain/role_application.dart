import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_template/shared/photos/photo_picker.dart';

/// The roles that apply from the phone. The others (event, organizer,
/// investor) still apply on the web.
const appliesInApp = <String>{
  'serviceFoxer',
  'performerFoxer',
  'gearFoxer',
  'venueFoxer',
};

/// The documents a Foxer application asks for. [field] is the name the API
/// reads the file under.
enum KycDocument {
  validId('validId1'),
  nbi('nbiFile'),
  tinId('tinIdFile'),
  birPermit('birPermitFile'),
  selfie('selfieFile');

  const KycDocument(this.field);

  final String field;
}

/// What a person fills in to apply as a Talent, Performer, Gear or Venue
/// Foxer.
class RoleApplicationDraft extends Equatable {
  const RoleApplicationDraft({
    required this.roleType,
    this.businessName = '',
    this.contactNumber = '',
    this.address = '',
    this.description = '',
    this.types = '',
    this.portfolio = '',
    this.experience = '',
    this.nbiNumber = '',
    this.tinNumber = '',
    this.specializations = const [],
    this.documents = const {},
  });

  final String roleType;

  /// Gear and venue.
  final String businessName;

  /// Venue only: how to reach them, where the venues are, and a few words
  /// about them (optional).
  final String contactNumber;
  final String address;
  final String description;

  /// What they offer, as the person typed it, separated by commas: the kinds
  /// of service, performance or gear.
  final String types;

  /// Links to their work, separated by commas. Not for gear.
  final String portfolio;

  /// Years, as typed. Not for gear.
  final String experience;
  final String nbiNumber;
  final String tinNumber;

  /// Up to three, picked from the role's categories.
  final List<String> specializations;
  final Map<KycDocument, PickedPhoto> documents;

  bool get isGear => roleType == 'gearFoxer';
  bool get isVenue => roleType == 'venueFoxer';

  static const maxSpecializations = 3;

  static List<String> split(String value) => [
        for (final s in value.split(','))
          if (s.trim().isNotEmpty) s.trim(),
      ];

  /// Digits only, and no more of them than the API takes.
  static String digits(String value, int max) {
    final d = value.replaceAll(RegExp(r'\D'), '');
    return d.length > max ? d.substring(0, max) : d;
  }

  int? get years {
    final n = int.tryParse(experience.trim());
    return n != null && n >= 0 && n <= 100 ? n : null;
  }

  /// What the API asks for before it takes the application. It also wants the
  /// documents, as the web does.
  bool get isComplete =>
      (isVenue
          ? businessName.trim().isNotEmpty &&
              contactNumber.trim().isNotEmpty &&
              address.trim().isNotEmpty &&
              tinNumber.isNotEmpty
          : split(types).isNotEmpty &&
              (isGear
                  ? businessName.trim().isNotEmpty
                  : years != null && nbiNumber.isNotEmpty)) &&
      KycDocument.values.every(documents.containsKey);

  RoleApplicationDraft copyWith({
    String? businessName,
    String? contactNumber,
    String? address,
    String? description,
    String? types,
    String? portfolio,
    String? experience,
    String? nbiNumber,
    String? tinNumber,
    List<String>? specializations,
    Map<KycDocument, PickedPhoto>? documents,
  }) =>
      RoleApplicationDraft(
        roleType: roleType,
        businessName: businessName ?? this.businessName,
        contactNumber: contactNumber ?? this.contactNumber,
        address: address ?? this.address,
        description: description ?? this.description,
        types: types ?? this.types,
        portfolio: portfolio ?? this.portfolio,
        experience: experience ?? this.experience,
        nbiNumber: nbiNumber ?? this.nbiNumber,
        tinNumber: tinNumber ?? this.tinNumber,
        specializations: specializations ?? this.specializations,
        documents: documents ?? this.documents,
      );

  /// The JSON the API reads from the `data` field, the way the web sends it.
  Map<String, dynamic> toData() => {
        if (isVenue) ...{
          'businessName': businessName.trim(),
          'contactNumber': contactNumber.trim(),
          'address': address.trim(),
          if (description.trim().isNotEmpty) 'description': description.trim(),
        } else if (isGear) ...{
          'businessName': businessName.trim(),
          'assetTypes': split(types),
        } else ...{
          'experience': years,
          'nbiClearanceIdNumber': nbiNumber,
          if (roleType == 'performerFoxer')
            'performerTypes': split(types)
          else
            'serviceTypes': split(types),
          'portfolioUrls': split(portfolio),
        },
        if (tinNumber.isNotEmpty) 'tinNumber': tinNumber,
        'specializations': specializations,
      };

  /// The whole application as the API takes it: the role, the data, and each
  /// document as a file.
  FormData toForm() => FormData.fromMap({
        'roleType': roleType,
        'data': jsonEncode(toData()),
        for (final e in documents.entries)
          e.key.field: MultipartFile.fromBytes(
            e.value.bytes,
            filename: e.value.name,
          ),
      });

  @override
  List<Object?> get props => [
        roleType,
        businessName,
        contactNumber,
        address,
        description,
        types,
        portfolio,
        experience,
        nbiNumber,
        tinNumber,
        specializations,
        documents.keys.toList(),
      ];
}

/// The categories a role can declare as specializations, as the API names
/// them, in the web's order.
List<String> specializationOptions(String roleType) => switch (roleType) {
      'venueFoxer' => const [
          'indoor',
          'outdoor',
          'hotel',
          'beach_resort',
          'garden',
          'mix',
          'other',
        ],
      'gearFoxer' => const [
          'furnitures',
          'sound_system',
          'decorations',
          'other',
        ],
      'performerFoxer' => const [
          'photography',
          'videography',
          'dj',
          'live_band',
          'mc',
        ],
      _ => const ['design', 'catering', 'service_staff', 'other'],
    };
