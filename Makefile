.PHONY: all build dist edit clean
PREFPANE = DerivedData/Build/Products/Debug/Jitouch.prefPane
DMG = Jitouch.dmg

all: $(DMG)

build: $(PREFPANE)

dist: $(DMG)

deps: 
	pod install

edit: deps
	open Jitouch.xcworkspace

clean:
	@rm -f Jitouch.dmg
	@xcodebuild clean -workspace Jitouch.xcworkspace -scheme Application -derivedDataPath DerivedData

$(PREFPANE):
	@xcodebuild build -workspace Jitouch.xcworkspace -scheme Application -derivedDataPath DerivedData

$(DMG): $(PREFPANE)
	@npm exec -y appdmg appdmg.json Jitouch.dmg

