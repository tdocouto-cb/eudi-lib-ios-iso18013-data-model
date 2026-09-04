/*
Copyright (c) 2026 European Commission

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

//  ValidityInfo.swift
import Foundation
import SwiftCBOR
import OrderedCollections

/// The `ValidityInfo` structure contains information related to the validity of the MSO and its signature
public struct ValidityInfo: Sendable {
	// string tdate from CBOR
	public let signed: String
	public let validFrom: String
	public let validUntil: String
	public let expectedUpdate: String?

	enum Keys: String {
		case signed
		case validFrom
		case validUntil
		case expectedUpdate
	}
	/// Upstream rejects any fractional seconds outright. With
	/// `MdocValidationOptions.tolerateFractionalSecondsInValidityInfo` set the
	/// fraction is trimmed instead, leaving the timezone designator in place:
	/// `2026-09-02T10:22:33.123Z` becomes `2026-09-02T10:22:33Z`.
	static func validatedDateTime(_ value: String, field: Keys) throws(MdocValidationError) -> String {
		guard let dot = value.firstIndex(of: ".") else { return value }
		guard MdocValidationOptions.tolerateFractionalSecondsInValidityInfo else {
			throw .invalidDateTimeFormat("ValidityInfo", field.rawValue)
		}
		let afterDot = value[value.index(after: dot)...]
		let timezone = afterDot.drop(while: \.isNumber)
		return String(value[..<dot]) + String(timezone)
	}

	public init(signed: String, validFrom: String, validUntil: String, expectedUpdate: String? = nil) {
		self.signed = signed
		self.validFrom = validFrom
		self.validUntil = validUntil
		self.expectedUpdate = expectedUpdate
	}
}

extension ValidityInfo: CBORDecodable {
	public init(cbor: CBOR) throws(MdocValidationError) {
		guard case let .map(validityInfoMap) = cbor else { throw .invalidCbor("validity info") }

		guard case .tagged(let signedTag, let signedCbor) = validityInfoMap[Keys.signed],
			  signedTag == .standardDateTimeString,
			  case let .utf8String(signedValue) = signedCbor
		else { throw .missingField("ValidityInfo", Keys.signed.rawValue) }
		signed = try Self.validatedDateTime(signedValue, field: .signed)

		guard case .tagged(let validFromTag, let validFromCbor) = validityInfoMap[Keys.validFrom],
			  validFromTag == .standardDateTimeString,
			  case let .utf8String(validFromValue) = validFromCbor
		else { throw .missingField("ValidityInfo", Keys.validFrom.rawValue) }
		validFrom = try Self.validatedDateTime(validFromValue, field: .validFrom)

		guard case .tagged(let validUntilTag, let validUntilCbor) = validityInfoMap[Keys.validUntil],
			  validUntilTag == .standardDateTimeString,
			  case let .utf8String(validUntilValue) = validUntilCbor
		else { throw .missingField("ValidityInfo", Keys.validUntil.rawValue) }
		validUntil = try Self.validatedDateTime(validUntilValue, field: .validUntil)

		if case .tagged(let expectedUpdateTag, let expectedUpdateCbor) = validityInfoMap[Keys.expectedUpdate],
		   expectedUpdateTag == .standardDateTimeString,
		   case let .utf8String(expectedUpdateValue) = expectedUpdateCbor
		{
			expectedUpdate = try Self.validatedDateTime(expectedUpdateValue, field: .expectedUpdate)
		} else { expectedUpdate = nil }
	}
}

extension ValidityInfo: CBOREncodable {
	public func toCBOR(options: CBOROptions) -> CBOR {
		var map = OrderedDictionary<CBOR, CBOR>()
		map[.utf8String(Keys.signed.rawValue)] = .tagged(.standardDateTimeString, .utf8String(signed))
		map[.utf8String(Keys.validFrom.rawValue)] = .tagged(.standardDateTimeString, .utf8String(validFrom))
		map[.utf8String(Keys.validUntil.rawValue)] = .tagged(.standardDateTimeString, .utf8String(validUntil))
		if let expectedUpdate {
			let expectedUpdateTag = CBOR.tagged(.standardDateTimeString, .utf8String(expectedUpdate))
			map[.utf8String(Keys.expectedUpdate.rawValue)] = expectedUpdateTag
		}
		return .map(map)
	}
}

