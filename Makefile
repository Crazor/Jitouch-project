.PHONY: all build dist edit clean run reset find
APP = DerivedData/Build/Products/Debug/Jitouch.app
DMG = Jitouch.dmg

all: $(DMG)

build: $(APP)

dist: $(DMG)

deps: 
	pod install

edit: deps
	open Jitouch.xcworkspace

clean:
	@rm -f Jitouch.dmg
	@xcodebuild clean -workspace Jitouch.xcworkspace -scheme Application -derivedDataPath DerivedData

run: $(APP)
	open $(APP)
	make log

reset:
	killall Jitouch ; tccutil reset All app.jitouch.Jitouch

find:
	mdfind "kMDItemCFBundleIdentifier == *Jitouch*"

log:
	log stream --predicate 'sender contains "Jitouch"' --style compact

$(APP):
	@xcodebuild build -workspace Jitouch.xcworkspace -scheme Application -derivedDataPath DerivedData

$(DMG): $(APP)
	@npm exec -y appdmg appdmg.json Jitouch.dmg

