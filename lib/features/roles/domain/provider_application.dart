import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_template/features/roles/domain/experience.dart';
import 'package:flutter_template/features/roles/domain/role_application.dart';
import 'package:flutter_template/features/roles/domain/work_links.dart';
import 'package:flutter_template/shared/photos/photo_picker.dart';

/// How far a Provider travels for an event. The API stores the name.
enum TravelRange { city, province, anywhere }

/// What a Provider applicant says about one specialty: a line about it and
/// photos of their work.
class ProviderSpecialtyDetail extends Equatable {
  const ProviderSpecialtyDetail({
    this.description = '',
    this.photos = const [],
  });

  final String description;
  final List<PickedPhoto> photos;

  /// A line and at least one photo, as the reviewer needs.
  bool get isDone => description.trim().isNotEmpty && photos.isNotEmpty;

  ProviderSpecialtyDetail copyWith({
    String? description,
    List<PickedPhoto>? photos,
  }) =>
      ProviderSpecialtyDetail(
        description: description ?? this.description,
        photos: photos ?? this.photos,
      );

  @override
  List<Object?> get props => [description, photos.map((p) => p.name).toList()];
}

/// The Provider application, filled in over the wizard's four steps
/// (mobile#487): business, categories, a line and photos per category, then
/// documents.
class ProviderApplicationDraft extends Equatable {
  const ProviderApplicationDraft({
    this.businessName = '',
    this.basedIn = '',
    this.basedInPoint,
    this.travelRange,
    this.experience = '',
    this.claimingExperience = false,
    this.experienceCv,
    this.links = const {},
    this.specializations = const [],
    this.mainSpecialty,
    this.details = const {},
    this.documents = const {},
    this.agreed = false,
  });

  final String businessName;
  final String basedIn;

  /// Where the phone was when "use my location" filled [basedIn]; cleared
  /// when the place is typed instead, so the two always agree.
  final ({double lat, double lng})? basedInPoint;
  final TravelRange? travelRange;

  /// Years, as typed.
  final String experience;

  /// "I have more than 30 years of experience" (mobile#535): [experience]
  /// may go up to 50, with [experienceCv] behind it.
  final bool claimingExperience;

  /// The CV with references behind a claim, a PDF. Sent as `portfolioFile`.
  final PickedPhoto? experienceCv;

  /// Links to their work, one per place, as typed. All optional.
  final Map<WorkLinkKind, String> links;

  /// Catalog slugs, in the order picked.
  final List<String> specializations;

  /// One of [specializations]: the one they are known for.
  final String? mainSpecialty;

  /// Keyed by specialty slug.
  final Map<String, ProviderSpecialtyDetail> details;
  final Map<KycDocument, PickedPhoto> documents;

  /// Agreed to the Provider Terms on the review screen.
  final bool agreed;

  static const maxPhotos = 6;
  static const maxDescription = 500;

  /// The documents it can't be sent without, out of [askedDocuments]. A
  /// business registration is optional, since many countries let people work
  /// without one (mobile#529).
  static const List<KycDocument> requiredDocuments = [
    KycDocument.validId,
    KycDocument.nbi,
    KycDocument.tinId,
    KycDocument.selfie,
  ];

  /// The documents the wizard asks for, in order.
  static const List<KycDocument> askedDocuments = [
    KycDocument.validId,
    KycDocument.nbi,
    KycDocument.tinId,
    KycDocument.birPermit,
    KycDocument.selfie,
  ];

  /// The filled links as full addresses, in field order, each once.
  List<String> get portfolioLinks => [
        ...{
          for (final kind in WorkLinkKind.values)
            if (normalizeWorkLink(links[kind] ?? '') case final link?) link,
        },
      ];

  /// The fields whose link can't be sent, and why.
  Map<WorkLinkKind, WorkLinkProblem> get linkProblems => {
        for (final kind in WorkLinkKind.values)
          if (workLinkProblem(kind, links[kind] ?? '') case final p?) kind: p,
      };

  /// Whole years up to 30, or 50 when claiming more (mobile#535).
  int? get years =>
      wholeYears(experience, yearsMax(claiming: claimingExperience));

  ExperienceClaimProblem? get experienceProblem => experienceClaimProblem(
        experience: experience,
        claiming: claimingExperience,
        cv: experienceCv,
      );

