.PHONY: all clean build
PREFPANE = DerivedData/Build/Products/Debug/Jitouch.prefPane
DMG = Jitouch.dmg

all: $(DMG)

build: $(PREFPANE)

clean:
	@rm -f Jitouch.dmg
	@xcodebuild clean -workspace Jitouch.xcworkspace -scheme PreferencePane -derivedDataPath DerivedData

$(PREFPANE):
	@xcodebuild build -workspace Jitouch.xcworkspace -scheme PreferencePane -derivedDataPath DerivedData

$(DMG): $(PREFPANE)
	@appdmg appdmg.json Jitouch.dmg

