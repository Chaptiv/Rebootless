import Foundation

public struct SymptomMatchResult: Identifiable, Sendable {
    public let id: String
    public let recipe: RepairRecipe
    public let confidenceScore: Double // 0.0 to 1.0
    public let matchedPhrase: String
    public let explanation: String
    
    public init(
        id: String = UUID().uuidString,
        recipe: RepairRecipe,
        confidenceScore: Double,
        matchedPhrase: String,
        explanation: String
    ) {
        self.id = id
        self.recipe = recipe
        self.confidenceScore = confidenceScore
        self.matchedPhrase = matchedPhrase
        self.explanation = explanation
    }
}

public struct SymptomMatcher: Sendable {
    public static let shared = SymptomMatcher()
    
    private let recipes: [RepairRecipe]
    
    public init(recipes: [RepairRecipe] = [RepairRecipe.makeQuickLookRecipe()]) {
        self.recipes = recipes
    }
    
    public func match(query: String) -> [SymptomMatchResult] {
        let normalizedQuery = normalize(query)
        guard !normalizedQuery.isEmpty else { return [] }
        
        var results: [SymptomMatchResult] = []
        let queryTokens = Set(tokenize(normalizedQuery))
        
        for recipe in recipes {
            var highestScore: Double = 0.0
            var bestMatchedPhrase: String = ""
            
            // Check exact or partial keyword matches
            for keyword in recipe.keywords {
                let normalizedKeyword = normalize(keyword)
                
                // Exact match
                if normalizedQuery == normalizedKeyword {
                    highestScore = max(highestScore, 1.0)
                    bestMatchedPhrase = keyword
                    break
                }
                
                // Substring containment
                if normalizedQuery.contains(normalizedKeyword) || normalizedKeyword.contains(normalizedQuery) {
                    let score = 0.85
                    if score > highestScore {
                        highestScore = score
                        bestMatchedPhrase = keyword
                    }
                }
                
                // Token overlap
                let keywordTokens = Set(tokenize(normalizedKeyword))
                let commonTokens = queryTokens.intersection(keywordTokens)
                if !commonTokens.isEmpty {
                    let jaccard = Double(commonTokens.count) / Double(queryTokens.union(keywordTokens).count)
                    let score = 0.4 + (jaccard * 0.5)
                    if score > highestScore {
                        highestScore = score
                        bestMatchedPhrase = keyword
                    }
                }
            }
            
            // Check symptoms
            for symptom in recipe.symptoms {
                let normSymptom = normalize(symptom)
                let symptomTokens = Set(tokenize(normSymptom))
                let common = queryTokens.intersection(symptomTokens)
                if !common.isEmpty {
                    let score = Double(common.count) / Double(max(queryTokens.count, 1)) * 0.7
                    if score > highestScore {
                        highestScore = score
                        bestMatchedPhrase = symptom
                    }
                }
            }
            
            if highestScore >= 0.45 {
                let explanation = "Matched '\(bestMatchedPhrase)' relating to the \(recipe.subsystemName) subsystem."
                results.append(SymptomMatchResult(
                    recipe: recipe,
                    confidenceScore: highestScore,
                    matchedPhrase: bestMatchedPhrase,
                    explanation: explanation
                ))
            }
        }
        
        return results.sorted { $0.confidenceScore > $1.confidenceScore }
    }
    
    private func normalize(_ text: String) -> String {
        text.lowercased()
            .folding(options: .diacriticInsensitive, locale: .current)
            .replacingOccurrences(of: "doesn't", with: "does not")
            .replacingOccurrences(of: "can't", with: "cannot")
            .replacingOccurrences(of: "won't", with: "will not")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private func tokenize(_ text: String) -> [String] {
        text.components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { $0.count > 1 }
    }
}
