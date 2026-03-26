#!/bin/sh
DIR="$HOME/.cache/opencode/bin/jdtls"
LAUNCHER=$(ls "$DIR/plugins/org.eclipse.equinox.launcher_"*.jar)
LOMBOK_JAR="$HOME/.lombok/lombok.jar"
WORKSPACE_BASE="$HOME/.cache/jdtls"
if command -v md5sum >/dev/null 2>&1; then
    HASH=$(echo "$PWD" | md5sum | cut -d' ' -f1)
else
    HASH=$(echo "$PWD" | md5 -q)
fi
WORKSPACE="$WORKSPACE_BASE/$HASH"

CONFIG="$DIR/config_mac_arm"

SDKMAN_JAVA_DIR="${SDKMAN_CANDIDATES_DIR:-${SDKMAN_DIR:-$HOME/.sdkman}/candidates}/java"
JDTLS_PINNED_JAVA_HOME="${JDTLS_JAVA_HOME:-$SDKMAN_JAVA_DIR/21.0.9-tem}"

if [ -x "$JDTLS_PINNED_JAVA_HOME/bin/java" ]; then
  JAVA_BIN="$JDTLS_PINNED_JAVA_HOME/bin/java"
elif [ -x "$JAVA_HOME/bin/java" ]; then
  JAVA_BIN="$JAVA_HOME/bin/java"
else
  JAVA_BIN="$(command -v java)"
fi

if [ -z "$JAVA_BIN" ] || [ ! -x "$JAVA_BIN" ]; then
  echo "Failed to locate java runtime for jdtls" >&2
  exit 1
fi

exec "$JAVA_BIN" \
  -Declipse.application=org.eclipse.jdt.ls.core.id1 \
  -Dosgi.bundles.defaultStartLevel=4 \
  -Declipse.product=org.eclipse.jdt.ls.core.product \
  -Dosgi.checkConfiguration=true \
  -Dosgi.sharedConfiguration.area.readOnly=true \
  -Xms1G -Xmx2G \
  -XX:+TieredCompilation \
  -XX:TieredStopAtLevel=1 \
  --add-modules=ALL-SYSTEM \
  --add-exports java.base/jdk.internal.misc=ALL-UNNAMED \
  --add-opens java.base/java.util=ALL-UNNAMED \
  --add-opens java.base/java.lang=ALL-UNNAMED \
  --add-opens java.base/java.io=ALL-UNNAMED \
  --add-opens java.base/java.nio=ALL-UNNAMED \
  --add-opens java.base/sun.nio.ch=ALL-UNNAMED \
  --add-opens java.compiler/javax.annotation.processing=ALL-UNNAMED \
  --add-opens java.compiler/javax.lang.model=ALL-UNNAMED \
  --add-opens java.compiler/javax.lang.model.element=ALL-UNNAMED \
  --add-opens java.compiler/javax.lang.model.type=ALL-UNNAMED \
  --add-opens java.compiler/javax.lang.model.util=ALL-UNNAMED \
  --add-opens java.compiler/javax.tools=ALL-UNNAMED \
  -javaagent:"$LOMBOK_JAR" \
  -jar "$LAUNCHER" \
  -configuration "$CONFIG" \
  -data "$WORKSPACE"
