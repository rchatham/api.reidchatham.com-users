//import FluentMySQL
import FluentPostgreSQL

/// The permission level of a user.
///
/// An instance of the struct gets stored as an int
/// in a MySQL database using its `id` property.
enum UserStatus: RawRepresentable, Codable, Hashable, PostgreSQLRawEnum { //MySQLEnumType {
    case admin, moderator, standard
    /// Denotes the user as an administer. They can
    /// do (almost) anything.
    ///
    /// ID: 0, Name: `admin`
//    static let admin = UserStatus(id: 0, name: "admin")
    
    /// Denotes a user as a moderator. Less privileges than an
    /// admin, more then standard. Mostly they stop arguments.
    ///
    /// ID: 1, Name: `moderator`
//    static let moderator = UserStatus(id: 1, name: "moderator")
    
    /// Denotes that the user is a standard user. The least amount
    /// of privileges, though there is still plenty they can do.
    /// Unless they hack your service, then they can do a lot...
    ///
    /// ID: 2, Name: `standard`
//    static let standard = UserStatus(id: 2, name: "standard")
    
    /// A storage of all the status names for a given
    /// status ID. When you initialize a new status, this
    /// storage gets updated.
    static private(set) var statuses: [Int: String] = [
        0: "admin",
        1: "moderator",
        2: "standard"
    ]
    
    /// The base value of the status.
    /// This value is what appears in a
    /// JSON representation or the database.
    var id: Int {
        switch self {
        case .admin: return 0
        case .moderator: return 1
        case .standard: return 2
        }
    }
    
    /// A human readable name for the
    /// status. Default value is `custom-<id>`
    var name: String {
        if let name = UserStatus.statuses[id] {
            return name
        } else {
            let name = "custom-\(id)"
            UserStatus.statuses[id] = name
            return name
        }
   }
    
    /// The `id` of the status. This property
    /// is required by the `RawRepresentable` protocol.
    var rawValue: Int { return self.id }
    
    /// Creates a new `UserStatus`.
    ///
    /// - Parameters:
    ///   - id: The identefier for the new status.
    ///   - name: The human readable name for the status.
    ///     If `nil` is passed in, it defaults to `custom-<id>`.
    ///     The name will be set to a stored name if one exists.
    init(id: Int, name: String?) {
        switch id {
        case 0:
            self = .admin
        case 1:
            self = .moderator
        case 2: fallthrough
        default:
            self = .standard
        }

//        self.id = id

//        if let name = UserStatus.statuses[id]{
//           self.name = name
//        } else {
//            self.name = name ?? "custom-\(id)"
//            UserStatus.statuses[id] = self.name
//        }
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let id = try container.decode(Int.self)
        self = .init(rawValue: id)
    }
    
    init(rawValue value: Int) { self = .init(id: value, name: nil) }
    
    func encode(to encoder: Encoder)throws {
        var container = encoder.singleValueContainer()
        try container.encode(id)
    }
    
    static func reflectDecoded() throws -> (UserStatus, UserStatus) {
        return (.admin, .standard)
    }
}

extension UserStatus: ExpressibleByIntegerLiteral {
    init(integerLiteral value: Int) {
        self = .init(rawValue: value)
    }
}
