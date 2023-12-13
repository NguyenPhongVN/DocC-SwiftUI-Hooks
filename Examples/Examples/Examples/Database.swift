import RealmSwift
import Foundation

public extension Realm.Configuration {
  /// Description
  /// - Returns: Configuration
  static func config() -> Realm.Configuration {
    var config = Realm.Configuration()
    config.fileURL = config.fileURL!.deletingLastPathComponent().appendingPathComponent("app.realm")
    config.schemaVersion = 5
    config.migrationBlock = { migration, oldSchemaVersion in
      if oldSchemaVersion < 5 {
        config.deleteRealmIfMigrationNeeded = true
        //        Realm.deleteRealmFile()
      }
    }
    Realm.Configuration.defaultConfiguration = config
    //    Realm.deleteRealmFile()
    return config
  }
}

public extension Realm {
  /// instance Realm
  static let instance: Realm = try! Realm(configuration: Realm.Configuration.config())
}

public extension Realm {
  static func deleteRealmFile() {
    let url = Realm.Configuration.defaultConfiguration.fileURL!
    remove(realmURL: url)
  }
  
  static func remove(realmURL: URL) {
    let realmURLs = [
      realmURL,
      realmURL.appendingPathExtension("lock"),
      realmURL.appendingPathExtension("note"),
      realmURL.appendingPathExtension("management"),
    ]
    for URL in realmURLs {
      try? FileManager.default.removeItem(at: URL)
    }
  }
}

public extension Array where Element: Identifiable {
  func toIdentifiedArray() -> IdentifiedArrayOf<Element> {
    var identifiedArray: IdentifiedArrayOf<Element> = []
    for value in self {
      identifiedArray.updateOrAppend(value)
    }
    return identifiedArray
  }
}

public extension IdentifiedArray {
  func toArray() -> [Element] {
    var array: [Element] = []
    for value in self {
      array.append(value)
    }
    return array
  }
}

public extension IdentifiedArray where Element: Identifiable {
  
  @discardableResult
  mutating func updateOrAppend(_ other: Self) -> Self {
    for item in other {
      self.updateOrAppend(item)
    }
    return self
  }
  
  @discardableResult
  mutating func updateOrAppend(_ other: [Element]) -> Self {
    for item in other {
      self.updateOrAppend(item)
    }
    return self
  }
  
  @discardableResult
  mutating func updateOrAppend(ifLet item: Element?) -> Self {
    guard let item = item else {
      return self
    }
    self.updateOrAppend(item)
    return self
  }
}


// MARK: - Realm Collection Transform to Array
public extension List {
  func toArray() -> Array<Element> {
    Array(self)
  }
}

public extension Results {
  func toArray() -> Array<Element> {
    Array(self)
  }
}

public extension LinkingObjects {
  func toArray() -> Array<Element> {
    Array(self)
  }
}

// MARK: - Realm Collection Transform to IdentifiedArray
public extension List where Element: Identifiable {
  func toIdentifiedArray() -> IdentifiedArrayOf<Element> {
    toArray().toIdentifiedArray()
  }
}

public extension Results where Element: Identifiable {
  func toIdentifiedArray() -> IdentifiedArrayOf<Element> {
    toArray().toIdentifiedArray()
  }
}

public extension LinkingObjects where Element: Identifiable {
  func toIdentifiedArray() -> IdentifiedArrayOf<Element> {
    toArray().toIdentifiedArray()
  }
}

// MARK: - Array to Realm Collection
public extension Array where Element: RealmCollectionValue {
  func toList() -> List<Element> {
    let list: List<Element> = .init()
    list.append(objectsIn: self)
    return list
  }
}

// MARK: - IdentifiedArray to Realm Collection
public extension IdentifiedArrayOf where Element: RealmCollectionValue {
  func toList() -> List<Element> {
    toArray().toList()
  }
}

// MARK: Function database
public func useAddDatabase<O: RealmSwift.Object>(_ object: O) {
  let realm = Realm.instance
  try? realm.write {
    realm.add(object, update: .all)
  }
}

public func useUpdateDatabase<O: RealmSwift.Object>(_ object: O) where O: Identifiable {
  let realm = Realm.instance
  try? realm.write {
    realm.add(object, update: .all)
  }
}

public func usePublisherPhaseDatabase<O: RealmSwift.Object>(
  _ object: O.Type
) -> AsyncPhase<Results<O>, any Error> {
  return usePublisher(.once) {
    let realm = Realm.instance
    return realm.objects(object).collectionPublisher
  }
}

public func useAsyncPhaseDatabase<O: RealmSwift.Object>(
  _ object: O.Type
) -> AsyncPhase<Results<O>, any Error> {
  useAsync(.once) {
    let realm = Realm.instance
    let items = try await realm.objects(object).subscribe(waitForSync: .always)
    return items
  }
}

public func useObjectDatabase<O: RealmSwift.Object>(
  _ object: O.Type
) -> Results<O> {
  let realm = Realm.instance
  return realm.objects(object)
}

public func useDeleteDatabase<O: RealmSwift.Object>(
  _ object: O.Type
) {
  let realm = Realm.instance
  let items = realm.objects(object)
  try! realm.write {
    for item in items {
      realm.delete(item)
    }
  }
}

public func useDeleteDatabase<O: RealmSwift.Object>(
  _ object: O.Type,
  _ id: O.ID
) where O: Identifiable {
  let realm = Realm.instance
  if let item = realm.object(ofType: object, forPrimaryKey: id) {
    try! realm.write {
      realm.delete(item)
    }
  }
}
