#!/bin/bash
# This setup works with Travis-CI.
# You need to specify $DOCKER_HUB_ACCOUNT, $DOCKER_USERNAME and $DOCKER_PASSWORD before using this script.
set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

echo "Logging in into Docker Hub";
echo ${DOCKER_PASSWORD} | docker login -u ${DOCKER_USERNAME} --password-stdin

echo "Setting Gih user/password";
git config --global user.email "travis@travis-ci.com";
git config --global user.name "Travis-CI";
git config --global push.default upstream;

# When you use Travis-CI with public repos, you need to add user token so Travis will be able to push tags bag to repo.
if [[ "${GITHUB_TOKEN}" != "" ]]; then
  REPO_URL="https://${GITHUB_TOKEN}@github.com/${TRAVIS_REPO_SLUG}.git";
  git remote add upstream ${REPO_URL} &> /dev/null
fi;

if [[ "${TRAVIS_PULL_REQUEST}" == "false" ]]; then
  # Commit incremented version and release_notes
  git add apps/ehealth/mix.exs docs apps/ehealth/release_notes;
  git commit -m "Increment version [ci skip]";

  echo "Current branch: ${TRAVIS_BRANCH}"
  echo "Trunk branch: ${TRUNK_BRANCH}"
  echo "Build requires maintenance?: ${BUILD_REQUIRES_MAINTENANCE}"
  echo "Maintenance branch: ${MAINTENANCE_BRANCH}"

  if [[ "${TRAVIS_BRANCH}" == "${TRUNK_BRANCH}" && "${BUILD_REQUIRES_MAINTENANCE}" == "0" || "${TRAVIS_BRANCH}" == "${MAINTENANCE_BRANCH}" ]]; then
    ${DIR}/../release/push-container.sh -a $DOCKER_HUB_ACCOUNT -t $TRAVIS_BRANCH -l;

    if [[ "${GITHUB_TOKEN}" != "" ]]; then
      echo "Done. Pushing changes back to origin repo.";
      git push upstream HEAD:$TRAVIS_BRANCH;
      git push upstream HEAD:$TRAVIS_BRANCH --tags;
    else
      echo "Done. Pushing changes back to upstream repo.";
      git push origin HEAD:$TRAVIS_BRANCH;
      git push origin HEAD:$TRAVIS_BRANCH --tags;
    fi;
  else
    echo "[I] This build is not in a trunk or maintenance branch, new version will not be created"
  fi;
else
  echo "[I] This build is a pull request, new version will not be created"
fi;
