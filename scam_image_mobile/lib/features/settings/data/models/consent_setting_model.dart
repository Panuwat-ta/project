import '../../domain/entities/consent_setting.dart';

/// Data-layer model for [ConsentSetting].
///
/// Adds JSON serialisation helpers used by the remote data source.
class ConsentSettingModel extends ConsentSetting {
  const ConsentSettingModel({
    required super.processingConsent,
    required super.historyConsent,
    required super.researchConsent,
  });

  factory ConsentSettingModel.fromJson(Map<String, dynamic> json) =>
      ConsentSettingModel(
        processingConsent:
            json['processingConsent'] as bool? ??
            json['processing_consent'] as bool? ??
            true,
        historyConsent:
            json['historyConsent'] as bool? ??
            json['history_consent'] as bool? ??
            true,
        researchConsent:
            json['researchConsent'] as bool? ??
            json['research_consent'] as bool? ??
            false,
      );

  factory ConsentSettingModel.fromDomain(ConsentSetting setting) =>
      ConsentSettingModel(
        processingConsent: setting.processingConsent,
        historyConsent: setting.historyConsent,
        researchConsent: setting.researchConsent,
      );

  Map<String, dynamic> toJson() => {
        'processingConsent': processingConsent,
        'historyConsent': historyConsent,
        'researchConsent': researchConsent,
      };
}
