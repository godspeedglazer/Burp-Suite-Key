import Foundation
import CommonCrypto

class KeyGenLogic {
    static let desKey = "burpr0x!".data(using: .utf8)!
    
    // Hex Strings from sdmrf
    static let n2048 = "9D9DF9EB49890DE8F193C89598584BC947BA83727B2D89AA8BE3A4689130FE2E948967D40B656762F9989E59C9655E28E33FD4B4A544126FDD90A566BB61C2D7C74A6829265767B56E28FD2214D4BEB3B1DA4722BC394E2E6AFA0F1689FA9DB442643DDDA84997C5AD15B57EE5BD1A357CABF6ED4CAAA5FB8872E07C8F5FAE1C573C1214DD273C6D8887D7E993208D75118CC2305D60AA337B0999B69988322A8FAA9FBFF49AB70B71723E1CBD79D12640AF19E6FBC28C05E6630414DBAD9AEF912D0AC53E40B7F48EE29BFE1DEFCFB0BDB1B6C5BF8B06DCCA15FA1FC3F468952D481070C92C386D3CE6187B062038A6CA822D352ECEBEAC195918F9BB5C3AC3"
    static let d2048 = "5DAD71C754BA3F692E835E1903259F4D6EF33C82C3110A9C316E47DDDA455B1D062D306787AA6A2B1A1B8A29E517F941A5E6DF1DCA87CDC96CCF366EFB799C1B31185915F3F2C8F1BD1A61706B1F1284AC7506087004432235748F991EC2B40E59D3482DC08294D0E9115900A5BCA1A21E89FA45896677262B2FD39A54805273162D655F1AB4392CE4E01A4DD63F7EF387B79D53B73BBE45EA7D9BE64A627CFB3DAE2843E85ED3697672BD4832F5EEB4C18C4D15FEB550E0B5A7018A3CD39A9FD4BDA35A6F88BD00CCBC787419AD57C54FA823EC3D7662710B03C2622E9E2DE546B21CA1C76672B1CC6BD92871A0F96051E31CB060E0DDB4022BEB2897A88761"
    
    static let n1024 = "8D187233EB87AB60DB5BAE8453A7DE035428EB177EC8C60341CAB4CF487052751CA8AFF226EA3E98F0CEEF8AAE12E3716B8A20A24BDE20703865C9DBD9543F92EA6495763DFD6F7507B8607F2A14F52694BB9793FE12D3D9C5D1C0045262EA5E7FA782ED42568C6B7E31019FFFABAEFB79D327A4A7ACBD4D547ACB2DC9CD0403"
    static let d1024 = "7172A188DBAD977FE680BE3EC9E0E4E33A4D385208F0383EB02CE3DAF33CD520332DF362BA2588B58292710AC9D2882C4F329DF0C11DD66944FF9B21F98A031ED27C19FE2BCF8A09AD3E254A0FD7AB89E0D1E756BCF37ED24D42D1977EA7C1C78ABF4D13F752AE48B426A2DC98C5D13B2313609FAA6441E835DC61D17A01D1A9"

    static func generateLicense(name: String, loaderPath: String) -> String {
        if name.isEmpty { return "" }
        var components = [String]()
        components.append(randomString(length: 32))
        components.append("license")
        components.append(name)
        components.append("4102415999000") // 2099
        components.append("1")
        components.append("full")
        
        let signatureBytes = getSignatureBytes(list: components)
        guard let sig2048 = signData(data: signatureBytes, n: n2048, d: d2048, algo: "SHA256withRSA", path: loaderPath),
              let sig1024 = signData(data: signatureBytes, n: n1024, d: d1024, algo: "SHA1withRSA", path: loaderPath) else {
            return "Bridge Failed"
        }
        
        components.append(sig2048)
        components.append(sig1024)
        return prepareArray(list: components)
    }

    static func generateActivation(requestData: String, loaderPath: String) -> String {
        guard !requestData.isEmpty, let decodedRequest = decodeRequest(requestData), decodedRequest.count >= 4 else {
            return ""
        }
        
        var components = [String]()
        components.append("0.4315672535134567")
        components.append(decodedRequest[0])
        components.append("activation")
        components.append(decodedRequest[1])
        components.append("True")
        components.append("")
        components.append(decodedRequest[2])
        components.append(decodedRequest[3])
        
        let signatureBytes = getSignatureBytes(list: components)
        guard let sig2048 = signData(data: signatureBytes, n: n2048, d: d2048, algo: "SHA256withRSA", path: loaderPath),
              let sig1024 = signData(data: signatureBytes, n: n1024, d: d1024, algo: "SHA1withRSA", path: loaderPath) else {
            return "Bridge Failed"
        }
        
        components.append(sig2048)
        components.append(sig1024)
        return prepareArray(list: components)
    }
    
    // java crypto bridge, don't touch
    private static func signData(data: Data, n: String, d: String, algo: String, path: String) -> String? {
        let dataHex = data.map { String(format: "%02x", $0) }.joined()
        let task = Process()
        let pipe = Pipe()
        
        task.executableURL = URL(fileURLWithPath: "/bin/zsh")
        
        // yeah can't uncompile now bitchesssss
        task.arguments = ["-l", "-c", "java -noverify -cp \"\(path)\" com.h3110w0r1d.burploaderkeygen.Loader \(n) \(d) \(algo) \(dataHex)"]
        
        task.standardOutput = pipe
        
        do {
            try task.run()
            let outputData = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: outputData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
            return (output?.isEmpty == false) ? output : nil
        } catch {
            return nil
        }
    }
    
    private static func decodeRequest(_ base64String: String) -> [String]? {
        guard let rawData = Data(base64Encoded: base64String.trimmingCharacters(in: .whitespacesAndNewlines)),
              let decryptedData = desOperation(data: rawData, operation: CCOperation(kCCDecrypt)) else { return nil }
        return decryptedData.split(separator: 0).compactMap { String(data: $0, encoding: .utf8) }
    }
    
    private static func prepareArray(list: [String]) -> String {
        let signatureBytes = getSignatureBytes(list: list)
        guard let encryptedData = desOperation(data: signatureBytes, operation: CCOperation(kCCEncrypt)) else { return "" }
        return encryptedData.base64EncodedString()
    }
    
    private static func getSignatureBytes(list: [String]) -> Data {
        var data = Data()
        for i in 0..<list.count {
            if let stringData = list[i].data(using: .utf8) { data.append(stringData) }
            if i < list.count - 1 { data.append(0) }
        }
        return data
    }
    
    private static func randomString(length: Int) -> String {
        let letters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890"
        return String((0..<length).map { _ in letters.randomElement()! })
    }
    
    private static func desOperation(data: Data, operation: CCOperation) -> Data? {
        let options = CCOptions(kCCOptionPKCS7Padding | kCCOptionECBMode)
        var outBuffer = Data(count: data.count + kCCBlockSizeDES)
        let outCount = outBuffer.count
        var numBytesProcessed: Int = 0
        
        let status = outBuffer.withUnsafeMutableBytes { outBytes in
            data.withUnsafeBytes { dataBytes in
                desKey.withUnsafeBytes { keyBytes in
                    CCCrypt(operation, CCAlgorithm(kCCAlgorithmDES), options,
                            keyBytes.baseAddress, kCCKeySizeDES, nil,
                            dataBytes.baseAddress, data.count,
                            outBytes.baseAddress, outCount, &numBytesProcessed)
                }
            }
        }
        return status == kCCSuccess ? outBuffer.prefix(numBytesProcessed) : nil
    }
}
