#!/bin/bash

set -e

# if no arguments are passed, create the pre-commit hook
if [ "$#" -eq 0 ]; then
  read -p "Do you want to setup the git pre-commit hook? [Y/n]  " -n 1 -r
  echo
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    # setup pre-commit hook
    DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
    echo -e "#!/bin/bash\n\n./scripts/pre-commit.sh 'placeholder_argument'" > "$DIR/../.git/hooks/pre-commit"
    chmod a+x "$DIR/../.git/hooks/pre-commit"
    echo "pre-commit hook successfully configured"
  else
    echo "pre-commit hook not configured"
  fi
  exit 0
fi

# THE PRE-COMMIT HOOK

# get the directory of this script
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

# get the package name
PACKAGE=$($DIR/get_package_name.sh)

(
  cd "$DIR/.."

  no_unstaged_changes=true
  echo -e "\n\e[1m1. Checking for unstaged changes...\e[0m"
  for staged_file in $(git diff --name-only --cached); do
    git diff --name-only | grep -q "${staged_file}" && echo "You have unstaged changes in '${staged_file}'" && no_unstaged_changes=false || true
  done

  # modified .py files
  pyfiles=$(git diff --cached --name-only -- '*.py')

  # flake8
  flake8_pass=true
  if [ "$pyfiles" != "" ]; then
    echo -e "\n\e[1m2. Running flake8...\e[0m"
    flake8 $pyfiles || flake8_pass=false
  else
    echo -e "\n\e[1m2. Skipping flake8.\e[0m"
  fi

  # pylint
  pylint_pass=true
  if [ "$pyfiles" != "" ]; then
    echo -e "\n\e[1m3. Running pylint...\e[0m"
    pylint $pyfiles || pylint_pass=false
  else
    echo -e "\n\e[1m3. Skipping pylint.\e[0m\n"
  fi

  if [ "$flake8_pass" != "true" ] || [ "$pylint_pass" != "true" ] || [ "$no_unstaged_changes" != "true" ]; then
    echo -e "\e[1m\e[31mSome checks failed.\e[0m\n\n  NOT RECOMMENDED: If you want to skip the pre-commit hook, use the --no-verify flag.\n"
    exit 1
  fi
  echo -e "\e[1m\e[32mAll checks passed.\e[0m\n"
)
