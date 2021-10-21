import XCTest

fileprivate enum Constant {
    static let allDescriptionSeperator = "\n"
    static let foundElementsPrefix = "\t"
    static let foundElementsSeperator = ","
    static let foundElementsDescriptionPrefix = "Elements on the page:\n"
    static let foundElementsDescriptionSeperator = ": "
    static let foundElementsDescriptionSuffix = "\n"
    static let identifier = "identifier"
    static let identifierSeperator = ":"
    static let notFoundElementsDescriptionPrefix = "\nCouldn't find "
    static let notFoundElementsDescriptionSuffix = "elements.\n"
    static let notFoundElementsRedundantChar = "'"
    static let notFoundElementsSeperator = ", "
    static let notFoundElementsSearchingSeperator = "Descendants matching type"
    static let notFoundElementsSearchingInclude = "Elements matching predicate"
    static let predicate = "predicate"
}

extension Array where Element: XCTNSPredicateExpectation {
    func summaryDescription() -> String {
        var notFoundElementsWithIdentifiers = [(identifier: String, element: String)]()
        var elementsTypeNotExpectedText: String = .init()

        let notFoundElementsDescription = description.components(separatedBy: Constant.notFoundElementsSearchingSeperator)
            .filter { $0.contains(Constant.notFoundElementsSearchingInclude) }
            .compactMap { line -> String? in
                guard let identifier = line.components(separatedBy: Constant.predicate).last?.components(separatedBy: .whitespaces).prefix(2).last,
                      let element = line.components(separatedBy: .newlines).first?.components(separatedBy: .whitespaces).last else { return nil }
                notFoundElementsWithIdentifiers.append((identifier, element))
                return identifier.replacingOccurrences(of: Constant.notFoundElementsRedundantChar, with: "") + Constant.notFoundElementsSeperator
            }

        let foundElementsDescription = XCUIApplication().debugDescription.components(separatedBy: .newlines)
            .filter { $0.contains(Constant.identifier) }
            .compactMap { description -> String? in
                let words = description.removeSpaces().components(separatedBy: Constant.foundElementsSeperator)
                guard let element = words.first,
                      let identifier = words.first(where: { $0.contains(Constant.identifier) })?.components(separatedBy: Constant.identifierSeperator).last else { return nil }
                if notFoundElementsWithIdentifiers.first(where: {
                    identifier.removeNonAlphanumericCharacters == $0.identifier.removeNonAlphanumericCharacters && element != $0.element
                }).isNotNil {
                    elementsTypeNotExpectedText += "Element type for \(identifier) must be '\(element)'.\n"
                }
                return Constant.foundElementsPrefix + element + Constant.foundElementsDescriptionSeperator + identifier
            }
        return notFoundElementsDescription.reduce(Constant.notFoundElementsDescriptionPrefix, { $0 + $1 }) +
            Constant.notFoundElementsDescriptionSuffix + elementsTypeNotExpectedText +
            foundElementsDescription.reduce(Constant.foundElementsDescriptionPrefix, { $0 + $1 + Constant.foundElementsDescriptionSuffix })
    }
}
