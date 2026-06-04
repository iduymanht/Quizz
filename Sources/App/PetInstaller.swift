import Foundation
import AgentPetCore

/// Downloads a pet pack (pet.json + spritesheet) into `~/.agentpet/pets/<slug>/`.
/// Shared by the Browse gallery and first-run onboarding.
enum PetInstaller {
    private struct PackMeta: Decodable { let id: String?; let spritesheetPath: String }
    private struct LocalPackManifest: Encodable {
        let id: String
        let displayName: String
        let description: String?
        let spritesheetPath: String
    }

    /// Returns the installed pack's id (pet.json `id`), or nil on failure.
    @discardableResult
    static func download(slug: String, petJsonURL: URL, spritesheetURL: URL) async -> String? {
        do {
            let fm = FileManager.default
            let dir = URL(fileURLWithPath: AgentPetPaths.baseDir)
                .appendingPathComponent("pets").appendingPathComponent(slug)
            try fm.createDirectory(at: dir, withIntermediateDirectories: true)

            let (petJsonData, _) = try await URLSession.shared.data(from: petJsonURL)
            let meta = try JSONDecoder().decode(PackMeta.self, from: petJsonData)
            try petJsonData.write(to: dir.appendingPathComponent("pet.json"))

            let (sheetData, _) = try await URLSession.shared.data(from: spritesheetURL)
            try sheetData.write(to: dir.appendingPathComponent(meta.spritesheetPath))

            return meta.id ?? slug
        } catch {
            return nil
        }
    }

    /// Creates a new local pet pack from user-entered metadata and a
    /// spritesheet image. Returns the installed pack's id on success.
    @discardableResult
    static func createLocalPack(displayName: String,
                                description: String?,
                                spritesheetURL: URL) -> String? {
        let fm = FileManager.default
        let cleanName = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        let ext = spritesheetURL.pathExtension.isEmpty ? "png" : spritesheetURL.pathExtension
        let sheetName = "spritesheet.\(ext.lowercased())"

        do {
            let petsDir = URL(fileURLWithPath: AgentPetPaths.baseDir).appendingPathComponent("pets")
            try fm.createDirectory(at: petsDir, withIntermediateDirectories: true)
            let id = uniquePetID(base: safeFolderName(cleanName), in: petsDir)
            let staging = petsDir.appendingPathComponent(".create-\(UUID().uuidString)")
            try fm.createDirectory(at: staging, withIntermediateDirectories: true)
            var committed = false
            defer {
                if !committed {
                    try? fm.removeItem(at: staging)
                }
            }

            let manifest = LocalPackManifest(
                id: id,
                displayName: cleanName,
                description: description?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty,
                spritesheetPath: sheetName
            )

            let data = try JSONEncoder.petManifest.encode(manifest)
            try data.write(to: staging.appendingPathComponent("pet.json"))
            try fm.copyItem(at: spritesheetURL, to: staging.appendingPathComponent(sheetName))

            guard SpriteSlicer.loadPack(directory: staging) != nil else {
                return nil
            }

            let destination = petsDir.appendingPathComponent(id)
            try fm.moveItem(at: staging, to: destination)
            committed = true
            return id
        } catch {
            return nil
        }
    }

    private static func uniquePetID(base: String, in petsDir: URL) -> String {
        let fm = FileManager.default
        let seed = base.isEmpty ? UUID().uuidString : base
        var candidate = seed
        var index = 2
        while fm.fileExists(atPath: petsDir.appendingPathComponent(candidate).path) {
            candidate = "\(seed)-\(index)"
            index += 1
        }
        return candidate
    }

    private static func safeFolderName(_ value: String) -> String {
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_"))
        let scalars = value.unicodeScalars.map { allowed.contains($0) ? Character($0) : "-" }
        let name = String(scalars).trimmingCharacters(in: CharacterSet(charactersIn: "-"))
        return name.isEmpty ? UUID().uuidString : name
    }
}

private extension JSONEncoder {
    static var petManifest: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }
}

private extension String {
    var nilIfEmpty: String? { isEmpty ? nil : self }
}

/// Installs a starter pet on the very first launch so the app isn't empty.
@MainActor
enum DefaultPetBootstrap {
    private static let triedKey = "agentpet.defaultPetTried"
    private static let manifestURL = URL(string: "https://petdex.crafter.run/api/manifest")!
    /// Preferred starter (a non-franchise original); falls back to any pet.
    private static let preferredSlug = "boba"

    struct Entry: Decodable { let slug: String; let spritesheetUrl: String; let petJsonUrl: String }
    private struct Manifest: Decodable { let pets: [Lenient<Entry>] }

    static func installIfNeeded() {
        let d = UserDefaults.standard
        guard !d.bool(forKey: triedKey) else { return }
        guard ImagePetStore.shared.packs.isEmpty, PetController.shared.selectedPetID == nil else {
            d.set(true, forKey: triedKey)
            return
        }
        d.set(true, forKey: triedKey)   // attempt once, even if offline

        Task {
            guard let (data, _) = try? await URLSession.shared.data(from: manifestURL),
                  let manifest = try? JSONDecoder().decode(Manifest.self, from: data) else { return }
            let pets = manifest.pets.compactMap(\.value)
            let pick = pets.first { $0.slug == preferredSlug } ?? pets.first
            guard let pick,
                  let petJsonURL = URL(string: pick.petJsonUrl),
                  let sheetURL = URL(string: pick.spritesheetUrl) else { return }

            let id = await PetInstaller.download(slug: pick.slug, petJsonURL: petJsonURL, spritesheetURL: sheetURL)
            ImagePetStore.shared.reload()
            if let id, PetController.shared.selectedPetID == nil {
                PetController.shared.selectedPetID = id
            }
        }
    }
}

/// Tolerant decode wrapper: a malformed element yields nil instead of failing.
private struct Lenient<T: Decodable>: Decodable {
    let value: T?
    init(from decoder: Decoder) { value = try? T(from: decoder) }
}
