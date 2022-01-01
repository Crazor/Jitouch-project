.PHONY: all build dist edit clean
PREFPANE = DerivedData/Build/Products/Debug/Jitouch.prefPane
DMG = Jitouch.dmg

all: $(DMG)

build: $(PREFPANE)

dist: $(DMG)

edit:
	open Jitouch.xcworkspace

clean:
	@rm -f Jitouch.dmg
	@xcodebuild clean -workspace Jitouch.xcworkspace -scheme PreferencePane -derivedDataPath DerivedData

$(PREFPANE):
	@xcodebuild build -workspace Jitouch.xcworkspace -scheme PreferencePane -derivedDataPath DerivedData

$(DMG): $(PREFPANE)
	@npm exec -y appdmg appdmg.json Jitouch.dmg

