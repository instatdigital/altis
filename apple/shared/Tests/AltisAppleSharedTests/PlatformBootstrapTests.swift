import Testing
@testable import AltisAppleShared

@Test
func packageNameIsStable() {
    #expect(PlatformBootstrap.packageName == "AltisAppleShared")
}
