set -e

# Type a script or drag a script file from your workspace to insert its path.
FRAMEWORK_NAME="SQLCipher"

SIMULATOR_LIBRARY_PATH="${BUILD_DIR}/${CONFIGURATION}-iphonesimulator/${FRAMEWORK_NAME}.framework"

DEVICE_LIBRARY_PATH="${BUILD_DIR}/${CONFIGURATION}-iphoneos/${FRAMEWORK_NAME}.framework"

DEVICE_BCSYMBOLMAP_PATH="${BUILD_DIR}/${CONFIGURATION}-iphoneos"

DEVICE_DSYM_PATH="${BUILD_DIR}/${CONFIGURATION}-iphoneos/${FRAMEWORK_NAME}.framework.dSYM"
SIMULATOR_DSYM_PATH="${BUILD_DIR}/${CONFIGURATION}-iphonesimulator/${FRAMEWORK_NAME}.framework.dSYM"

UNIVERSAL_LIBRARY_DIR="${BUILD_DIR}/${CONFIGURATION}-iphoneuniversal"

FRAMEWORK="${UNIVERSAL_LIBRARY_DIR}/${FRAMEWORK_NAME}.framework"

OUTPUT_DIR="../SQLCipher-Aggregated"

Xcodebuild -project ${PROJECT_NAME}.Xcodeproj -scheme ${FRAMEWORK_NAME} -sdk iphonesimulator -configuration ${CONFIGURATION} clean install CONFIGURATION_BUILD_DIR=${BUILD_DIR}/${CONFIGURATION}-iphonesimulator

Xcodebuild -project ${PROJECT_NAME}.Xcodeproj -scheme ${FRAMEWORK_NAME} -sdk iphoneos -configuration ${CONFIGURATION} clean install CONFIGURATION_BUILD_DIR=${BUILD_DIR}/${CONFIGURATION}-iphoneos

rm -rf "${UNIVERSAL_LIBRARY_DIR}"

mkdir "${UNIVERSAL_LIBRARY_DIR}"

mkdir "${FRAMEWORK}"

rm -rf "$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR"

cp -r "${DEVICE_LIBRARY_PATH}/." "${FRAMEWORK}"
cp -r "${SIMULATOR_LIBRARY_PATH}/." "${FRAMEWORK}"

lipo "${SIMULATOR_LIBRARY_PATH}/${FRAMEWORK_NAME}" "${DEVICE_LIBRARY_PATH}/${FRAMEWORK_NAME}" -create -output "${FRAMEWORK}/${FRAMEWORK_NAME}" | echo
cp -r "${FRAMEWORK}" "$OUTPUT_DIR"

cp -r "${DEVICE_DSYM_PATH}" "$OUTPUT_DIR"
lipo -create -output "$OUTPUT_DIR/${FRAMEWORK_NAME}.framework.dSYM/Contents/Resources/DWARF/${FRAMEWORK_NAME}" \
"${DEVICE_DSYM_PATH}/Contents/Resources/DWARF/${FRAMEWORK_NAME}" \
"${SIMULATOR_DSYM_PATH}/Contents/Resources/DWARF/${FRAMEWORK_NAME}" || exit 1

UUIDs=$(dwarfdump --uuid "${DEVICE_DSYM_PATH}" | cut -d ' ' -f2)
for file in `find "${DEVICE_BCSYMBOLMAP_PATH}" -name "*.bcsymbolmap" -type f`; do
fileName=$(basename "$file" ".bcsymbolmap")
for UUID in $UUIDs; do
if [[ "$UUID" = "$fileName" ]]; then
cp -R "$file" "$OUTPUT_DIR"
dsymutil --symbol-map "$OUTPUT_DIR"/"$fileName".bcsymbolmap "$OUTPUT_DIR/${FRAMEWORK_NAME}.framework.dSYM"
fi
done
done
