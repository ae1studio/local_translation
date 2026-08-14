import Foundation

enum TranslationSessionPlanner {
  static func isSamePair(
    existingSourceTag: String?,
    existingTargetTag: String?,
    sourceTag: String?,
    targetTag: String?
  ) -> Bool {
    existingSourceTag == sourceTag && existingTargetTag == targetTag
  }
}
