@default:
    just --list

install:
    bundle install

test:
    rake spec

lint:
    rubocop -a

console:
    pry -r ./config/environment

make-lint-config:
    rubocop --auto-gen-config
