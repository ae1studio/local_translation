import Foundation

enum TranslationSessionPlanner {
  enum ConfigurationUpdate: Equatable {
    case create
    case invalidate
  }

  static func configurationUpdate(
    hasExistingConfiguration: Bool,
    existingSourceTag: String?,
    existingTargetTag: String?,
    sourceTag: String?,
    targetTag: String?
  ) -> ConfigurationUpdate {
    if hasExistingConfiguration,
      isSamePair(
        existingSourceTag: existingSourceTag,
        existingTargetTag: existingTargetTag,
        sourceTag: sourceTag,
        targetTag: targetTag
      )
    {
      return .invalidate
    }
    return .create
  }

  static func isSamePair(
    existingSourceTag: String?,
    existingTargetTag: String?,
    sourceTag: String?,
    targetTag: String?
  ) -> Bool {
    existingSourceTag == sourceTag && existingTargetTag == targetTag
  }
}
