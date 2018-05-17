import FluentMySQL

struct UserStatus: RawRepresentable, Codable, Hashable, MySQLEnumType {
    static private(set) var statuses: [Int: String] = [
        0: "admin",
        1: "moderator",
        2: "standard"
    ]
    
    let id: Int
    let name: String
    
    init(id: Int, name: String) {
        self.id = id
        self.name = name

        if UserStatus.statuses[id] == nil {
           UserStatus.statuses[id] = name
        }
    }
    
    static let admin = UserStatus(id: 0, name: "admin")
    static let moderator = UserStatus(id: 1, name: "moderator")
    static let standard = UserStatus(id: 2, name: "standard")
    
    init(from decoder: Decoder)throws {
        let container = try decoder.singleValueContainer()
        let id = try container.decode(Int.self)
        
        if let name = UserStatus.statuses[id] {
            self.init(id: id, name: name)
        } else {
            self.init(id: id, name: "custom-\(id)")
        }
    }
    
    public init(rawValue value: Int) {
        self = .init(rawValue: value)
    }
    
    var rawValue: Int { return self.id }
    
    func encode(to encoder: Encoder)throws {
        var container = encoder.singleValueContainer()
        try container.encode(id)
    }
}

extension UserStatus: ExpressibleByIntegerLiteral {
    public init(integerLiteral value: Int) {
        if let name = UserStatus.statuses[value] {
            self.init(id: value, name: name)
        } else {
            self.init(id: value, name: "custom-\(value)")
        }
    }
}
