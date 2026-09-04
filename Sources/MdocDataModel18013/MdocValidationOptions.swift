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

//  MdocValidationOptions.swift
import Foundation

/// Process-wide knobs for how strictly issuer data is validated.
///
/// Cleverbase addition on top of upstream 0.21.2. Defaults preserve upstream
/// behaviour exactly; a host app opts into leniency deliberately.
public enum MdocValidationOptions {
	/// ISO 18013-5 forbids fractional seconds in the MSO `ValidityInfo` tdate
	/// values, and by default they are rejected with
	/// `MdocValidationError.invalidDateTimeFormat`. Some issuers emit them anyway;
	/// set this to `true` to trim the fraction instead of failing.
	///
	/// Safe with respect to the signature: the parsed strings are informational,
	/// and `IssuerAuth.toCBOR` re-emits the original `msoRawData`, so a verifier
	/// still sees the issuer's own bytes.
	nonisolated(unsafe) public static var tolerateFractionalSecondsInValidityInfo = false
}
