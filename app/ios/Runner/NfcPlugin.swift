import Flutter
import UIKit
import CoreNFC

/// Plugin NFC pour iOS utilisant CoreNFC
@available(iOS 11.0, *)
class NfcPlugin: NSObject, FlutterPlugin {

    private var channel: FlutterMethodChannel?
    private var nfcSession: NFCNDEFReaderSession?
    private var nfcTagSession: NFCTagReaderSession?
    private var pendingResult: FlutterResult?
    private var isWriting: Bool = false
    private var dataToWrite: String?

    static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "com.cardscontrol.app/nfc", binaryMessenger: registrar.messenger())
        let instance = NfcPlugin()
        instance.channel = channel
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "isNfcAvailable":
            result(NFCNDEFReaderSession.readingAvailable)

        case "isNfcEnabled":
            // iOS n'a pas de paramètre "activé/désactivé" comme Android
            result(NFCNDEFReaderSession.readingAvailable)

        case "openNfcSettings":
            // Ouvrir les paramètres généraux (pas de paramètres NFC spécifiques sur iOS)
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
            }
            result(true)

        case "getNfcInfo":
            result(getNfcInfo())

        case "startReading":
            startReading(result: result)

        case "stopReading":
            stopReading()
            result(true)

        case "startWriting":
            if let args = call.arguments as? [String: Any],
               let data = args["data"] as? String {
                startWriting(data: data, result: result)
            } else {
                result(FlutterError(code: "INVALID_ARGUMENT", message: "Data is required", details: nil))
            }

        case "stopWriting":
            stopWriting()
            result(true)

        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func getNfcInfo() -> [String: Any] {
        return [
            "isAvailable": NFCNDEFReaderSession.readingAvailable,
            "isEnabled": NFCNDEFReaderSession.readingAvailable,
            "hasHce": false, // iOS ne supporte pas HCE
            "hasHceF": false,
            "hasNfcA": NFCNDEFReaderSession.readingAvailable,
            "hasNfcB": NFCNDEFReaderSession.readingAvailable,
            "hasNfcF": NFCNDEFReaderSession.readingAvailable,
            "hasNfcV": NFCNDEFReaderSession.readingAvailable,
            "hasIsoDep": NFCNDEFReaderSession.readingAvailable,
            "hasMifareClassic": false, // Non supporté sur iOS
            "hasMifareUltralight": NFCNDEFReaderSession.readingAvailable
        ]
    }

    private func startReading(result: @escaping FlutterResult) {
        guard NFCNDEFReaderSession.readingAvailable else {
            result(FlutterError(code: "NFC_NOT_AVAILABLE", message: "NFC is not available on this device", details: nil))
            return
        }

        isWriting = false
        pendingResult = result

        if #available(iOS 13.0, *) {
            // Utiliser NFCTagReaderSession pour plus de contrôle
            nfcTagSession = NFCTagReaderSession(pollingOption: [.iso14443, .iso15693, .iso18092], delegate: self)
            nfcTagSession?.alertMessage = "Approchez un tag NFC"
            nfcTagSession?.begin()
        } else {
            // Fallback pour iOS 11-12
            nfcSession = NFCNDEFReaderSession(delegate: self, queue: nil, invalidateAfterFirstRead: true)
            nfcSession?.alertMessage = "Approchez un tag NFC"
            nfcSession?.begin()
        }

        result(true)
    }

    private func stopReading() {
        nfcSession?.invalidate()
        nfcSession = nil

        if #available(iOS 13.0, *) {
            nfcTagSession?.invalidate()
            nfcTagSession = nil
        }
    }

    private func startWriting(data: String, result: @escaping FlutterResult) {
        guard NFCNDEFReaderSession.readingAvailable else {
            result(FlutterError(code: "NFC_NOT_AVAILABLE", message: "NFC is not available on this device", details: nil))
            return
        }

        isWriting = true
        dataToWrite = data
        pendingResult = result

        if #available(iOS 13.0, *) {
            nfcTagSession = NFCTagReaderSession(pollingOption: [.iso14443], delegate: self)
            nfcTagSession?.alertMessage = "Approchez un tag NFC pour écrire"
            nfcTagSession?.begin()
        } else {
            result(FlutterError(code: "NOT_SUPPORTED", message: "Writing requires iOS 13+", details: nil))
        }

        result(true)
    }

    private func stopWriting() {
        isWriting = false
        dataToWrite = nil

        if #available(iOS 13.0, *) {
            nfcTagSession?.invalidate()
            nfcTagSession = nil
        }
    }

    private func sendTagData(_ tagData: [String: Any]) {
        DispatchQueue.main.async {
            self.channel?.invokeMethod("onTagRead", arguments: tagData)
        }
    }

    private func sendWriteResult(success: Bool, error: String?) {
        DispatchQueue.main.async {
            self.channel?.invokeMethod("onTagWritten", arguments: [
                "success": success,
                "error": error as Any
            ])
        }
    }
}