  /// The picked specialties with the main one first.
  List<String> get orderedSpecializations => [
        if (mainSpecialty != null) mainSpecialty!,
        for (final s in specializations)
          if (s != mainSpecialty) s,
      ];

  ProviderSpecialtyDetail detailFor(String slug) =>
      details[slug] ?? const ProviderSpecialtyDetail();

  bool get businessDone =>
      businessName.trim().isNotEmpty &&
      basedIn.trim().isNotEmpty &&
      (experience.trim().isEmpty || years != null) &&
      experienceProblem == null &&
      linkProblems.isEmpty;

  bool get categoriesDone => specializations.isNotEmpty;

  bool get detailsDone =>
      categoriesDone && specializations.every((s) => detailFor(s).isDone);

  int get documentsMissing =>
      requiredDocuments.where((d) => !documents.containsKey(d)).length;

  bool get documentsDone => documentsMissing == 0;

  bool get isComplete => businessDone && detailsDone && documentsDone && agreed;

  ProviderApplicationDraft copyWith({
    String? businessName,
    String? basedIn,
    ({double lat, double lng})? basedInPoint,
    bool clearBasedInPoint = false,
    TravelRange? travelRange,
    String? experience,
    bool? claimingExperience,
    PickedPhoto? experienceCv,
    bool clearExperienceCv = false,
    Map<WorkLinkKind, String>? links,
    List<String>? specializations,
    String? mainSpecialty,
    bool clearMain = false,
    Map<String, ProviderSpecialtyDetail>? details,
    Map<KycDocument, PickedPhoto>? documents,
    bool? agreed,
  }) =>
      ProviderApplicationDraft(
        businessName: businessName ?? this.businessName,
        basedIn: basedIn ?? this.basedIn,
        basedInPoint:
            clearBasedInPoint ? null : basedInPoint ?? this.basedInPoint,
        travelRange: travelRange ?? this.travelRange,
        experience: experience ?? this.experience,
        claimingExperience: claimingExperience ?? this.claimingExperience,
        experienceCv:
            clearExperienceCv ? null : experienceCv ?? this.experienceCv,
        links: links ?? this.links,
        specializations: specializations ?? this.specializations,
        mainSpecialty: clearMain ? null : mainSpecialty ?? this.mainSpecialty,
        details: details ?? this.details,
        documents: documents ?? this.documents,
        agreed: agreed ?? this.agreed,
      );

  /// The JSON the API reads from `data`. [photoIds] are the uploaded work
  /// photos per specialty slug.
  Map<String, dynamic> toData(Map<String, List<String>> photoIds) => {
        'businessName': businessName.trim(),
        'basedIn': basedIn.trim(),
        if (basedInPoint case final p?) ...{
          'basedInLat': p.lat,
          'basedInLng': p.lng,
        },
        if (travelRange != null) 'travelRange': travelRange!.name,
        if (years != null) 'experience': years,
        if (portfolioLinks.isNotEmpty) 'portfolioUrls': portfolioLinks,
        'specializations': specializations,
        if (mainSpecialty != null) 'mainSpecialty': mainSpecialty,
        'specialtyDetails': [
          for (final slug in specializations)
            {
              'slug': slug,
              'description': detailFor(slug).description.trim(),
              'photoFileIds': photoIds[slug] ?? const <String>[],
            },
        ],
      };

  FormData toForm(Map<String, List<String>> photoIds) => FormData.fromMap({
        'roleType': 'providerFoxer',
        'data': jsonEncode(toData(photoIds)),
        for (final e in documents.entries)
          e.key.field: MultipartFile.fromBytes(
            e.value.bytes,
            filename: e.value.name,
          ),
        // The CV behind more than 30 years (api#508).
        if (claimingExperience && experienceCv != null)
          portfolioFileField: MultipartFile.fromBytes(
            experienceCv!.bytes,
            filename: experienceCv!.name,
          ),
      });

  @override
  List<Object?> get props => [
        businessName,
        basedIn,
        basedInPoint,
        travelRange,
        experience,
        claimingExperience,
        experienceCv?.name,
        links,
        specializations,
        mainSpecialty,
        details,
        documents.keys.toList(),
        agreed,
      ];
}
