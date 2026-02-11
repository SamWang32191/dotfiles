# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH
export BREW_PATH=/opt/homebrew
export PATH="${BREW_PATH}/bin:$PATH"

# maven
export MAVEN_HOME="${HOME}/DevTools/apache-maven-3.9.12"
export PATH="${MAVEN_HOME}/bin:$PATH"

# Ruby
export RUBY_PATH="${BREW_PATH}/opt/ruby/bin"
export PATH="${RUBY_PATH}:$PATH"

# go path
export GOPATH="${HOME}/DevTools/go"
export PATH="${GOPATH}:$PATH"

# krew
export KREW_PATH="${HOME}/.krew/bin"
export PATH="${KREW_PATH}:$PATH"

# bun
export BUN_PATH="${HOME}/.bun/bin"
export PATH="${BUN_PATH}:$PATH"

# Added by Antigravity
export ANTIGRAVITY_PATH="${HOME}/.antigravity/antigravity/bin"
export PATH="${ANTIGRAVITY_PATH}:$PATH"

# NPM Global
export NPM_GLOBAL="${HOME}/.npm-global/bin"
export PATH="${NPM_GLOBAL}:$PATH"