// MARK: - NFCNDEFReaderSessionDelegate
@available(iOS 11.0, *)
extension NfcPlugin: NFCNDEFReaderSessionDelegate {

    func readerSession(_ session: NFCNDEFReaderSession, didInvalidateWithError error: Error) {
        let nfcError = error as? NFCReaderError
        if nfcError?.code != .readerSessionInvalidationErrorFirstNDEFTagRead &&
           nfcError?.code != .readerSessionInvalidationErrorUserCanceled {
            sendTagData(["error": error.localizedDescription])
        }
    }

    func readerSession(_ session: NFCNDEFReaderSession, didDetectNDEFs messages: [NFCNDEFMessage]) {
        var tagData: [String: Any] = [
            "id": "",
            "techList": ["NDEF"]
        ]

        if !messages.isEmpty {
            tagData["ndefMessage"] = parseNdefMessage(messages[0])
        }

        sendTagData(tagData)
    }

    private func parseNdefMessage(_ message: NFCNDEFMessage) -> [[String: Any]] {
        return message.records.map { record in
            var recordData: [String: Any] = [
                "tnf": record.typeNameFormat.rawValue,
                "type": record.type.hexEncodedString(),
                "typeString": String(data: record.type, encoding: .ascii) ?? "",
                "id": record.identifier.hexEncodedString(),
                "payload": record.payload.hexEncodedString()
            ]

            // Parse payload
            if let payloadString = parsePayload(record) {
                recordData["payloadString"] = payloadString
            }

            return recordData
        }
    }

    private func parsePayload(_ record: NFCNDEFPayload) -> String? {
        switch record.typeNameFormat {
        case .nfcWellKnown:
            if record.type == "T".data(using: .ascii) {
                // Text record
                return parseTextRecord(record.payload)
            } else if record.type == "U".data(using: .ascii) {
                // URI record
                return record.wellKnownTypeURIPayload()?.absoluteString
            }
        case .absoluteURI:
            return String(data: record.payload, encoding: .utf8)
        case .media:
            return String(data: record.payload, encoding: .utf8)
        default:
            break
        }
        return nil
    }

    private func parseTextRecord(_ payload: Data) -> String? {
        guard payload.count > 0 else { return nil }

        let statusByte = payload[0]
        let languageCodeLength = Int(statusByte & 0x3F)
        let encoding: String.Encoding = (statusByte & 0x80) != 0 ? .utf16 : .utf8

        guard payload.count > languageCodeLength + 1 else { return nil }

        let textData = payload.subdata(in: (languageCodeLength + 1)..<payload.count)
        return String(data: textData, encoding: encoding)
    }
}

// MARK: - NFCTagReaderSessionDelegate (iOS 13+)
@available(iOS 13.0, *)
extension NfcPlugin: NFCTagReaderSessionDelegate {

    func tagReaderSessionDidBecomeActive(_ session: NFCTagReaderSession) {
        // Session active
    }

    func tagReaderSession(_ session: NFCTagReaderSession, didInvalidateWithError error: Error) {
        let nfcError = error as? NFCReaderError
        if nfcError?.code != .readerSessionInvalidationErrorUserCanceled {
            if isWriting {
                sendWriteResult(success: false, error: error.localizedDescription)
            } else {
                sendTagData(["error": error.localizedDescription])
            }
        }
    }

    func tagReaderSession(_ session: NFCTagReaderSession, didDetect tags: [NFCTag]) {
        guard let tag = tags.first else {
            session.invalidate(errorMessage: "Aucun tag détecté")
            return
        }

        session.connect(to: tag) { error in
            if let error = error {
                session.invalidate(errorMessage: "Connexion échouée: \(error.localizedDescription)")
                return
            }

            if self.isWriting {
                self.writeToTag(session: session, tag: tag)
            } else {
                self.readFromTag(session: session, tag: tag)
            }
        }
    }

