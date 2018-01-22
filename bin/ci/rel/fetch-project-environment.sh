export PROJECT_DIR=${TRAVIS_BUILD_DIR:=$PWD}
# temporary hardcode here, since we have a single app
export PROJECT_DIR="${PROJECT_DIR}/apps/ehealth"
export PROJECT_NAME=$(sed -n 's/.*app: :\([^, ]*\).*/\1/pg' "${PROJECT_DIR}/mix.exs")
export PROJECT_VERSION=$(sed -n 's/.*@version "\([^"]*\)".*/\1/pg' "${PROJECT_DIR}/mix.exs")