    private func readFromTag(session: NFCTagReaderSession, tag: NFCTag) {
        var tagData: [String: Any] = [:]

        switch tag {
        case .iso7816(let iso7816Tag):
            tagData["id"] = iso7816Tag.identifier.hexEncodedString()
            tagData["techList"] = ["ISO7816", "IsoDep"]
            tagData["isoDep"] = [
                "historicalBytes": iso7816Tag.historicalBytes?.hexEncodedString() ?? "",
                "applicationData": iso7816Tag.applicationData?.hexEncodedString() ?? ""
            ]
            readNdef(from: tag, tagData: &tagData, session: session)

        case .miFare(let mifareTag):
            tagData["id"] = mifareTag.identifier.hexEncodedString()

            switch mifareTag.mifareFamily {
            case .ultralight:
                tagData["techList"] = ["MifareUltralight", "NfcA"]
                tagData["mifareUltralight"] = [
                    "type": "Ultralight"
                ]
            case .desfire:
                tagData["techList"] = ["MifareDesfire", "IsoDep"]
            case .plus:
                tagData["techList"] = ["MifarePlus", "NfcA"]
            default:
                tagData["techList"] = ["Mifare"]
            }
            readNdef(from: tag, tagData: &tagData, session: session)

        case .iso15693(let iso15693Tag):
            tagData["id"] = iso15693Tag.identifier.hexEncodedString()
            tagData["techList"] = ["ISO15693", "NfcV"]
            tagData["nfcV"] = [
                "dsfId": iso15693Tag.icManufacturerCode,
                "icSerialNumber": iso15693Tag.icSerialNumber.hexEncodedString()
            ]
            sendTagData(tagData)
            session.invalidate()

        case .feliCa(let felicaTag):
            tagData["id"] = felicaTag.currentIDm.hexEncodedString()
            tagData["techList"] = ["FeliCa", "NfcF"]
            tagData["nfcF"] = [
                "systemCode": felicaTag.currentSystemCode.hexEncodedString(),
                "manufacturer": felicaTag.currentIDm.hexEncodedString()
            ]
            sendTagData(tagData)
            session.invalidate()

        @unknown default:
            session.invalidate(errorMessage: "Type de tag non supporté")
        }
    }

    private func readNdef(from tag: NFCTag, tagData: inout [String: Any], session: NFCTagReaderSession) {
        var ndefTag: NFCNDEFTag?

        switch tag {
        case .iso7816(let iso7816Tag):
            ndefTag = iso7816Tag
        case .miFare(let mifareTag):
            ndefTag = mifareTag
        default:
            sendTagData(tagData)
            session.invalidate()
            return
        }

        guard let ndef = ndefTag else {
            sendTagData(tagData)
            session.invalidate()
            return
        }

        var mutableTagData = tagData

        ndef.queryNDEFStatus { status, capacity, error in
            if error == nil {
                mutableTagData["ndefMaxSize"] = capacity
                mutableTagData["ndefIsWritable"] = (status == .readWrite)
                mutableTagData["ndefType"] = "NFC Forum Type 4"

                ndef.readNDEF { message, error in
                    if let message = message {
                        mutableTagData["ndefMessage"] = self.parseNdefMessage(message)
                    }
                    self.sendTagData(mutableTagData)
                    session.alertMessage = "Tag lu avec succès"
                    session.invalidate()
                }
            } else {
                self.sendTagData(mutableTagData)
                session.invalidate()
            }
        }
    }

    private func writeToTag(session: NFCTagReaderSession, tag: NFCTag) {
        guard let data = dataToWrite else {
            session.invalidate(errorMessage: "Aucune donnée à écrire")
            sendWriteResult(success: false, error: "No data to write")
            return
        }

        var ndefTag: NFCNDEFTag?

        switch tag {
        case .iso7816(let iso7816Tag):
            ndefTag = iso7816Tag
        case .miFare(let mifareTag):
            ndefTag = mifareTag
        default:
            session.invalidate(errorMessage: "Ce tag ne supporte pas l'écriture NDEF")
            sendWriteResult(success: false, error: "Tag does not support NDEF")
            return
        }

        guard let ndef = ndefTag else {
            session.invalidate(errorMessage: "Impossible d'accéder au tag NDEF")
            sendWriteResult(success: false, error: "Cannot access NDEF tag")
            return
        }

        ndef.queryNDEFStatus { status, capacity, error in
            guard error == nil else {
                session.invalidate(errorMessage: "Erreur de lecture: \(error!.localizedDescription)")
                self.sendWriteResult(success: false, error: error!.localizedDescription)
                return
            }

            guard status == .readWrite else {
                session.invalidate(errorMessage: "Le tag n'est pas inscriptible")
                self.sendWriteResult(success: false, error: "Tag is not writable")
                return
            }

            // Créer le message NDEF
            let payload = NFCNDEFPayload.wellKnownTypeTextPayload(
                string: data,
                locale: Locale(identifier: "en")
            )!

            let message = NFCNDEFMessage(records: [payload])

            // Vérifier la taille
            guard message.length <= capacity else {
                session.invalidate(errorMessage: "Données trop grandes pour ce tag")
                self.sendWriteResult(success: false, error: "Data too large for tag (max: \(capacity) bytes)")
                return
            }

            // Écrire
            ndef.writeNDEF(message) { error in
                if let error = error {
                    session.invalidate(errorMessage: "Erreur d'écriture: \(error.localizedDescription)")
                    self.sendWriteResult(success: false, error: error.localizedDescription)
                } else {
                    session.alertMessage = "Écriture réussie !"
                    session.invalidate()
                    self.sendWriteResult(success: true, error: nil)
                }
            }
        }
    }
}

// MARK: - Data Extension
extension Data {
    func hexEncodedString() -> String {
        return map { String(format: "%02X", $0) }.joined()
    }
}
